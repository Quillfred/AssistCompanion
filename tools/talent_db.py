#!/usr/bin/env python3
"""Talent database from the game's own data (SimC's generated trait and spell text tables).

Writes docs/talents/<class>.md: every class, spec and hero talent for the class, with its spell ID,
choice nodes, what it replaces, tooltip text, flags for what can change the addon's suggestions
(cooldowns, resources, button replacements, empowers, charges, durations, target counts), and
whether the addon already uses the spell.

    SIMC=/path/to/simc python3 tools/talent_db.py deathknight evoker

SIMC defaults to ../simc next to the repository (see tools/README.md). Healer specs are left out
unless --healers is given.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SIMC = os.environ.get("SIMC", os.path.join(os.path.dirname(ROOT), "simc"))
GEN = os.path.join(SIMC, "engine", "dbc", "generated")

CLASSES = {
    "warrior": 1, "paladin": 2, "hunter": 3, "rogue": 4, "priest": 5, "deathknight": 6, "shaman": 7,
    "mage": 8, "warlock": 9, "monk": 10, "druid": 11, "demonhunter": 12, "evoker": 13,
}
CLASS_NAMES = {1: "Warrior", 2: "Paladin", 3: "Hunter", 4: "Rogue", 5: "Priest", 6: "Death Knight",
               7: "Shaman", 8: "Mage", 9: "Warlock", 10: "Monk", 11: "Druid", 12: "Demon Hunter", 13: "Evoker"}
SPECS = {
    71: "Arms", 72: "Fury", 73: "Protection", 65: "Holy", 66: "Protection", 70: "Retribution",
    253: "Beast Mastery", 254: "Marksmanship", 255: "Survival", 259: "Assassination", 260: "Outlaw",
    261: "Subtlety", 256: "Discipline", 257: "Holy", 258: "Shadow", 250: "Blood", 251: "Frost",
    252: "Unholy", 262: "Elemental", 263: "Enhancement", 264: "Restoration", 62: "Arcane", 63: "Fire",
    64: "Frost", 265: "Affliction", 266: "Demonology", 267: "Destruction", 268: "Brewmaster",
    269: "Windwalker", 270: "Mistweaver", 102: "Balance", 103: "Feral", 104: "Guardian",
    105: "Restoration", 577: "Havoc", 581: "Vengeance", 1480: "Devourer", 1467: "Devastation",
    1468: "Preservation", 1473: "Augmentation",
}
SPEC_CLASS = {1: (71, 72, 73), 2: (65, 66, 70), 3: (253, 254, 255), 4: (259, 260, 261), 5: (256, 257, 258),
              6: (250, 251, 252), 7: (262, 263, 264), 8: (62, 63, 64), 9: (265, 266, 267),
              10: (268, 269, 270), 11: (102, 103, 104, 105), 12: (577, 581, 1480), 13: (1467, 1468, 1473)}
HEALERS = {65, 256, 257, 264, 270, 105, 1468}
TREES = {1: "class", 2: "spec", 3: "hero"}
NODE_TYPES = {0: "", 1: "tiered", 2: "choice", 3: "hero choice"}

CSTR = r'"((?:[^"\\]|\\.)*)"'
TRAIT_RE = re.compile(
    r"\{\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+),"
    r"\s*(-?\d+),\s*(-?\d+),\s*(-?\d+),\s*" + CSTR +
    r",\s*\{\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+)\s*\},\s*\{[^}]*\},\s*(\d+),\s*(\d+)\s*\}")
SUBTREE_RE = re.compile(r"\{\s*(\d+),\s*" + CSTR + r",\s*(\d+)\s*\}")
TEXT_RE = re.compile(r"^\s*\{\s*(\d+),\s*(?:" + CSTR + r"|0)\s*,")
NAME_RE = re.compile(r'^\s*\{\s*"((?:[^"\\]|\\.)*)"\s*,\s*(\d+),')
# sc_spell_data rows: name, id, ..., min range, max range, cooldown (ms), gcd (ms), ...; fields 16/17.
RACIAL_RE = re.compile(r"\{\s*0x([0-9a-fA-F]+),\s*0x([0-9a-fA-F]+),\s*(\d+),\s*" + CSTR + r"\s*\}")
MASTERY_RE = re.compile(r"\{\s*(\d+),\s*(\d+)\s*\}")
# Bit positions in the racial table's race mask (bit = n - 1). SimC's own numbering, which follows
# the game's race IDs only up to 11 (engine/util/util.cpp, util::race_id).
RACES = {1: "Human", 2: "Orc", 3: "Dwarf", 4: "Night Elf", 5: "Undead", 6: "Tauren", 7: "Gnome", 8: "Troll",
         9: "Goblin", 10: "Blood Elf", 11: "Draenei", 12: "Dark Iron Dwarf", 13: "Vulpera", 14: "Mag'har Orc",
         15: "Mechagnome", 16: "Dracthyr (Horde)", 17: "Dracthyr (Alliance)", 18: "Earthen (Horde)",
         19: "Earthen (Alliance)", 20: "Haranir (Horde)", 21: "Haranir (Alliance)", 22: "Worgen",
         24: "Pandaren", 25: "Pandaren (Alliance)", 26: "Pandaren (Horde)", 27: "Nightborne",
         28: "Highmountain Tauren", 29: "Void Elf", 30: "Lightforged Draenei", 31: "Zandalari Troll",
         32: "Kul Tiran"}

# What a tooltip says that can change what the addon should suggest, and when.
FLAGS = [
    ("cooldown", r"cooldown|recharge"),
    ("resource", r"essence|runic power|\brunes?\b|holy power|combo point|soul shard|astral power|"
                 r"maelstrom|insanity|\bfury\b|\brage\b|\benergy\b|\bfocus\b|\bchi\b"),
    ("empower", r"empower"),
    ("charges", r"\bcharges?\b"),
    ("duration", r"duration|extend|lasts"),
    ("targets", r"enem(y|ies)|targets"),
]


def read(name):
    with open(os.path.join(GEN, name), encoding="utf-8", errors="replace") as f:
        return f.read()


def unescape(s):
    return s.replace('\\"', '"').replace("\\r\\n", " ").replace("\\n", " ").replace("\\\\", "\\")


def clean(text):
    text = unescape(text)
    text = re.sub(r"\|c[0-9A-Fa-f]{8}|\|r", "", text)  # colour codes
    return re.sub(r"\s+", " ", text).strip()


def load():
    traits = []
    data = read("trait_data.inc")
    body = data.split("__trait_data_data", 1)[1].split("} };", 1)[0]
    for m in TRAIT_RE.finditer(body):
        g = m.groups()
        traits.append({
            "tree": int(g[0]), "class": int(g[1]), "node": int(g[3]), "ranks": int(g[4]),
            "spell": int(g[7]), "replaces": int(g[8]), "override": int(g[9]),
            "row": int(g[10]), "col": int(g[11]), "name": unescape(g[13]),
            "specs": [int(x) for x in g[14:18] if int(x)], "hero": int(g[18]), "type": int(g[19]),
        })
    heroes = {}
    sub = data.split("__trait_sub_tree_data", 1)[1].split("} };", 1)[0]
    for m in SUBTREE_RE.finditer(sub):
        heroes[int(m.group(1))] = (unescape(m.group(2)), int(m.group(3)))
    texts = {}
    for line in read("spelltext_data.inc").splitlines():
        m = TEXT_RE.match(line)
        if m and m.group(2) is not None:
            texts[int(m.group(1))] = clean(m.group(2))
    names, cooldowns = {}, {}
    for line in read("sc_spell_data.inc").splitlines():
        m = NAME_RE.match(line)
        if m:
            sid = int(m.group(2))
            names.setdefault(sid, unescape(m.group(1)))
            rest = line[m.end():].split(",")  # fields from index 2 on
            try:
                cooldowns.setdefault(sid, int(rest[14]))
            except (IndexError, ValueError):
                pass
    return traits, heroes, texts, names, cooldowns


def addon_spells():
    """Spell IDs the addon refers to (Rules.lua's S table and literals)."""
    with open(os.path.join(ROOT, "AssistCompanion", "Rules.lua"), encoding="utf-8") as f:
        return {int(x) for x in re.findall(r"\b(\d{5,7})\b", f.read())}


def flags_for(text):
    t = text.lower()
    return [name for name, pat in FLAGS if re.search(pat, t)]


def short(text, n=260):
    return text if len(text) <= n else text[:n].rsplit(" ", 1)[0] + "…"


def esc(s):
    return s.replace("|", "\\|")


def load_racials():
    body = read("racial_spells.inc").split("__racial_spell_data", 1)[1].split("} };", 1)[0]
    out = []
    for m in RACIAL_RE.finditer(body):
        races = int(m.group(1), 16)
        classes = int(m.group(2), 16)
        out.append({"races": [RACES.get(b + 1, f"race {b + 1}") for b in range(64) if races >> b & 1],
                    "classes": [CLASS_NAMES[b + 1] for b in range(13) if classes >> b & 1],
                    "spell": int(m.group(3)), "name": unescape(m.group(4))})
    return out


def load_masteries():
    body = read("mastery_spells.inc").split("__mastery_spell_data", 1)[1].split("} };", 1)[0]
    return {int(a): int(b) for a, b in MASTERY_RE.findall(body)}


def write_racials(texts, cooldowns, used):
    rows = load_racials()
    by_race = {}
    for r in rows:
        for race in r["races"]:
            by_race.setdefault(race, []).append(r)
    lines = ["# Racial abilities", "",
             "Generated by `tools/talent_db.py` from the game's racial table (SimC `racial_spells.inc`). "
             "**Cooldown** comes from the spell data: an on-use racial the highlight never suggests "
             "(e.g. Blood Fury, Berserking, Fireblood, Ancestral Call) is a candidate for a reminder; a "
             "passive (no cooldown) can still change numbers the addon estimates (haste, crit, cooldown "
             "or cast speed). **Classes**: only when the racial differs by class.", ""]
    for race in sorted(by_race):
        lines += [f"## {race}", "",
                  "| Racial | Spell | Cooldown | Classes | Can affect the addon | In addon | Tooltip |",
                  "|---|--:|--:|---|---|:-:|---|"]
        for r in sorted(by_race[race], key=lambda r: (r["name"], r["spell"])):
            text = texts.get(r["spell"], "")
            cd = cooldowns.get(r["spell"], 0)
            cls = "" if len(r["classes"]) >= 13 else ", ".join(r["classes"])
            fl = flags_for(text)
            if re.search(r"haste|critical|mastery|versatility|intellect|strength|agility", text.lower()):
                fl.append("stats")
            lines.append(f"| {esc(r['name'])} | {r['spell']} | {f'{cd // 1000}s' if cd else 'passive'} | "
                         f"{esc(cls)} | {', '.join(fl)} | {'✓' if r['spell'] in used else ''} | {esc(short(text))} |")
        lines.append("")
    path = os.path.join(ROOT, "docs", "talents", "racials.md")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    return path, len(rows)


def write_masteries(names, texts, used, healers):
    """Every spec's mastery, marked by whether it can change what the addon times or counts."""
    masteries = load_masteries()
    lines = ["# Masteries", "",
             "Generated by `tools/talent_db.py` from the game's mastery table (SimC `mastery_spells.inc`). "
             "Mastery scales with gear and buffs. Most masteries only add damage or healing, which doesn't "
             "change what the addon suggests or when. The ones that matter change a **duration**, "
             "**cooldown**, **resource** or **charges** the addon estimates (Augmentation's Timewalker "
             "lengthens Ebon Might). **Matters** is a keyword match on the tooltip, so check it.", "",
             "| Class | Spec | Mastery | Spell | Matters | In addon | Tooltip |", "|---|---|---|--:|---|:-:|---|"]
    by_class = {}
    for spec, spell in masteries.items():
        cls = next((c for c, n in CLASS_NAMES.items() if spec in SPEC_CLASS.get(c, ())), 0)
        by_class.setdefault(cls, []).append((spec, spell))
    for cls in sorted(by_class):
        for spec, spell in sorted(by_class[cls]):
            if spec in HEALERS and not healers:
                continue
            text = texts.get(spell, "")
            fl = [f for f in flags_for(text) if f in ("cooldown", "resource", "duration", "charges")]
            lines.append(f"| {CLASS_NAMES.get(cls, '?')} | {SPECS.get(spec, spec)} | "
                         f"{esc(names.get(spell, str(spell)))} | {spell} | "
                         f"{', '.join(fl) if fl else 'no (damage only)'} | {'✓' if spell in used else ''} | "
                         f"{esc(text)} |")
    path = os.path.join(ROOT, "docs", "talents", "masteries.md")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    return path, sum(len(v) for v in by_class.values())


def write_class(cls_key, traits, heroes, texts, names, used, healers, masteries):
    cid = CLASSES[cls_key]
    mine = [t for t in traits if t["class"] == cid]
    spec_ids = sorted({s for t in mine for s in t["specs"]} |
                      {s for s, n in SPECS.items() if any(s in t["specs"] for t in mine)})
    if not healers:
        spec_ids = [s for s in spec_ids if s not in HEALERS]
    hero_ids = sorted({t["hero"] for t in mine if t["hero"]})
    # Which hero trees each spec can pick: the selection rows (tree 4). Hero talents themselves only
    # list one of the specs that can use them, so they can't tell us.
    spec_heroes = {}
    for t in mine:
        if t["tree"] == 4 and t["hero"]:
            for sp in t["specs"]:
                spec_heroes.setdefault(sp, set()).add(t["hero"])
    mine = [t for t in mine if t["spell"]]  # drop selection/empty rows

    def row(t):
        text = texts.get(t["spell"], "")
        fl = flags_for(text)
        bits = []
        if t["replaces"]:
            bits.append("replaces " + names.get(t["replaces"], str(t["replaces"])))
        if t["override"]:
            bits.append("button becomes " + names.get(t["override"], str(t["override"])))
        kind = NODE_TYPES.get(t["type"], "")
        mark = "✓" if t["spell"] in used else ""
        return (f"| {esc(t['name'])} | {t['spell']} | {kind} | {', '.join(fl)} | "
                f"{esc('; '.join(bits))} | {mark} | {esc(short(text))} |")

    head = ("| Talent | Spell | Node | Can affect the addon | Replaces / button | In addon | Tooltip |\n"
            "|---|--:|---|---|---|:-:|---|")

    def section(title, rows):
        rows = sorted(rows, key=lambda t: (t["row"], t["col"], t["name"]))
        out = [f"### {title} ({len(rows)})", "", head]
        out += [row(t) for t in rows]
        return out + [""]

    lines = [f"# {CLASS_NAMES[cid]} talents", "",
             "Generated by `tools/talent_db.py` from the game's talent data (SimC `trait_data.inc`, "
             "`spelltext_data.inc`, build in the file header). **Can affect the addon**: what the tooltip "
             "mentions that can change which spell to suggest or when (cooldown, resource, empower, charges, "
             "duration, targets); a keyword match, so check the tooltip. **In addon**: the spell ID is already "
             "used in `Rules.lua`. Tooltips keep the game's `$s1`-style placeholders.", ""]
    lines += ["## Specs and hero trees", ""]
    for s in spec_ids:
        hs = [heroes[h][0] for h in sorted(spec_heroes.get(s, ()))]
        lines.append(f"* **{SPECS.get(s, s)}** ({s}): hero trees {', '.join(hs) or 'none listed'}")
    lines += [""]
    lines += ["## Mastery", "",
              "Mastery scales with gear and buffs, so anything it lengthens, shortens or adds to changes "
              "the addon's estimates (e.g. Augmentation's Timewalker lengthens Ebon Might).", "",
              "| Spec | Mastery | Spell | In addon | Tooltip |", "|---|---|--:|:-:|---|"]
    for s in spec_ids:
        m = masteries.get(s)
        if m:
            lines.append(f"| {SPECS.get(s, s)} | {esc(names.get(m, str(m)))} | {m} | "
                         f"{'✓' if m in used else ''} | {esc(texts.get(m, ''))} |")
    lines += [""]

    lines += ["## Class tree", ""]
    cls_rows = [t for t in mine if t["tree"] == 1]
    lines += section("Shared by all specs", cls_rows)
    for s in spec_ids:
        lines += [f"## {SPECS.get(s, s)} ({s})", ""]
        lines += section("Spec tree", [t for t in mine if t["tree"] == 2 and s in t["specs"]])
        for h in sorted(spec_heroes.get(s, ())):
            rows = [t for t in mine if t["tree"] == 3 and t["hero"] == h]
            if rows:
                lines += section(f"Hero: {heroes[h][0]}", rows)
    path = os.path.join(ROOT, "docs", "talents", f"{cls_key}.md")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    return path, len(mine)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    healers = "--healers" in sys.argv
    if not args:
        sys.exit("usage: talent_db.py <class> [<class>...]  (" + ", ".join(CLASSES) + ")")
    traits, heroes, texts, names, cooldowns = load()
    used = addon_spells()
    masteries = load_masteries()
    for a in args:
        path, n = write_class(a, traits, heroes, texts, names, used, healers, masteries)
        print(f"{path}: {n} talent entries")
    path, n = write_racials(texts, cooldowns, used)
    print(f"{path}: {n} racial entries")
    path, n = write_masteries(names, texts, used, healers)
    print(f"{path}: {n} masteries")


if __name__ == "__main__":
    main()

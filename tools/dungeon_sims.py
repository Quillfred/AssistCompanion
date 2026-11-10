#!/usr/bin/env python3
"""DungeonSlice sims for every spec on the rankings page: optimal rotation, the highlight (SimC's
use_blizzard_action_list=1, as the page's other fights) and, for specs Assist Companion supports, the
highlight + the addon's rules (tools/addon_apl.py). Each spec on the page's 5-target (AoE) optimal-rotation
build and its SimC profile (run_sims.SPECS). Augmentation is scored like talent_search.py: raid DPS minus the
same raid with an idle Augmentation. Writes $SIMC/../dungeon/summary.json.
Usage: SIMC=<simc> python3 tools/dungeon_sims.py [iterations]
"""
import json, os, re, subprocess, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
SIMC = os.environ.get("SIMC") or sys.exit("set SIMC")
BIN = os.path.join(SIMC, "build", "simc")
OUT = os.path.join(os.path.dirname(os.path.abspath(SIMC)), "dungeon")
ITER = int(sys.argv[1]) if len(sys.argv) > 1 else 1000
PAGE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "docs", "pages", "highlight-rankings.html")
# the spec's exported highlight list (SimC's assisted_combat/<file>.simc), run through the same wrapper as the
# addon's rules: the addon's gain is measured against it, which cancels what the wrapper changes (SimC's
# built-in use_blizzard_action_list keeps things a stripped profile doesn't; Frost's Cryogenic Chamber did 3x
# the damage in DungeonSlice). Same method as the Patchwerk estimates on the page.
HL_FILE = {"frost": "deathknight_frost", "unholy": "deathknight_unholy", "blood": "deathknight_blood",
           "devastation": "evoker_devastation", "windwalker": "monk_windwalker", "brewmaster": "monk_brewmaster"}
ADDON = {"Frost DK": "frost", "Unholy DK": "unholy", "Blood DK": "blood", "Devastation Evoker": "devastation",
         "Windwalker Monk": "windwalker", "Brewmaster Monk": "brewmaster"}
os.makedirs(OUT, exist_ok=True)


def profiles():
    src = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "run_sims.py")).read()
    block = src[src.index("SPECS = {"):src.index("}", src.index("SPECS = {"))]
    m = dict(re.findall(r'"([^"]+)": "([^"]+\.simc)"', block))
    return {k.replace(" (tank)", ""): v for k, v in m.items()}


def sublist(lines):
    """The rules' main list moved into a sub-list (actions.ac), called from the default list. SimC's
    DungeonSlice mishandles a long flat default list: Frost's rules scored -9.1% flat and -1.4% as a
    sub-list (Patchwerk: the same either way)."""
    out, main = [], []
    auto = any(l in ("actions=auto_attack", "actions+=/auto_attack") for l in lines)  # Evokers have none
    for l in lines:
        if l.startswith("actions=") or l.startswith("actions+="):
            a = l.split("=", 1)[1].lstrip("/")
            if a != "auto_attack":
                main.append(a)
        else:
            out.append(l)
    head = ["actions=auto_attack", "actions+=/call_action_list,name=ac"] if auto else ["actions=call_action_list,name=ac"]
    return out + head + ["actions.ac=" + main[0]] + \
        ["actions.ac+=/" + a for a in main[1:]]


def mirror(lines, hl_file):
    """The rules in SimC's own highlight structure: its cooldowns sub-list unchanged (use_items, potion,
    racials, and whatever SimC adds for the spec) and the rules' list (minus auto_attack / use_items /
    potion) as the assisted_combat sub-list. SimC's DungeonSlice results depend on this structure."""
    exp = [l for l in open(hl_file).read().splitlines() if l.startswith("actions")]
    # SimC's cooldowns sub-list minus the cooldowns SimC adds for the spec (Breath, Raise Dead, Xuen, Touch of
    # Karma, Niuzao...): the in-game highlight never shows those, and the addon's rules handle them.
    keep = ("use_items", "potion", "blood_fury", "berserking", "fireblood", "ancestral_call")
    head = [l for l in exp if not l.startswith("actions.assisted_combat") and
            not (l.startswith("actions.cooldowns") and l.split("=", 1)[1].lstrip("/").split(",")[0] not in keep)]
    pre = [l for l in lines if l.startswith("actions.precombat") or (l.startswith("actions.") and
                                                                       not l.startswith(("actions=", "actions+=")))]
    main = [l.split("=", 1)[1].lstrip("/") for l in lines if l.startswith(("actions=", "actions+="))]
    main = [a for a in main if a not in ("auto_attack", "use_items", "potion")]
    head = [l for l in head if not l.startswith("actions.precombat")] + [l for l in pre if l.startswith("actions.precombat")]
    sub = [l for l in pre if not l.startswith("actions.precombat")]
    return head + sub + ["actions.assisted_combat=" + main[0]] + ["actions.assisted_combat+=/" + a for a in main[1:]]


def run(tag, args, extra=(), raid=False):
    js = os.path.join(OUT, tag + ".json")
    if not os.path.exists(js):
        cmd = [BIN, *args, f"iterations={ITER}", "threads=4", "fight_style=DungeonSlice", f"json2={js}", *extra]
        r = subprocess.run(cmd, cwd=SIMC, capture_output=True, text=True)
        if r.returncode != 0 or not os.path.exists(js):
            print(f"{tag}: failed {(r.stderr or r.stdout)[-300:]}", flush=True)
            return None
    d = json.load(open(js))["sim"]
    return d["statistics"]["raid_dps"]["mean"] if raid else d["players"][0]["collected_data"]["dps"]["mean"]


def main():
    s = open(PAGE).read()
    data = json.loads(re.search(r"const DATA = (\[.*?\]);", s, re.S).group(1))
    prof = profiles()
    res = {}
    out = os.path.join(OUT, "summary.json")
    if os.path.exists(out):
        res = json.load(open(out))
    for e in data:
        spec = e["spec"]
        if spec in res and res[spec].get("optimal") and (spec not in ADDON or res[spec].get("hlwrap")):
            continue
        dh = ["demonhunter.enable_dungeon_slice=1"] if spec.endswith(" DH") else []  # SimC disables DungeonSlice for DH
        tal = f"talents={e['t_aoe']}"
        tag = re.sub(r"\W", "", spec)
        if spec == "Augmentation Evoker":
            import talent_search as ts
            base = ts.aug_profile()
            r = {k: (run(f"{tag}_{k}", base + [tal], x, raid=True) or 0) for k, x in
                 (("optimal", []), ("highlight", ["use_blizzard_action_list=1"]), ("idle", ["actions=snapshot_stats"]))}
            row = {"optimal": r["optimal"] - r["idle"], "highlight": r["highlight"] - r["idle"]}
        else:
            p = os.path.join(SIMC, "profiles", prof[spec])
            row = {"optimal": run(f"{tag}_optimal", [p, tal], dh),
                   "highlight": run(f"{tag}_highlight", [p, tal], ["use_blizzard_action_list=1"] + dh)}
            if spec in ADDON:
                import addon_apl
                body = [l for l in open(p).read().splitlines() if not l.startswith(("actions", "talents="))]
                apl = os.path.join(OUT, f"{tag}_addon.simc")
                hl_file = os.path.join(SIMC, "ActionPriorityLists", "assisted_combat", HL_FILE[ADDON[spec]] + ".simc")
                open(apl, "w").write("\n".join(body + mirror(addon_apl.actions(ADDON[spec]), hl_file)) + "\n")
                row["addon"] = run(f"{tag}_addon", [apl, tal])
                hl = [l for l in open(os.path.join(SIMC, "ActionPriorityLists", "assisted_combat",
                                                   HL_FILE[ADDON[spec]] + ".simc")).read().splitlines()
                      if l.startswith("actions")]
                wrap = os.path.join(OUT, f"{tag}_hlwrap.simc")
                open(wrap, "w").write("\n".join(body + hl) + "\n")
                row["hlwrap"] = run(f"{tag}_hlwrap", [wrap, tal])
        res[spec] = row
        json.dump(res, open(out, "w"), indent=1)
        print(spec, {k: round(v) for k, v in row.items() if v}, flush=True)


if __name__ == "__main__":
    main()

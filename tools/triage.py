#!/usr/bin/env python3
"""Phase 1 triage: for every spec and fight (1, 3, 5 targets), compare the Assisted Highlight
(on its best build) with the optimal rotation (on its best build) using the saved sim results,
and label each gap by whether an addon could plausibly correct it in combat under Midnight's
addon restrictions.

Inputs (under SIM_ROOT, default: this folder):
  simc/ActionPriorityLists/{default,assisted_combat}/*.simc
  simout/ (single target, optimal), simout_ahbuild_1t/ (single target, highlight's best build)
  simout_cleave3/ (3 targets, both), simout_5t_aoebuild/ (5 targets, optimal), simout_ahbuild/ (5 targets, highlight)
Outputs: triage.json and TRIAGE.md in OUT_DIR (default: SIM_ROOT).

Labels are heuristics from the highlight's own rule conditions:
  not-suggested   castable in the optimal rotation but absent from the in-game highlight     -> fixable (cast timing)
  simc-only       the in-game highlight never suggests it, but SimC presses it in highlight sims
                  (its cooldown list / automation-only lines), so the sim gap understates it -> fixable
  threshold       highlight has it with only resource/charge/range/cooldown conditions       -> likely fixable
  target-count    highlight condition on enemy count (e.g. ">3" holes)                         -> needs an enemy count in combat (untested)
  proc-gated      every highlight rule for it needs a buff/debuff/dot/health state             -> not fixable (hidden in combat)
  indirect        damage from procs, DoT ticks or pets that follows from other casts            -> not counted
"""
import hashlib, json, os, re, sys

ROOT = os.environ.get("SIM_ROOT", os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.environ.get("OUT_DIR", ROOT)
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from run_sims import SPECS  # noqa: E402  label -> profile path

APL = os.path.join(ROOT, "simc", "ActionPriorityLists")
MIN_SHARE = 0.005   # ignore ability gaps under 0.5% of optimal DPS
NOT_ROTATIONAL = re.compile(r"^(call_action_list|run_action_list|auto_attack|auto_shot|use_items?|potion|variable|"
                            r"snapshot_stats|invoke_external_buff|summon_pet|apply_poison|ancestral_call|berserking|"
                            r"blood_fury|fireblood|arcane_torrent|bag_of_tricks|lights_judgment|arcane_pulse|"
                            r".*_stance|.*_form|.*_weapon|prowl|charge|stealth|retarget_auto_attack)$")
_om = os.path.join(ROOT, "override_map.json")
OVERRIDES = json.load(open(_om)) if os.path.exists(_om) else {}   # override action -> [base actions]
FIXABLE = {"not-suggested": 1.0, "simc-only": 1.0, "threshold": 0.6, "target-count": 0.3, "override-unresolved": 0.3}
RESOURCE_WORDS = r"(runic_power|rune|energy|focus|rage|soul_shard|holy_power|chi|insanity|maelstrom|astral_power|fury|essence|combo_points|mana|arcane_charges)"


def slug(label):
    x = label.replace(" (tank)", "").replace(" DK", " Death Knight").replace(" DH", " Demon Hunter")
    return x.lower().replace(" ", "-")


def tag(label, mode):
    return f"{label}_{mode}".replace(" ", "_").replace("(", "").replace(")", "")


def h(talents):
    return hashlib.sha1((talents or "profile").encode()).hexdigest()[:10]


def apl_name(profile):
    base = re.sub(r"^MID\d_", "", os.path.basename(profile).replace(".simc", ""))
    for a, b in (("Death_Knight", "deathknight"), ("Demon_Hunter", "demonhunter")):
        base = base.replace(a, b)
    parts = base.split("_")
    return (parts[0] + "_" + "_".join(parts[1:])).lower()


def parse_apl(path):
    """{action: [condition strings]} for every action line, plus which lists they came from."""
    acts, lists = {}, {}
    automation_next = False
    for ln in open(path):
        ln = ln.strip()
        if ln.startswith("#"):
            automation_next = "Blizzard automation" in ln
            continue
        m = re.match(r"actions(\.[\w]+)?\+?=/?(.*)", ln)
        if not m:
            continue
        lst = (m.group(1) or ".default")[1:]
        for entry in m.group(2).split("/"):
            name = entry.split(",")[0].strip()
            if not name:
                continue
            cond = re.search(r"if=([^,]*(?:,[^=,]+(?=,|$))*)", entry)
            acts.setdefault(name, []).append(cond.group(1) if cond else "")
            lists.setdefault(name, set()).add("automation" if automation_next else lst)
        automation_next = False
    return acts, lists


def classify(name, hl_acts, hl_lists, opt_acts):
    lists = hl_lists.get(name, set())
    in_game_lists = lists & {"assisted_combat"}
    if any(b in hl_acts and "assisted_combat" in hl_lists.get(b, set()) for b in OVERRIDES.get(name, [])):
        return "button-override"   # in game the base button casts this; SimC's highlight sim can't
    if name in hl_acts and not in_game_lists:
        return "simc-only"
    if name not in hl_acts:
        return "not-suggested" if name in opt_acts else "indirect"
    conds = hl_acts[name]
    if any("charges" in c for c in conds):
        return "threshold"         # charges can be counted from your casts
    if any(re.search(r"active_enemies", c) for c in conds) and not any(c == "" for c in conds):
        return "target-count"
    def gated(c):
        return bool(re.search(r"(buff\.|debuff\.|dot\.|health|aura\.)", c))
    if conds and all(gated(c) for c in conds):
        return "proc-gated"
    return "threshold"


def player(path):
    p = json.load(open(path))["sim"]["players"][0]
    cd = p["collected_data"]
    fl = cd["fight_length"]["mean"]
    dmg, casts = {}, {}
    for s in p["stats"]:
        amt = s.get("compound_amount") or 0
        if s.get("type") == "damage" and amt:
            dmg[s["name"]] = dmg.get(s["name"], 0) + amt / fl
        n = s.get("num_executes", {}).get("mean", 0)
        if n:
            casts[s["name"]] = casts.get(s["name"], 0) + n
    pets = p.get("stats_pets") or {}
    for pet, stats in (pets.items() if isinstance(pets, dict) else []):
        for s in stats:
            amt = s.get("compound_amount") or 0
            if s.get("type") == "damage" and amt:
                dmg["pet:" + pet] = dmg.get("pet:" + pet, 0) + amt / fl
    waste = {}
    for g in p.get("gains", []):
        for res, d in g.items():
            if isinstance(d, dict) and res != "health":
                a, o = waste.get(res, (0, 0))
                waste[res] = (a + d.get("actual", 0), o + d.get("overflow", 0))
    waste = {r: 100 * o / (a + o) for r, (a, o) in waste.items() if a + o > 0}
    buffs = {b["name"]: b.get("uptime", 0) for b in p.get("buffs", []) if b.get("uptime") is not None}
    return {"dps": cd["dps"]["mean"], "dmg": dmg, "casts": casts, "waste": waste, "buffs": buffs, "fl": fl}


def fight_files(label):
    s = slug(label)
    ah1 = json.load(open(os.path.join(ROOT, "simout_ahbuild_1t", "summary.json")))[label]
    ah5 = json.load(open(os.path.join(ROOT, "simout_ahbuild", "summary.json")))[label]
    c3 = json.load(open(os.path.join(ROOT, "simout_cleave3", "summary.json")))[label]
    return {
        1: (os.path.join(ROOT, "simout", tag(label, "full") + ".json"),
            os.path.join(ROOT, "simout_ahbuild_1t", f"{s}_final_{h(ah1['talents'])}.json")),
        3: (os.path.join(ROOT, "simout_cleave3", f"{s}_full_final_{h(c3['opt_talents'])}.json"),
            os.path.join(ROOT, "simout_cleave3", f"{s}_hl_final_{h(c3['hl_talents'])}.json")),
        5: (os.path.join(ROOT, "simout_5t_aoebuild", tag(label, "full") + ".json"),
            os.path.join(ROOT, "simout_ahbuild", f"{s}_final_{h(ah5['talents'])}.json")),
    }


def analyse(label):
    name = apl_name(SPECS[label])
    hl_acts, hl_lists = parse_apl(os.path.join(APL, "assisted_combat", name + ".simc"))
    opt_acts, _ = parse_apl(os.path.join(APL, "default", name + ".simc"))
    fights, simc_only = {}, set()
    for act, lists in hl_lists.items():
        if "assisted_combat" not in lists and act in opt_acts and not NOT_ROTATIONAL.match(act):
            simc_only.add(act)
    for t, (fo, fh) in fight_files(label).items():
        o, hl = player(fo), player(fh)
        loss = 100 * (hl["dps"] / o["dps"] - 1)
        gaps = []
        for a in set(o["dmg"]) | set(hl["dmg"]):
            d = o["dmg"].get(a, 0) - hl["dmg"].get(a, 0)
            if d < MIN_SHARE * o["dps"]:
                continue
            base = a.split(":")[0] if a.startswith("pet:") else a
            label_ = "indirect" if a.startswith("pet:") else classify(base, hl_acts, hl_lists, opt_acts)
            gaps.append({"ability": a, "dps_gap": d, "share": 100 * d / o["dps"], "label": label_,
                         "casts_opt": round(o["casts"].get(a, 0), 1), "casts_hl": round(hl["casts"].get(a, 0), 1)})
        gaps.sort(key=lambda g: -g["dps_gap"])
        pos = sum(g["dps_gap"] for g in gaps) or 1
        fixable = sum(g["dps_gap"] * FIXABLE.get(g["label"], 0) for g in gaps) / pos
        waste = [{"resource": r, "opt": round(o["waste"].get(r, 0), 1), "hl": round(w, 1)}
                 for r, w in hl["waste"].items() if w - o["waste"].get(r, 0) >= 3]
        buffs = sorted(({"buff": b, "opt": round(o["buffs"][b], 1), "hl": round(hl["buffs"].get(b, 0), 1)}
                        for b in o["buffs"] if o["buffs"][b] - hl["buffs"].get(b, 0) >= 10),
                       key=lambda x: x["hl"] - x["opt"])[:4]
        artifact = sum(g["share"] for g in gaps if g["label"] == "button-override")
        corrected = None
        cf = os.path.join(ROOT, "simout_override", f"{slug(label)}_{t}t.json")
        if os.path.exists(cf):
            corrected = round(100 * (player(cf)["dps"] / o["dps"] - 1), 1)
        fights[t] = {"loss": round(loss, 1), "corrected_loss": corrected, "artifact_share": round(artifact, 1),
                     "gaps": gaps[:8], "fixable_share": round(100 * fixable), "waste": waste, "buffs": buffs}
    eff = {t: (fights[t]["corrected_loss"] if fights[t]["corrected_loss"] is not None else fights[t]["loss"]) for t in fights}
    l1, l3, l5 = eff[1], eff[3], eff[5]
    hole3 = l3 < min(l1, l5) - 4
    est = sum(-eff[t] * fights[t]["fixable_share"] / 100 for t in fights) / 3
    patterns = []
    if any(fights[t]["waste"] for t in fights):
        patterns.append("resource cap")
    if hole3:
        patterns.append("3-target hole")
    if simc_only:
        patterns.append("never suggested in game: " + ", ".join(sorted(simc_only)))
    if any(g["label"] == "not-suggested" for t in fights for g in fights[t]["gaps"]):
        patterns.append("missing from highlight")
    improved = sum(eff[t] - fights[t]["loss"] for t in fights) / 3
    if improved < 1:
        # The re-sim with overrides didn't help, so these gaps are real, not a SimC artifact.
        for t in fights:
            for g in fights[t]["gaps"]:
                if g["label"] == "button-override":
                    g["label"] = "override-unresolved"
            gs = fights[t]["gaps"]
            tot = sum(g["dps_gap"] for g in gs) or 1
            fights[t]["fixable_share"] = round(100 * sum(g["dps_gap"] * FIXABLE.get(g["label"], 0) for g in gs) / tot)
        est = sum(-eff[t] * fights[t]["fixable_share"] / 100 for t in fights) / 3
    if improved >= 1:
        patterns.append(f"SimC button-override artifact (highlight {improved:+.1f} pts better than SimC showed)")
    return {"spec": label, "fights": fights, "simc_only": sorted(simc_only), "override_gain": round(improved, 1),
            "avg_loss": round((l1 + l3 + l5) / 3, 1), "est_recoverable": round(est, 1), "patterns": patterns}


def md(results):
    out = ["# Assisted Highlight gap triage (phase 1)", "",
           "Optimal rotation (its best build) vs the in-game Assisted Highlight (its best build), from saved SimC",
           "results (patch 12.1.5, Patchwerk 300s). **Est. recoverable** = average loss across 1/3/5 targets x the",
           "share of the damage gap in abilities an addon could plausibly correct (heuristic, an upper-end guide).",
           "Where SimC's highlight sim couldn't press button overrides (e.g. Chaos Strike -> Annihilation in",
           "Metamorphosis), losses are corrected by re-simming with the overrides added; SimC's figure is in brackets.", "",
           "| Spec | Loss 1T | 3T | 5T | Est. recoverable | Patterns |", "|---|--:|--:|--:|--:|---|"]
    def cell(f):
        c = f["corrected_loss"]
        return f"{c}% (SimC {f['loss']}%)" if c is not None and abs(c - f["loss"]) >= 1 else f"{f['loss']}%"
    for r in results:
        f = r["fights"]
        out.append(f"| {r['spec']} | {cell(f[1])} | {cell(f[3])} | {cell(f[5])} | "
                   f"**{r['est_recoverable']}%** | {'; '.join(r['patterns']) or '-'} |")
    out += ["", "Labels: **not-suggested** (missing from the in-game highlight), **simc-only** (never suggested in",
            "game; SimC presses it in highlight sims), **threshold** (resource/charge/range rules), **target-count**",
            "(enemy-count rules), **proc-gated** (needs hidden buffs, not fixable), **indirect** (procs, DoTs, pets).", ""]
    for r in results:
        out.append(f"## {r['spec']}")
        if r["simc_only"]:
            out.append(f"*Never suggested by the in-game highlight (SimC presses these in its highlight sims, so real losses are larger):* {', '.join(r['simc_only'])}")
        for t in (1, 3, 5):
            f = r["fights"][t]
            out.append(f"\n**{t} target{'s' if t > 1 else ''}:** {cell(f)} loss, {f['fixable_share']}% of the gap in fixable-looking abilities")
            if f["gaps"]:
                out.append("\n| Ability | DPS gap | Casts opt / hl | Label |\n|---|--:|--:|---|")
                for g in f["gaps"][:6]:
                    out.append(f"| {g['ability']} | {g['share']:.1f}% | {g['casts_opt']} / {g['casts_hl']} | {g['label']} |")
            if f["waste"]:
                out.append("\nResource waste (opt -> hl): " + ", ".join(f"{w['resource']} {w['opt']}% -> {w['hl']}%" for w in f["waste"]))
            if f["buffs"]:
                out.append("\nBuff uptime (opt -> hl): " + ", ".join(f"{b['buff']} {b['opt']}% -> {b['hl']}%" for b in f["buffs"]))
        out.append("")
    return "\n".join(out) + "\n"


if __name__ == "__main__":
    results = []
    for label in SPECS:
        try:
            results.append(analyse(label))
        except FileNotFoundError as e:
            print(f"skip {label}: {e}", file=sys.stderr)
    results.sort(key=lambda r: -r["est_recoverable"])
    json.dump(results, open(os.path.join(OUT_DIR, "triage.json"), "w"), indent=1)
    open(os.path.join(OUT_DIR, "TRIAGE.md"), "w").write(md(results))
    for r in results:
        print(f"{r['spec']:28} avg loss {r['avg_loss']:6.1f}%  est. recoverable {r['est_recoverable']:5.1f}%  {'; '.join(r['patterns'])}")

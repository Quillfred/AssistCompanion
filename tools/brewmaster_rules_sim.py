#!/usr/bin/env python3
"""Brewmaster: what Assist Companion's rules are worth, simmed (same method as windwalker_rules_sim.py).

Rotations per build and fight (Patchwerk 300s, 1/3/5 targets by default):
  optimal    SimC's default APL.
  hl_simc    the highlight as SimC plays it (use_blizzard_action_list=1: adds Invoke Niuzao from SimC's cooldown list).
  hl_game    the highlight as it plays in game: its own list, no Invoke Niuzao.
  hl_addon / +<rule> / -<rule>: the addon's rules on top (see RULES below).
Usage: SIMC=<simc checkout with build/simc> python3 tools/brewmaster_rules_sim.py [iterations]
"""
import json, os, re, subprocess, sys

SIMC = os.environ.get("SIMC") or sys.exit("set SIMC to a SimC checkout with build/simc")
BIN = os.path.join(SIMC, "build", "simc")
OUT = os.path.join(os.path.dirname(os.path.abspath(SIMC)), "bmsim")
ITER = int(sys.argv[1]) if len(sys.argv) > 1 else 1000
FIGHTS = [int(x) for x in os.environ.get("BM_FIGHTS", "1,3,5").split(",")]
BUILDS = {"Harmony": ("profiles/MID2/MID2_Monk_Brewmaster.simc", None)}
if os.environ.get("BM_SHADOPAN"):  # talent string for a Shado-Pan build
    BUILDS["Shado-Pan"] = ("profiles/MID2/MID2_Monk_Brewmaster.simc", os.environ["BM_SHADOPAN"])
HL = [l.split("=", 1)[1].lstrip("/") for l in
      open(os.path.join(SIMC, "ActionPriorityLists/assisted_combat/monk_brewmaster.simc")).read().splitlines()
      if l.startswith("actions.assisted_combat")]
# rule -> (top lines, {highlight line prefix: lines to put before it})
RULE_LINES = {
    "combo3": ([], {"keg_smash,if=charges>=2": ["tiger_palm,if=buff.blackout_combo.up&active_enemies>2"]}),
    "purify": (["purifying_brew"], {}),
    "celestial": (["celestial_brew"], {}),
    # spacing variants: not while Empty Barrel is up (Bring Me Another; SimC's optimal), or only near 2 charges
    "celbarrel": (["celestial_brew,if=!buff.empty_barrel.up"], {}),
    "cel19": (["celestial_brew,if=cooldown.celestial_brew.charges_fractional>1.9|buff.empty_barrel.down&cooldown.celestial_brew.charges_fractional>=1"], {}),
    "niuzao": (["invoke_niuzao"], {}),
    "bob": (["black_ox_brew,if=cooldown.celestial_brew.charges_fractional<1"], {}),
    "cellar": (["empty_the_cellar"], {}),
    "pool65": ([], {}), "pool90": ([], {}), "poolks": ([], {}),
}
# rule -> {highlight line: replacement}: pooling energy for Keg Smash (40) before filler Tiger Palm (50) / Spinning Crane Kick
POOL = {
    "pool65": "energy>=65",
    "pool90": "energy>=90",
    "poolks": "(energy>=90|cooldown.keg_smash.remains>3)",
}
FILLERS = ("tiger_palm,if=!talent.press_the_advantage", "spinning_crane_kick,if=active_enemies>3")
RULES = [r for r in os.environ.get("BM_RULES", "pool65,combo3,purify,celbarrel,niuzao,bob,cellar").split(",") if r]  # 0.27.4: celbarrel
MODES = {"hl_game": []}
if RULES:
    MODES["hl_addon"] = RULES
    for r in RULES:
        MODES["+" + r] = [r]
        MODES["-" + r] = [x for x in RULES if x != r]
for extra in ("pool90", "poolks"):
    MODES["all:" + extra] = [extra if x == "pool65" else x for x in RULES]
for extra in ("celestial", "cel19"):
    MODES["all:" + extra] = [extra if x == "celbarrel" else x for x in RULES]
os.makedirs(OUT, exist_ok=True)


def apl(rules):
    top, before = [], {}
    for r in rules:
        t, b = RULE_LINES[r]
        top += t
        for k, v in b.items():
            before.setdefault(k, []).extend(v)
    hl = []
    for a in HL:
        for k, v in before.items():
            if a.startswith(k):
                hl += v
        for r in rules:
            if r in POOL and a in FILLERS:
                a = a.replace(",if=", f",if={POOL[r]}&", 1)
        hl.append(a)
    return ["actions.precombat=snapshot_stats", "actions=auto_attack", "actions+=/use_items",
            "actions+=/potion"] + [f"actions+=/{a}" for a in top + hl]


def profile(build, mode):
    path, talents = BUILDS[build]
    src = open(os.path.join(SIMC, path)).read().splitlines()
    if talents:
        src = [f"talents={talents}" if l.startswith("talents=") else l for l in src]
    if mode in ("optimal", "hl_simc"):
        return "\n".join(src) + "\n"
    return "\n".join([l for l in src if not l.startswith("actions")] + apl(MODES[mode])) + "\n"


def run(build, mode, n):
    tag = re.sub(r"\W", "", f"{build}_{mode}_{n}t")
    prof, js = os.path.join(OUT, tag + ".simc"), os.path.join(OUT, tag + ".json")
    text = profile(build, mode)
    stale = not os.path.exists(prof) or open(prof).read() != text
    open(prof, "w").write(text)
    if stale or not os.path.exists(js):
        cmd = [BIN, prof, f"iterations={ITER}", "threads=4", f"desired_targets={n}", "fight_style=Patchwerk",
               "max_time=300", f"json2={js}"] + (["use_blizzard_action_list=1"] if mode == "hl_simc" else [])
        r = subprocess.run(cmd, cwd=SIMC, capture_output=True, text=True)
        if r.returncode != 0 or not os.path.exists(js):
            sys.exit(f"{tag}: {(r.stderr or r.stdout)[-500:]}")
    return json.load(open(js))["sim"]["players"][0]["collected_data"]["dps"]["mean"]


def main():
    modes = ["optimal", "hl_simc"] + list(MODES)
    res = {(b, m, n): run(b, m, n) for b in BUILDS for m in modes for n in FIGHTS}
    for b in BUILDS:
        print(f"\n{b}: DPS vs optimal ({' / '.join(f'{n}T' for n in FIGHTS)}), and vs hl_game")
        for m in modes:
            print(f"{m:>12} " + " ".join(
                f"{res[(b, m, n)]:9.0f} {100 * (res[(b, m, n)] / res[(b, 'optimal', n)] - 1):+6.1f}% "
                f"({100 * (res[(b, m, n)] / res[(b, 'hl_game', n)] - 1):+5.1f})" for n in FIGHTS))


if __name__ == "__main__":
    main()

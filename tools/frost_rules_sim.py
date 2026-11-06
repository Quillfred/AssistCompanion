#!/usr/bin/env python3
"""Frost: what Assist Companion's rules are worth, simmed (same method as blood_rules_sim.py).

Rotations per build (MID2 Deathbringer and Rider profiles) and fight:
  optimal    SimC's default APL.
  hl_simc    use_blizzard_action_list=1 (SimC adds Breath of Sindragosa and Raise Dead on cooldown).
  hl_game    the highlight in game: no Breath of Sindragosa ("for Blizzard automation", never shown) or
             Raise Dead.
  hl_addon   hl_game + the addon's Frost rules: Breath of Sindragosa during Pillar of Frost when ready,
             Raise Dead when ready, Frostscythe instead of Obliterate at exactly 3 targets.
  (Empower Rune Weapon out of range is about movement; not simmable on Patchwerk.)
Usage: SIMC=<simc checkout with build/simc> python3 tools/frost_rules_sim.py [iterations]
"""
import json, os, re, subprocess, sys

SIMC = os.environ.get("SIMC") or sys.exit("set SIMC to a SimC checkout with build/simc")
BIN = os.path.join(SIMC, "build", "simc")
OUT = os.path.join(os.path.dirname(os.path.abspath(SIMC)), "frostsim")
ITER = int(sys.argv[1]) if len(sys.argv) > 1 else 1500
FIGHTS = [1, 3, 5]
BUILDS = {
    "Deathbringer": "profiles/MID2/MID2_Death_Knight_Frost.simc",
    "Rider": "profiles/MID2/MID2_Death_Knight_Frost_Rider.simc",
}
HL = [l.split("=", 1)[1].lstrip("/") for l in
      open(os.path.join(SIMC, "ActionPriorityLists/assisted_combat/deathknight_frost.simc")).read().splitlines()
      if l.startswith("actions.assisted_combat")]
HL = [a for a in HL if a != "breath_of_sindragosa"]  # "for Blizzard automation": not in the game's list
os.makedirs(OUT, exist_ok=True)
MODES = {"hl_game": (0, 0, 0), "hl_addon": (1, 1, 1), "+breath": (1, 0, 0), "+raisedead": (0, 1, 0), "+frostscythe3": (0, 0, 1)}


def apl(flags):
    breath, rd, fs3 = flags
    top = (["breath_of_sindragosa,if=buff.pillar_of_frost.up"] if breath else []) + (["raise_dead"] if rd else [])
    hl = []
    for a in HL:
        if fs3 and a.startswith("obliterate"):
            cond = a.split(",if=", 1)[1] if ",if=" in a else ""
            hl.append("frostscythe,if=active_enemies=3" + (f"&({cond})" if cond else ""))
        hl.append(a)
    return ["actions.precombat=snapshot_stats", "actions=auto_attack", "actions+=/use_items", "actions+=/potion"] + \
        [f"actions+=/{a}" for a in top + hl]


def profile(build, mode):
    src = open(os.path.join(SIMC, BUILDS[build])).read().splitlines()
    if mode in ("optimal", "hl_simc"):
        return "\n".join(src) + "\n"
    return "\n".join([l for l in src if not l.startswith("actions")] + apl(MODES[mode])) + "\n"


def run(build, mode, n):
    tag = re.sub(r"\W", "", f"{build}_{mode}_{n}t")
    prof, js = os.path.join(OUT, tag + ".simc"), os.path.join(OUT, tag + ".json")
    open(prof, "w").write(profile(build, mode))
    if not os.path.exists(js):
        cmd = [BIN, prof, f"iterations={ITER}", "threads=4", f"desired_targets={n}", "fight_style=Patchwerk",
               "max_time=300", f"json2={js}"] + (["use_blizzard_action_list=1"] if mode == "hl_simc" else [])
        r = subprocess.run(cmd, cwd=SIMC, capture_output=True, text=True)
        if r.returncode != 0 or not os.path.exists(js):
            sys.exit(f"{tag}: {(r.stderr or r.stdout)[-500:]}")
    return json.load(open(js))["sim"]["players"][0]["collected_data"]["dps"]["mean"]


def main():
    modes = ["optimal", "hl_simc"] + list(MODES)
    res = {(b, m, n): run(b, m, n) for b in BUILDS for m in modes for n in FIGHTS}
    json.dump({f"{b}|{m}|{n}": v for (b, m, n), v in res.items()}, open(os.path.join(OUT, "summary.json"), "w"), indent=1)
    for b in BUILDS:
        print(f"\n{b}: DPS vs optimal")
        for m in modes:
            print(f"{m:>14} " + " ".join(f"{res[(b, m, n)]:9.0f} {100 * (res[(b, m, n)] / res[(b, 'optimal', n)] - 1):+6.1f}%" for n in FIGHTS))


if __name__ == "__main__":
    main()

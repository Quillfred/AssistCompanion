#!/usr/bin/env python3
"""Blood: what Assist Companion's rules are worth, simmed (same method as dev_addon_sim.py).

SimC can't run the addon, so its rules are written as a SimC action list on top of the in-game
highlight's list (SimC's assisted_combat/deathknight_blood.simc). Rotations per build and fight:

  optimal    SimC's default APL.
  hl_simc    use_blizzard_action_list=1: the highlight as the rankings sim it (SimC adds Vampiric Blood
             and Raise Dead on cooldown; Consumption at max rank).
  hl_game    the highlight as it plays in game: no Vampiric Blood or Raise Dead (never suggested).
  hl_addon   hl_game + the addon's Blood rules (0.21.7): Bone Shield refresh (Marrowrend, Death's Caress
             under 2 runes) with 5s left, Vampiric Blood and Raise Dead when ready, Death Strike within
             20 runic power of max, Blood Boil instead of Heart Strike (any Heart Strike button state)
             with a charge, Consumption at rank 1.
  hl_addon_novb  hl_addon without the Vampiric Blood rule (the owner turns it off).
  hl_addon_nobone  hl_addon without the Bone Shield refresh (to weigh damage against damage taken).
  Breakdown (each = hl_game + one rule): +bone, +cds, +ds, +bb, +rank.

Usage: SIMC=<simc checkout with build/simc> python3 tools/blood_rules_sim.py [iterations]
"""
import json, os, re, subprocess, sys

SIMC = os.environ.get("SIMC") or sys.exit("set SIMC to a SimC checkout with build/simc")
BIN = os.path.join(SIMC, "build", "simc")
OUT = os.path.join(os.path.dirname(os.path.abspath(SIMC)), "bloodsim")
ITER = int(sys.argv[1]) if len(sys.argv) > 1 else 2000
FIGHTS = [1, 3, 5]
BUILDS = {
    "San'layn": "profiles/MID2/MID2_Death_Knight_Blood.simc",
    "Deathbringer": "profiles/MID2/MID2_Death_Knight_Blood_Deathbringer.simc",
}
HL = [l.split("=", 1)[1].lstrip("/") for l in
      open(os.path.join(SIMC, "ActionPriorityLists/assisted_combat/deathknight_blood.simc")).read().splitlines()
      if l.startswith("actions.assisted_combat")]
os.makedirs(OUT, exist_ok=True)

BONE = ["marrowrend,if=buff.bone_shield.up&buff.bone_shield.remains<5&rune>=2",
        "deaths_caress,if=buff.bone_shield.up&buff.bone_shield.remains<5&rune<2"]
CDS = ["vampiric_blood", "raise_dead"]
DS = ["death_strike,if=runic_power.deficit<20"]
BB = "blood_boil,if=charges>=1&target.distance<=10"
MODES = {  # name: (bone, vb, raise dead, ds, bb, rank)
    "hl_game": (0, 0, 0, 0, 0, 0),
    "hl_addon": (1, 1, 1, 1, 1, 1),
    "hl_addon_novb": (1, 0, 1, 1, 1, 1),
    "hl_addon_nobone": (0, 1, 1, 1, 1, 1),
    "+bone": (1, 0, 0, 0, 0, 0), "+cds": (0, 1, 1, 0, 0, 0), "+ds": (0, 0, 0, 1, 0, 0),
    "+bb": (0, 0, 0, 0, 1, 0), "+rank": (0, 0, 0, 0, 0, 1),
}


def apl(flags):
    bone, vb, rd, ds, bb, rank = flags
    top = (BONE if bone else []) + (["vampiric_blood"] if vb else []) + (["raise_dead"] if rd else []) + (DS if ds else [])
    hl = []
    for a in HL:
        if bb and a.startswith("heart_strike"):
            cond = a.split(",if=", 1)[1] if ",if=" in a else ""
            hl.append(BB + (f"&({cond})" if cond else ""))
        if rank and a.startswith("consumption"):
            a = a.replace("consumption", "consumption,empower_to=1", 1)
        hl.append(a)
    lines = ["actions.precombat=snapshot_stats", "actions=auto_attack", "actions+=/use_items", "actions+=/potion"]
    lines += [f"actions+=/{a}" for a in top + hl]
    return lines


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
    p = json.load(open(js))["sim"]["players"][0]
    return p["collected_data"]["dps"]["mean"], p["collected_data"].get("dtps", {}).get("mean", 0)


def main():
    modes = ["optimal", "hl_simc"] + list(MODES)
    res = {(b, m, n): run(b, m, n) for b in BUILDS for m in modes for n in FIGHTS}
    json.dump({f"{b}|{m}|{n}": v for (b, m, n), v in res.items()}, open(os.path.join(OUT, "summary.json"), "w"), indent=1)
    for b in BUILDS:
        print(f"\n{b}: DPS vs optimal (damage taken per second in brackets)")
        print(f"{'mode':>14} " + " ".join(f"{str(n) + ' target(s)':>24}" for n in FIGHTS))
        for m in modes:
            cells = []
            for n in FIGHTS:
                d, t = res[(b, m, n)]
                o = res[(b, "optimal", n)][0]
                cells.append(f"{d:8.0f} {100 * (d / o - 1):+6.1f}% ({t / 1e6:4.1f}M)")
            print(f"{m:>14} " + " ".join(f"{c:>24}" for c in cells))


if __name__ == "__main__":
    main()

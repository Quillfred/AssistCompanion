#!/usr/bin/env python3
"""Sim each spec three ways (SimC full APL, Assisted Highlight, One Button) and report DPS loss."""
import json, os, subprocess, sys, concurrent.futures as cf

ROOT = os.path.dirname(os.path.abspath(__file__))
SIMC = os.path.join(ROOT, "simc", "build", "simc")
PROF = os.path.join(ROOT, "simc", "profiles")
TARGETS = int(os.environ.get("TARGETS", "1"))
BUILD = os.environ.get("BUILD", "")  # "aoe" -> use Noxxic's top AoE talent build per spec
OUT = os.path.join(ROOT, ("simout" if TARGETS == 1 else f"simout_{TARGETS}t") + (f"_{BUILD}build" if BUILD else ""))
TALENTS = {}
if BUILD:
    _b = json.load(open(os.path.join(ROOT, "nox", "aoe_builds.json")))
    def _slug(label):
        x = label.replace(" (tank)", "").replace(" DK", " Death Knight").replace(" DH", " Demon Hunter")
        return x.lower().replace(" ", "-")
    TALENTS = {k: _b[_slug(k)][BUILD] for k in []}  # filled after SPECS is defined

os.makedirs(OUT, exist_ok=True)

ITER = int(os.environ.get("ITER", "3000"))
THREADS = int(os.environ.get("THREADS", "4"))

SPECS = {
    # spec label: profile file (relative to profiles/)
    "Blood DK (tank)": "MID2/MID2_Death_Knight_Blood.simc",
    "Frost DK": "MID2/MID2_Death_Knight_Frost.simc",
    "Unholy DK": "MID2/MID2_Death_Knight_Unholy.simc",
    "Havoc DH": "MID2/MID2_Demon_Hunter_Havoc.simc",
    "Devourer DH": "MID2/MID2_Demon_Hunter_Devourer.simc",
    "Vengeance DH (tank)": "MID2/MID2_Demon_Hunter_Vengeance.simc",
    "Balance Druid": "MID1/MID1_Druid_Balance.simc",
    "Feral Druid": "MID2/MID2_Druid_Feral.simc",
    "Guardian Druid (tank)": "MID1/MID1_Druid_Guardian.simc",
    "Devastation Evoker": "MID1/MID1_Evoker_Devastation.simc",
    "Beast Mastery Hunter": "MID2/MID2_Hunter_Beast_Mastery.simc",
    "Marksmanship Hunter": "MID2/MID2_Hunter_Marksmanship.simc",
    "Survival Hunter": "MID2/MID2_Hunter_Survival.simc",
    "Arcane Mage": "MID2/MID2_Mage_Arcane.simc",
    "Fire Mage": "MID2/MID2_Mage_Fire.simc",
    "Frost Mage": "MID2/MID2_Mage_Frost.simc",
    "Brewmaster Monk (tank)": "MID2/MID2_Monk_Brewmaster.simc",
    "Windwalker Monk": "MID2/MID2_Monk_Windwalker.simc",
    "Protection Paladin (tank)": "MID2/MID2_Paladin_Protection.simc",
    "Retribution Paladin": "MID2/MID2_Paladin_Retribution.simc",
    "Shadow Priest": "MID2/MID2_Priest_Shadow.simc",
    "Assassination Rogue": "MID2/MID2_Rogue_Assassination.simc",
    "Outlaw Rogue": "MID2/MID2_Rogue_Outlaw.simc",
    "Subtlety Rogue": "MID2/MID2_Rogue_Subtlety.simc",
    "Elemental Shaman": "MID2/MID2_Shaman_Elemental.simc",
    "Enhancement Shaman": "MID2/MID2_Shaman_Enhancement.simc",
    "Affliction Warlock": "MID2/MID2_Warlock_Affliction.simc",
    "Demonology Warlock": "MID2/MID2_Warlock_Demonology.simc",
    "Destruction Warlock": "MID2/MID2_Warlock_Destruction.simc",
    "Arms Warrior": "MID2/MID2_Warrior_Arms.simc",
    "Fury Warrior": "MID2/MID2_Warrior_Fury.simc",
    "Protection Warrior (tank)": "MID2/MID2_Warrior_Protection.simc",
}

if BUILD:
    TALENTS = {k: _b[_slug(k)][BUILD] for k in SPECS}

MODES = {
    "full": [],
    "highlight": ["use_blizzard_action_list=1"],
}


def run(label, prof, mode):
    tag = f"{label}_{mode}".replace(" ", "_").replace("(", "").replace(")", "")
    jpath = os.path.join(OUT, tag + ".json")
    if not os.path.exists(jpath):
        cmd = [SIMC, os.path.join(PROF, prof), *([f"talents={TALENTS[label]}"] if TALENTS else []), *MODES[mode],
               f"iterations={ITER}", f"threads={THREADS}", f"desired_targets={TARGETS}",
               "fight_style=Patchwerk", f"json2={jpath}"]
        r = subprocess.run(cmd, cwd=os.path.join(ROOT, "simc"), capture_output=True, text=True)
        if r.returncode != 0 or not os.path.exists(jpath):
            return label, mode, None, (r.stderr or r.stdout)[-400:]
    d = json.load(open(jpath))
    p = d["sim"]["players"][0]["collected_data"]["dps"]
    return label, mode, (p["mean"], p.get("mean_std_dev", 0)), None


def main():
    only = sys.argv[1:]
    jobs = [(l, p, m) for l, p in SPECS.items() if not only or l in only for m in MODES]
    res = {}
    # SimC is already multithreaded; run one sim at a time
    for l, p, m in jobs:
        label, mode, val, err = run(l, p, m)
        res.setdefault(label, {})[mode] = val
        print(f"{label:28} {mode:10} {'ERR ' + err if err else f'{val[0]:,.0f}'}", flush=True)
    json.dump(res, open(os.path.join(OUT, "summary.json"), "w"), indent=1)


if __name__ == "__main__":
    main()

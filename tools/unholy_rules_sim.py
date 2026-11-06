#!/usr/bin/env python3
"""Unholy: what Assist Companion's rules are worth, simmed (same method as blood_rules_sim.py).

Rotations per build (MID2 Rider and San'layn profiles) and fight:
  optimal    SimC's default APL.
  hl_simc / hl_game   the highlight (use_blizzard_action_list=1 / its own list; SimC adds no Unholy
             cooldowns, so they match).
  hl_addon   + the addon's Unholy rules: Blightfall when the highlight loops on Outbreak (Blightfall is on
             the Dark Transformation button), Death Coil (1-3 targets) / Epidemic (4+) at 80+ runic power
             (the runic power layer, shown over anything the highlight says except Death Coil / Epidemic).
  +blightfall / +rpcap: one rule each.
Usage: SIMC=<simc checkout with build/simc> python3 tools/unholy_rules_sim.py [iterations]
"""
import json, os, re, subprocess, sys

SIMC = os.environ.get("SIMC") or sys.exit("set SIMC to a SimC checkout with build/simc")
BIN = os.path.join(SIMC, "build", "simc")
OUT = os.path.join(os.path.dirname(os.path.abspath(SIMC)), "unholysim")
ITER = int(sys.argv[1]) if len(sys.argv) > 1 else 1500
FIGHTS = [1, 3, 5]
BUILDS = {
    "Rider": "profiles/MID2/MID2_Death_Knight_Unholy.simc",
    "San'layn": "profiles/MID2/MID2_Death_Knight_Unholy_San'layn.simc",
}
HL = [l.split("=", 1)[1].lstrip("/") for l in
      open(os.path.join(SIMC, "ActionPriorityLists/assisted_combat/deathknight_unholy.simc")).read().splitlines()
      if l.startswith("actions.assisted_combat")]
os.makedirs(OUT, exist_ok=True)
MODES = {"hl_game": (0, 0), "hl_addon": (1, 1), "+blightfall": (1, 0), "+rpcap": (0, 1)}
RP_AT = int(os.environ.get("UNHOLY_RP", "80"))  # the addon's default (/ac unholyrp)


def apl(flags):
    bf, rp = flags
    top = ([f"death_coil,if=runic_power>={RP_AT}&active_enemies<=3",
            f"epidemic,if=runic_power>={RP_AT}&active_enemies>=4"] if rp else [])
    hl = []
    for a in HL:
        if bf and a == "outbreak,if=buff.blightfall.up":
            hl.append("dark_transformation,if=buff.blightfall.up")  # the button casts Blightfall
        hl.append(a)
    if bf:  # Blightfall outranks the runic power layer (rule order)
        top = ["dark_transformation,if=buff.blightfall.up"] + top
    return ["actions.precombat=snapshot_stats", "actions.precombat+=/raise_dead", "actions=auto_attack",
            "actions+=/use_items", "actions+=/potion"] + [f"actions+=/{a}" for a in top + hl]


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

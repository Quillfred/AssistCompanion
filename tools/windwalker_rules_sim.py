#!/usr/bin/env python3
"""Windwalker: what Assist Companion's rules are worth, simmed (same method as unholy_rules_sim.py).

Rotations per build (MID2 Shado-Pan and Conduit of the Celestials profiles) and fight:
  optimal    SimC's default APL.
  hl_simc    the highlight as SimC plays it (use_blizzard_action_list=1: it also presses Zenith, Celestial
             Conduit, Flying Serpent Kick and SimC's cooldown list, Xuen and Touch of Karma).
  hl_game    the highlight as it plays in game: its own list without the automation-only steps (Zenith,
             Celestial Conduit, Flying Serpent Kick) and without Xuen / Touch of Karma.
  hl_addon   + every rule below.
  +<rule>    one rule alone; -<rule>: all rules but that one; all:<variant>: all rules with that variant.
    sck3      Spinning Crane Kick in place of Tiger Palm / Blackout Kick at exactly 3 targets (the highlight's
              filler Spinning Crane Kick needs 4+). Variants: sck3f = only its filler lines, sck3n = not the
              energy-cap Tiger Palm.
    xuen      Invoke Xuen when ready (Conduit; Shado-Pan doesn't have it).
    zenith    Zenith when a charge is ready and Zenith isn't running (zenithx: only with Xuen up or 30+ s away).
    conduit   Celestial Conduit when ready (Conduit; usable after Xuen).
    docj1     Spinning Crane Kick at 1 Dance of Chi-Ji stack (the highlight waits for 2).
    sckrsk    Spinning Crane Kick in place of the highlight's Rising Sun Kick at 3+ targets (sckrsk4: 4+).
Usage: SIMC=<simc checkout with build/simc> python3 tools/windwalker_rules_sim.py [iterations]
"""
import json, os, re, subprocess, sys

SIMC = os.environ.get("SIMC") or sys.exit("set SIMC to a SimC checkout with build/simc")
BIN = os.path.join(SIMC, "build", "simc")
OUT = os.path.join(os.path.dirname(os.path.abspath(SIMC)), "wwsim")
ITER = int(sys.argv[1]) if len(sys.argv) > 1 else 1000
FIGHTS = [int(x) for x in os.environ.get("WW_FIGHTS", "1,3,5").split(",")]
BUILDS = {
    "Shado-Pan": "profiles/MID2/MID2_Monk_Windwalker.simc",
    "Conduit": "profiles/MID2/MID2_Monk_Windwalker_Conduit.simc",
}
AUTOMATION = ("celestial_conduit", "zenith", "flying_serpent_kick")  # not in the game's highlight
HL = [l.split("=", 1)[1].lstrip("/") for l in
      open(os.path.join(SIMC, "ActionPriorityLists/assisted_combat/monk_windwalker.simc")).read().splitlines()
      if l.startswith("actions.assisted_combat")]
HL_GAME = [a for a in HL if not a.startswith(AUTOMATION)]
RULES = os.environ.get("WW_RULES", "sck3,xuen,zenith,conduit").split(",")
MODES = {"hl_game": [], "hl_addon": RULES}
for r in RULES + ["sck3f", "sck3n", "zenithx", "docj1", "sckrsk"]:
    MODES["+" + r] = [r]
for r in RULES:  # each rule's worth with all the others on
    MODES["-" + r] = [x for x in RULES if x != r]
for extra in ("docj1", "sckrsk", "sckrsk4"):  # candidates on top of the full set
    MODES["all+" + extra] = RULES + [extra]
MODES["all+docj1+sckrsk"] = RULES + ["docj1", "sckrsk"]
FINAL = RULES + ["sckrsk4c4", "docj12"]  # what the addon ships (0.26.3: Spinning Crane Kick over Rising Sun Kick at 4+ chi)
MODES["final"] = FINAL
MODES["final:conduitz"] = [("conduitz" if x == "conduit" else x) for x in FINAL]
MODES["final:anychi"] = [("sckrsk4" if x == "sckrsk4c4" else x) for x in FINAL]
MODES["final:c5"] = [("sckrsk4c5" if x == "sckrsk4c4" else x) for x in FINAL]
MODES["final+fofpool"] = FINAL + ["fofpool"]
MODES["final-docj"] = RULES + ["sckrsk4"]  # if the proc can't be seen in game
for alt, base in (("sck3f", "sck3"), ("sck3n", "sck3"), ("zenithx", "zenith")):  # variants inside the full set
    MODES["all:" + alt] = [alt if x == base else x for x in RULES]
os.makedirs(OUT, exist_ok=True)


def cond(a):
    return a.split(",if=", 1)[1].split(",")[0] if ",if=" in a else ""


def apl(rules):
    top = []
    if "xuen" in rules:
        top.append("invoke_xuen_the_white_tiger")
    if "conduit" in rules:
        top.append("celestial_conduit")
    if "zenith" in rules:
        top.append("zenith,if=buff.zenith.down")
    if "conduitz" in rules:  # after Zenith, only while Zenith runs
        top.append("celestial_conduit,if=buff.zenith.up")
    if "zenithx" in rules:
        top.append("zenith,if=buff.zenith.down&(!talent.invoke_xuen_the_white_tiger|pet.xuen_the_white_tiger.active"
                   "|cooldown.invoke_xuen_the_white_tiger.remains>30)")
    if "docj1" in rules:  # Dance of Chi-Ji at 1 stack (its proc glow), above the highlight's whole list
        top.append("spinning_crane_kick,if=buff.dance_of_chiji.up&combo_strike")
    if "docj12" in rules:  # the same at 1-2 targets only
        top.append("spinning_crane_kick,if=buff.dance_of_chiji.up&active_enemies<=2&combo_strike")
    if "fofpool" in rules:  # Tiger Palm to reach 3 chi when Fists of Fury is ready (true cooldown: an upper bound)
        top.append("tiger_palm,if=combo_strike&chi<3&!cooldown.fists_of_fury.remains&active_enemies>=3")
    hl = []
    for a in HL_GAME:
        if "sckrsk" in rules and a.startswith("rising_sun_kick,if=combo_strike"):
            hl.append("spinning_crane_kick,if=active_enemies>=3&combo_strike")
        if "sckrsk4c4" in rules and a.startswith("rising_sun_kick,if=combo_strike"):  # keep 2 chi after it
            hl.append("spinning_crane_kick,if=active_enemies>=4&combo_strike&chi>=4")
        if "sckrsk4c5" in rules and a.startswith("rising_sun_kick,if=combo_strike"):  # keep 3 chi (Fists of Fury)
            hl.append("spinning_crane_kick,if=active_enemies>=4&combo_strike&chi>=5")
        if "sckrsk4" in rules and a.startswith("rising_sun_kick,if=combo_strike"):
            hl.append("spinning_crane_kick,if=active_enemies>=4&combo_strike")
        filler = a.startswith(("tiger_palm,if=combo_strike", "blackout_kick,if=active_enemies<=2"))
        energy_cap = a.startswith("tiger_palm,if=chi<=4&energy>=101")
        tp_bok = a.startswith(("tiger_palm", "blackout_kick"))
        if ("sck3" in rules and tp_bok) or ("sck3f" in rules and filler) or ("sck3n" in rules and tp_bok and not energy_cap):
            c = cond(a)
            hl.append("spinning_crane_kick,if=active_enemies=3&combo_strike" + (f"&({c})" if c else ""))
        hl.append(a)
    return ["actions.precombat=snapshot_stats", "actions=auto_attack", "actions+=/use_items",
            "actions+=/potion"] + [f"actions+=/{a}" for a in top + hl]


def profile(build, mode):
    src = open(os.path.join(SIMC, BUILDS[build])).read().splitlines()
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
    json.dump({f"{b}|{m}|{n}": v for (b, m, n), v in res.items()}, open(os.path.join(OUT, "summary.json"), "w"), indent=1)
    for b in BUILDS:
        print(f"\n{b}: DPS vs optimal ({' / '.join(f'{n}T' for n in FIGHTS)}), and vs hl_game")
        for m in modes:
            print(f"{m:>10} " + " ".join(
                f"{res[(b, m, n)]:9.0f} {100 * (res[(b, m, n)] / res[(b, 'optimal', n)] - 1):+6.1f}% "
                f"({100 * (res[(b, m, n)] / res[(b, 'hl_game', n)] - 1):+5.1f})" for n in FIGHTS))


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Devastation: what Assist Companion's rules are worth, simmed.

SimC can't run the addon, so its rules are written as a SimC action list on top of the in-game
highlight's list (SimC's assisted_combat/evoker_devastation.simc). Four rotations per build and fight:

  optimal      SimC's default APL (the rankings' "optimal").
  hl_simc      use_blizzard_action_list=1: the highlight as the rankings sim it. SimC adds its own
               cooldown list (Dragonrage, Deep Breath, Tip the Scales used on cooldown) and plays every
               empower at max rank; Azure Sweep / Unbound Flame are never cast (SimC can't press the
               button overrides).
  hl_game      the highlight as it plays in game: no Dragonrage / Deep Breath / Tip the Scales (the owner's
               logs: never suggested), button overrides pressed (Azure Sweep, Unbound Flame), empowers at
               max rank (the highlight doesn't say a rank).
  hl_cds       hl_game + Dragonrage / Deep Breath / Tip the Scales pressed on cooldown by the player
               (what hl_simc does, but with the button overrides working): splits the addon's gain into
               its cooldown part and its rotation part (essence cap, Pyre at 3, ranks).
  hl_ranks / hl_cap   breakdown: hl_cds + only the empower rank badge / only essence cap + Pyre at 3.
  hl_addon     hl_game + Assist Companion 0.21.5's Devastation rules: Dragonrage / Deep Breath / Tip the
               Scales prompts, essence cap, Pyre at 3 targets (Flameshaper), empower rank badge.

Usage: SIMC=<simc checkout with build/simc> python3 tools/dev_addon_sim.py [iterations]
Writes a table to stdout and JSON to $SIMC/../devsim/.
"""
import json, os, subprocess, sys, concurrent.futures as cf

SIMC = os.environ.get("SIMC") or sys.exit("set SIMC to a SimC checkout with build/simc")
BIN = os.path.join(SIMC, "build", "simc")
OUT = os.path.join(os.path.dirname(os.path.abspath(SIMC)), "devsim")
ITER = int(sys.argv[1]) if len(sys.argv) > 1 else 2000
THREADS = int(os.environ.get("THREADS", "4"))
FIGHTS = [1, 3, 5]
BUILDS = {
    "Scalecommander": "profiles/MID1/MID1_Evoker_Devastation.simc",
    "Flameshaper": "profiles/MID1/MID1_Evoker_Devastation_FS.simc",
}
os.makedirs(OUT, exist_ok=True)
MODES = ("optimal", "hl_simc", "hl_game", "hl_cds", "hl_addon")
EXTRA = ("hl_ranks", "hl_cap")  # breakdown: hl_cds + only the rank badge / only essence cap + Pyre at 3

PRE = ["actions.precombat=snapshot_stats", "actions.precombat+=/living_flame"]
# Kept in every hand-written rotation, as in SimC's highlight mode (the player uses these themselves).
ITEMS = ["actions.items=potion",
         "actions.items+=/use_items,if=buff.dragonrage.up|!talent.dragonrage|cooldown.dragonrage.remains>20"]

FS_PYRE3 = "talent.legacy_of_the_lifebinder&(talent.volatility|talent.feed_the_flames)"
# Empower rank badge (Rules.lua ns.empowerRank[1467]), as conditions per rank.
ES_RANKS = [
    (1, "active_enemies<=1+talent.eternitys_span"),
    (2, "active_enemies<=2*(1+talent.eternitys_span)"),
    (3, "active_enemies<=3*(1+talent.eternitys_span)|!talent.font_of_magic"),
    (4, "1"),
]
FB_RANKS = [
    (1, "talent.mass_disintegrate&(active_enemies=1|active_enemies>4)|!talent.mass_disintegrate&(active_enemies=1|"
        "talent.legacy_of_the_lifebinder&(active_enemies>=5|active_enemies>=3&(talent.volatility|talent.feed_the_flames)))"),
    (2, "talent.mass_disintegrate&active_enemies=2|!talent.mass_disintegrate&(active_enemies=2|buff.dragonrage.up|buff.rising_fury.up)"),
    (3, "talent.mass_disintegrate&(active_enemies=3|active_enemies=4&!talent.font_of_magic)|!talent.mass_disintegrate"),
    (4, "1"),
]


def ranked(action, cond, ranks, extra=""):
    out = []
    for r, rc in ranks:
        c = f"({rc})" + (f"&({cond})" if cond else "")
        out.append(f"{action},empower_to={r},if={c}{extra}")
    return out


def highlight_game(ranks, cap):
    """The in-game highlight list (assisted_combat), optionally with the addon's corrections folded in."""
    L = []
    fb1 = "talent.consume_flame&!dot.fire_breath_damage.ticking"
    fb2 = "!talent.consume_flame"
    if ranks:
        L += ranked("fire_breath", fb1, FB_RANKS, ",cooldown_allow_casting_success=1")
        L += ranked("fire_breath", fb2, FB_RANKS, ",cooldown_allow_casting_success=1")
        L += ranked("eternity_surge", "", ES_RANKS, ",cooldown_allow_casting_success=1")
    else:
        L += [f"fire_breath,if={fb1},cooldown_allow_casting_success=1",
              f"fire_breath,if={fb2},cooldown_allow_casting_success=1",
              "eternity_surge,cooldown_allow_casting_success=1"]
    L += ["disintegrate,if=active_enemies>3&buff.mass_disintegrate_stacks.up",
          "unbound_flame,if=buff.unbound_flame.up&buff.essence_burst.stack<=1",  # Dragonrage button
          "pyre,if=active_enemies>3"]
    if cap:  # essence cap: spend instead of the generators below
        L += [f"pyre,if=essence>=essence.max&(active_enemies>3|active_enemies=3&{FS_PYRE3})",
              "disintegrate,if=essence>=essence.max"]
    L += ["azure_sweep,if=buff.azure_sweep.up",  # Azure Strike button
          "living_flame,if=active_enemies>3&buff.burnout.up&buff.leaping_flames.up",
          "azure_strike,if=active_enemies>3"]
    if cap:
        L += [f"pyre,if=active_enemies=3&{FS_PYRE3}"]
    L += ["disintegrate", "living_flame"]
    return L


def apl(mode):
    if mode in ("optimal", "hl_simc"):
        return None
    lines = list(PRE) + ITEMS
    acts = ["actions=call_action_list,name=items"]
    if mode != "hl_game":
        acts += ["actions+=/dragonrage",
                 "actions+=/deep_breath,if=talent.imminent_destruction|talent.melt_armor|talent.maneuverability|active_enemies>1",
                 "actions+=/tip_the_scales,if=cooldown.fire_breath.ready"]
    acts += ["actions+=/call_action_list,name=hl"]
    hl = highlight_game(mode in ("hl_addon", "hl_ranks"), mode in ("hl_addon", "hl_cap"))
    lines += acts + ["actions.hl=" + hl[0]] + ["actions.hl+=/" + a for a in hl[1:]]
    return lines


def profile(build, mode):
    src = open(os.path.join(SIMC, BUILDS[build])).read().splitlines()
    body = [l for l in src if not l.startswith("actions")]
    a = apl(mode)
    if a is None:
        return "\n".join(src) + "\n"
    return "\n".join(body + a) + "\n"


def run(build, mode, n):
    tag = f"{build}_{mode}_{n}t"
    prof = os.path.join(OUT, tag + ".simc")
    js = os.path.join(OUT, tag + ".json")
    open(prof, "w").write(profile(build, mode))
    if not os.path.exists(js):
        cmd = [BIN, prof, f"iterations={ITER}", f"threads={THREADS}", f"desired_targets={n}",
               "fight_style=Patchwerk", "max_time=300", f"json2={js}"]
        if mode == "hl_simc":
            cmd.append("use_blizzard_action_list=1")
        r = subprocess.run(cmd, cwd=SIMC, capture_output=True, text=True)
        if r.returncode != 0 or not os.path.exists(js):
            return build, mode, n, None, (r.stderr or r.stdout)[-600:]
    d = json.load(open(js))
    p = d["sim"]["players"][0]
    casts = {s["name"]: round(s.get("num_executes", {}).get("mean", 0), 1)
             for s in p["stats"] if s.get("num_executes", {}).get("mean", 0) > 0}
    return build, mode, n, p["collected_data"]["dps"]["mean"], casts


def main():
    jobs = [(b, m, n) for b in BUILDS for m in MODES + EXTRA for n in FIGHTS]
    res = {}
    with cf.ThreadPoolExecutor(1) as ex:  # SimC is already multithreaded
        for b, m, n, dps, extra in ex.map(lambda j: run(*j), jobs):
            if dps is None:
                print(f"FAILED {b} {m} {n}t:\n{extra}", file=sys.stderr)
                continue
            res[(b, m, n)] = (dps, extra)
    json.dump({f"{b}|{m}|{n}": {"dps": v[0], "casts": v[1]} for (b, m, n), v in res.items()},
              open(os.path.join(OUT, "summary.json"), "w"), indent=1)
    for b in BUILDS:
        print(f"\n{b}  (loss vs optimal; last two columns: addon vs highlight alone, and vs highlight + cooldowns)")
        print(f"{'targets':>8} {'optimal':>9} " + " ".join(f"{m:>16}" for m in MODES[1:]) + f" {'vs hl_game':>10} {'vs hl_cds':>10}")
        for n in FIGHTS:
            if (b, "optimal", n) not in res:
                continue
            opt = res[(b, "optimal", n)][0]
            d = {m: res.get((b, m, n), (None,))[0] for m in MODES}
            cells = [f"{d[m]:9.0f} {100 * (d[m] / opt - 1):+5.1f}%" if d[m] else "-" for m in MODES[1:]]
            g = lambda base: f"{100 * (d['hl_addon'] / d[base] - 1):+.1f}%" if d[base] and d["hl_addon"] else "-"
            print(f"{n:>8} {opt:9.0f} " + " ".join(f"{c:>16}" for c in cells) + f" {g('hl_game'):>10} {g('hl_cds'):>10}")
        for n in FIGHTS:
            c = res.get((b, "hl_cds", n), (None,))[0]
            parts = [f"{m}: {100 * (res[(b, m, n)][0] / c - 1):+.1f}%" for m in EXTRA if c and (b, m, n) in res]
            print(f"   {n}t vs hl_cds: " + ", ".join(parts))

if __name__ == "__main__":
    main()

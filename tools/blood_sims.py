#!/usr/bin/env python3
"""Blood DK: optimal rotation vs Assisted Highlight at 1/3/5 targets.
Reports cast counts, runic power waste, Bone Shield uptime, damage taken and DPS."""
import json, os, subprocess

OLD = os.environ.get("SIM_ROOT", os.path.dirname(os.path.abspath(__file__)))  # folder with simc/ and table_data.json
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "blood")
os.makedirs(OUT, exist_ok=True)
SIMC = f"{OLD}/simc/build/simc"
PROFILE = f"{OLD}/simc/profiles/MID2/MID2_Death_Knight_Blood.simc"
row = [x for x in json.load(open(f"{OLD}/table_data.json")) if x["spec"] == "Blood DK"][0]

FIGHTS = {  # targets: (optimal build, highlight build)
    1: (row["t_st"], row["t_st2"]),
    3: (row["t_c3"], row["t_c3_2"]),
    5: (row["t_aoe"], row["t_aoe2"]),
}
KEYS = ["death_strike", "heart_strike", "marrowrend", "deaths_caress", "blood_boil", "death_and_decay",
        "dancing_rune_weapon", "consumption", "bonestorm", "tombstone", "soul_reaper", "reapers_mark",
        "vampiric_blood", "rune_tap", "icebound_fortitude", "antimagic_shell", "raise_dead", "vampiric_strike"]


def sim(targets, talents, hl):
    tag = f"{targets}t_{'hl' if hl else 'opt'}"
    j = os.path.join(OUT, tag + ".json")
    if not os.path.exists(j):
        cmd = [SIMC, PROFILE, f"talents={talents}", f"desired_targets={targets}", "iterations=3000",
               "threads=4", "fight_style=Patchwerk", f"json2={j}"] + (["use_blizzard_action_list=1"] if hl else [])
        subprocess.run(cmd, cwd=f"{OLD}/simc", capture_output=True)
    p = json.load(open(j))["sim"]["players"][0]
    cd = p["collected_data"]
    casts = {}
    for s in p["stats"]:
        v = s.get("num_executes", {}).get("mean", 0)
        if v:
            casts[s["name"]] = casts.get(s["name"], 0) + v
    gained = wasted = 0
    for g in p.get("gains", []):
        d = g.get("runic_power")
        if isinstance(d, dict):
            gained += d.get("actual", 0); wasted += d.get("overflow", 0)
    bone = next((b for b in p.get("buffs", []) if b.get("name") == "bone_shield"), {})
    dtps = cd.get("dtps", {}).get("mean")
    return {"dps": cd["dps"]["mean"], "casts": casts, "rp_gained": gained, "rp_wasted": wasted,
            "bone_uptime": bone.get("uptime"), "dtps": dtps}


res = {}
for t, (opt_t, hl_t) in FIGHTS.items():
    res[t] = {"opt": sim(t, opt_t, False), "hl": sim(t, hl_t, True)}
json.dump(res, open(os.path.join(OUT, "summary.json"), "w"), indent=1)

for t in FIGHTS:
    o, h = res[t]["opt"], res[t]["hl"]
    print(f"\n===== {t} target(s)")
    print(f"{'':22}{'optimal':>12}{'highlight':>12}")
    print(f"{'DPS':22}{o['dps']:>12,.0f}{h['dps']:>12,.0f}   ({(h['dps']/o['dps']-1)*100:+.1f}%)")
    for lab, k in [("RP wasted %", None), ("Bone Shield uptime %", "bone_uptime"), ("damage taken/s", "dtps")]:
        if k is None:
            f = lambda r: 100 * r["rp_wasted"] / max(1, r["rp_gained"] + r["rp_wasted"])
            print(f"{lab:22}{f(o):>12.1f}{f(h):>12.1f}")
        else:
            fmt = lambda v: f"{v:>12,.1f}" if isinstance(v, (int, float)) else f"{'n/a':>12}"
            print(f"{lab:22}{fmt(o[k])}{fmt(h[k])}")
    for k in KEYS:
        a, b = o["casts"].get(k, 0), h["casts"].get(k, 0)
        if a or b:
            print(f"{k:22}{a:>12.1f}{b:>12.1f}")

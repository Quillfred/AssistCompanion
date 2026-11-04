#!/usr/bin/env python3
"""Estimate what the proposed Blood corrections are worth: sim the in-game Assisted Highlight
priority with our correction rules inserted on top, and compare with the plain highlight and the
optimal rotation. Each rule mirrors what the addon can actually observe in combat:
  * Bone Shield refresh: >=25s since the last Marrowrend / Death's Caress (addon times this
    from your casts) -> Marrowrend, or Death's Caress if fewer than 2 runes
  * Death Strike at runic power within 20 of max (runic power is readable)
  * Blood Boil instead of Heart Strike when a charge is available (addon tracks charges from casts)
"""
import json, os, re, subprocess

OLD = os.environ.get("SIM_ROOT", os.path.dirname(os.path.abspath(__file__)))  # folder with simc/ and table_data.json
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "blood")
SIMC = f"{OLD}/simc/build/simc"
PROFILE = f"{OLD}/simc/profiles/MID2/MID2_Death_Knight_Blood.simc"
APL = open(f"{OLD}/simc/ActionPriorityLists/assisted_combat/deathknight_blood.simc").read()
row = [x for x in json.load(open(f"{OLD}/table_data.json")) if x["spec"] == "Blood DK"][0]
BUILDS = {1: row["t_st2"], 3: row["t_c3_2"], 5: row["t_aoe2"]}
summary = json.load(open(os.path.join(OUT, "summary.json")))

BONE = ["marrowrend,if=buff.bone_shield.up&buff.bone_shield.remains<5&rune>=2",
        "deaths_caress,if=buff.bone_shield.up&buff.bone_shield.remains<5&rune<2"]
DS = ["death_strike,if=runic_power.deficit<20"]
BB = ["blood_boil,if=charges>=1&target.distance<=10"]


def build_apl(bone=False, ds=False, bb=False):
    lines = APL.splitlines()
    out, top_inserted = [], False
    for ln in lines:
        m = re.match(r"actions\.assisted_combat(\+?=)/?(.*)", ln)
        if m and not top_inserted:
            # our corrections go first: they override the highlight's suggestion
            first = (BONE if bone else []) + (DS if ds else [])
            for i, a in enumerate(first):
                out.append(("actions.assisted_combat=" if i == 0 else "actions.assisted_combat+=/") + a)
            rest = m.group(2)
            out.append(("actions.assisted_combat+=/" if first else "actions.assisted_combat=") + rest)
            top_inserted = True
            continue
        if bb and re.match(r"actions\.assisted_combat\+=/heart_strike", ln) and not any(BB[0] in o for o in out):
            out.append("actions.assisted_combat+=/" + BB[0])   # Blood Boil just above Heart Strike
        out.append(ln)
    return "\n".join(out) + "\n"


def run(targets, name, apl_text):
    j = os.path.join(OUT, f"rules_{targets}t_{name}.json")
    if not os.path.exists(j):
        apl_file = os.path.join(OUT, f"rules_{name}.simc")
        open(apl_file, "w").write(apl_text)
        subprocess.run([SIMC, PROFILE, f"talents={BUILDS[targets]}", apl_file, f"desired_targets={targets}",
                        "iterations=3000", "threads=4", "fight_style=Patchwerk", f"json2={j}"],
                       cwd=f"{OLD}/simc", capture_output=True)
    p = json.load(open(j))["sim"]["players"][0]
    cd = p["collected_data"]
    gained = wasted = 0
    for g in p.get("gains", []):
        d = g.get("runic_power")
        if isinstance(d, dict):
            gained += d.get("actual", 0); wasted += d.get("overflow", 0)
    bone = next((b for b in p.get("buffs", []) if b.get("name") == "bone_shield"), {})
    return cd["dps"]["mean"], cd.get("dtps", {}).get("mean"), 100 * wasted / max(1, gained + wasted), bone.get("uptime")


VARIANTS = [
    ("highlight (reproduced)", dict()),
    ("+ Bone Shield refresh", dict(bone=True)),
    ("+ Death Strike at RP cap", dict(ds=True)),
    ("+ Blood Boil charges", dict(bb=True)),
    ("all three", dict(bone=True, ds=True, bb=True)),
]
for t in (1, 3, 5):
    opt = summary[str(t)]["opt"]; hl = summary[str(t)]["hl"]
    print(f"\n===== {t} target(s)   optimal {opt['dps']:,.0f} DPS, {opt['dtps']/1e6:.2f}M dmg taken/s")
    print(f"  {'in-game highlight (sim flag)':30}{hl['dps']:>10,.0f}  {(hl['dps']/opt['dps']-1)*100:+6.1f}%   taken {hl['dtps']/1e6:5.2f}M/s")
    for name, kw in VARIANTS:
        key = name.split(" ")[0] + "_" + "_".join(k for k, v in kw.items() if v)
        dps, dtps, waste, up = run(t, key, build_apl(**kw))
        print(f"  {name:30}{dps:>10,.0f}  {(dps/opt['dps']-1)*100:+6.1f}%   taken {dtps/1e6:5.2f}M/s   RP waste {waste:4.1f}%   Bone Shield {up or 0:5.1f}%")

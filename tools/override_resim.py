#!/usr/bin/env python3
"""Re-sim the Assisted Highlight for specs hit by SimC's button-override limitation.

In game, the highlight suggests a base spell (e.g. Chaos Strike) and pressing that button casts
its current override (Annihilation during Metamorphosis). SimC's base actions refuse to fire in
those states, so its highlight sims undercount. Here each override is added right after its base
spell's line(s) in the highlight list, with the same conditions, and the highlight is re-simmed on
its best build for 1, 3 and 5 targets. Results: simout_override/<spec>_<n>t.json.

Usage: SIM_ROOT=<folder with simc/, summaries, override_map.json> python3 override_resim.py [spec ...]
"""
import json, os, re, subprocess, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from run_sims import SPECS  # noqa: E402
from triage import ROOT, APL, OVERRIDES, apl_name, parse_apl, slug  # noqa: E402

OUT = os.path.join(ROOT, "simout_override")
os.makedirs(OUT, exist_ok=True)
SIMC = os.path.join(ROOT, "simc", "build", "simc")
ITER = int(os.environ.get("ITER", "3000"))


def patched_apl(spec_file, opt_acts):
    by_base = {}
    for o, bases in OVERRIDES.items():
        if o in opt_acts:                      # SimC implements the override as its own action
            for b in bases:
                by_base.setdefault(b, []).append(o)
    out, added = [], []
    for ln in open(spec_file):
        ln = ln.rstrip("\n")
        out.append(ln)
        m = re.match(r"actions\.assisted_combat\+?=/?([a-z0-9_]+)(,.*)?$", ln)
        if m and m.group(1) in by_base:
            for o in by_base[m.group(1)]:
                out.append(f"actions.assisted_combat+=/{o}{m.group(2) or ''}")
                added.append(f"{m.group(1)}->{o}")
    return "\n".join(out) + "\n", sorted(set(added))


def talents_for(label):
    ah1 = json.load(open(os.path.join(ROOT, "simout_ahbuild_1t", "summary.json")))[label]["talents"]
    c3 = json.load(open(os.path.join(ROOT, "simout_cleave3", "summary.json")))[label]["hl_talents"]
    ah5 = json.load(open(os.path.join(ROOT, "simout_ahbuild", "summary.json")))[label]["talents"]
    return {1: ah1, 3: c3, 5: ah5}


def run(label, apl_text, suffix=""):
    s = slug(label)
    apl_file = os.path.join(OUT, f"{s}{suffix}.simc")
    open(apl_file, "w").write(apl_text)
    # The profile's own action lists (e.g. trinket lists) reference variables from the optimal
    # list, so load the profile without them: gear, talents and stats only.
    prof = os.path.join(OUT, f"{s}_profile.simc")
    with open(os.path.join(ROOT, "simc", "profiles", SPECS[label])) as src, open(prof, "w") as dst:
        dst.writelines(ln for ln in src if not ln.lstrip().startswith("actions"))
    for t, tal in talents_for(label).items():
        j = os.path.join(OUT, f"{s}_{t}t{suffix}.json")
        if os.path.exists(j):
            continue
        subprocess.run([SIMC, prof, *([f"talents={tal}"] if tal else []), apl_file, f"desired_targets={t}",
                        f"iterations={ITER}", "threads=4", "fight_style=Patchwerk", f"json2={j}"],
                       cwd=os.path.join(ROOT, "simc"), capture_output=True)


def main():
    targets = sys.argv[1:] or list(SPECS)
    for label in targets:
        name = apl_name(SPECS[label])
        hl_file = os.path.join(APL, "assisted_combat", name + ".simc")
        opt_acts, _ = parse_apl(os.path.join(APL, "default", name + ".simc"))
        text, added = patched_apl(hl_file, opt_acts)
        if not added:
            continue
        print(f"{label}: {', '.join(added)}", flush=True)
        run(label, text)
        if os.environ.get("BASELINE"):
            run(label, open(hl_file).read(), suffix="_baseline")


if __name__ == "__main__":
    main()

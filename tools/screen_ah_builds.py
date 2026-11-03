#!/usr/bin/env python3
"""Find each spec's best Assisted Highlight talent build on N targets (TARGETS env, default 5).

Pass 1 (screen): every candidate build at low iterations.
Pass 2 (final):  the winner per spec at full iterations.
Results are cached per run so the script can resume after a restart.
"""
import hashlib, json, os, subprocess, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, ROOT)
import run_sims as rs  # reuse SPECS, SIMC, PROF

CANDS = json.load(open(os.path.join(ROOT, "nox", "candidate_builds.json")))
TARGETS = int(os.environ.get("TARGETS", "5"))
OUT = os.path.join(ROOT, "simout_ahbuild" if TARGETS == 5 else f"simout_ahbuild_{TARGETS}t")
os.makedirs(OUT, exist_ok=True)
SCREEN_ITER = int(os.environ.get("SCREEN_ITER", "600"))
FINAL_ITER = int(os.environ.get("FINAL_ITER", "3000"))


def slug(label):
    x = label.replace(" (tank)", "").replace(" DK", " Death Knight").replace(" DH", " Demon Hunter")
    return x.lower().replace(" ", "-")


def sim(label, talents, iters, tag):
    h = hashlib.sha1((talents or "profile").encode()).hexdigest()[:10]
    jpath = os.path.join(OUT, f"{slug(label)}_{tag}_{h}.json")
    if not os.path.exists(jpath):
        cmd = [rs.SIMC, os.path.join(rs.PROF, rs.SPECS[label]),
               *([f"talents={talents}"] if talents else []),
               "use_blizzard_action_list=1", f"iterations={iters}", "threads=4",
               f"desired_targets={TARGETS}", "fight_style=Patchwerk", f"json2={jpath}"]
        r = subprocess.run(cmd, cwd=os.path.join(ROOT, "simc"), capture_output=True, text=True)
        if r.returncode != 0 or not os.path.exists(jpath):
            print(f"ERR {label} {h}: {(r.stderr or r.stdout)[-300:]}", flush=True)
            return None
    p = json.load(open(jpath))["sim"]["players"][0]["collected_data"]["dps"]
    return p["mean"], p.get("mean_std_dev", 0)


def main():
    best = {}
    for label in rs.SPECS:
        cands = [None] + CANDS[slug(label)]  # None = SimC profile's own talents
        scored = []
        for t in cands:
            v = sim(label, t, SCREEN_ITER, "screen")
            if v:
                scored.append((v[0], t))
        scored.sort(key=lambda x: x[0], reverse=True)
        top = scored[0]
        print(f"SCREEN {label:28} {len(scored):2} builds  best={top[0]:,.0f}", flush=True)
        best[label] = top[1]
    finals = {}
    for label, t in best.items():
        v = sim(label, t, FINAL_ITER, "final")
        finals[label] = {"talents": t, "dps": v[0], "err": v[1]}
        print(f"FINAL {label:28} {v[0]:,.0f}", flush=True)
    json.dump(finals, open(os.path.join(OUT, "summary.json"), "w"), indent=1)


if __name__ == "__main__":
    main()

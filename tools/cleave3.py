#!/usr/bin/env python3
"""3-target cleave: find the optimal rotation's best build and the highlight's best build per spec.

Outputs simout_cleave3/summary.json with, per spec:
  opt_talents / opt_dps        optimal rotation on its best 3-target build
  hl_on_opt_dps                Assisted Highlight on that same build
  hl_talents / hl_dps          Assisted Highlight on its own best 3-target build
Every sim is cached on disk so the script resumes after a restart.
"""
import hashlib, json, os, subprocess, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, ROOT)
import run_sims as rs  # SPECS, SIMC, PROF

CANDS = json.load(open(os.path.join(ROOT, "nox", "candidate_builds.json")))
OUT = os.path.join(ROOT, "simout_cleave3")
os.makedirs(OUT, exist_ok=True)
TARGETS = 3
SCREEN_ITER = int(os.environ.get("SCREEN_ITER", "600"))
FINAL_ITER = int(os.environ.get("FINAL_ITER", "3000"))


def slug(label):
    x = label.replace(" (tank)", "").replace(" DK", " Death Knight").replace(" DH", " Demon Hunter")
    return x.lower().replace(" ", "-")


def sim(label, talents, rotation, iters, tag):
    h = hashlib.sha1((talents or "profile").encode()).hexdigest()[:10]
    jpath = os.path.join(OUT, f"{slug(label)}_{rotation}_{tag}_{h}.json")
    if not os.path.exists(jpath):
        cmd = [rs.SIMC, os.path.join(rs.PROF, rs.SPECS[label]),
               *([f"talents={talents}"] if talents else []),
               *(["use_blizzard_action_list=1"] if rotation == "hl" else []),
               f"iterations={iters}", "threads=4", f"desired_targets={TARGETS}",
               "fight_style=Patchwerk", f"json2={jpath}"]
        r = subprocess.run(cmd, cwd=os.path.join(ROOT, "simc"), capture_output=True, text=True)
        if r.returncode != 0 or not os.path.exists(jpath):
            print(f"ERR {label} {rotation} {h}: {(r.stderr or r.stdout)[-300:]}", flush=True)
            return None
    p = json.load(open(jpath))["sim"]["players"][0]["collected_data"]["dps"]
    return p["mean"]


def best_build(label, rotation):
    scored = []
    for t in [None] + CANDS[slug(label)]:  # None = SimC profile's own talents
        v = sim(label, t, rotation, SCREEN_ITER, "screen")
        if v:
            scored.append((v, t))
    scored.sort(key=lambda x: x[0], reverse=True)
    return scored[0][1], len(scored)


def main():
    res = {}
    for label in rs.SPECS:
        opt_t, n1 = best_build(label, "full")
        hl_t, n2 = best_build(label, "hl")
        print(f"SCREEN {label:28} full:{n1} hl:{n2}", flush=True)
        res[label] = {"opt_talents": opt_t, "hl_talents": hl_t}
    for label, r in res.items():
        r["opt_dps"] = sim(label, r["opt_talents"], "full", FINAL_ITER, "final")
        r["hl_on_opt_dps"] = sim(label, r["opt_talents"], "hl", FINAL_ITER, "final")
        r["hl_dps"] = sim(label, r["hl_talents"], "hl", FINAL_ITER, "final")
        print(f"FINAL {label:28} opt={r['opt_dps']:,.0f} hl_on_opt={r['hl_on_opt_dps']:,.0f} hl={r['hl_dps']:,.0f}", flush=True)
    json.dump(res, open(os.path.join(OUT, "summary.json"), "w"), indent=1)


if __name__ == "__main__":
    main()

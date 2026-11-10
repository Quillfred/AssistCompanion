#!/usr/bin/env python3
"""Talent re-check for the specs Assist Companion supports: the best build when playing the highlight +
the addon's rules, against the rankings page's optimal-rotation build, at 1 / 3 / 5 targets.

For each spec and fight: hill-climb (talent_search.climb, "addon" rotation) from the page's build for that
fight, the page's highlight build and SimC's profile build for each hero tree; then sim the page's build and
the best found at FINAL_ITER. Writes $SIMC/../talentsearch/addon_recheck.json and prints a table.
Usage: SIMC=<simc> python3 tools/addon_talent_recheck.py [spec ...]
"""
import json, os, re, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import talent_search as ts  # noqa: E402

PAGE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "docs", "pages", "highlight-rankings.html")
NAMES = {"frost": "Frost DK", "unholy": "Unholy DK", "blood": "Blood DK", "devastation": "Devastation Evoker",
         "windwalker": "Windwalker Monk", "brewmaster": "Brewmaster Monk"}
PROFILES = {  # other hero trees' SimC builds as extra starting points
    "frost": ["profiles/MID2/MID2_Death_Knight_Frost.simc", "profiles/MID2/MID2_Death_Knight_Frost_Rider.simc"],
    "unholy": ["profiles/MID2/MID2_Death_Knight_Unholy.simc", "profiles/MID2/MID2_Death_Knight_Unholy_San'layn.simc"],
    "blood": ["profiles/MID2/MID2_Death_Knight_Blood.simc", "profiles/MID2/MID2_Death_Knight_Blood_Deathbringer.simc"],
    "devastation": ["profiles/MID1/MID1_Evoker_Devastation.simc", "profiles/MID1/MID1_Evoker_Devastation_FS.simc"],
    "windwalker": ["profiles/MID2/MID2_Monk_Windwalker.simc", "profiles/MID2/MID2_Monk_Windwalker_Conduit.simc"],
    "brewmaster": ["profiles/MID2/MID2_Monk_Brewmaster.simc"],
}
FIGHTS = {1: ("t_st", "t_st2"), 3: ("t_c3", "t_c3_2"), 5: ("t_aoe", "t_aoe2")}


def page():
    s = open(PAGE).read()
    return {e["spec"]: e for e in json.loads(re.search(r"const DATA = (\[.*?\]);", s, re.S).group(1))}


def talents(path):
    for l in open(os.path.join(ts.SIMC, path)):
        if l.startswith("talents="):
            return l.strip().split("=", 1)[1]


def main():
    specs = sys.argv[1:] or list(NAMES)
    data = page()
    out_path = os.path.join(ts.OUT, "addon_recheck.json")
    res = json.load(open(out_path)) if os.path.exists(out_path) else {}
    for spec in specs:
        ts.NODES = ts.class_nodes(ts.SPECS[spec][1])
        e = data[NAMES[spec]]
        for n, (k_opt, k_hl) in FIGHTS.items():
            key = f"{spec}|{n}"
            if key in res:
                continue
            page_build = e[k_opt]
            starts = list(dict.fromkeys([page_build, e[k_hl]] + [talents(p) for p in PROFILES[spec]]))
            best = None
            for st in starts:
                b, d, log = ts.climb(spec, "addon", n, st)
                if b and (best is None or d > best[0]):
                    best = (d, b, st, log)
                print(f"{spec} {n}T start {st[:20]}..: {d and round(d)} {'; '.join(log)}", flush=True)
            base = ts.sim(spec, "addon", n, page_build, ts.FINAL)
            res[key] = {"page_build": page_build, "page_dps": base, "best_build": best[1], "best_dps": best[0],
                        "gain": 100 * (best[0] / base - 1), "from": best[2], "swaps": best[3],
                        "hero": ts.names(best[1], ts.NODES)[:0]}
            json.dump(res, open(out_path, "w"), indent=1)
            print(f"== {spec} {n}T: page build {base:,.0f}, best {best[0]:,.0f} ({res[key]['gain']:+.2f}%) "
                  f"{'; '.join(best[3]) or '(no swap)'}", flush=True)


if __name__ == "__main__":
    main()

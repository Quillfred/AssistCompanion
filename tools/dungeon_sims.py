#!/usr/bin/env python3
"""DungeonSlice sims for every spec on the rankings page: optimal rotation, the highlight (SimC's
use_blizzard_action_list=1, as the page's other fights) and, for specs Assist Companion supports, the
highlight + the addon's rules (tools/addon_apl.py). Each spec on the page's 5-target (AoE) optimal-rotation
build and its SimC profile (run_sims.SPECS). Augmentation is scored like talent_search.py: raid DPS minus the
same raid with an idle Augmentation. Writes $SIMC/../dungeon/summary.json.
Usage: SIMC=<simc> python3 tools/dungeon_sims.py [iterations]
"""
import json, os, re, subprocess, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
SIMC = os.environ.get("SIMC") or sys.exit("set SIMC")
BIN = os.path.join(SIMC, "build", "simc")
OUT = os.path.join(os.path.dirname(os.path.abspath(SIMC)), "dungeon")
ITER = int(sys.argv[1]) if len(sys.argv) > 1 else 1000
PAGE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "docs", "pages", "highlight-rankings.html")
ADDON = {"Frost DK": "frost", "Unholy DK": "unholy", "Blood DK": "blood", "Devastation Evoker": "devastation",
         "Windwalker Monk": "windwalker", "Brewmaster Monk": "brewmaster"}
os.makedirs(OUT, exist_ok=True)


def profiles():
    src = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "run_sims.py")).read()
    block = src[src.index("SPECS = {"):src.index("}", src.index("SPECS = {"))]
    m = dict(re.findall(r'"([^"]+)": "([^"]+\.simc)"', block))
    return {k.replace(" (tank)", ""): v for k, v in m.items()}


def run(tag, args, extra=(), raid=False):
    js = os.path.join(OUT, tag + ".json")
    if not os.path.exists(js):
        cmd = [BIN, *args, f"iterations={ITER}", "threads=4", "fight_style=DungeonSlice", f"json2={js}", *extra]
        r = subprocess.run(cmd, cwd=SIMC, capture_output=True, text=True)
        if r.returncode != 0 or not os.path.exists(js):
            print(f"{tag}: failed {(r.stderr or r.stdout)[-300:]}", flush=True)
            return None
    d = json.load(open(js))["sim"]
    return d["statistics"]["raid_dps"]["mean"] if raid else d["players"][0]["collected_data"]["dps"]["mean"]


def main():
    s = open(PAGE).read()
    data = json.loads(re.search(r"const DATA = (\[.*?\]);", s, re.S).group(1))
    prof = profiles()
    res = {}
    out = os.path.join(OUT, "summary.json")
    if os.path.exists(out):
        res = json.load(open(out))
    for e in data:
        spec = e["spec"]
        if spec in res:
            continue
        tal = f"talents={e['t_aoe']}"
        tag = re.sub(r"\W", "", spec)
        if spec == "Augmentation Evoker":
            import talent_search as ts
            base = ts.aug_profile()
            r = {k: (run(f"{tag}_{k}", base + [tal], x, raid=True) or 0) for k, x in
                 (("optimal", []), ("highlight", ["use_blizzard_action_list=1"]), ("idle", ["actions=snapshot_stats"]))}
            row = {"optimal": r["optimal"] - r["idle"], "highlight": r["highlight"] - r["idle"]}
        else:
            p = os.path.join(SIMC, "profiles", prof[spec])
            row = {"optimal": run(f"{tag}_optimal", [p, tal]),
                   "highlight": run(f"{tag}_highlight", [p, tal], ["use_blizzard_action_list=1"])}
            if spec in ADDON:
                import addon_apl
                body = [l for l in open(p).read().splitlines() if not l.startswith(("actions", "talents="))]
                apl = os.path.join(OUT, f"{tag}_addon.simc")
                open(apl, "w").write("\n".join(body + addon_apl.actions(ADDON[spec])) + "\n")
                row["addon"] = run(f"{tag}_addon", [apl, tal])
        res[spec] = row
        json.dump(res, open(out, "w"), indent=1)
        print(spec, {k: round(v) for k, v in row.items() if v}, flush=True)


if __name__ == "__main__":
    main()

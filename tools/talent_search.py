#!/usr/bin/env python3
"""Best talent build per rotation and target count, by hill-climbing over choice nodes.

Starts from a few known builds (SimC profiles, the rankings page's builds), then repeatedly tries every
single choice-node swap (class, spec and hero trees; same points, so every variant is a legal build)
and keeps the best one, until no swap helps by more than the noise. The hero tree itself is not
swapped: give a start build for each hero tree.

Talent strings are decoded/encoded here (same bit layout as SimC's parse_traits_hash: per node of the
class, sorted by node id: selected, purchased, partial rank (6 bits), choice index (2 bits)).

Usage:
  SIMC=<simc checkout> python3 tools/talent_search.py <spec> <rotation> <targets> <start build>...
  rotation: optimal (SimC's APL) or highlight (use_blizzard_action_list=1)
  Augmentation is scored on raid DPS minus the raid with an idle Augmentation (SimC adds 8 simplified
  allies to a lone Augmentation), with deterministic=1 so builds share random numbers.
Prints the best build and its DPS; results cached in $SIMC/../talentsearch/.
"""
import hashlib, json, os, subprocess, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import talent_db  # noqa: E402  (reads SimC's trait data; SIMC env)

SIMC = talent_db.SIMC
BIN = os.path.join(SIMC, "build", "simc")
OUT = os.path.join(os.path.dirname(os.path.abspath(SIMC)), "talentsearch")
B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
SCREEN, FINAL = int(os.environ.get("SCREEN_ITER", "1500")), int(os.environ.get("FINAL_ITER", "6000"))
NOISE = float(os.environ.get("NOISE", "0.25"))  # % a swap must gain to be kept
SPECS = {  # spec -> (spec id, SimC class index in trait data via a known talent, base profile)
    "devastation": (1467, "Pyre", "profiles/MID1/MID1_Evoker_Devastation.simc"),
    "augmentation": (1473, "Ebon Might", None),
}


def class_nodes(talent_name):
    traits, *_ = talent_db.load()
    cls = next(t["class"] for t in traits if t["name"] == talent_name)
    nodes = {}
    for t in traits:
        if t["class"] == cls:
            nodes.setdefault(t["node"], []).append(t)
    return [(nid, nodes[nid]) for nid in sorted(nodes)]


class Bits:
    def __init__(self, s=""):
        self.bits = [(B64.index(c) >> i) & 1 for c in s for i in range(6)]
        self.pos = 0

    def get(self, n):
        v = 0
        for i in range(n):
            b = self.bits[self.pos] if self.pos < len(self.bits) else 0
            v |= b << i
            self.pos += 1
        return v


def decode(s, nodes):
    r = Bits(s)
    head = (r.get(8), r.get(16), r.get(128))
    out = []
    for nid, entries in nodes:
        n = {"sel": r.get(1)}
        if n["sel"]:
            n["buy"] = r.get(1)
            if n["buy"]:
                n["part"] = r.get(1)
                if n["part"]:
                    n["rank"] = r.get(6)
                n["choice"] = r.get(1)
                if n["choice"]:
                    n["idx"] = r.get(2)
        out.append(n)
    return head, out


def encode(head, nodes_state):
    bits = []
    put = lambda v, n: bits.extend((v >> i) & 1 for i in range(n))
    put(head[0], 8); put(head[1], 16); put(head[2], 128)
    for n in nodes_state:
        put(n["sel"], 1)
        if n["sel"]:
            put(n["buy"], 1)
            if n["buy"]:
                put(n["part"], 1)
                if n["part"]:
                    put(n["rank"], 6)
                put(n["choice"], 1)
                if n["choice"]:
                    put(n["idx"], 2)
    while len(bits) % 6:
        bits.append(0)
    s = "".join(B64[sum(bits[i + j] << j for j in range(6))] for i in range(0, len(bits), 6))
    return s.rstrip("A") or "A"


def swaps(s, nodes, spec_id):
    """Every build one choice-node swap away (not the hero tree selection, tree 4)."""
    head, st = decode(s, nodes)
    out = []
    for i, ((nid, entries), n) in enumerate(zip(nodes, st)):
        if not n.get("choice") or entries[0]["tree"] == 4:
            continue
        for j, e in enumerate(entries):
            if j == n["idx"] or (e["specs"] and spec_id not in e["specs"]):
                continue
            new = [dict(x) for x in st]
            new[i]["idx"] = j
            out.append((f"{entries[n['idx']]['name']} -> {e['name']}", encode(head, new)))
    return out


def names(s, nodes, bought=False):
    """Selected talents (bought=True: only bought ones; hero tree roots are granted for every tree)."""
    _, st = decode(s, nodes)
    return [e[n.get("idx", 0)]["name"] for (nid, e), n in zip(nodes, st) if n["sel"] and (n.get("buy") or not bought)]


def sim(spec, rotation, targets, talents, iters):
    os.makedirs(OUT, exist_ok=True)
    h = hashlib.sha1(f"{spec}{rotation}{targets}{talents}{iters}".encode()).hexdigest()[:12]
    js = os.path.join(OUT, h + ".json")
    if not os.path.exists(js):
        sid, _, prof = SPECS[spec]
        args = [os.path.join(SIMC, prof)] if prof else aug_profile()
        cmd = [BIN, *args, f"talents={talents}", f"iterations={iters}", "threads=4",
               f"desired_targets={targets}", "fight_style=Patchwerk", "max_time=300", f"json2={js}"]
        if rotation == "highlight":
            cmd.append("use_blizzard_action_list=1")
        if rotation == "idle":
            cmd.append("actions=snapshot_stats")
        if spec == "augmentation":
            cmd.append("deterministic=1")  # same random numbers for every build: the raid's noise cancels out
        r = subprocess.run(cmd, cwd=SIMC, capture_output=True, text=True)
        if r.returncode != 0 or not os.path.exists(js):
            return None
    d = json.load(open(js))["sim"]
    p = d["players"][0]
    if p["talents"] != talents and decode(p["talents"], NODES)[1] != decode(talents, NODES)[1]:
        return None  # SimC rejected / rewrote the build
    if spec == "augmentation":
        # Augmentation's worth = its own damage + what it adds to the allies SimC gives it: raid DPS minus
        # the same raid with an idle Augmentation.
        raid = d["statistics"]["raid_dps"]["mean"]
        if rotation == "idle":
            return raid
        return raid - sim(spec, "idle", targets, talents, iters)
    return p["collected_data"]["dps"]["mean"]


def aug_profile():
    # No Augmentation profile in SimC: Devastation's gear with spec=augmentation; SimC adds simplified
    # allies for a solo Augmentation (evoker.make_simplified_if_alone), so DPS includes what it gives them.
    src = open(os.path.join(SIMC, SPECS["devastation"][2])).read().splitlines()
    body = [l for l in src if not l.startswith(("actions", "talents", "spec=", "evoker="))]
    path = os.path.join(OUT, "aug_base.simc")
    open(path, "w").write("\n".join(['evoker="Aug"', "spec=augmentation"] + body) + "\n")
    return [path]


def climb(spec, rotation, targets, start):
    cur, best = start, sim(spec, rotation, targets, start, SCREEN)
    if best is None:
        return None, None, []
    log = []
    while True:
        cands = [(sim(spec, rotation, targets, t, SCREEN), why, t) for why, t in swaps(cur, NODES, SPECS[spec][0])]
        cands = [c for c in cands if c[0]]
        if not cands:
            break
        d, why, t = max(cands)
        if d <= best * (1 + NOISE / 100):
            break
        log.append(f"{why}: {100 * (d / best - 1):+.2f}%")
        cur, best = t, d
    return cur, sim(spec, rotation, targets, cur, FINAL), log


NODES = None


def main():
    global NODES
    spec, rotation, targets = sys.argv[1], sys.argv[2], int(sys.argv[3])
    NODES = class_nodes(SPECS[spec][1])
    results = []
    for start in sys.argv[4:]:
        b, d, log = climb(spec, rotation, targets, start)
        if b:
            results.append((d, b, start, log))
            print(f"start {start[:24]}...: {d:,.0f}  ({'; '.join(log) or 'no swap helped'})", flush=True)
        else:
            print(f"start {start[:24]}...: failed", flush=True)
    d, b, start, log = max(results)
    print(json.dumps({"spec": spec, "rotation": rotation, "targets": targets, "dps": d, "talents": b,
                      "from": start, "swaps": log}))


if __name__ == "__main__":
    main()

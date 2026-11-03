#!/usr/bin/env python3
"""Decode a WoW retail talent export string into talent names, using SimC's talent data.

Usage: decode_talents.py <export string>
Reads the spec from the string's header, then runs SimC with debug logging,
which prints every talent it adds from the string.
"""
import base64, os, re, subprocess, sys, tempfile

ROOT = os.path.dirname(os.path.abspath(__file__))
SIMC = os.path.join(ROOT, "simc", "build", "simc")

SPECS = {
    71: ("warrior", "arms"), 72: ("warrior", "fury"), 73: ("warrior", "protection"),
    65: ("paladin", "holy"), 66: ("paladin", "protection"), 70: ("paladin", "retribution"),
    253: ("hunter", "beast_mastery"), 254: ("hunter", "marksmanship"), 255: ("hunter", "survival"),
    259: ("rogue", "assassination"), 260: ("rogue", "outlaw"), 261: ("rogue", "subtlety"),
    256: ("priest", "discipline"), 257: ("priest", "holy"), 258: ("priest", "shadow"),
    250: ("deathknight", "blood"), 251: ("deathknight", "frost"), 252: ("deathknight", "unholy"),
    262: ("shaman", "elemental"), 263: ("shaman", "enhancement"), 264: ("shaman", "restoration"),
    62: ("mage", "arcane"), 63: ("mage", "fire"), 64: ("mage", "frost"),
    265: ("warlock", "affliction"), 266: ("warlock", "demonology"), 267: ("warlock", "destruction"),
    268: ("monk", "brewmaster"), 270: ("monk", "mistweaver"), 269: ("monk", "windwalker"),
    102: ("druid", "balance"), 103: ("druid", "feral"), 104: ("druid", "guardian"), 105: ("druid", "restoration"),
    577: ("demonhunter", "havoc"), 581: ("demonhunter", "vengeance"), 1480: ("demonhunter", "devourer"),
    1467: ("evoker", "devastation"), 1468: ("evoker", "preservation"), 1473: ("evoker", "augmentation"),
}
B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"


def spec_id(s):
    """Blizzard's export packs bits LSB-first, 6 per base64 char: 8-bit version, then 16-bit spec ID."""
    bits = []
    for ch in s[:5]:
        v = B64.index(ch)
        bits += [(v >> i) & 1 for i in range(6)]
    read = lambda off, n: sum(bits[off + i] << i for i in range(n))
    return read(8, 16)


def main():
    s = sys.argv[1].strip()
    if not re.fullmatch(r"[A-Za-z0-9+/]+", s):
        sys.exit("That doesn't look like a talent export string.")
    sid = spec_id(s)
    if sid not in SPECS:
        sys.exit(f"Unknown spec ID {sid} in the string header.")
    cls, spec = SPECS[sid]
    with tempfile.TemporaryDirectory() as td:
        log = os.path.join(td, "log.txt")
        cmd = [SIMC, f"{cls}=decode", f"spec={spec}", "level=90", f"talents={s}",
               "iterations=1", "max_time=1", "debug=1", "log=1", f"output={log}"]
        subprocess.run(cmd, cwd=os.path.join(ROOT, "simc"), capture_output=True, text=True)
        text = open(log, errors="ignore").read() if os.path.exists(log) else ""
    found = re.findall(r"adding (class|spec|hero|selection) talent (.+?) \(node=\d+ entry=\d+ rank=(\d+)/(\d+)\)", text)
    hero_tree = re.findall(r"activating sub tree (.+?) \(id=", text)
    if not found:
        sys.exit("SimC could not decode that string (it may be from an older patch).")
    print(f"Spec: {spec.replace('_', ' ').title()} {cls.replace('deathknight', 'Death Knight').replace('demonhunter', 'Demon Hunter').title()}")
    groups = {}
    if hero_tree:
        print(f"Hero tree: {hero_tree[0]}")
    for tree, name, r, mx in found:
        if tree == "selection":
            continue
        groups.setdefault(tree, []).append(f"{name}" + (f" {r}/{mx}" if mx != "1" else ""))
    for tree in ("class", "spec", "hero"):
        if tree in groups:
            print(f"\n{tree.title()} talents ({len(groups[tree])}):")
            for t in groups[tree]:
                print(f"  {t}")


if __name__ == "__main__":
    main()

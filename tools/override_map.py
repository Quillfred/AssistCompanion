#!/usr/bin/env python3
"""Build the game's button-override map ("casting button B actually casts A in some state") from
SimC's spell data: every Override Action Spell (aura 332) effect. Output: override_map.json,
{override_action: [base_action, ...]} with SimC-style snake_case names.

Usage: SIM_ROOT=<folder with simc/> python3 override_map.py
"""
import json, os, re, subprocess

ROOT = os.environ.get("SIM_ROOT", os.path.dirname(os.path.abspath(__file__)))
SIMC = os.path.join(ROOT, "simc", "build", "simc")


def snake(name):
    return re.sub(r"[^a-z0-9]+", "_", name.lower().replace("'", "")).strip("_")


def query(q):
    return subprocess.run([SIMC, f"spell_query={q}"], cwd=os.path.join(ROOT, "simc"),
                          capture_output=True, text=True).stdout


def main():
    text = query("effect.sub_type=332")
    pairs, need = set(), {}
    lines = text.splitlines()
    for i, ln in enumerate(lines):
        if "Override Action Spell" not in ln:
            continue
        m = re.search(r"Override Action Spell[^:]*: (.+?) overrides ([^|]+?)\s*(?:\||$)", ln)
        if m:
            pairs.add((m.group(1).strip(), m.group(2).strip()))
            continue
        block = " ".join(lines[i + 1:i + 4])
        base_val = re.search(r"Base Value: (\d+)", block)
        affected = re.search(r"Affected Spells: (.+?)(?:\s{2,}|$)", block)
        if base_val and affected and base_val.group(1) != "0":
            for name in re.findall(r"([A-Z][^,(]+?) \(\d+\)", affected.group(1)):
                need.setdefault(base_val.group(1), set()).add(name.strip())
    for sid, bases in need.items():
        m = re.search(r"^Name\s+: (.+?) \(id=", query(f"spell.id={sid}"), re.M)
        if m:
            for b in bases:
                pairs.add((m.group(1).strip(), b))
    out = {}
    for new, base in pairs:
        a, b = snake(new), snake(base)
        if a and b and a != b:
            out.setdefault(a, set()).add(b)
    out = {k: sorted(v) for k, v in sorted(out.items())}
    json.dump(out, open(os.path.join(ROOT, "override_map.json"), "w"), indent=1)
    print(f"{len(out)} override actions")


if __name__ == "__main__":
    main()

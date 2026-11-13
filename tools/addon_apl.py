#!/usr/bin/env python3
"""The highlight + Assist Companion's shipped rules for each finished spec, as a SimC action list.

Reuses each spec's rules sim (tools/*_rules_sim.py, dev_addon_sim.py) so the rules match what was simmed.
Used by talent_search.py's "addon" rotation. Augmentation has no rules sim (its value is its allies').
Usage: SIMC=<simc> python3 tools/addon_apl.py <spec>   (prints the action lines)
"""
import importlib, os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
SPECS = ("frost", "unholy", "blood", "devastation", "windwalker", "brewmaster")


def _mod(name):
    saved = sys.argv
    sys.argv = [name]  # the rules sims read an optional iteration count from argv
    try:
        return importlib.import_module(name)
    finally:
        sys.argv = saved


def actions(spec):
    if spec == "frost":
        return _mod("frost_rules_sim").apl((1, 1, 1))
    if spec == "blood":
        return _mod("blood_rules_sim").apl((1, 1, 1, 1, 1, 1))
    if spec == "devastation":
        return _mod("dev_addon_sim").apl("hl_addon")
    if spec == "windwalker":
        m = _mod("windwalker_rules_sim")
        return m.apl(m.FINAL)
    if spec == "brewmaster":
        m = _mod("brewmaster_rules_sim")
        return m.apl(m.RULES)
    if spec == "unholy":
        # 0.25.0 as shipped: Blightfall fix for both trees; Death Coil / Epidemic at 80+ runic power only in
        # place of the rune spenders and only for San'layn (Vampiric Strike talent).
        m = _mod("unholy_rules_sim")
        lines = m.apl((1, 0, 1))  # 0.27.13: + Festering Scythe uptime
        out = []
        for l in lines:
            a = l.split("=", 1)[1].lstrip("/") if l.startswith("actions+=") else None
            # the Festering Scythe uptime rule comes before the runic power rule in the addon: leave it alone
            if a and a.startswith(("scourge_strike", "festering_strike", "vampiric_strike", "festering_scythe")) \
                    and "festering_scythe_tt.remains" not in a:
                c = a.split(",if=", 1)[1].split(",")[0] if ",if=" in a else ""
                extra = f"&({c})" if c else ""
                out.append(f"actions+=/death_coil,if=talent.vampiric_strike&runic_power>=80&active_enemies<=3{extra}")
                out.append(f"actions+=/epidemic,if=talent.vampiric_strike&runic_power>=80&active_enemies>=4{extra}")
            out.append(l)
        return out
    raise SystemExit(f"no addon rules sim for {spec}")


if __name__ == "__main__":
    print("\n".join(actions(sys.argv[1])))

# Research tools

Scripts used to produce the numbers in `docs/FINDINGS.md`. They expect, next to this folder:

* `simc/`: a SimulationCraft checkout (`midnight` branch) built with `cmake -S simc -B simc/build -DBUILD_GUI=OFF -DSC_NO_NETWORKING=ON && ninja -C simc/build simc`
* `table_data.json`: per-spec results and talent strings written while building the rankings page (Blood scripts; set `SIM_ROOT` if it lives elsewhere)
* `nox/`: talent build data (`aoe_builds.json`, `candidate_builds.json`) gathered from Noxxic's talent pages

| Script | What it does |
|---|---|
| `run_sims.py` | Sims every spec with the optimal rotation and with Assisted Highlight. `TARGETS=5 BUILD=aoe` for AoE builds |
| `screen_ah_builds.py` | Finds each spec's best talent build when following the highlight (`TARGETS=1/5`) |
| `cleave3.py` | 3-target cleave: best build for each rotation, then full-precision sims |
| `decode_talents.py` | Lists the talents in an in-game export string: `python3 decode_talents.py <string>` |
| `blood_sims.py` | Blood: optimal vs highlight at 1/3/5 targets (casts, runic power waste, Bone Shield uptime, damage taken) |
| `blood_rules_sim.py` | Blood: the highlight alone vs with the addon's rules (SimC list), San'layn and Deathbringer, 1/3/5 targets, per-rule breakdown (`SIMC=<simc> python3 blood_rules_sim.py [iterations]`) |
| `frost_rules_sim.py` | Frost: the highlight alone vs with the addon's rules (SimC list), Deathbringer and Rider, 1/3/5 targets, per-rule breakdown |
| `unholy_rules_sim.py` | Unholy: the highlight alone vs with the addon's rules (SimC list), Rider and San'layn, 1/3/5 targets (`UNHOLY_RP=` threshold) |
| `addon_apl.py` | Each finished spec's shipped rules (highlight + Assist Companion) as a SimC action list, from its rules sim |
| `addon_talent_recheck.py` | Talent re-check: best build with the addon's rules per spec and fight (talent_search's `addon` rotation) |
| `dungeon_sims.py` | DungeonSlice for every rankings-page spec: optimal, highlight, and highlight + addon (rules in SimC's highlight structure) |
| `brewmaster_rules_sim.py` | Brewmaster: the highlight alone vs with the addon's rules (SimC list), Master of Harmony (and Shado-Pan with `BM_SHADOPAN=<talent string>`), 1/3/5 targets, each rule left out, energy pooling variants |
| `windwalker_rules_sim.py` | Windwalker: the highlight alone vs with the addon's rules (SimC list), Shado-Pan and Conduit, 1-5 targets (`WW_FIGHTS=1,2,3,4,5`), each rule alone and left out, candidate rules |
| `override_map.py` | Builds `override_map.json`: every "button B casts A in some state" pair from the game's Override Action Spell effects |
| `override_resim.py` | Re-sims the highlight with each override added after its base spell (SimC's base actions refuse to fire in override states, e.g. Chaos Strike during Metamorphosis) |
| `dev_addon_sim.py` | Devastation: highlight alone vs highlight + Assist Companion's rules (written as a SimC action list), Scalecommander and Flameshaper, 1/3/5 targets (`SIMC=<simc> python3 dev_addon_sim.py [iterations]`) |
| `talent_search.py` | Best build per rotation (`optimal` / `highlight` / `addon`) and target count: hill-climbs over choice-node swaps from given start builds (`SIMC=<simc> python3 talent_search.py devastation highlight 1 <build>...`). Point moves between nodes aren't searched (no tree connections in SimC's data) |
| `talent_db.py` | Talent / mastery / racial database from the game's data: writes `docs/talents/` (`SIMC=<simc> python3 talent_db.py <class>...`) |
| `triage.py` | Phase 1 triage: per spec and fight, where the highlight loses damage vs optimal and whether an addon could fix it. Writes `triage.json` and `TRIAGE.md` |

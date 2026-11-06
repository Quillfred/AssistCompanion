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
| `blood_rules_sim.py` | Blood: the highlight's own priority with the addon's corrections added, to measure what they're worth |
| `override_map.py` | Builds `override_map.json`: every "button B casts A in some state" pair from the game's Override Action Spell effects |
| `override_resim.py` | Re-sims the highlight with each override added after its base spell (SimC's base actions refuse to fire in override states, e.g. Chaos Strike during Metamorphosis) |
| `dev_addon_sim.py` | Devastation: highlight alone vs highlight + Assist Companion's rules (written as a SimC action list), Scalecommander and Flameshaper, 1/3/5 targets (`SIMC=<simc> python3 dev_addon_sim.py [iterations]`) |
| `talent_db.py` | Talent / mastery / racial database from the game's data: writes `docs/talents/` (`SIMC=<simc> python3 talent_db.py <class>...`) |
| `triage.py` | Phase 1 triage: per spec and fight, where the highlight loses damage vs optimal and whether an addon could fix it. Writes `triage.json` and `TRIAGE.md` |

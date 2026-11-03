# Research tools

Scripts used to produce the numbers in `docs/FINDINGS.md`. They expect, next to this folder:

* `simc/`: a SimulationCraft checkout (`midnight` branch) built with `cmake -S simc -B simc/build -DBUILD_GUI=OFF -DSC_NO_NETWORKING=ON && ninja -C simc/build simc`
* `nox/`: talent build data (`aoe_builds.json`, `candidate_builds.json`) gathered from Noxxic's talent pages

| Script | What it does |
|---|---|
| `run_sims.py` | Sims every spec with the optimal rotation and with Assisted Highlight. `TARGETS=5 BUILD=aoe` for AoE builds |
| `screen_ah_builds.py` | Finds each spec's best talent build when following the highlight (`TARGETS=1/5`) |
| `cleave3.py` | 3-target cleave: best build for each rotation, then full-precision sims |
| `decode_talents.py` | Lists the talents in an in-game export string: `python3 decode_talents.py <string>` |

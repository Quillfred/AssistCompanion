# Published pages

Copies of the research pages published on claude.ai (owner's other account), kept here so their
history is versioned with the data behind them. Open the `.html` files in a browser.

| File | Live page | Built from |
|---|---|---|
| `highlight-rankings.html` | [Assisted Highlight Rankings](https://claude.ai/artifact/Bsb4RK7eVZd2DGZSGoABSK) | `tools/run_sims.py`, `screen_ah_builds.py`, `cleave3.py`; button-override corrections from `tools/override_resim.py` (see `docs/TRIAGE.md`) |
| `gap-triage.html` | [Highlight Gap Triage](https://claude.ai/artifact/8XA1gJsvvMFchkKj3TqGzP) | `tools/triage.py` (`docs/TRIAGE.md`), plus in-game findings from `docs/FINDINGS.md` |

Last updated Nov 5, 2026:
* **Rankings:** the nine specs SimC couldn't play with button overrides (Devourer, Havoc, Shadow,
  Retribution, Affliction, Fury, Marksmanship, Survival, Guardian) show the re-simmed losses. In
  "Best for optimal rotation" mode those are estimates (same correction per fight).
* **Triage:** "What testing in game changed" section (enemy counts work with nameplates on; runic power is
  hidden but threshold icons work; Devastation's Azure Sweep gap is a SimC artifact), an
  "In Assist Companion" tag on covered specs, and the shortlist marked with what's done.

When a page changes, update the copy here in the same commit as the data or finding behind it.

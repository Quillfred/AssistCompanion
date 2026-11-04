# Next steps (hand-off)

Written at the end of a long working session so a fresh session can pick up without the old
conversation. Current addon version: **0.16.3** (0.13.0-beta1 on CurseForge) (see `AssistCompanion/AssistCompanion.toc`).

## Where things stand

* **Addon:** Blood, Frost and Unholy Death Knight. Next-cast icon (Assisted Highlight suggestion with
  keybind, GCD swipe, range/resource shading, gold border = correction, blue = opener step), opener bar,
  Blood low-health Death Strike icon, optional text alerts (off), saved debug log (`/ac debug`).
  Rules live in `AssistCompanion/Rules.lua`; display, tracking and commands in `Core.lua`.
* **Tests:** `lua5.1 tests/harness.lua AssistCompanion` (mocked WoW API, ~198 cases). CI runs them on push.
* **Research:** `docs/FINDINGS.md` (per-rule evidence), `docs/TRIAGE.md` (phase 1, all specs).
* **Rankings page** (claude.ai artifact, owner's account): sortable table of highlight vs optimal DPS per
  spec. **Out of date** for specs hit by the SimC button-override limitation (below).

**Minimap button (0.16.0):** `AssistCompanion/Minimap.lua`, no libraries (left-click options, shift-click debug log on/off (icon red while on),
ctrl-click clear the log, right-click lock/unlock,
drag around the minimap, square minimaps handled; `db.minimapButton`, `db.minimapAngle`, `/ac minimap`) plus the
addon compartment entry (`## AddonCompartmentFunc` in the TOC).

**Options menu (0.12.0):** `AssistCompanion/Options.lua`, a canvas panel in the game's Settings (Esc > Options >
AddOns, or `/ac`). The ability tree is built from `ns.specInfo` (class/spec list), `ns.rules` (each rule's `name`,
`desc`, `spell` icon) and `ns.specOptions` (spec settings), so a new spec shows up by adding it to `ns.specInfo`.
Rule toggles are now per spec (`db.disabled["250:raisedead"]`); old key-only toggles are migrated to every spec
with that key. `alwaysShow` became `showMode` ("always" / "target" / "combat"); `showWhenDead` is new.
Not yet seen in the live game: check the panel's layout, scrolling, and that checkboxes and +/- buttons respond.

## Plan (agreed order)

1. **Done in 0.11.0 for DKs + Devastation:** `ns.readyCooldowns` in `Rules.lua` (per spec: spell, base cooldown,
   optional `when`, `after` = rule key to slot in behind). Frost: Breath, Raise Dead. Blood: Vampiric Blood,
   Raise Dead. Devastation and Unholy: none (checked, see `docs/FINDINGS.md`). Adding a spec = one table
   entry, but non-DK specs also need Core.lua to read their own power (it only reads runic power
   and runes), an `ns.meleeSpell` range spell, and the TOC notes updated.
   Original plan text: **Cooldown-ready template, DKs + Devastation first.** Generalize Frost's Breath of Sindragosa rule
   (`Rules.lua`, rule `breath`, plus `ns.trackCooldowns`) into a data-driven template: per spec, a list of
   cooldowns the in-game highlight never suggests; show the icon when one is ready (cooldown read out of
   combat, timed from your own casts in combat, as Breath does since 0.7.2). DK: Breath of Sindragosa,
   Raise Dead, Vampiric Blood (Blood). Devastation: confirm the list from `docs/TRIAGE.md` and the
   highlight list (`simc/ActionPriorityLists/assisted_combat/evoker_devastation.simc`).
2. **Devastation deep dive** (Blood-style, see "How Blood was done"):
   * Azure Sweep never cast (34-45 casts optimal, 0 highlight). The re-sim with the Azure Strike -> Azure Sweep
     override did **not** change anything, so it's a real gap: check the highlight's Azure Strike rule
     conditions and SimC's `azure_sweep` buff/ready logic.
   * Essence waste 24% vs 8-12% optimal: "spend at cap" rule (essence is readable via UnitPower).
   * Pyre skipped at exactly 3 targets (">3" rule): needs an enemy count in combat (see open checks).
   * Disintegrate under-used at 1 target (86 vs 62 casts).
   * Empowered spells: the highlight never says which empower rank; consider showing the rank.
3. **Augmentation Evoker: done in 0.13.0** (rules `ebonmight`, `breatheons`, `prescience`; `ns.replacedBy` maps
   Deep Breath -> Breath of Eons; `ns.onCast` tracks Ebon Might's expiry; findings in `docs/FINDINGS.md`).
   Not measured (see "Measuring it" below). In-game checks: does the highlight return Deep Breath (357210) or
   Breath of Eons (403631)? Does `UNIT_SPELLCAST_SUCCEEDED` fire for empowered spells (Fire Breath, Upheaval)?
   Without it, the Ebon Might estimate runs short and the refresh shows early.
   **0.14.0:** empower rank badge on Fire Breath / Upheaval (`ns.empowerRank`, option `empowerRank`).
   **0.14.0 also:** Tip the Scales and Time Skip as cooldown-ready rules. The owner's debug log confirmed the
   in-game highlight never suggests them (nor Breath of Eons / Deep Breath), and that empowered spells do fire
   `UNIT_SPELLCAST_SUCCEEDED` (details in `docs/FINDINGS.md`).
   **0.14.1:** cooldown model for Augmentation (Time Skip, Temporal Burst from its tooltip, Clear Empower
   Cooldown reset, learned empower recovery factor; `ns.augCooldownLeft`, `ns.onTick`), rank 1 within 1.5s of
   Upheaval, `ebonfirst` rule. Status line: `em= emcd= up= x=`. From the owner's second log (`docs/FINDINGS.md`).
   **0.14.2:** speed-ups apply to the cooldown-ready rules too (Breath of Eons was held ~23s), and the Upheaval
   estimate reads only the button's spell (it was always 0). From the owner's third log.
   **0.14.3:** cooldown reads ignored in combat (empowers read "ready" right after the cast, so `up=` was
   always 0), and `ebonfirst` now holds empowers up to 6s for Ebon Might with an Eruption / Chrono Flames
   filler. From the owner's fourth log.
   **0.15.0:** Tip the Scales is a full rule (`ns.augTipRule`): cooldown from when its buff is used up, Chronoboon,
   and the `tipMacro` option (Icy Veins' cancel macro: with an empower ready within a GCD, else on cooldown via
   the macro; off = with Fire Breath as before). Rule notes (`alert.note`) show under the icon.
   **0.15.1:** Upheaval timed from the cast once cast (`up=` was still 0), Accretion modelled, macro note "macro x2",
   macro-mode cooldown from the press. Status: `upb=` `tip=`. From the owner's fifth log.
   **0.15.2:** "x2" after the keybind when the Tip the Scales macro should be pressed (macro option only).
   **0.15.3:** the real `up=0` cause (highlight still shows Upheaval right after the cast; learning now waits 3s),
   Tip the Scales learns a speed factor from early presses (`tx=`), `haste=` logged. `upb=396286` confirmed.
   **0.16.1:** cancelled empowers undone (`UNIT_SPELLCAST_EMPOWER_STOP`, `ns.onCastCancelled`); learned factors
   averaged, implausible readings dropped. `up=` confirmed counting down (seventh log). Haste is ~8% and hidden
   in combat, so it doesn't explain the Tip the Scales gap; `tx=` learning stays.
   **Open:** check the empower-cancel event reports `complete` readably in game (look for "empower cancelled" in
   the log after cancelling a Fire Breath).
   **Open:** the Ebon Might estimate runs at least 8s short in the owner's log, so the `ebonmight` refresh rule
   never fires. Next log: compare `em=` on the status lines with when the highlight asks for Ebon Might again
   (it only does once the buff is down and Ebon Might is off cooldown). Original notes:
   * **What exists online (checked Nov 2026):** no published optimal-vs-highlight comparison.
     Icy Veins' easy-mode guide calls the highlight "acceptable with no real loss of performance" (a judgment,
     not a sim): https://astro.k.icy-veins.com/wow/augmentation-evoker-pve-dps-easy-mode. Icy Veins' sim page
     notes Aug sims report raid DPS with large error (~300 DPS at 0.05% target error):
     https://www.icy-veins.com/wow/augmentation-evoker-pve-dps-simulations. Noxxic has an Aug Assisted
     Highlight rotation page and highlight build rankings (12.1.5; top single-target build Chronowarden) but no
     highlight-vs-full percentage: https://www.noxxic.com/wow/guide/augmentation-evoker/assisted-highlight
   * **Gaps from the game's highlight rules** (`simc/ActionPriorityLists/assisted_combat/evoker_augmentation.simc`):
     Breath of Eons never suggested (SimC cooldown list only); Ebon Might only re-applied after it drops
     (optimal refreshes below 40% duration); Prescience goes on the current target (optimal picks the best DPS,
     avoids tanks/healers/Augs); Fire Breath, Upheaval and Eruption aren't held for Ebon Might windows.
   * **Addon candidates:** Breath of Eons via the cooldown-ready template; Ebon Might "refresh soon" timed from
     your own casts (fixed duration, like Bone Shield); possibly a Prescience reminder. Prescience targeting can't
     be automated.
   * **Measuring it** needs SimC's raid-DPS setup with simulated allies (noisy, slow); decide if worth it.
4. **Cooldown template for the remaining specs**, a few classes per batch, push after each.
5. Optional: **update the rankings page** with the corrected losses from `simout_override/`.

The owner plays Frost/Unholy/Blood DK, Devastation and Augmentation Evoker, uses EllesmereUI bars, and
prefers: 48px icon, text alerts off, HIGH strata, icons always shown (not when dead).

## Key findings to keep in mind

* **SimC button-override limitation:** SimC's base actions refuse to fire in override states (Chaos Strike
  during Metamorphosis -> Annihilation, Raging Blow -> Crushing Blow, Consume -> Devour...), so its
  `use_blizzard_action_list=1` sims understate the highlight for those specs. `tools/override_map.py` builds
  all 162 pairs from game data; `tools/override_resim.py` re-sims with them. Corrected average losses:
  Devourer -55.7 -> -29.6, Havoc -34.6 -> -12.3, Shadow -27.3 -> -10.0, Ret -15.8 -> -8.6,
  Affliction -23.9 -> -17.9 (Fury +4.8 points, others ~unchanged).
* **SimC presses some cooldowns in its highlight sims** that the in-game highlight never suggests
  (its `actions.cooldowns` list and "Blizzard automation" lines). Real in-game losses for those specs are
  larger than the sims show (Frost DK: -1.6% in sim, about -20% following only the in-game highlight).
* **Midnight addon restrictions (12.1.5 API docs):** readable in combat: `C_AssistedCombat.GetNextCastSpell`,
  your own `UnitPower`, `C_Spell.GetOverrideSpell`, `C_Spell.IsSpellUsable`, `C_Spell.IsSpellInRange`,
  `C_ActionBar.*`, your own casts. Hidden: auras, cooldowns, charges, health, combat log, damage meter.
  Cooldown frames and `Texture:SetAlpha` accept hidden values (used for the GCD swipe and the low-health
  icon). `UnitPowerMax` can be hidden even out of combat (Blood uses a talent-based fallback).
* **Highlight data quirks:** Blood's Heart Strike is stored as Rune Strike (316239); Unholy's Blightfall
  rule loops Outbreak; many AoE rules use ">3" so exactly 3 targets plays as single target.

## Open in-game checks (owner to test, ideally with `/ac debug` and the saved log)

* Low-health Death Strike icon fades in below 50% health (curve covers 0-1 and 0-100 scales; unconfirmed).
* `enemies=` in the debug log during combat: if it's always `nil`, enemy counting is blocked and the
  3-target rules (Frost Frostscythe, Unholy 1-3 vs 4+, future Pyre) stay quiet.
* GCD swipe shows in combat (cooldown frames accepting hidden values).
* `rp=x/125` with Ossuary on Blood (or "(fb)" = fallback in use).
* Keybinds on EllesmereUI bars 9-10 (read from button text).

## How Blood was done (template for a deep dive)

1. `tools/blood_sims.py`: optimal vs highlight at 1/3/5 targets on each rotation's best build; compare
   casts, resource waste, buff uptimes, damage taken.
2. Read the highlight's rules from game data (`simc/engine/dbc/generated/assisted_combat.inc`, condition
   types in `simc/engine/dbc/data_enums.hh`, `AC_*`) and the optimal list.
3. Design corrections the addon can observe in combat.
4. `tools/blood_rules_sim.py`: sim the highlight's own list with the corrections added on top (strip the
   profile's own `actions` lines, see `override_resim.py`), to prove they help before building.
5. Implement in `Rules.lua`, add tests, bump version, push.

## Environment notes for a fresh session

* SimC must be rebuilt: clone `simulationcraft/simc` (midnight branch) and
  `cmake -S simc -B simc/build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_GUI=OFF -DSC_NO_NETWORKING=ON && ninja -C simc/build simc`
  (~20 min on 4 cores; give the build a long timeout). Put it next to the tools or set `SIM_ROOT`.
* Sim outputs from this session (`simout*/`, `table_data.json`, `nox/` talent builds, `override_map.json`)
  were in the old container's scratch space and may be gone; the tools regenerate them
  (`tools/README.md`). Talent build lists came from Noxxic's talent pages (`nox/aoe_builds.json`,
  `nox/candidate_builds.json`), scraped from `https://www.noxxic.com/wow/guide/<spec>/talent-builds`.
* Lua 5.1 for tests: `apt-get install -y lua5.1`.
* Commits end with the session's attribution lines. Push to the session's branch, then open a pull request
  into `main` and merge it once CI passes. The owner wants Claude to handle all pull requests and merges
  without asking.
* **CurseForge releases** (project 1783748, `## X-Curse-Project-ID` in the TOC): add the version's notes to
  `CHANGELOG.md`, bump `## Version:` in the TOC, merge, then start the release workflow
  (`-beta1` / `-alpha1` suffix = beta / alpha file). Claude sessions can't push tags (pushes are limited to the
  session branch), so trigger `release.yml` with `workflow_dispatch` (GitHub MCP `actions_run_trigger`, input
  `tag`, ref `main`); the job creates and pushes the tag itself. Pushing a `v*` tag by hand also works. `.github/workflows/release.yml` checks the tag matches the
  TOC, runs the tests, and runs the BigWigs packager (`.pkgmeta` ships only the `AssistCompanion` folder) to
  upload to CurseForge (`CF_API_KEY` repository secret) and attach the zip to a GitHub release.
* After every update to GitHub (each merge into `main`), send the owner a zip of the addon in the chat:
  the `AssistCompanion` folder from `main`, zipped with that folder at the top level, named
  `AssistCompanion-<version>.zip` (version from the TOC).

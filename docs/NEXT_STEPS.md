# Next steps (hand-off)

Written at the end of a long working session so a fresh session can pick up without the old
conversation. Current addon version: **0.27.12** (0.13.0-beta1 on CurseForge) (see `AssistCompanion/AssistCompanion.toc`).

## Where things stand

* **Addon:** Blood, Frost and Unholy Death Knight. Next-cast icon (Assisted Highlight suggestion with
  keybind, GCD swipe, range/resource shading, gold border = correction, blue = opener step), opener bar,
  Blood low-health Death Strike icon, optional text alerts (off), saved debug log (`/ac debug`).
  Rules live in `AssistCompanion/Rules.lua`; display, tracking and commands in `Core.lua`.
* **Tests:** `lua5.1 tests/harness.lua AssistCompanion` (mocked WoW API, ~198 cases). CI runs them on push.
* **Research:** `docs/FINDINGS.md` (per-rule evidence), `docs/HIDDEN_RESOURCES.md` (hidden resources playbook), `docs/TRIAGE.md` (phase 1, all specs), `docs/pages/` (copies of the published rankings and triage pages), `docs/talents/` (every class/spec/hero talent, mastery and racial from game data, flagged for what can affect the addon; `tools/talent_db.py`).
* **Rankings page** (claude.ai artifact, owner's account): sortable table of highlight vs optimal DPS per
  spec. Updated Nov 5, 2026 with the button-override corrections; a copy is in `docs/pages/`.

**Minimap button (0.16.0):** `AssistCompanion/Minimap.lua`, no libraries (left-click options, shift-click debug log on/off (icon red while on),
ctrl-click clear the log, right-click lock/unlock,
drag around the minimap, square minimaps handled; `db.minimapButton`, `db.minimapAngle`, `/ac minimap`) plus the
addon compartment entry (`## AddonCompartmentFunc` in the TOC). 0.16.5: never re-place it on clicks, and not at all
once another addon (e.g. a minimap button bar) has reparented it: the owner's button bar lost it on shift/ctrl-click.

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
2. **Devastation: first version in 0.20.0** (rules `essencecap`, `pyre3`, empower rank badge; findings in
   `docs/FINDINGS.md` "Devastation"). Not simmed (SimC build not allowed in that session). To check in game:
   the essence cap correction, Pyre at 3 targets (Flameshaper), the rank numbers, and that the icon shows Azure
   Sweep after Eternity Surge (status line: `es=` `fb=` ranks). Original notes:
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
   **0.16.4:** learned factors saved (`db.augLearned`), reset when Accretion / Chronoboon / Temporal Burst change,
   loaded only once the spellbook is ready. Eighth log clean (see FINDINGS). CurseForge beta on hold at the
   owner's request until everything is confirmed.
   **Confirmed (ninth log):** cancelled empowers are detected (`complete == false` is readable) and undone;
   learned factors are saved.
   **0.16.6:** Ebon Might estimate now includes mastery (aura duration, from the Timewalker tooltip) and average
   extension crits; replaying the first log lands within ~0.5s of the real drop. To confirm in game: `emdur=`
   should read ~1.14 and `crit=` ~21 out of combat, and `em=` should reach 0 about when the highlight asks for
   Ebon Might once it's off cooldown. CurseForge beta still on hold until the owner says everything is clear.
   **Done in 0.17.0 (owner approved):** talent effects on timing (corrected: Nozdormu Adept is -2s, not -4s):
   Tomorrow, Today (Time Skip +1s channel: ~27s of recovery instead of 18), Instability Matrix (empowers -0-6s
   own cooldown per cast, ~3s average), Interwoven Threads (all cooldowns -10%), Dream of Spring (Emerald
   Blossom extends Ebon Might 1s), Nozdormu Adept (Prescience cooldown -2s), Overlord (Breath of Eons casts
   Eruptions on up to 3 targets: invisible Ebon Might extensions and Accretion), Wingleader (Mass Eruption
   -1.5s Breath of Eons per target). The debug log lists them at each combat start (`talents:`). The owner
   uses Overlord.
   **Resolved in 0.16.6:** the Ebon Might estimate used to run ~8s short; mastery (aura duration) and average
   extension crits fixed it (replay within ~0.5s of the real drop). Original notes:
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
prefers: 48px icon, text alerts off, HIGH strata (now an option, `db.strata`, 0.17.1), icons always shown (not when dead).

## Key findings to keep in mind

* **Hidden resources playbook: `docs/HIDDEN_RESOURCES.md`.** What's readable in combat (runic power and energy
  hidden, chi and stagger readable...), how to probe a new spec in a debug log, and the fix for hidden values: curve-driven
  layers the game draws (`ns.powerIcon`, `ns.holdSpender`; Blood runic power, Brewmaster energy). Read it before a new spec.

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

* **Runic power is hidden** (confirmed 0.17.2-0.17.4: `rp=hidden`). 0.18.0 added a runic power icon; since 0.19.0 it's a
  layer over the next-cast icon (Core.lua `pf`, child of `nf`; Rules.lua `ns.powerIcon`) whose alpha comes from `UnitPowerPercent("player", 6, false, curve)`
  with a step curve at the rule's threshold. **To confirm in game on Unholy/Blood:** the status line's
  `rpicon=` reads `hidden` (the game returned a secret alpha: confirmed on Unholy, 0.18.0; and it lights up at the
  threshold: confirmed by the owner with `/ac rptest`, 0.18.1), a number, `error` (signature wrong;
  the log line says why), `no api`, or `waiting` (highlight not on a rune spender). If it errors, try the other
  argument orders or a StatusBar fed the secret value.
* **Enemy count: confirmed working** (0.17.3, Frost on 5 dummies with all nameplates shown: `enemies=5 inrange=5`
  in combat). The highlight switches to AoE by itself (Frostscythe / Glacial Advance / Howling Blast), so the
  3-target corrections are a safety net. Still to check: Unholy and Blood on a group.

* Low-health Death Strike icon fades in below 50% health (curve covers 0-1 and 0-100 scales; unconfirmed).
* `enemies=` in the debug log during combat: if it's always `nil`, enemy counting is blocked and the
  3-target rules (Frost Frostscythe, Unholy 1-3 vs 4+, future Pyre) stay quiet.
* GCD swipe shows in combat (cooldown frames accepting hidden values).
* `rp=x/125` with Ossuary on Blood (or "(fb)" = fallback in use).
* Keybinds on EllesmereUI bars 9-10 (read from button text).

## Class-by-class completion (owner's plan)

Evoker: done (0.21.6; Devastation and Augmentation tested in game, Devastation rules simmed). Death Knight audit in
progress: **Blood done** (0.21.7 audit: talent timings, opener, sim of all rules; 0.22–0.23: opener order fix, rank badge above the GCD swipe, Death Strike hold option; all confirmed in the owner's logs; `docs/FINDINGS.md` "Blood audit");
to confirm in a Blood debug log: Dancing Rune Weapon / Reaper's Mark / Consumption suggested by the highlight,
`bs=` resetting after Dancing Rune Weapon (Insatiable Blade), `vb=` growing with Death Strikes (Red Thirst).
**Frost done in 0.24.0** (Rider opener, Chosen of Frostbrood Breath window, rules sim; to confirm in game: the Rider opener). **Unholy done in 0.25.0** (runic power rule San'layn only, rune spenders only; opener unchanged). **Death Knight finished.** **Windwalker done in 0.26.0** (Zenith / Xuen / Celestial Conduit ready, Spinning Crane Kick at 3 and over Rising Sun Kick at 4+, Dance of Chi-Ji at 1 stack via the button glow, opener; `docs/FINDINGS.md` "Windwalker audit"; 0.26.3: Spinning Crane Kick over Rising Sun Kick at 4+ targets only with 4+ chi. 0.26.2: enemies counted within Fists of Fury range (8 yd). 0.26.1: charge counts no longer reset by SPELLS_CHANGED in combat (Zenith shown on cooldown); confirmed in the owner's Shado-Pan log: Dance of Chi-Ji glow (`glow=y`, readable spell ID), opener, chi readable; to confirm: `zen=` charges after the fix, Celestial Conduit shown after Xuen and which button casts it). **Windwalker finished (0.26.3, CurseForge v0.26.3-beta1).** **Brewmaster finished (0.27.7, CurseForge v0.27.7-beta1):** brews, Niuzao, Blackout Combo on 3+, energy for Keg Smash, opener; to confirm in a debug log: brew charge counts (`pb=` `cb=`) against the buttons, `keg=` showing Empty the Cellar, `combo=`. Owner preference: nothing goes to GitHub until a spec is finished in review; test zips in chat. Builds for testing: the rankings page's "Best for optimal rotation" builds. Mistweaver: looked at in 0.25.1–0.25.2 (spec support for debug logs); the highlight's damage rotation is fine and it never heals, so on hold (owner). Next class: owner's choice. Then the next class; healers
only Mistweaver and Discipline, last.

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

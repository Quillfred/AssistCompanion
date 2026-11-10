# Hidden resources: how to find them and work around them

WoW Midnight (12.x) hides many values from addons in combat as "secret values". An addon can hold a secret
value and pass it to certain UI functions, but it can't compare it, do maths with it or print it. This page
is the playbook from Blood (runic power) and Brewmaster (energy): how to find out what a spec can see, and
how to build a rule on a value the addon can't read. Use it for every new spec.

## What's been seen so far (owner's debug logs, 12.1.5)

| Value | Readable in combat? | Spec / log | Notes |
|---|---|---|---|
| Runic power (`UnitPower`, type 6) | **hidden** | Blood, Frost, Unholy | Max readable (`UnitPowerMax`) or from talents (`ns.powerMaxFallback`) |
| Runes (`UnitPower`, type 5) | reads 6 always (useless) | Blood | Count ready runes with `GetRuneCooldown(1..6)` |
| Energy (`UnitPower`, type 3) | **hidden, even out of combat** | Brewmaster (0.27.5 probe) | `UnitPowerMax` = 100 readable; `UnitPowerPercent` hidden |
| Energy regen (`GetPowerRegen`) | out of combat only | Brewmaster | 12.7/12.7 out of combat, hidden in combat |
| Chi (`UnitPower`, type 12) | **readable** | Windwalker (`rp=2/6`) | |
| Stagger (`UnitStagger`) | **readable** | Brewmaster (0.27.3 probe) | Level debuffs (124273-5) read nothing in combat |
| Health | hidden | Blood | `UnitHealthPercent` with a curve works (below) |
| Buffs / debuffs (`C_UnitAuras`) | hidden | all | Track from your own casts instead |
| Cooldowns / charges (`C_Spell.GetSpellCooldown` / `GetSpellCharges`) | hidden | all | Read out of combat, then count casts (`ns.chargeTrack`, `ns.readyCooldowns`) |
| Usable (`C_Spell.IsSpellUsable`, `C_ActionBar.IsUsableAction`) | readable in the Brewmaster log | Brewmaster | Only says "can afford the cost", not a custom threshold; earlier DK logs suggested it can be hidden |
| Proc glows (`SPELL_ACTIVATION_OVERLAY_GLOW_SHOW/HIDE`) | **readable** (spell ID in the event) | Windwalker, Brewmaster | Dance of Chi-Ji, Purifying Brew at high stagger |
| Button overrides (`C_Spell.GetOverrideSpell`) | readable | Unholy, Brewmaster | Blightfall, Empty the Cellar |
| Your own casts (`UNIT_SPELLCAST_SUCCEEDED`, `_FAILED`) | readable | all | The base for every timer and counter |

Don't assume: the same value can differ by spec or patch (energy was hidden even out of combat). Probe first.

## Step 1: probe it in a debug log

Before designing a rule, add a probe to the spec's `ns.debugStatus[spec]` (Rules.lua) so the owner's next
`/ac debug` log answers the question. Pattern (see `bmEnergyText` / `bmStaggerText` in Rules.lua):

* Call each candidate API in `pcall`; show a number, `y`/`n` for booleans, `hidden` when
  `issecretvalue(v)` is true, `nil`, or `?` when the API is missing or errors.
* Try every route: the resource by type and with no type, `UnitPowerPercent`, regen, the usable check for
  the spells that cost it (by spell and through the action button), and any related aura.
* Ask the owner to stand out of combat for a few seconds, then fight ~30 s, ideally running low on the
  resource. Out-of-combat and in-combat answers can differ.
* Add a harness test for the probe line (mock the API returning a number, `"SECRET"` with
  `issecretvalue`, and missing).

## Step 2: pick the approach

1. **Readable**: write a normal rule on `ctx.power` (set `ns.powerType[spec]`).
2. **Countable from your casts**: rebuild it yourself. Charges (`ns.chargeTrack`, with `ns.chargeShift`
   / `chargeRefill` / `chargeAdd` / `chargeEmpty` for casts that change them), runes (`GetRuneCooldown`),
   buff timers (`ctx.lastCast`), combo buffs (Brewmaster's Blackout Combo). Correct it from refused casts
   (`ns.onCastFailed` on `UNIT_SPELLCAST_FAILED`). Don't count a resource with refunds you can't see
   (Brewmaster energy: Keg Smash and Tiger Palm refund energy with talents).
3. **Hidden, but the rule is "at / below a threshold"**: let the game draw it. This is the fix for runic
   power (Blood, Unholy) and energy (Brewmaster), below.

## The fix: curve-driven layers (the game decides, the addon only displays)

`UnitPowerPercent(unit, powerType, predicted, curve)` and `UnitHealthPercent(unit, predicted, curve)` take
a `C_CurveUtil` curve and return the curve's value at the hidden percent, as a **secret** number. A
texture or frame accepts a secret number in `SetAlpha`. So a step curve (alpha 1 on one side of the
threshold, 0 on the other) makes a layer appear exactly when the hidden value crosses it, without the addon
ever knowing the value.

Core.lua has three ready-made mechanisms; a new spec usually only needs a table entry in Rules.lua:

| Mechanism | Rules.lua table | What it shows | Used by |
|---|---|---|---|
| Power layer (`updatePowerIcon`, `buildPowerCurve`: 1 at or above) | `ns.powerIcon[spec]` = `{ rule, spell, when, at }` | A spender over the next-cast icon when the resource is at or above `at` | Unholy Death Coil / Epidemic at 80+ runic power (San'layn), Blood Death Strike near cap |
| Hold layer (`updateHold`, `buildBelowCurve`: 1 below) | `ns.holdSpender[spec]` = `{ option, spell, when, at, instead, health }` | When the highlight asks for `spell`, cover it with `instead` while the resource is below `at`; optional `health` adds the spender back on top at low health (`UnitHealthPercent`) | Blood: hold runic power for Death Strike; Brewmaster: Keg Smash over a filler Tiger Palm below 65 energy (save energy) |
| Short tint (`shortOnResource`, `shortCurve`) | none (automatic) | A blue tint when you can't afford the suggested spell, from its cost (`C_Spell.GetSpellPowerCost`) and a curve at cost / max | All specs with hidden power |
| Health icon (`updateHealthIcon`) | `ns.healthIcon[spec]` | A separate icon fading in as health drops | Blood's low-health Death Strike |

Details that matter:

* **Curves cover both scales.** It's unclear whether the APIs evaluate on 0-1 or 0-100, so every curve has
  points for both (see `buildPowerCurve`, `buildBelowCurve`, `buildHealthCurve`). Keep that pattern.
* **The threshold is a fraction of max**: `at / powerMax`. Max must be known: `UnitPowerMax` when readable
  (energy: 100), else `ns.powerMaxFallback[spec]` from talents.
* **Readable conditions gate the layer** (`when`, the highlight's suggestion, the rule's on/off toggle,
  higher-priority corrections hide it). Only the hidden threshold goes to the game.
* **The addon can't confirm it visually**: the debug log only says the layer is on (`rpicon=hidden`,
  `hold=on:<spell>`), not whether the game drew it visible. Ask the owner to confirm in game (Blood:
  `/ac rptest` makes the runic power layer follow the resource out of combat for a visual check).
* **It can't drive decisions.** A secret value can only become an alpha. A rule that must *choose*
  between spells from the hidden value needs one layer per outcome stacked by priority (Blood's hold uses
  two: hold layer, then the low-health layer on top).
* **Sim the threshold first** (as for every rule): Brewmaster's 65 energy came from
  `tools/brewmaster_rules_sim.py` (`pool65` vs 90 / "90 or Keg Smash 3s+ away").
* **Tests**: the harness mocks `UnitPowerPercent` as `curve:Evaluate(state.rpPct)` and `UnitPower` returning
  `"SECRET"` with `issecretvalue`; check the layer's `shown`, `alpha` (1 / 0) and icon. See the "Hold:" and
  "Brewmaster: ... energy" tests in `tests/harness.lua`.

## Checklist for a new spec

1. Note the spec's resources and what its rules need (thresholds, counts, buffs).
2. Add probes for anything not in the table above; ship them in the first test build.
3. From the owner's log: readable -> normal rule; countable -> track from casts; hidden threshold ->
   `ns.powerIcon` / `ns.holdSpender`.
4. Sim the threshold, add tests, and add the result to the table above.

# Findings behind the rules

All numbers come from SimulationCraft (`midnight` branch, commit `36e21fe`, game data 12.1.5.70688), Patchwerk, 300 s fights. "Assisted Highlight" means SimC's `use_blizzard_action_list=1`, which plays the in-game highlight's priority as read from the game's `AssistedCombatStep` / `AssistedCombatRule` data.

## Blood

Optimal rotation (its best build per fight) vs the in-game highlight (its best build), then the highlight with the addon's three corrections added on top (`tools/blood_rules_sim.py`; the plain highlight list reproduces the `use_blizzard_action_list=1` numbers within 0.4%):

| | 1 target | 3 targets | 5 targets |
|---|---|---|---|
| Highlight: DPS vs optimal | −13.1% | −19.3% | −18.5% |
| Highlight: damage taken / s (optimal) | 12.9M (9.6M) | 10.6M (4.5M) | 7.8M (2.6M) |
| **+ corrections: DPS vs optimal** | **−4.8%** | **−10.7%** | **−9.4%** |
| **+ corrections: damage taken / s** | **11.7M** | **6.3M** | **4.2M** |

What drives the gap (highlight vs optimal casts):

* **Blood Boil:** 7–13 vs 52–56. The highlight only casts it to apply Blood Plague with 2 charges. Blood Boil has 2 charges and a fixed 7.5s recharge (not hasted), so the addon counts charges from your casts.
* **Bone Shield:** ~90% uptime vs 100%. The highlight refreshes on stack count (≤6) only, so the 30s duration can run out. Death's Caress: 0 casts vs 5–7. The addon times the 30s from your Marrowrend / Death's Caress casts.
* **Runic power waste:** 7.5% (3 targets) and 12% (5 targets) vs 0%. The highlight's Death Strike rules are "≤50% health" or "≥80 runic power".

Max runic power for Blood is 125 with Ossuary (219786 grants +10; confirmed in game and in SimC's Blood profile), 115 without. `UnitPowerMax` can return a hidden value even out of combat, so the addon falls back to that, and never assumes less than the most runic power it has seen. The Death Strike rule therefore fires at 105 with Ossuary.

The highlight's data stores Heart Strike as Rune Strike (316239), which Heart Strike replaces. SimC's highlight sims also press Vampiric Blood on cooldown, which the in-game highlight never suggests; no defensive is ever suggested.

Health is secret in combat, but `UnitHealthPercent(unit, usePredicted, curve)` evaluates a curve on it, and `Texture:SetAlpha` accepts secret values from addon code, so the low-health icon's alpha is set by the game. The docs don't say whether the health input is 0–1 or 0–100, so the curve covers both.

## Unholy: Outbreak / Blightfall loop

The highlight's second rule for Unholy (game data step 15428) is "cast Outbreak (77575) while you have aura 1271975 (Blightfall)". That aura's only effect is to turn Dark Transformation into Blightfall (1271967) until you press it. Outbreak doesn't remove the aura, so the rule stays true and the highlight suggests Outbreak after every press.

Single target, a build with Blightfall:

| | Optimal rotation | Assisted Highlight |
|---|---|---|
| DPS | 253,765 | 151,418 (−40%) |
| Outbreak casts | 1 | 25.6 |
| Putrefy casts | 22.6 | 0 |

## Unholy: runic power overcapping

The highlight only suggests Epidemic or Death Coil with Sudden Doom or Forbidden Knowledge active, or Death Coil as a fallback below the rune spenders. Between procs, runic power caps.

5 targets, the highlight's best AoE build:

| | Optimal rotation | Assisted Highlight |
|---|---|---|
| Runic power wasted | ~0% | 15% |
| Epidemic casts | 111 | 87 |
| Death Coil casts | 0 | 12.5 |

At exactly 4 targets neither proc rule applies (Death Coil is `<= 3` targets, Epidemic `> 4`).

## Frost: Breath of Sindragosa never suggested

In the game data, Breath is marked as automation only, so it never shows in the highlight. SimC presses it anyway in its highlight sims.

| Following | 1 target | 3 targets | 5 targets |
|---|---|---|---|
| Highlight + manual Breath, trinkets, potion, racials | −0.9% | −2.4% | −1.0% |
| Only the in-game highlight | −20.0% | −19.7% | −18.7% |

With trinkets, potion and racials removed, Breath (plus Raise Dead) alone is worth about 7.3% in single target. The rest of the gap is on-use trinkets, potion and racials, which the highlight never suggests for any spec.

## Frost: 3-target Frostscythe

The highlight's Frostscythe and Glacial Advance rules require more than 3 enemies. At exactly 3: 0 Frostscythe casts (optimal: 128), about −2.4%.

## Frost: Empower Rune Weapon while out of range

| Priority | Ability | Conditions in game data |
|---|---|---|
| 1 | Pillar of Frost | Frost Strike ready and target within 8 yards |
| 2 | Frostwyrm's Fury | target within 30 yards and Pillar active |
| 3 | Empower Rune Weapon | runic power ≤ 80 and Killing Machine ≤ 1. No range check |

Out of range before a pull, Pillar fails its range check, so the highlight suggests Empower Rune Weapon. The optimal opener presses Empower Rune Weapon and Pillar together once in melee.

## Openers (SimC optimal single target, default builds; identical across seeds)

* **Frost:** Empower Rune Weapon, Pillar of Frost, Reaper's Mark, Breath of Sindragosa, Obliterate, Frostwyrm's Fury, Obliterate ×3
* **Unholy:** Raise Dead (pre-pull), Outbreak, Festering Strike ×2, Army of the Dead, Dark Transformation, Putrefy, Death Coil, Putrefy, Death Coil

## Addon API notes (12.1.5)

From Blizzard's generated API documentation:

* Readable in combat: `C_Spell.IsSpellUsable` (usable / not enough resources), `C_AssistedCombat.GetNextCastSpell`, `UnitPower("player", …)`, `C_Spell.GetOverrideSpell`, `C_Spell.IsSpellInRange`, `C_ActionBar.FindSpellActionButtons`, `C_ActionBar.IsActionInRange`, your own `UNIT_SPELLCAST_SUCCEEDED`.
* Secret in combat unless a spell is exempt: auras (`C_UnitAuras`), cooldowns (`C_Spell.GetSpellCooldown`).
* The addon treats any secret value as "unknown" and stays quiet rather than guessing.
* Cooldown frames may display secret values: `Cooldown:SetCooldown` and `Cooldown:SetCooldownFromDurationObject` accept them, and `C_Spell.GetSpellCooldownDuration` returns a duration object. The GCD swipe (spell 61304) passes these straight through without reading them.

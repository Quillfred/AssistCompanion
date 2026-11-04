# Assisted Highlight gap triage (phase 1)

Optimal rotation (its best build) vs the in-game Assisted Highlight (its best build), from saved SimC
results (patch 12.1.5, Patchwerk 300s). **Est. recoverable** = average loss across 1/3/5 targets x the
share of the damage gap in abilities an addon could plausibly correct (heuristic, an upper-end guide).
Where SimC's highlight sim couldn't press button overrides (e.g. Chaos Strike -> Annihilation in
Metamorphosis), losses are corrected by re-simming with the overrides added; SimC's figure is in brackets.

| Spec | Loss 1T | 3T | 5T | Est. recoverable | Patterns |
|---|--:|--:|--:|--:|---|
| Devastation Evoker | -32.3% | -28.5% | -29.9% | **11.1%** | resource cap |
| Devourer DH | -8.1% (SimC -46.2%) | -34.3% (SimC -56.3%) | -46.5% (SimC -64.7%) | **9.8%** | resource cap; never suggested in game: the_hunt, voidblade; missing from highlight; SimC button-override artifact (highlight +26.1 pts better than SimC showed) |
| Elemental Shaman | -4.6% | -42.8% | -24.5% | **9.2%** | 3-target hole; never suggested in game: ascendance; missing from highlight |
| Brewmaster Monk (tank) | -24.9% | -32.3% | -47.4% | **8.3%** | missing from highlight |
| Blood DK (tank) | -12.8% | -19.6% | -18.3% | **6.1%** | resource cap; never suggested in game: raise_dead, vampiric_blood |
| Windwalker Monk | -5.6% | -32.3% | -21.2% | **6.0%** | resource cap; 3-target hole; never suggested in game: celestial_conduit, invoke_xuen_the_white_tiger, touch_of_karma, zenith |
| Marksmanship Hunter | -8.8% (SimC -12.6%) | -23.9% | -9.0% | **5.4%** | resource cap; 3-target hole; never suggested in game: trueshot; missing from highlight; SimC button-override artifact (highlight +1.6 pts better than SimC showed) |
| Arms Warrior | -2.2% | -21.1% | -21.3% | **5.3%** | - |
| Vengeance DH (tank) | -30.3% | -30.7% | -32.1% | **5.1%** | never suggested in game: metamorphosis; missing from highlight |
| Outlaw Rogue | -13.9% | -15.8% | -13.5% | **5.0%** | never suggested in game: adrenaline_rush, keep_it_rolling, vanish |
| Balance Druid | -6.6% | -24.3% | -12.1% | **4.6%** | 3-target hole; never suggested in game: celestial_alignment |
| Feral Druid | -3.4% | -27.4% | -13.8% | **3.9%** | 3-target hole; never suggested in game: berserk; missing from highlight |
| Enhancement Shaman | -18.7% | -23.0% | -19.0% | **3.5%** | 3-target hole; never suggested in game: ascendance, doom_winds |
| Protection Paladin (tank) | -17.7% | -15.6% | -15.3% | **3.4%** | never suggested in game: avenging_wrath |
| Destruction Warlock | -1.5% | -31.9% | -5.3% | **3.1%** | resource cap; 3-target hole; never suggested in game: summon_infernal |
| Fury Warrior | -12.6% (SimC -23.8%) | -30.1% | -16.6% (SimC -20.7%) | **2.9%** | 3-target hole; never suggested in game: avatar, recklessness; SimC button-override artifact (highlight +4.8 pts better than SimC showed) |
| Subtlety Rogue | -8.2% | -8.9% | -6.7% | **2.6%** | resource cap; never suggested in game: shadow_blades |
| Arcane Mage | -6.3% | -10.6% | -11.4% | **2.3%** | resource cap; never suggested in game: arcane_surge |
| Affliction Warlock | -3.8% (SimC -12.3%) | -24.6% (SimC -29.7%) | -25.3% (SimC -29.8%) | **2.2%** | never suggested in game: summon_darkglare; SimC button-override artifact (highlight +6.0 pts better than SimC showed) |
| Survival Hunter | -2.4% (SimC -5.0%) | -2.5% | -2.8% | **1.9%** | never suggested in game: takedown; missing from highlight |
| Demonology Warlock | -4.0% | -20.2% | -16.6% | **1.9%** | never suggested in game: summon_demonic_tyrant; missing from highlight |
| Beast Mastery Hunter | -3.0% | -22.0% | -5.8% | **1.8%** | 3-target hole; missing from highlight |
| Frost Mage | -3.8% | -8.8% | -10.0% | **1.8%** | resource cap |
| Guardian Druid (tank) | -9.2% (SimC -11.2%) | -15.8% | -20.1% | **1.7%** | resource cap; never suggested in game: berserk; missing from highlight; SimC button-override artifact (highlight +1.2 pts better than SimC showed) |
| Protection Warrior (tank) | -5.4% | -3.6% | -3.1% | **1.7%** | never suggested in game: avatar, demoralizing_shout, ignore_pain, shield_block, shield_charge, shield_wall |
| Assassination Rogue | -5.7% | -9.3% | -13.9% | **1.6%** | never suggested in game: deathmark, vanish |
| Unholy DK | -10.7% | -7.6% | -9.3% | **1.5%** | resource cap |
| Fire Mage | -5.2% | -10.5% | -2.3% | **1.1%** | 3-target hole; never suggested in game: combustion |
| Frost DK | -0.7% | -3.9% | -1.0% | **0.7%** | never suggested in game: breath_of_sindragosa, raise_dead |
| Retribution Paladin | 0.5% (SimC -6.6%) | -13.7% (SimC -23.1%) | -12.5% (SimC -17.6%) | **0.7%** | never suggested in game: avenging_wrath; SimC button-override artifact (highlight +7.2 pts better than SimC showed) |
| Shadow Priest | -2.0% (SimC -22.5%) | -12.1% (SimC -29.9%) | -16.0% (SimC -29.4%) | **0.6%** | never suggested in game: power_infusion; SimC button-override artifact (highlight +17.2 pts better than SimC showed) |
| Havoc DH | -11.4% (SimC -41.3%) | -13.9% (SimC -32.4%) | -11.5% (SimC -30.1%) | **0.1%** | resource cap; never suggested in game: felblade, metamorphosis, the_hunt, vengeful_retreat; SimC button-override artifact (highlight +22.3 pts better than SimC showed) |

Labels: **not-suggested** (missing from the in-game highlight), **simc-only** (never suggested in
game; SimC presses it in highlight sims), **threshold** (resource/charge/range rules), **target-count**
(enemy-count rules), **proc-gated** (needs hidden buffs, not fixable), **indirect** (procs, DoTs, pets).

## Devastation Evoker

**1 target:** -32.3% loss, 40% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| disintegrate | 14.0% | 86.0 / 61.9 | threshold |
| azure_sweep | 11.0% | 34.2 / 0 | override-unresolved |
| bombardments | 3.9% | 150.5 / 87.0 | indirect |
| unbound_flame | 1.9% | 7.0 / 0 | override-unresolved |
| fire_breath | 1.0% | 16.4 / 14.4 | threshold |
| deep_breath | 0.7% | 11.7 / 11.7 | target-count |

Resource waste (opt -> hl): mana 57.3% -> 61.9%, essence 8.5% -> 24.0%

Buff uptime (opt -> hl): azure_sweep 87.0% -> 0%, hover 84.7% -> 0%, burnout 82.7% -> 28.7%, unbound_flame 47.7% -> 0%

**3 targets:** -28.5% loss, 34% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| pyre | 13.3% | 38.4 / 0 | target-count |
| azure_sweep | 11.6% | 38.2 / 0 | override-unresolved |
| disintegrate | 2.3% | 53.1 / 60.9 | threshold |
| living_flame | 1.4% | 18.4 / 10.7 | threshold |
| deep_breath | 1.0% | 14.2 / 13.5 | target-count |
| fire_breath | 0.9% | 16.2 / 14.7 | threshold |

Resource waste (opt -> hl): mana 53.7% -> 66.9%, essence 12.3% -> 24.5%

Buff uptime (opt -> hl): azure_sweep 80.4% -> 0%, hover 74.3% -> 0%, burnout 82.8% -> 58.6%, iridescence_blue 38.2% -> 19.4%

**5 targets:** -29.9% loss, 36% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| azure_sweep | 13.6% | 44.6 / 0 | override-unresolved |
| pyre | 11.0% | 53.2 / 35.4 | target-count |
| disintegrate | 7.1% | 40.5 / 30.9 | threshold |
| deep_breath | 1.5% | 15.9 / 14.6 | target-count |
| bombardments | 0.7% | 129.0 / 93.2 | indirect |
| fire_breath | 0.7% | 18.2 / 15.6 | threshold |

Resource waste (opt -> hl): mana 54.7% -> 67.6%, essence 10.0% -> 24.6%

Buff uptime (opt -> hl): hover 78.3% -> 0%, azure_sweep 69.0% -> 0%, burnout 94.7% -> 76.1%, charged_blast 71.0% -> 57.9%

## Devourer DH
*Never suggested by the in-game highlight (SimC presses these in its highlight sims, so real losses are larger):* the_hunt, voidblade

**1 target:** -8.1% (SimC -46.2%) loss, 24% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| cull | 25.3% | 42.1 / 0 | button-override |
| devour | 10.9% | 51.2 / 0 | button-override |
| voidsurge | 8.4% | 0 / 0 | indirect |
| reapers_toll | 7.6% | 19.2 / 0 | not-suggested |
| burning_blades | 4.3% | 0 / 0 | indirect |
| pierce_the_veil | 3.7% | 11.5 / 0 | not-suggested |

Resource waste (opt -> hl): fury 23.3% -> 34.3%

Buff uptime (opt -> hl): demonsurge_demonic_intensity 60.0% -> 0%, demonsurge_demonsurge 60.0% -> 0%, voidsurge 40.1% -> 0%, metamorphosis 60.0% -> 30.2%

**3 targets:** -34.3% (SimC -56.3%) loss, 31% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| eradicate | 28.0% | 38.1 / 0 | button-override |
| collapsing_star | 12.6% | 13.1 / 0 | not-suggested |
| voidsurge | 7.5% | 0 / 0 | indirect |
| the_hunt_dot | 5.5% | 0 / 0 | indirect |
| void_ray | 5.3% | 38.5 / 39.8 | threshold |
| reapers_toll | 5.1% | 26.5 / 0 | not-suggested |

Resource waste (opt -> hl): fury 19.6% -> 35.3%

Buff uptime (opt -> hl): student_of_suffering 72.3% -> 0%, demonsurge_demonic_intensity 60.3% -> 0%, demonsurge_demonsurge 60.3% -> 0%, impending_apocalypse 46.7% -> 0%

**5 targets:** -46.5% (SimC -64.7%) loss, 36% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| eradicate | 28.9% | 34.4 / 0 | button-override |
| collapsing_star | 16.0% | 15.0 / 0 | not-suggested |
| reapers_toll | 9.7% | 24.9 / 0 | not-suggested |
| voidsurge | 7.0% | 0 / 0 | indirect |
| the_hunt_dot | 6.9% | 0 / 0 | indirect |
| burning_blades | 4.0% | 0 / 0 | indirect |

Resource waste (opt -> hl): fury 23.7% -> 36.1%

Buff uptime (opt -> hl): demonsurge_demonic_intensity 62.1% -> 0%, demonsurge_demonsurge 62.1% -> 0%, impending_apocalypse 49.7% -> 0%, emptiness 61.3% -> 24.0%

## Elemental Shaman
*Never suggested by the in-game highlight (SimC presses these in its highlight sims, so real losses are larger):* ascendance

**1 target:** -4.6% loss, 14% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| elemental_blast | 2.4% | 41.3 / 38.4 | override-unresolved |
| pet:primal_fire_elemental | 1.6% | 0 / 0 | indirect |
| earthen_rage | 1.3% | 144.7 / 0 | indirect |

**3 targets:** -42.8% loss, 33% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| pet:ancestor | 25.3% | 0 / 0 | indirect |
| earthquake | 18.9% | 53.6 / 0 | target-count |
| chain_lightning | 18.1% | 127.7 / 0 | target-count |
| voltaic_blaze | 14.7% | 37.8 / 0 | not-suggested |
| flame_shock | 4.9% | 119.1 / 9.0 | target-count |

Buff uptime (opt -> hl): call_of_the_ancestors 76.7% -> 0%, purging_flames 45.0% -> 0%, lava_surge 28.2% -> 5.8%

**5 targets:** -24.5% loss, 52% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| voltaic_blaze | 14.8% | 37.8 / 0 | not-suggested |
| flame_shock | 6.6% | 198.7 / 15.0 | target-count |
| pet:ancestor | 6.5% | 0 / 0 | indirect |
| pet:primal_storm_elemental | 3.4% | 0 / 0 | indirect |
| lava_burst | 2.8% | 35.1 / 0 | threshold |
| earthquake | 2.6% | 86.8 / 84.6 | target-count |

Buff uptime (opt -> hl): call_lightning 84.8% -> 0%, purging_flames 45.7% -> 0%, storm_elemental 26.2% -> 0%, wind_gust 24.8% -> 0%

## Brewmaster Monk (tank)

**1 target:** -24.9% loss, 25% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| aspect_of_harmony_damage | 15.1% | 138.8 / 0 | indirect |
| keg_smash | 8.4% | 58.1 / 13.3 | threshold |
| tiger_palm | 7.0% | 73.4 / 126.8 | target-count |
| breath_of_fire | 2.8% | 56.9 / 27.1 | threshold |
| special_delivery | 1.9% | 62.9 / 0 | indirect |
| chi_burst_damage | 1.1% | 9.9 / 9.7 | indirect |

Buff uptime (opt -> hl): pretense_of_instability 94.3% -> 0%, aspect_of_harmony_accumulator 87.9% -> 0%, balanced_stratagem_magic 74.7% -> 0%, light_stagger_stagger 74.0% -> 2.7%

**3 targets:** -32.3% loss, 23% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| tiger_palm | 20.7% | 75.3 / 101.5 | target-count |
| aspect_of_harmony_damage | 13.5% | 400.6 / 0 | indirect |
| keg_smash | 6.7% | 55.4 / 28.2 | threshold |
| special_delivery | 3.0% | 63.8 / 0 | indirect |
| breath_of_fire | 2.0% | 54.7 / 38.0 | threshold |
| chi_burst_damage | 1.7% | 9.9 / 9.8 | indirect |

Buff uptime (opt -> hl): pretense_of_instability 93.9% -> 0%, aspect_of_harmony_accumulator 87.6% -> 0%, balanced_stratagem_magic 74.2% -> 0%, harmonic_surge 62.3% -> 0%

**5 targets:** -47.4% loss, 24% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| tiger_palm | 32.5% | 75.1 / 0 | target-count |
| aspect_of_harmony_damage | 12.4% | 626.2 / 0 | indirect |
| keg_smash | 7.9% | 55.2 / 20.1 | threshold |
| blackout_kick | 6.6% | 72.3 / 32.8 | proc-gated |
| special_delivery | 3.8% | 64.4 / 0 | indirect |
| breath_of_fire | 2.6% | 54.4 / 33.5 | threshold |

Buff uptime (opt -> hl): pretense_of_instability 93.8% -> 0%, aspect_of_harmony_accumulator 87.5% -> 0%, balanced_stratagem_magic 73.8% -> 0%, light_stagger_stagger 75.4% -> 11.0%

## Blood DK (tank)
*Never suggested by the in-game highlight (SimC presses these in its highlight sims, so real losses are larger):* raise_dead, vampiric_blood

**1 target:** -12.8% loss, 44% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| death_strike | 10.6% | 91.8 / 82.1 | threshold |
| heart_strike | 7.7% | 144.8 / 114.9 | threshold |
| pet:dance_of_midnight | 3.6% | 0 / 0 | indirect |
| dancing_rune_weapon | 2.3% | 3.7 / 3.7 | threshold |
| pet:everlasting_bond | 2.3% | 0 / 0 | indirect |
| blood_boil | 2.1% | 52.9 / 13.4 | threshold |

Buff uptime (opt -> hl): essence_of_the_blood_queen 98.1% -> 0%, transfusion 82.9% -> 0%, bloodsoaked_ground 81.8% -> 0%, visceral_strength 72.8% -> 0%

**3 targets:** -19.6% loss, 36% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| death_strike | 8.2% | 104.4 / 95.4 | threshold |
| blood_boil | 4.1% | 51.5 / 7.4 | threshold |
| blood_boil_boiling_point | 3.1% | 50.3 / 13.0 | indirect |
| pet:dance_of_midnight | 2.3% | 0 / 0 | indirect |
| sanguinary_burst | 1.6% | 3.7 / 0 | indirect |
| pet:everlasting_bond | 1.1% | 0 / 0 | indirect |

Resource waste (opt -> hl): runic_power 0.0% -> 7.5%

Buff uptime (opt -> hl): boiling_point_echo 47.3% -> 13.0%, hemostasis 42.9% -> 11.5%, visceral_strength 72.7% -> 43.0%, relentless_riders_strength 32.3% -> 19.1%

**5 targets:** -18.3% loss, 31% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| death_strike | 6.5% | 112.2 / 107.5 | threshold |
| blood_boil | 5.9% | 55.8 / 6.8 | threshold |
| blood_boil_boiling_point | 5.6% | 74.4 / 22.3 | indirect |
| pet:dance_of_midnight | 2.3% | 0 / 0 | indirect |
| sanguinary_burst | 2.2% | 3.7 / 0 | indirect |
| marrowrend | 1.1% | 10.1 / 10.7 | proc-gated |

Resource waste (opt -> hl): runic_power 0.0% -> 12.0%

Buff uptime (opt -> hl): boiling_point_echo 68.5% -> 22.2%, visceral_strength 72.8% -> 42.3%, hemostasis 45.5% -> 15.4%, relentless_riders_strength 33.3% -> 20.5%

## Windwalker Monk
*Never suggested by the in-game highlight (SimC presses these in its highlight sims, so real losses are larger):* celestial_conduit, invoke_xuen_the_white_tiger, touch_of_karma, zenith

**1 target:** -5.6% loss, 34% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| spinning_crane_kick | 3.6% | 18.9 / 6.5 | target-count |
| rushing_wind_kick | 3.2% | 14.5 / 9.8 | override-unresolved |
| fists_of_fury | 1.9% | 31.5 / 29.9 | threshold |
| flurry_strikes | 0.5% | 0 / 0 | indirect |

Resource waste (opt -> hl): chi 2.7% -> 6.3%

**3 targets:** -32.3% loss, 30% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| spinning_crane_kick | 40.8% | 73.2 / 5.2 | target-count |
| zenith | 2.2% | 4.7 / 5.3 | simc-only |
| empowered_tiger_lightning | 1.8% | 53.8 / 0 | indirect |
| whirling_dragon_punch | 1.6% | 12.1 / 8.6 | proc-gated |
| flurry_of_xuen | 1.1% | 178.1 / 0 | indirect |
| pet:xuen_the_white_tiger | 0.9% | 0 / 0 | indirect |

Resource waste (opt -> hl): chi 0.3% -> 15.1%

Buff uptime (opt -> hl): celestial_conduit 68.5% -> 0%, strength_of_the_black_ox 40.2% -> 0%, combo_breaker 44.4% -> 15.7%, courage_of_the_white_tiger 28.7% -> 0%

**5 targets:** -21.2% loss, 30% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| spinning_crane_kick | 25.1% | 70.6 / 51.6 | target-count |
| zenith | 1.8% | 4.7 / 6.5 | simc-only |
| empowered_tiger_lightning | 1.8% | 89.6 / 0 | indirect |
| whirling_dragon_punch | 1.5% | 12.0 / 8.6 | proc-gated |
| fists_of_fury | 0.7% | 36.4 / 32.4 | threshold |
| strength_of_the_black_ox_damage_celestial | 0.6% | 15.7 / 0 | indirect |

Resource waste (opt -> hl): chi 0.3% -> 8.6%

Buff uptime (opt -> hl): celestial_conduit 68.5% -> 0%, strength_of_the_black_ox 41.3% -> 0%, courage_of_the_white_tiger 28.5% -> 0%, combo_breaker 45.8% -> 17.7%

## Marksmanship Hunter
*Never suggested by the in-game highlight (SimC presses these in its highlight sims, so real losses are larger):* trueshot

**1 target:** -8.8% (SimC -12.6%) loss, 58% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| arcane_shot | 4.4% | 64.5 / 34.7 | threshold |
| moonlight_chakram | 4.3% | 2.8 / 0 | not-suggested |
| aimed_shot | 2.9% | 50.4 / 53.2 | threshold |
| lunar_storm | 1.5% | 0 / 0 | indirect |
| master_marksman | 1.4% | 376.0 / 362.8 | indirect |
| blood_fletching | 0.6% | 0 / 0 | indirect |

Resource waste (opt -> hl): focus 15.3% -> 37.9%

**3 targets:** -23.9% loss, 35% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| multishot | 9.9% | 83.5 / 0 | target-count |
| lunar_storm | 8.0% | 0 / 0 | indirect |
| aimed_shot | 7.6% | 49.8 / 46.1 | threshold |
| rapid_fire | 7.2% | 24.3 / 23.9 | threshold |
| sanctified_armaments | 3.7% | 0 / 0 | indirect |
| blood_fletching | 2.5% | 0 / 0 | indirect |

Resource waste (opt -> hl): focus 7.7% -> 38.6%

Buff uptime (opt -> hl): stargazer 98.7% -> 0%, trick_shots 88.3% -> 53.4%, moonlight_chakram 14.1% -> 0%

**5 targets:** -9.0% loss, 35% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| lunar_storm | 3.0% | 0 / 0 | indirect |
| aimed_shot | 1.7% | 49.8 / 48.8 | threshold |
| rapid_fire | 1.4% | 24.3 / 24.2 | threshold |
| moonlight_chakram | 1.2% | 2.7 / 0 | not-suggested |
| blood_fletching | 0.7% | 0 / 0 | indirect |
| multishot | 0.7% | 83.4 / 80.3 | target-count |

Resource waste (opt -> hl): focus 7.7% -> 12.0%

## Arms Warrior

**1 target:** -2.2% loss, 52% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| bladestorm | 1.1% | 10.4 / 10.8 | threshold |
| execute | 1.0% | 72.2 / 69.9 | threshold |
| cleave | 0.7% | 13.9 / 0 | target-count |

**3 targets:** -21.1% loss, 33% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| cleave | 24.1% | 81.4 / 0 | target-count |
| overpower | 3.8% | 51.9 / 34.9 | threshold |
| bladestorm | 2.7% | 13.0 / 10.5 | threshold |
| slayers_strike | 2.2% | 103.5 / 66.3 | indirect |
| execute | 1.3% | 62.3 / 64.5 | threshold |
| rend_dot | 1.1% | 270.8 / 73.4 | indirect |

Buff uptime (opt -> hl): collateral_damage 80.9% -> 0%, executioners_precision 54.5% -> 39.0%

**5 targets:** -21.3% loss, 36% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| cleave | 21.2% | 81.2 / 12.7 | target-count |
| execute | 3.4% | 63.7 / 57.0 | threshold |
| bladestorm | 2.7% | 13.4 / 11.0 | threshold |
| overpower | 1.9% | 51.1 / 41.3 | threshold |
| slayers_strike | 1.5% | 109.0 / 75.1 | indirect |
| rend_dot | 0.6% | 432.9 / 113.8 | indirect |

Buff uptime (opt -> hl): executioners_precision 55.1% -> 37.1%

## Vengeance DH (tank)
*Never suggested by the in-game highlight (SimC presses these in its highlight sims, so real losses are larger):* metamorphosis

**1 target:** -30.3% loss, 18% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| voidfall_meteor | 11.0% | 69.7 / 43.4 | indirect |
| spirit_bomb | 5.3% | 27.1 / 17.0 | proc-gated |
| immolation_aura | 4.4% | 28.4 / 0 | target-count |
| catastrophe | 4.3% | 0 / 0 | indirect |
| fiery_brand | 2.5% | 7.6 / 0 | not-suggested |
| sigil_of_flame | 1.3% | 10.3 / 8.7 | proc-gated |

Buff uptime (opt -> hl): demon_spikes 91.5% -> 0%, immolation_aura 85.7% -> 0%, fiery_brand 29.8% -> 0%

**3 targets:** -30.7% loss, 15% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| voidfall_meteor | 12.5% | 71.2 / 49.4 | indirect |
| spirit_bomb | 4.9% | 28.1 / 20.1 | proc-gated |
| catastrophe | 4.6% | 0 / 0 | indirect |
| sigil_of_flame | 3.0% | 10.3 / 1.0 | proc-gated |
| fiery_brand | 2.6% | 7.6 / 0 | not-suggested |
| immolation_aura | 1.3% | 28.3 / 30.7 | target-count |

Buff uptime (opt -> hl): demon_spikes 95.7% -> 0%, fiery_brand 34.7% -> 0%, soul_fragments 68.8% -> 56.4%

**5 targets:** -32.1% loss, 16% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| voidfall_meteor | 12.7% | 72.0 / 50.5 | indirect |
| catastrophe | 4.5% | 0 / 0 | indirect |
| spirit_bomb | 4.3% | 28.7 / 22.0 | proc-gated |
| sigil_of_flame | 3.9% | 10.3 / 1.0 | proc-gated |
| fiery_brand | 2.8% | 7.6 / 0 | not-suggested |
| immolation_aura | 1.7% | 28.3 / 30.7 | target-count |

Buff uptime (opt -> hl): demon_spikes 95.8% -> 0%, fiery_brand 39.5% -> 0%, soul_fragments 70.8% -> 57.7%

## Outlaw Rogue
*Never suggested by the in-game highlight (SimC presses these in its highlight sims, so real losses are larger):* adrenaline_rush, keep_it_rolling, vanish

**1 target:** -13.9% loss, 38% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| killing_spree | 9.1% | 11.4 / 9.7 | target-count |
| between_the_eyes | 3.7% | 69.1 / 65.0 | threshold |
| pistol_shot | 1.3% | 54.0 / 46.7 | threshold |
| sinister_strike | 0.8% | 99.4 / 85.5 | threshold |
| coup_de_grace | 0.7% | 14.7 / 14.4 | override-unresolved |
| unseen_blade | 0.6% | 70.7 / 65.9 | indirect |

Buff uptime (opt -> hl): triple_threat 47.7% -> 24.9%, opportunity 59.9% -> 41.7%, loaded_dice 61.2% -> 48.9%

**3 targets:** -15.8% loss, 33% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| blade_flurry | 9.1% | 44.1 / 28.9 | target-count |
| killing_spree | 4.7% | 10.9 / 9.2 | target-count |
| between_the_eyes | 1.7% | 65.4 / 62.5 | threshold |

Buff uptime (opt -> hl): opportunity 65.7% -> 40.4%, triple_threat 49.0% -> 25.2%, fazed 41.6% -> 23.1%, loaded_dice 58.8% -> 46.1%

**5 targets:** -13.5% loss, 35% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| blade_flurry | 11.8% | 45.4 / 40.5 | target-count |
| killing_spree | 3.0% | 11.3 / 10.2 | target-count |
| between_the_eyes | 1.3% | 68.6 / 65.6 | threshold |
| pistol_shot | 0.9% | 35.0 / 28.2 | threshold |
| sinister_strike | 0.6% | 66.6 / 53.1 | threshold |

Buff uptime (opt -> hl): triple_threat 48.8% -> 22.7%, loaded_dice 60.9% -> 43.4%, opportunity 57.7% -> 44.4%

## Balance Druid
*Never suggested by the in-game highlight (SimC presses these in its highlight sims, so real losses are larger):* celestial_alignment

**1 target:** -6.6% loss, 22% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| starsurge | 2.7% | 84.0 / 85.0 | target-count |
| fury_of_elune | 1.7% | 6.7 / 5.3 | threshold |
| astral_smolder | 1.4% | 482.7 / 412.8 | indirect |
| sunseeker_mushroom | 1.2% | 9.2 / 0 | indirect |
| shooting_stars | 1.0% | 0 / 0 | indirect |
| sundered_firmament | 0.5% | 9.0 / 8.0 | indirect |

**3 targets:** -24.3% loss, 30% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| starfall | 25.1% | 86.9 / 0 | target-count |
| starfire | 4.1% | 93.7 / 78.0 | target-count |
| shooting_stars | 3.1% | 0 / 0 | indirect |
| fury_of_elune | 2.9% | 13.6 / 6.9 | threshold |
| moonfire | 2.7% | 5.8 / 13.6 | threshold |
| astral_smolder | 1.9% | 1394.8 / 1061.9 | indirect |

Buff uptime (opt -> hl): orbit_breaker 96.7% -> 0%, starfall 96.1% -> 0%, dreamstate 33.2% -> 0%, fury_of_elune 35.7% -> 18.2%

**5 targets:** -12.1% loss, 41% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| moonfire | 10.9% | 7.1 / 0.3 | threshold |
| starfire | 8.4% | 91.1 / 86.7 | target-count |
| fury_of_elune | 4.7% | 13.6 / 5.3 | threshold |
| starfall | 4.7% | 90.9 / 85.9 | target-count |
| astral_smolder | 1.5% | 2172.7 / 2041.0 | indirect |
| starsurge_cascade | 1.5% | 33.1 / 0 | indirect |

Buff uptime (opt -> hl): fury_of_elune 35.7% -> 14.0%

## Feral Druid
*Never suggested by the in-game highlight (SimC presses these in its highlight sims, so real losses are larger):* berserk

**1 target:** -3.4% loss, 26% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| bloodseeker_vines | 10.4% | 59.2 / 0 | indirect |
| lunar_inspiration | 5.3% | 18.9 / 0 | threshold |
| rake | 4.7% | 28.0 / 33.5 | threshold |
| rip | 4.7% | 16.1 / 12.0 | proc-gated |
| feral_frenzy | 1.5% | 10.0 / 9.2 | threshold |

Buff uptime (opt -> hl): strategic_infusion 20.7% -> 0%

**3 targets:** -27.4% loss, 29% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| primal_wrath | 27.3% | 35.5 / 0 | target-count |
| bloodseeker_vines | 13.9% | 101.4 / 0 | indirect |
| convoke_the_spirits | 6.4% | 2.9 / 0 | proc-gated |
| swipe_cat | 5.7% | 110.6 / 0 | not-suggested |
| rake | 3.2% | 44.6 / 36.6 | threshold |
| frantic_frenzy | 1.1% | 7.0 / 6.3 | threshold |

Buff uptime (opt -> hl): root_network 98.9% -> 0%, berserk_cat 23.7% -> 0%, strategic_infusion 20.3% -> 0%

**5 targets:** -13.8% loss, 21% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| bloodseeker_vines | 15.3% | 129.6 / 0 | indirect |
| primal_wrath | 9.9% | 35.5 / 22.7 | target-count |
| rake | 7.3% | 66.0 / 23.2 | threshold |
| convoke_the_spirits | 5.4% | 2.9 / 0 | proc-gated |
| frantic_frenzy | 1.2% | 7.0 / 6.3 | threshold |

Buff uptime (opt -> hl): root_network 99.0% -> 0%, berserk_cat 23.7% -> 0%, strategic_infusion 20.3% -> 0%, clearcasting_cat 51.1% -> 39.7%

## Enhancement Shaman
*Never suggested by the in-game highlight (SimC presses these in its highlight sims, so real losses are larger):* ascendance, doom_winds

**1 target:** -18.7% loss, 14% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| crash_lightning | 2.9% | 55.9 / 50.9 | threshold |
| main_hand | 2.8% | 236.2 / 0 | indirect |
| thorims_invocation | 2.7% | 0 / 0 | indirect |
| windfury_attack | 1.7% | 682.8 / 378.5 | indirect |
| offhand | 1.4% | 236.3 / 0 | indirect |
| fire_nova | 1.4% | 8.3 / 7.0 | override-unresolved |

Buff uptime (opt -> hl): storm_swell 43.9% -> 0%

**3 targets:** -23.0% loss, 17% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| chain_lightning | 7.4% | 42.2 / 0 | target-count |
| thorims_invocation | 5.9% | 0 / 0 | indirect |
| lightning_rod | 2.7% | 817.8 / 796.7 | indirect |
| crash_lightning | 1.9% | 58.7 / 53.4 | threshold |
| main_hand | 1.4% | 240.0 / 0 | indirect |
| fire_nova | 1.4% | 8.3 / 6.9 | override-unresolved |

**5 targets:** -19.0% loss, 21% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| tempest | 6.2% | 17.1 / 0 | override-unresolved |
| thorims_invocation | 3.8% | 0 / 0 | indirect |
| lightning_rod | 2.7% | 1269.9 / 1240.2 | indirect |
| crash_lightning | 2.1% | 61.2 / 56.9 | threshold |
| fire_nova | 1.7% | 8.4 / 6.7 | override-unresolved |
| arc_discharge | 1.0% | 0 / 0 | indirect |

Buff uptime (opt -> hl): storm_swell 47.3% -> 0%, arc_discharge 13.6% -> 3.6%

## Protection Paladin (tank)
*Never suggested by the in-game highlight (SimC presses these in its highlight sims, so real losses are larger):* avenging_wrath

**1 target:** -17.7% loss, 19% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| shield_of_the_righteous | 6.0% | 89.4 / 102.5 | proc-gated |
| hammer_of_wrath | 5.4% | 54.2 / 38.0 | override-unresolved |
| avengers_shield | 1.9% | 45.5 / 43.4 | threshold |
| lesser_weapon_proc_damage | 1.4% | 76.1 / 55.9 | indirect |
| consecration | 1.4% | 26.8 / 19.8 | threshold |
| sacred_weapon_proc_damage | 1.3% | 35.2 / 26.1 | indirect |

Buff uptime (opt -> hl): holy_bulwark 38.1% -> 14.0%, masterwork_bulwark 23.7% -> 0%, fake_solidarity_bulwark 35.4% -> 13.9%, masterwork_weapon 39.9% -> 19.0%

**3 targets:** -15.6% loss, 22% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| hammer_of_wrath | 5.9% | 51.3 / 36.7 | override-unresolved |
| shield_of_the_righteous | 4.2% | 128.8 / 117.7 | proc-gated |
| consecration | 2.0% | 31.2 / 23.5 | threshold |
| sacred_weapon_proc_damage | 1.6% | 30.7 / 17.9 | indirect |
| avengers_shield | 1.2% | 42.3 / 37.6 | threshold |
| lesser_weapon_proc_damage | 0.9% | 77.9 / 56.0 | indirect |

Buff uptime (opt -> hl): afterimage 99.7% -> 0%, fake_solidarity_bulwark 30.1% -> 0%, holy_bulwark 30.1% -> 0%, holy_bulwark_absorb 28.2% -> 0%

**5 targets:** -15.3% loss, 22% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| shield_of_the_righteous | 4.9% | 129.4 / 118.1 | proc-gated |
| hammer_of_wrath | 4.9% | 52.4 / 37.1 | override-unresolved |
| sacred_weapon_proc_damage | 1.9% | 30.6 / 18.0 | indirect |
| consecration | 1.5% | 31.3 / 23.4 | threshold |
| avengers_shield | 1.5% | 43.2 / 38.1 | threshold |
| refining_fire | 0.9% | 0 / 0 | indirect |

Buff uptime (opt -> hl): afterimage 99.7% -> 0%, fake_solidarity_bulwark 30.2% -> 0%, holy_bulwark 30.2% -> 0%, masterwork_bulwark 29.7% -> 0%

## Destruction Warlock
*Never suggested by the in-game highlight (SimC presses these in its highlight sims, so real losses are larger):* summon_infernal

**1 target:** -1.5% loss, 0% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| blackened_soul | 1.6% | 0 / 0 | indirect |

**3 targets:** -31.9% loss, 28% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| rain_of_fire | 14.0% | 56.2 / 0 | target-count |
| shadowburn | 11.4% | 52.7 / 0 | target-count |
| diabolic_oculi | 7.2% | 0 / 0 | indirect |
| ruination | 6.2% | 7.5 / 0 | override-unresolved |
| chaos_bolt | 5.8% | 23.9 / 0 | target-count |
| soul_fire | 4.4% | 6.6 / 0 | threshold |

Resource waste (opt -> hl): soul_shard 0.2% -> 99.4%

Buff uptime (opt -> hl): demonic_oculi 82.8% -> 0%, minds_eyes 72.7% -> 0%, diabolic_ritual_overlord 30.5% -> 0%, diabolic_ritual_mother_of_chaos 29.7% -> 0%

**5 targets:** -5.3% loss, 9% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| diabolic_oculi | 7.1% | 0 / 0 | indirect |
| ruination | 6.9% | 7.4 / 0 | override-unresolved |
| immolate_direct | 4.2% | 0 / 0 | indirect |
| pet:overlord | 2.8% | 0 / 0 | indirect |
| pet:mother_of_chaos | 2.6% | 0 / 0 | indirect |
| pet:pit_lord | 2.6% | 0 / 0 | indirect |

Buff uptime (opt -> hl): demonic_oculi 85.5% -> 0%, minds_eyes 73.0% -> 0%, rain_of_chaos 36.2% -> 0%, diabolic_ritual_overlord 31.4% -> 0%

## Fury Warrior
*Never suggested by the in-game highlight (SimC presses these in its highlight sims, so real losses are larger):* avatar, recklessness

**1 target:** -12.6% (SimC -23.8%) loss, 12% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| crushing_blow | 16.8% | 70.6 / 0 | button-override |
| rampage | 5.3% | 146.6 / 111.9 | threshold |
| slayers_strike | 3.1% | 59.3 / 44.9 | indirect |
| bladestorm | 2.8% | 8.4 / 8.0 | proc-gated |
| auto_attack_mh | 1.7% | 259.3 / 227.3 | indirect |
| bloodbath_dot | 1.1% | 31.8 / 12.1 | indirect |

Buff uptime (opt -> hl): fury_mid2_4pc_crit 51.3% -> 14.2%, surge_of_adrenaline 58.4% -> 24.7%, recklessness 63.9% -> 43.8%

**3 targets:** -30.1% loss, 17% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| thunder_blast | 16.9% | 42.7 / 0 | button-override |
| bloodbath | 11.1% | 40.3 / 0 | button-override |
| thunder_clap | 10.7% | 52.0 / 0 | target-count |
| rampage | 7.0% | 103.0 / 109.9 | threshold |
| bloodthirst | 4.7% | 45.0 / 47.0 | threshold |
| crushing_blow | 4.4% | 13.5 / 0 | button-override |

Buff uptime (opt -> hl): scent_of_blood 82.7% -> 0%, avatar 70.3% -> 0%, whirlwind 91.9% -> 50.8%, sudden_death 42.9% -> 14.8%

**5 targets:** -16.6% (SimC -20.7%) loss, 11% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| thunder_blast | 17.4% | 42.7 / 0 | button-override |
| thunder_clap | 11.2% | 52.0 / 0 | target-count |
| bloodbath | 11.0% | 40.2 / 0 | button-override |
| crushing_blow | 4.3% | 13.4 / 0 | button-override |
| bloodbath_dot | 3.7% | 201.2 / 13.5 | indirect |
| bloodthirst | 3.6% | 45.0 / 41.1 | threshold |

Buff uptime (opt -> hl): bloodborne 98.3% -> 0%, scent_of_blood 83.0% -> 0%, avatar 70.3% -> 0%, sudden_death 42.6% -> 16.2%

## Subtlety Rogue
*Never suggested by the in-game highlight (SimC presses these in its highlight sims, so real losses are larger):* shadow_blades

**1 target:** -8.2% loss, 53% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| eviscerate | 6.3% | 130.5 / 142.2 | threshold |
| backstab | 4.5% | 84.4 / 0 | threshold |
| secret_technique | 1.6% | 12.6 / 14.9 | proc-gated |
| goremaws_bite | 1.4% | 6.6 / 7.0 | threshold |
| shadow_blades | 1.4% | 3.6 / 3.7 | simc-only |
| lingering_shadow | 0.9% | 354.3 / 404.4 | indirect |

Resource waste (opt -> hl): energy 17.0% -> 20.0%

Buff uptime (opt -> hl): momentum_of_despair 24.3% -> 0%

**3 targets:** -8.9% loss, 32% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| eviscerate | 12.4% | 43.1 / 0 | threshold |
| deathstalkers_mark | 7.5% | 128.1 / 0 | indirect |
| shuriken_storm | 5.4% | 130.6 / 120.3 | target-count |
| lingering_shadow | 3.9% | 1094.1 / 1404.3 | indirect |
| singular_focus | 1.9% | 1236.5 / 0 | indirect |
| shadow_blades | 1.3% | 3.6 / 3.7 | simc-only |

Buff uptime (opt -> hl): unshakeable_drive 99.7% -> 0%, momentum_of_despair 98.9% -> 0%, lingering_darkness 32.7% -> 0%, lingering_darkness_dark_brew 32.7% -> 0%

**5 targets:** -6.7% loss, 11% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| secret_technique | 7.1% | 17.2 / 15.9 | proc-gated |
| shadow_blades | 1.0% | 3.6 / 3.7 | simc-only |
| nimble_flurry | 0.9% | 1061.0 / 1030.6 | indirect |

Resource waste (opt -> hl): energy 8.9% -> 12.9%

Buff uptime (opt -> hl): cold_blood 39.0% -> 29.0%

## Arcane Mage
*Never suggested by the in-game highlight (SimC presses these in its highlight sims, so real losses are larger):* arcane_surge

**1 target:** -6.3% loss, 20% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| arcane_splinter | 9.2% | 970.4 / 0 | indirect |
| prismatic_bolt | 6.6% | 25.4 / 15.9 | override-unresolved |
| arcane_barrage | 4.2% | 65.1 / 60.3 | threshold |
| touch_of_the_magi | 1.8% | 6.9 / 7.0 | proc-gated |
| arcane_assault | 0.6% | 214.7 / 0 | indirect |

Resource waste (opt -> hl): mana 25.3% -> 35.0%

Buff uptime (opt -> hl): arcane_salvo 96.3% -> 76.2%

**3 targets:** -10.6% loss, 30% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| prismatic_bolt | 6.6% | 26.5 / 17.2 | override-unresolved |
| arcane_missiles | 1.9% | 77.2 / 73.5 | target-count |
| arcane_barrage | 1.8% | 67.2 / 63.2 | threshold |
| touch_of_the_magi | 1.2% | 7.0 / 7.0 | proc-gated |
| meteorite | 0.6% | 429.0 / 399.2 | indirect |

Buff uptime (opt -> hl): clearcasting 58.9% -> 47.7%

**5 targets:** -11.4% loss, 23% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| arcane_splinter | 12.7% | 1760.3 / 0 | indirect |
| arcane_orb | 9.8% | 40.3 / 1.9 | target-count |
| prismatic_bolt | 6.8% | 29.1 / 17.3 | override-unresolved |
| arcane_barrage | 6.1% | 74.5 / 63.9 | threshold |
| touch_of_the_magi | 1.5% | 6.9 / 7.0 | proc-gated |

Buff uptime (opt -> hl): clearcasting 78.2% -> 47.7%, arcane_salvo 97.8% -> 71.7%

## Affliction Warlock
*Never suggested by the in-game highlight (SimC presses these in its highlight sims, so real losses are larger):* summon_darkglare

**1 target:** -3.8% (SimC -12.3%) loss, 14% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| malefic_grasp | 7.8% | 18.8 / 0 | button-override |
| unstable_affliction | 3.0% | 99.6 / 97.1 | threshold |
| blackened_soul | 1.2% | 0 / 0 | indirect |
| shadowbolt_volley | 0.7% | 0 / 0 | indirect |

Buff uptime (opt -> hl): shard_instability 34.6% -> 8.4%

**3 targets:** -24.6% (SimC -29.7%) loss, 12% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| seed_of_corruption | 19.1% | 107.6 / 0 | target-count |
| corruption_direct | 9.1% | 0 / 0 | indirect |
| demonic_soul | 7.0% | 0 / 0 | indirect |
| malefic_grasp | 3.9% | 17.1 / 0 | button-override |
| soul_anathema | 3.8% | 0 / 0 | indirect |
| wicked_reaping | 3.3% | 0 / 0 | indirect |

Buff uptime (opt -> hl): nightfall 57.3% -> 27.9%, succulent_soul 29.2% -> 0%, manifested_demonic_soul 17.8% -> 0%

**5 targets:** -25.3% (SimC -29.8%) loss, 12% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| seed_of_corruption | 22.6% | 105.6 / 1.0 | target-count |
| agony | 12.9% | 47.7 / 17.2 | proc-gated |
| wither_direct | 12.0% | 0 / 0 | indirect |
| blackened_soul | 4.9% | 0 / 0 | indirect |
| pet:darkglare | 2.6% | 0 / 0 | indirect |
| malefic_grasp | 2.0% | 14.8 / 0 | button-override |

Buff uptime (opt -> hl): malevolence 56.3% -> 0%

## Survival Hunter
*Never suggested by the in-game highlight (SimC presses these in its highlight sims, so real losses are larger):* takedown

**1 target:** -2.4% (SimC -5.0%) loss, 100% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| moonlight_chakram | 4.8% | 3.6 / 0 | not-suggested |

**3 targets:** -2.5% loss, 39% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| wildfire_bomb | 12.7% | 49.0 / 39.3 | threshold |
| lunar_storm | 8.6% | 0 / 0 | indirect |
| boomstick | 2.8% | 13.0 / 11.2 | target-count |
| moonlight_chakram | 2.3% | 3.7 / 0 | not-suggested |
| sanctified_armaments | 1.6% | 0 / 0 | indirect |

Buff uptime (opt -> hl): stargazer 100.0% -> 0%, tip_of_the_spear 80.1% -> 65.9%

**5 targets:** -2.8% loss, 73% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| moonlight_chakram | 1.6% | 3.6 / 0 | not-suggested |
| wildfire_bomb | 1.5% | 48.8 / 46.8 | threshold |
| boomstick | 0.6% | 16.5 / 16.0 | target-count |

Buff uptime (opt -> hl): tip_of_the_spear 84.0% -> 67.1%

## Demonology Warlock
*Never suggested by the in-game highlight (SimC presses these in its highlight sims, so real losses are larger):* summon_demonic_tyrant

**1 target:** -4.0% loss, 6% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| pet:demonic_tyrant | 7.3% | 0 / 0 | indirect |
| pet:grimoire_imp_lord | 4.1% | 0 / 0 | indirect |
| diabolic_oculi | 3.9% | 0 / 0 | indirect |
| infernal_bolt | 3.4% | 8.4 / 0 | override-unresolved |
| pet:dreadstalker | 3.4% | 0 / 0 | indirect |
| ruination | 2.4% | 8.4 / 0 | override-unresolved |

Buff uptime (opt -> hl): minds_eyes 77.4% -> 0%, demonic_oculi 63.1% -> 0%, abyssal_dominion 33.3% -> 0%, diabolic_ritual_overlord 28.3% -> 0%

**3 targets:** -20.2% loss, 12% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| pet:wild_imp | 13.5% | 0 / 0 | indirect |
| implosion | 2.4% | 19.0 / 0 | not-suggested |
| pet:demonic_tyrant | 2.0% | 0 / 0 | indirect |
| pet:grimoire_imp_lord | 1.9% | 0 / 0 | indirect |
| pet:antoran_jailer | 0.5% | 0 / 0 | indirect |

Buff uptime (opt -> hl): grimoire_imp_lord 19.3% -> 0%, demonic_core 46.2% -> 30.1%

**5 targets:** -16.6% loss, 18% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| pet:wild_imp | 9.3% | 0 / 0 | indirect |
| implosion | 3.0% | 18.9 / 0 | not-suggested |
| pet:demonic_tyrant | 2.2% | 0 / 0 | indirect |
| pet:grimoire_imp_lord | 1.3% | 0 / 0 | indirect |
| pet:antoran_jailer | 0.5% | 0 / 0 | indirect |
| pet:lady_sacrolash | 0.5% | 0 / 0 | indirect |

Buff uptime (opt -> hl): grimoire_imp_lord 19.3% -> 0%, demonic_core 46.2% -> 30.1%

## Beast Mastery Hunter

**1 target:** -3.0% loss, 75% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| barbed_shot | 1.7% | 65.4 / 61.5 | threshold |
| cobra_shot | 1.0% | 94.4 / 92.6 | not-suggested |

**3 targets:** -22.0% loss, 14% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| pet:animal_companion | 9.5% | 0 / 0 | indirect |
| pet:duck | 8.9% | 0 / 0 | indirect |
| pet:natures_ally_pet | 8.8% | 0 / 0 | indirect |
| barbed_shot | 5.9% | 59.1 / 44.9 | threshold |
| cobra_cleave | 4.5% | 0 / 0 | indirect |
| boar_charge | 4.3% | 0 / 0 | indirect |

Buff uptime (opt -> hl): bear_summon 100.0% -> 0%, howl_of_the_pack_leader_cooldown 90.4% -> 0%, wyverns_cry 49.4% -> 0%, stampede 13.3% -> 0%

**5 targets:** -5.8% loss, 0% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| pet:natures_ally_pet | 3.3% | 0 / 0 | indirect |
| cobra_cleave | 2.1% | 0 / 0 | indirect |

Buff uptime (opt -> hl): beast_cleave 90.7% -> 75.9%

## Frost Mage

**1 target:** -3.8% loss, 16% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| ice_lance | 1.4% | 134.4 / 133.8 | proc-gated |
| flurry | 0.7% | 38.8 / 35.1 | threshold |
| font_of_venomous_rage | 0.7% | 2.0 / 2.0 | indirect |
| glacial_spike | 0.6% | 26.5 / 25.3 | override-unresolved |
| frost_splinter | 0.5% | 1375.3 / 1317.3 | indirect |

Buff uptime (opt -> hl): fingers_of_frost 24.4% -> 12.1%

**3 targets:** -8.8% loss, 29% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| glacial_spike | 5.7% | 33.0 / 29.2 | override-unresolved |
| flurry | 2.4% | 50.1 / 39.7 | threshold |
| comet_storm | 1.3% | 7.3 / 7.2 | override-unresolved |
| frostfire_bolt | 1.2% | 69.2 / 55.8 | indirect |
| molten_chill_ignite | 0.9% | 627.4 / 507.8 | indirect |
| ice_lance | 0.6% | 86.3 / 98.7 | proc-gated |

Resource waste (opt -> hl): mana 22.2% -> 29.2%

Buff uptime (opt -> hl): fingers_of_frost 47.7% -> 19.3%, brainstorm 73.6% -> 57.8%, comet_storm 20.1% -> 7.7%

**5 targets:** -10.0% loss, 21% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| glacial_spike | 6.6% | 33.6 / 27.8 | override-unresolved |
| ice_lance | 4.4% | 88.4 / 85.2 | proc-gated |
| frostfire_bolt | 2.1% | 68.0 / 41.9 | indirect |
| flurry | 2.0% | 45.4 / 34.5 | threshold |
| comet_storm | 1.7% | 7.2 / 6.9 | override-unresolved |
| molten_chill_ignite | 0.9% | 602.8 / 448.8 | indirect |

Resource waste (opt -> hl): mana 22.0% -> 26.7%

Buff uptime (opt -> hl): fingers_of_frost 52.9% -> 24.4%, brainstorm 66.4% -> 50.1%, comet_storm 20.6% -> 7.5%

## Guardian Druid (tank)
*Never suggested by the in-game highlight (SimC presses these in its highlight sims, so real losses are larger):* berserk

**1 target:** -9.2% (SimC -11.2%) loss, 30% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| maul | 11.5% | 14.9 / 56.1 | threshold |
| heart_of_the_wild_cat | 7.8% | 2.9 / 0 | indirect |
| mangle | 5.2% | 92.9 / 88.0 | threshold |
| vicious_brambles | 4.5% | 159.3 / 163.8 | indirect |
| moonless_night | 2.4% | 209.8 / 222.4 | indirect |
| spirits_wrath | 2.4% | 43.2 / 24.6 | indirect |

Resource waste (opt -> hl): rage 1.5% -> 37.7%

Buff uptime (opt -> hl): bear_form 98.7% -> 0%, lycaras_teachings_vers 98.7% -> 0%, gift_of_an_ancient_guardian 78.0% -> 0%, ironfur 78.0% -> 0%

**3 targets:** -15.8% loss, 10% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| raze | 21.5% | 27.9 / 52.8 | indirect |
| vicious_brambles | 6.1% | 406.9 / 365.6 | indirect |
| heart_of_the_wild_cat | 4.0% | 2.8 / 0 | indirect |
| mangle | 3.5% | 73.1 / 81.4 | threshold |
| swipe_bear | 2.2% | 45.7 / 0.4 | not-suggested |
| moonless_night | 1.8% | 417.2 / 404.9 | indirect |

Resource waste (opt -> hl): rage 1.7% -> 59.2%

Buff uptime (opt -> hl): bear_form 98.9% -> 0%, lycaras_teachings_vers 98.9% -> 0%, ursocs_fury 92.4% -> 0%, gift_of_an_ancient_guardian 74.6% -> 0%

**5 targets:** -20.1% loss, 5% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| raze | 27.4% | 37.2 / 45.4 | indirect |
| vicious_brambles | 6.9% | 644.4 / 463.3 | indirect |
| heart_of_the_wild_cat | 2.6% | 2.9 / 0 | indirect |
| moonless_night | 2.4% | 635.2 / 496.8 | indirect |
| swipe_bear | 1.8% | 34.2 / 0.0 | not-suggested |
| spirits_wrath | 1.3% | 49.1 / 18.4 | indirect |

Resource waste (opt -> hl): rage 0.3% -> 70.1%

Buff uptime (opt -> hl): bear_form 98.8% -> 0%, lycaras_teachings_vers 98.8% -> 0%, ursocs_fury 96.3% -> 0%, gift_of_an_ancient_guardian 76.5% -> 0%

## Protection Warrior (tank)
*Never suggested by the in-game highlight (SimC presses these in its highlight sims, so real losses are larger):* avatar, demoralizing_shout, ignore_pain, shield_block, shield_charge, shield_wall

**1 target:** -5.4% loss, 37% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| auto_attack_mh | 1.7% | 253.0 / 225.4 | indirect |
| shield_slam | 1.7% | 101.5 / 98.2 | threshold |
| execute | 1.1% | 31.4 / 30.0 | threshold |

**3 targets:** -3.6% loss, 44% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| thunder_clap | 2.5% | 71.7 / 59.5 | threshold |
| revenge | 1.2% | 54.6 / 45.8 | target-count |
| shield_slam | 1.1% | 99.3 / 106.0 | threshold |
| auto_attack_mh | 1.0% | 250.3 / 221.6 | indirect |

**5 targets:** -3.1% loss, 52% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| thunder_clap | 2.9% | 72.1 / 59.8 | threshold |
| shield_slam | 1.3% | 99.0 / 105.9 | threshold |
| auto_attack_mh | 0.7% | 250.4 / 221.5 | indirect |

## Assassination Rogue
*Never suggested by the in-game highlight (SimC presses these in its highlight sims, so real losses are larger):* deathmark, vanish

**1 target:** -5.7% loss, 14% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| rupture | 1.7% | 10.4 / 9.6 | proc-gated |
| garrote | 1.4% | 13.8 / 12.4 | threshold |
| kingsbane | 1.1% | 5.2 / 5.2 | proc-gated |
| deadly_poison_driver | 0.6% | 0 / 0 | indirect |
| envenom | 0.6% | 57.5 / 58.7 | proc-gated |
| amplifying_poison | 0.6% | 0 / 0 | indirect |

Buff uptime (opt -> hl): cold_blood 69.0% -> 0%, inspiring_strike 79.1% -> 66.7%

**3 targets:** -9.3% loss, 19% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| rupture | 5.8% | 10.2 / 9.8 | proc-gated |
| garrote | 3.2% | 14.3 / 11.9 | threshold |
| singular_focus | 0.6% | 5839.0 / 5782.2 | indirect |
| deathstalkers_mark | 0.5% | 60.4 / 65.8 | indirect |

**5 targets:** -13.9% loss, 16% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| rupture | 6.4% | 10.0 / 10.1 | proc-gated |
| garrote | 3.5% | 14.3 / 12.3 | threshold |
| deathstalkers_mark | 1.2% | 80.8 / 81.8 | indirect |
| singular_focus | 0.9% | 11581.6 / 11236.5 | indirect |
| caustic_spatter | 0.8% | 2471.1 / 2464.9 | indirect |

## Unholy DK

**1 target:** -10.7% loss, 10% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| lord_of_the_dead | 2.9% | 22.7 / 20.0 | indirect |
| lesser_ghoul | 2.7% | 0 / 0 | indirect |
| dread_plague | 1.5% | 1.0 / 6.6 | indirect |
| putrefy | 1.1% | 16.4 / 17.7 | proc-gated |
| raise_dead | 1.0% | 1.0 / 1.0 | threshold |
| death_coil | 0.8% | 61.6 / 51.5 | threshold |

Resource waste (opt -> hl): runic_power 0.0% -> 12.2%

Buff uptime (opt -> hl): festering_scythe_tt 99.2% -> 59.0%, festering_scythe 34.8% -> 18.2%, lesser_ghoul_ready 82.0% -> 65.5%

**3 targets:** -7.6% loss, 20% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| epidemic | 5.8% | 70.9 / 0 | target-count |
| lord_of_the_dead | 3.0% | 24.7 / 24.0 | indirect |
| putrefy | 0.8% | 20.6 / 22.2 | proc-gated |
| raise_dead | 0.5% | 1.0 / 1.0 | threshold |

Buff uptime (opt -> hl): death_and_decay 36.3% -> 0%

**5 targets:** -9.3% loss, 20% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| lord_of_the_dead | 3.9% | 25.5 / 24.0 | indirect |
| epidemic | 3.5% | 110.8 / 86.6 | target-count |
| raise_dead | 1.1% | 1.0 / 1.0 | threshold |
| putrefy | 0.9% | 23.1 / 22.3 | proc-gated |
| dark_transformation | 0.5% | 7.0 / 7.1 | threshold |

Resource waste (opt -> hl): runic_power 0.3% -> 15.4%

Buff uptime (opt -> hl): death_and_decay 36.6% -> 0%

## Fire Mage
*Never suggested by the in-game highlight (SimC presses these in its highlight sims, so real losses are larger):* combustion

**1 target:** -5.2% loss, 0% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| scorch | 3.7% | 29.1 / 0 | proc-gated |
| pyroblast | 3.1% | 175.9 / 170.9 | proc-gated |
| ignite | 1.6% | 593.9 / 577.2 | indirect |

Buff uptime (opt -> hl): hot_streak 34.2% -> 8.2%, overflowing_energy 48.7% -> 26.7%, heat_shimmer 21.1% -> 0%

**3 targets:** -10.5% loss, 27% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| flamestrike | 43.0% | 155.3 / 0 | target-count |
| meteorite | 5.0% | 135.9 / 0 | indirect |
| pet:arcane_phoenix | 4.2% | 0 / 0 | indirect |
| fireball | 3.4% | 76.9 / 0 | threshold |

Buff uptime (opt -> hl): mana_cascade 96.9% -> 0%, spellfire_sphere 94.8% -> 0%, feel_the_burn 78.0% -> 0%, fiery_rush 23.2% -> 0%

**5 targets:** -2.3% loss, 22% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| flamestrike | 1.8% | 154.0 / 153.2 | target-count |
| ignite | 0.6% | 2006.5 / 1997.2 | indirect |

Buff uptime (opt -> hl): hot_streak 24.7% -> 8.5%

## Frost DK
*Never suggested by the in-game highlight (SimC presses these in its highlight sims, so real losses are larger):* breath_of_sindragosa, raise_dead

**1 target:** -0.7% loss, 55% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| reapers_mark | 10.0% | 7.1 / 0 | threshold |
| howling_blast | 3.2% | 59.4 / 60.2 | threshold |
| frost_fever | 1.2% | 80.2 / 60.2 | indirect |
| frost_strike | 1.0% | 99.8 / 101.0 | threshold |

Buff uptime (opt -> hl): dark_talons 62.9% -> 0%, bind_in_darkness 35.0% -> 0%, swift_and_painful 18.6% -> 0%

**3 targets:** -3.9% loss, 32% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| frostscythe | 19.5% | 129.5 / 0 | target-count |
| howling_blast | 0.6% | 62.3 / 61.9 | threshold |
| frostwyrms_fury | 0.6% | 7.4 / 7.5 | threshold |

**5 targets:** -1.0% loss, 60% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| frostwyrms_fury | 0.7% | 7.4 / 7.5 | threshold |

## Retribution Paladin
*Never suggested by the in-game highlight (SimC presses these in its highlight sims, so real losses are larger):* avenging_wrath

**1 target:** 0.5% (SimC -6.6%) loss, 5% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| dawnlight | 11.7% | 30.7 / 0 | indirect |
| blade_of_justice_walk_into_light | 6.0% | 38.5 / 0 | indirect |
| divine_arbiter | 5.5% | 37.0 / 17.5 | indirect |
| hammer_of_wrath | 4.2% | 33.2 / 0 | button-override |
| divine_storm | 3.8% | 39.0 / 5.5 | target-count |
| suns_avatar | 2.8% | 223.0 / 0 | indirect |

Buff uptime (opt -> hl): born_in_sunlight 42.1% -> 0%, blessing_of_anshe 19.7% -> 0%, dawnlight 12.5% -> 0%, rush_of_light 83.2% -> 73.0%

**3 targets:** -13.7% (SimC -23.1%) loss, 10% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| hammer_of_wrath | 4.3% | 29.9 / 0 | button-override |
| blade_of_justice_walk_into_light | 4.2% | 35.3 / 0 | indirect |
| divine_arbiter | 4.0% | 37.3 / 23.1 | indirect |
| divine_toll | 2.8% | 5.3 / 0 | target-count |
| highlords_judgment | 2.7% | 90.8 / 36.4 | indirect |
| execution_sentence | 2.3% | 5.2 / 5.5 | threshold |

Buff uptime (opt -> hl): divine_resonance 14.7% -> 0%

**5 targets:** -12.5% (SimC -17.6%) loss, 6% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| suns_avatar | 8.1% | 394.1 / 0 | indirect |
| dawnlight | 7.1% | 30.7 / 0 | indirect |
| divine_storm | 5.3% | 145.1 / 147.9 | target-count |
| hammer_of_wrath | 4.6% | 29.9 / 0 | button-override |
| blade_of_justice_walk_into_light | 3.9% | 35.3 / 0 | indirect |
| divine_arbiter | 3.4% | 37.2 / 28.3 | indirect |

Buff uptime (opt -> hl): born_in_sunlight 42.1% -> 0%, blessing_of_anshe 19.5% -> 0%, divine_resonance 14.6% -> 0%, dawnlight 12.4% -> 0%

## Shadow Priest
*Never suggested by the in-game highlight (SimC presses these in its highlight sims, so real losses are larger):* power_infusion

**1 target:** -2.0% (SimC -22.5%) loss, 11% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| void_volley | 10.1% | 40.1 / 0 | button-override |
| void_blast | 7.2% | 29.9 / 0 | button-override |
| shadow_word_pain | 4.8% | 4.9 / 6.6 | proc-gated |
| entropic_rift | 3.7% | 10.3 / 0 | indirect |
| void_torrent | 3.6% | 10.3 / 0 | threshold |
| shadow_word_madness | 3.4% | 77.7 / 69.3 | threshold |

Buff uptime (opt -> hl): mental_fortitude 99.8% -> 0%, voidheart 71.3% -> 0%, entropic_rift 45.4% -> 0%, collapsing_void 31.2% -> 0%

**3 targets:** -12.1% (SimC -29.9%) loss, 7% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| shadow_word_pain | 11.6% | 7.6 / 69.3 | proc-gated |
| entropic_rift | 5.4% | 10.2 / 0 | indirect |
| void_volley | 5.0% | 39.9 / 0 | button-override |
| vampiric_touch | 3.6% | 78.9 / 69.3 | proc-gated |
| void_blast | 3.3% | 32.8 / 0 | button-override |
| shadow_word_madness | 2.9% | 87.4 / 71.4 | threshold |

Buff uptime (opt -> hl): voidheart 71.3% -> 0%, entropic_rift 45.7% -> 0%, collapsing_void 33.0% -> 0%, darkening_horizon 29.0% -> 0%

**5 targets:** -16.0% (SimC -29.4%) loss, 5% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| shadow_word_pain | 10.7% | 10.0 / 131.9 | proc-gated |
| void_volley | 3.8% | 39.7 / 0 | button-override |
| shadeburst | 2.7% | 266.9 / 219.8 | indirect |
| shadowy_apparitions | 2.5% | 989.3 / 813.6 | indirect |
| pet:thing_from_beyond | 2.3% | 0 / 0 | indirect |
| shadow_word_madness | 2.1% | 88.5 / 75.1 | threshold |

Buff uptime (opt -> hl): voidform 25.3% -> 0%, ancient_madness_extension 24.7% -> 0%, freightrunners_flask 15.5% -> 0%, void_volley 14.3% -> 0%

## Havoc DH
*Never suggested by the in-game highlight (SimC presses these in its highlight sims, so real losses are larger):* felblade, metamorphosis, the_hunt, vengeful_retreat

**1 target:** -11.4% (SimC -41.3%) loss, 0% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| death_sweep | 12.5% | 46.4 / 0 | button-override |
| annihilation | 12.4% | 122.6 / 0 | button-override |
| burning_blades | 8.7% | 0 / 0 | indirect |
| demonsurge | 7.3% | 0 / 0 | indirect |
| essence_break | 3.9% | 9.9 / 7.8 | proc-gated |
| abyssal_gaze | 3.8% | 6.5 / 0 | button-override |

Resource waste (opt -> hl): fury 0.6% -> 31.8%

Buff uptime (opt -> hl): immolation_aura 34.4% -> 0%, demonsurge 67.0% -> 40.4%, demonsurge_demonic_intensity 45.0% -> 19.4%, metamorphosis 71.0% -> 47.0%

**3 targets:** -13.9% (SimC -32.4%) loss, 0% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| wounded_quarry | 13.9% | 187.2 / 0 | indirect |
| soulscar | 13.4% | 0 / 0 | indirect |
| death_sweep | 12.2% | 46.4 / 0 | button-override |
| art_of_the_glaive | 6.8% | 0 / 0 | indirect |
| annihilation | 5.8% | 115.0 / 0 | button-override |
| reavers_glaive | 5.0% | 25.7 / 0 | button-override |

Resource waste (opt -> hl): fury 3.5% -> 33.5%

Buff uptime (opt -> hl): serrated_glaive 97.9% -> 0%, thrill_of_the_fight_haste 96.9% -> 0%, art_of_the_glaive 78.9% -> 0%, thrill_of_the_fight_damage 69.0% -> 0%

**5 targets:** -11.5% (SimC -30.1%) loss, 3% of the gap in fixable-looking abilities

| Ability | DPS gap | Casts opt / hl | Label |
|---|--:|--:|---|
| demonsurge | 9.6% | 0 / 0 | indirect |
| death_sweep | 7.1% | 39.1 / 0 | button-override |
| abyssal_gaze | 4.5% | 4.0 / 0 | button-override |
| essence_break | 3.3% | 9.8 / 7.8 | proc-gated |
| glaive_tempest | 2.2% | 49.5 / 32.9 | indirect |
| annihilation | 2.0% | 70.1 / 0 | button-override |

Resource waste (opt -> hl): fury 1.0% -> 36.4%


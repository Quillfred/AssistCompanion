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

## Cooldowns the highlight never suggests (DKs, Devastation)

From each spec's Assisted Combat list (SimC `ActionPriorityLists/assisted_combat/`, game build 12.1.5.70688). A cooldown counts as missing when it isn't in the list, or is in it but marked "This is for Blizzard automation" (never shown in the highlight).

| Spec | Never suggested | Optimal use | Cooldown (game data) |
|---|---|---|---|
| Frost | Breath of Sindragosa (automation only) | During Pillar of Frost | 90s (1249658) |
| Frost | Raise Dead | On cooldown, off the GCD | 120s (46585) |
| Blood | Vampiric Blood | On cooldown | 90s (55233) |
| Blood | Raise Dead | On cooldown, off the GCD | 120s (46585) |
| Unholy | none | | |
| Devastation | none | | |

Devastation's list has Dragonrage, Tip the Scales (when Fire Breath is ready), Deep Breath, Fire Breath and Eternity Surge, and no automation-only lines. Its losses come from conditions and button overrides instead (Azure Sweep, Pyre at 3 targets, essence cap).

## Devastation (0.20.0)

**The highlight's rules** (`assisted_combat.inc`, spec 1467, in order): Blessing-type aura check (364342), Dragonrage, Fire Breath (Consume Flame talent, Fire Breath DoT missing), Tip the Scales (Fire Breath off cooldown), Fire Breath, Eternity Surge, Deep Breath (within 40 yd, Recall missing), Disintegrate (>3 targets near the target and Mass Disintegrate stacks), Dragonrage (Unbound Flame up, Essence Burst <= 1), **Pyre (>3 targets)**, **Azure Strike (Azure Sweep 1265871 up)**, Living Flame (>3 targets, Burnout + Leaping Flames), Azure Strike (>3 targets), Disintegrate, Living Flame. No essence conditions at all.

* **Azure Sweep (0 casts in the highlight sims) is a SimC artifact.** Eternity Surge grants the Azure Sweep buff (1265871) and Azure Strike's button becomes Azure Sweep (1265872). The highlight's rule is "Azure Strike while the buff is up", but SimC's `azure_strike_t::action_ready` returns false while the buff is up (`sc_evoker.cpp`), so the rule can never fire in SimC. In game the button casts Azure Sweep. 0.20.0 shows the button's spell on the icon (any override), so it reads Azure Sweep. To confirm in game: the highlight asks for Azure Strike right after Eternity Surge.
* **Essence:** no essence condition in the highlight; essence waste 24% vs 8.5-12% optimal (triage). Essence is readable in combat (`UnitPower`, type 19; Augmentation confirmed). Rule `essencecap`: at max essence (UnitPowerMax, or 5 / 6 with Power Nexus 369908 when hidden) and the highlight on a generator (Living Flame, Azure Strike / Sweep), show the spender.
* **Pyre:** highlight ">3"; SimC's Flameshaper list (`use_pyre_fs`) wants it at 3+ with Legacy of the Lifebinder (1264269) and Volatility rank 2 (369089) or Feed the Flames (369846); at 5+ with Legacy alone. Volatility's rank isn't readable, so any rank counts. Scalecommander's list only uses Pyre at 3 with 15 Charged Blast stacks (hidden), so the rule needs Legacy. Triage at 3 targets: Pyre 38 casts optimal vs 0.
* **Empower ranks** (SimC `es`, `fb_fs`, `fb_sc`): Eternity Surge hits 1 target per rank (2 with Eternity's Span 375757), max rank 3, or 4 with Font of Magic (411212). SimC picks ranks by exact target match and falls back to rank 1 otherwise; the addon uses the lowest rank that hits every enemy instead (the guides' rule), capped at max. Fire Breath: Flameshaper rank 1 on 1 target or with the Pyre plan, 2 on 2 targets or in Dragonrage (18 s from the cast, 375087), else 3; Scalecommander (Mass Disintegrate 436335) one rank per target up to 4, rank 1 on 5+.
* **Not measured:** SimC couldn't be built in this session, so these rules' DPS value isn't simmed (Blood's were). Enemy counts come from nameplates within 25 yd (Disintegrate's range) or in combat, while Pyre and Eternity Surge care about enemies near the target, so big pulls can count high.

The addon's Breath rule used to time Breath with a 120s cooldown. Game data says 90s (Breath 1249658, duration 8s), so after a Breath cast in combat the icon now returns 30s sooner.

## Augmentation Evoker

From the game's highlight list (`assisted_combat/evoker_augmentation.simc`), the optimal list, and game data. Not simmed: Augmentation's value is mostly allies' damage, which solo sims can't measure.

* **Breath of Eons (403631)** isn't in the highlight's list, but the talent data says it replaces **Deep Breath (357210)**, which is (`deep_breath` if within 40 yards). In game the highlight probably points at the Breath of Eons button, as Blood's Rune Strike entry points at Heart Strike. SimC can't model a talent replacement, so its highlight sims never cast Breath of Eons. The addon shows Deep Breath suggestions as Breath of Eons, and also shows it when ready (120s) after Ebon Might and Prescience, in case the highlight skips replaced spells. Whether the game returns 357210 or 403631 is unconfirmed (check with `/ac debug`).
* **Ebon Might (395152):** the highlight recasts it only when the buff is down (`buff.ebon_might_self.down`). Optimal refreshes with 40% (4s) of its 10s left; recasting keeps up to 3s (pandemic). Cooldown 30s. Sands of Time (395153) extends it by 1s per Eruption, 2s per empowered spell and 5s per Breath of Eons/Deep Breath (Breath of Eons also grants 5s if it's down); each extension has your crit chance to be 50% longer. All of these are your own casts, so the addon tracks the expiry itself. Crits make its estimate run short, so the reminder can come early, never late.
* **Prescience (409311):** 2 charges, 12s recharge, 18s duration. The highlight casts it only when its buff is down, so one charge sits capped. Optimal keeps it on the best DPS allies (not tanks, healers or other Augmentations); the target can't be chosen for you. The addon shows it in a group at 2 charges.
* **Owner's debug log (0.13.0, 108s on a dummy, Chronowarden build):**
  * The in-game highlight **never suggested Tip the Scales, Time Skip, Deep Breath or Breath of Eons**, although Tip the Scales, Time Skip and Deep Breath are in its game-data list. Fire Breath was suggested many times with Tip the Scales ready (its rule is "if Fire Breath is ready", right before Fire Breath), and Chrono Flames filler showed where Time Skip (no condition, ahead of the filler) should have. At the pull, Breath of Eons was ready and the highlight said Upheaval; the addon's `breatheons` rule showed it and it was cast. Tip the Scales and Time Skip are now cooldown-ready rules too (0.14.0).
  * `UNIT_SPELLCAST_SUCCEEDED` fires for empowered spells (Fire Breath 357208, Upheaval 396286). Breath of Eons reports 403631 at the start and 403758 at the end; only 403631 extends Ebon Might in the addon. Essence reads in combat (`rp=6/6`).
  * **The Ebon Might estimate runs well short.** First cast just before the pull: the addon's estimate ran out about 26s in, but the highlight kept showing lower-priority spells at 32-33s with Ebon Might off cooldown (so the buff was still up), and only asked for Ebon Might at 34.7s. So the real buff lasted at least 8s longer than the estimate. Likely causes: crit extensions (+50%) and extensions the addon drops after its estimate has (wrongly) run out. The refresh reminder never fired, because by the time Ebon Might was ready the estimate said it had dropped. The status line now shows the estimate (`em=`) to measure this.
  * `enemies=0` before and during combat on a dummy: counting returns a number, not `nil`, but the dummy wasn't counted (nameplates hidden, or the dummy doesn't count as in combat). Still unresolved.
* **Owner's second debug log (0.14.0, 93s):**
  * Tip the Scales, Time Skip and Breath of Eons corrections all showed and were cast. Ranks showed as designed, but Fire Breath often said **rank 3 while Upheaval was ready**. The highlight suggested Upheaval at +28.1s (cast at +4.0s; Time Skip at +27.9s) and again 29.4s after the next cast, not 40s.
  * Causes: **Time Skip** (cooldowns recover 10× for its 2s channel, ~+18s), **Temporal Burst** (Chronowarden; after Tip the Scales cooldown recovery +30% fading over 30s in game data, **34.1s in the owner's tooltip**), and **"[DNT] Clear Empower Cooldown" (397374)**, cast right after a Tip the Scales Fire Breath, after which Fire Breath was ready 3s later and Upheaval within a second (so it resets both). Also unmodelled: the 4-piece set bonus (empowers recover 10% faster during Ebon Might, 1264820), possibly haste.
  * 0.14.1 models Time Skip, Temporal Burst (read from the tooltip) and the reset, and learns an empower recovery factor from the highlight: the first time it suggests Fire Breath or Upheaval after a cast, that spell is ready, which gives a lower bound on how fast they recover (40/29.4 = 1.36 in this log).
  * **Fire Breath right before Ebon Might** (+88.7s): Fire Breath was suggested and cast at +90.1s, Ebon Might came off cooldown ~0.2s later. Optimal casts empowers only inside Ebon Might. New rule `ebonfirst`: Ebon Might first when the highlight asks for an empower in the last 1.5s before Ebon Might is ready and our estimate says it has run out or has under 4s. Once Ebon Might is ready, the highlight asks for it itself if the buff is down, so suggesting an empower then means the buff is still up.
  * Ebon Might estimate: inconclusive this time (the refresh rule fired once, at +28.7s). When the highlight asks for Ebon Might, the addon now treats the buff as down.
* **Owner's third debug log (0.14.1, 139s):**
  * **Breath of Eons held ~23s:** cast at +1.1s, shown again at +121.2s (120s from the cast). Time Skip at +26.6s (~+18s) and Temporal Burst after Tip the Scales at +25.1s (~+5s) had made it ready around +98s. 0.14.1 applied the speed-ups only to Fire Breath, Upheaval and Ebon Might; 0.14.2 applies them to every cooldown-ready rule (`ns.cooldownSpeedup`).
  * **`up=` was 0.0 on every line**, so Fire Breath always showed rank 1. For example at +56.1s, while the highlight only offered Upheaval at +60.8s. Cause: the estimate took the out-of-combat cooldown read of *either* Upheaval ID, and the Font of Magic ID (not talented) reads as ready. Fixed by reading only the spell on the button.
  * `ebonfirst` fired four times (+27.2, +54.8, +85.9, +117.2s), each 1-2s before Ebon Might came back with the highlight on an empower, and Ebon Might went out before the empower each time. Learned empower factor: 1.25.
* **Owner's fourth debug log (0.14.2, 140s):**
  * **`up=` still 0.0 all fight** (so Fire Breath always rank 1), while `emcd=` counted down fine through the same code. The difference is the empower: `UNIT_SPELLCAST_SUCCEEDED` fires at the start of the empower, but the cooldown starts on release. So the tick right after the cast reads Upheaval as *not on cooldown*, and that read is readable rather than secret. Real cooldowns are hidden in combat, so nothing ever corrected it. 0.14.3 ignores cooldown reads in combat, and "ready" reads within 5s of casting the spell (a pre-pull empower).
  * Breath of Eons came back at +98.2s after Time Skip (0.14.2 fix confirmed). Tip the Scales showed once (+30.0s); with the speed-ups it was next ready ~+127s, after the last Fire Breath (+111s).
  * Empowers just before Ebon Might: e.g. Upheaval suggested at +26.2s with Ebon Might 2.1s away; `ebonfirst` only acted at 1.5s (+26.9s), as Upheaval went out (+27.0s). The owner asked to fill longer waits with another ability. 0.14.3: hold the empower when Ebon Might is back within 6s and our estimate says the buff ends before then; Eruption (if usable) or Chrono Flames while waiting more than a GCD, Ebon Might within a GCD.
  * Tried and dropped: treating "Ebon Might off cooldown + highlight suggests something below it" as "buff still up". It's true, but the remaining time is unknown, so it made the refresh reminder nag for an early recast.
* **Tip the Scales** (Icy Veins' Augmentation guide, via the owner; Chronoboon value from game data 1260484 and the owner's tooltip): its 2-minute cooldown starts when the buff is used up (by an empower, or `/cancelaura`), not on the press. Chronoboon takes 30s off. For Chronowarden with Time Skip, Icy Veins uses it on cooldown with a cancel macro (`/cast Tip the Scales` + `/cancelaura Tip the Scales`), unless an empower is available within a GCD, to keep Temporal Burst and Time Skip in sync. 0.15.0 times the cooldown from the buff being used (an empower within 2s of the press, else cancelled when the macro option is on) and adds the `tipMacro` option.
* **Owner's fifth debug log (0.15.0, 114s, macro option on):**
  * `up=` **still 0.0 all fight.** Most likely the button's Upheaval ID (`C_Spell.GetOverrideSpell(396286)`) differs from the cast ID (396286) and reads ready out of combat, and casts never clear it. 0.15.1: once the ability has been cast this session, time it from the cast (in combat) or read the ID that was cast (out of combat). Status line `upb=` shows the button's ID to confirm.
  * **Accretion** (407876, Augmentation talent): each Eruption takes 1s off Upheaval's remaining cooldown (411932: -1000 ms; SimC `cooldown.upheaval->adjust`). This explains most of the "Upheaval back in ~29s" gap in the second log (about 7 Eruptions plus Temporal Burst). Now modelled. The learned factor accounts for it.
  * **Motes of Possibility** (409267): Eruption has a chance to spawn a mote that gives an ally a random buff from Inferno's Blessing, Prescience, Symbiotic Bloom or Shifting Sands (SimC `mote_buffs_e`). None speeds up cooldowns, so motes don't explain cooldown timing.
  * **The cancel macro needs two presses:** `/cancelaura` runs before the buff exists. The note says "macro x2". A bug counted the cooldown from the next empower 18s later (+90.6s, after the +72.9s macro press). In macro mode, only an empower within 2s of the press counts as using the buff now.
* **Owner's sixth debug log (0.15.2, 111s, macro option on):**
  * `upb=396286`: the button's Upheaval *is* the cast ID, so the 0.15.1 theory was wrong. Real cause of `up=0`: the highlight keeps suggesting Upheaval for ~0.5-1s after the cast (empower plus lag; e.g. cast at +13.1s, still suggested at +13.8s). `learnEmpower` took that as "ready again" and marked it ready. 0.15.3 ignores suggestions within 3s of the cast.
  * Tip the Scales: used at +4.6s (Upheaval consumed it), estimated ready +71.5s with Chronoboon + Time Skip + Temporal Burst, shown at +71.6s. The owner saw it ready earlier, while empowers were suggested (~+61-66s), so the real recovery was 5-10s faster than modelled. SimC models it the same way (cooldown starts when the buff expires; Temporal Burst recharge effects), so the gap is unexplained (haste?). 0.15.3 learns a factor from early presses (a press proves it was ready) and logs `haste=`.
* **Owner's seventh debug log (0.15.3, 102s):**
  * `up=` now counts down (e.g. 38.8 right after Upheaval). Fire Breath showed rank 3 with Upheaval far off and rank 1 close to it. Accretion visible: `up=` drops ~2s per Eruption (1s of time + 1s Accretion).
  * Tip the Scales: shown at +71.1s, pressed at +72.9s (`tx` stayed 1.00). Haste 8.3% out of combat, hidden in combat (`haste=?`); too small to explain the earlier 5-10s gap.
  * **Cancelled empower:** a Fire Breath "cast" at +57.5s, then the highlight still offered Fire Breath and it was cast again at +63.2s (30s cooldown, no reset), so the first was started and cancelled. `UNIT_SPELLCAST_SUCCEEDED` fires at the start of an empower, so the addon counted it, then learned "Fire Breath recovered in 4s" and capped the factor at 1.60, which made the Upheaval estimate ~7s early. 0.16.1: `UNIT_SPELLCAST_EMPOWER_STOP` with `complete == false` undoes the cast (lastCast, Ebon Might extension, Tip consumption). Learned factors are averaged and implausible readings dropped.
* **Owner's eighth debug log (0.16.1, 138s):** clean. `x=` settled at 1.07-1.13. After the first cycle, Upheaval estimates were within ~1.5s of the highlight offering it (+72.3s ~1s late, +100.3s on time, +129.6s ~1.5s late). Fire Breath rank 3 whenever Upheaval was more than 1.5s away. Tip the Scales estimate matched (shown +70.8s, pressed +71.6s). Breath of Eons back at +93.6s with both Temporal Bursts and Time Skip counted. `ebonfirst` held Fire Breath twice with a filler. The first Upheaval of the session was ~5.5s early versus the uncorrected estimate (factor starts at 1.00), so 0.16.4 saves the learned factors (`db.augLearned`, keyed by an Accretion/Chronoboon/Temporal Burst signature). No cancelled empowers in this fight.
* **Owner's ninth debug log (0.16.5, empower-cancel test):** `UNIT_SPELLCAST_EMPOWER_STOP` reports `complete == false` readably in combat. Three cancelled Fire Breaths (+29.9, +31.8, +35.6s) and two cancelled Upheavals (+38.8, +41.2s) each logged "empower cancelled". The Ebon Might +2s extension was removed each time (`em` 5.7→2.7, 3.7→0.7, 10.7→7.6), `up=` went back to 0.0 after the cancelled Upheaval, and the learned factor stayed steady (1.20→1.18). Normal releases logged no cancel. Saved learned factors confirmed (`augLearned = { sig = "ACT", empower = 1.18 }`).
* **Ebon Might estimate explained (owner's screenshots):** Mastery: Timewalker (406380) lengthens "your other helpful auras" by the mastery's second value (13.8% at 7.51% mastery). SimC applies it to Ebon Might's base duration (`buff_duration() * (1 + mastery effect 2)`), but not to extensions. Sands of Time extensions can crit for +50% (owner's crit 20.6%, so +10% on average). Replaying the first log with both: the estimate ends at +34.04s. The buff really ended between +33.6s (highlight still below Ebon Might, with it off cooldown) and +33.7s (the Upheaval cast then didn't keep it up; the highlight asked at +34.7s). The old estimate ended at ~+26s. 0.16.6 reads the mastery percentage from its tooltip (last "%" in the text) and the best spell crit (`GetSpellCritChance` 2-7) out of combat; pandemic is 30% of the stretched duration. The crit part is an average, so single casts can still be off by a second or so.
* **Owner's tenth debug log (0.16.6):** `emdur=1.14` and `crit=21-25` read correctly. A short first pull showed **Tip the Scales at combat start while the highlight asked for Prescience** (Ebon Might not up yet). Breath of Eons waits for the highlight's Prescience / Ebon Might, but Tip the Scales didn't. 0.16.7 makes it wait. The opener differed from earlier logs because the pull started at the Ebon Might cast (no pre-pull Fire Breath), so Tip the Scales paired with Fire Breath instead of Upheaval. Time Skip was only suggested at +111s, most likely still on cooldown from an unlogged earlier pull (the out-of-combat read). `ts=` / `boe=` added to the status line to confirm such cases.
* **Owner's eleventh debug log (0.16.7):** Fire Breath **rank 3 was shown with ~1-2s of Ebon Might left** (+62.9s, `em=1.2`, Ebon Might ~15s from ready). A rank 3 charge (~2-2.5s) would end after Ebon Might, missing both its damage bonus and the +2s extension. The owner cast rank 1. 0.16.8: rank 1 whenever Ebon Might has under 2.5s left. Also confirmed: Time Skip ready (`ts=0`) and shown in the opener; Breath of Eons shown when `boe` reached 0; a cancelled Upheaval undone. The owner confirmed the tenth log's late Time Skip was still on cooldown from an earlier pull.
* **Timing talents (0.17.0, from game data):** Tomorrow, Today (412723: Time Skip +1000 ms channel), Instability Matrix (431484: each empower -0..6s off its own cooldown, modelled as the 3s average), Interwoven Threads (412713: cooldowns -10%), Dream of Spring (414969: Emerald Blossom 355913 extends Ebon Might 1s), Nozdormu Adept (431715: Prescience cooldown -2s; the tooltip's s3 = -2000 ms, not the -4000 of another effect), Overlord (410260: Breath of Eons casts Eruption at the first 3 enemies; SimC's overlord Eruptions extend Ebon Might and trigger Accretion; one assumed), Wingleader (441206: Mass Eruption, i.e. the first Eruption after an empower with Mass Eruption 438587, -1.5s Breath of Eons per target; one assumed). The owner uses Overlord (talent screenshot). The learned-factor signature now includes Tomorrow, Today / Instability Matrix / Interwoven Threads.
* **Owner's Frost debug log (0.17.1, single dummy then a group with AoE):** `enemies=0` throughout, even on the group (nameplate state unknown). **`rp=nil/100` throughout, even out of combat, while runes read 6**: runic power may now be hidden from addons, which would silence Unholy `rpcap` and Blood `rpcap` (to confirm on Blood/Unholy). The highlight stayed on Pillar of Frost (its first rule, never pressed) except out of melee, so its AoE switch wasn't observable. Raise Dead correction shown. 0.17.2 adds `np=`/units/attackable/incombat/hidden to the status line and reports `rp=hidden` for secret power values.
* **Owner's nameplate tests (0.17.2, Frost, 4 runs: EllesmereUI on/off x all nameplates shown or not):**
  * **Runic power is hidden from addons:** `rp=hidden` on every line (secret value), while runes read. Unholy `rpcap` and Blood `rpcap` (Death Strike at cap) can't fire. Essence (Augmentation) still reads.
  * **Nameplates aren't the problem:** with "show all nameplates" the addon saw `np=7 units=7 attackable=7` with or without EllesmereUI (`np=1-2` otherwise). But **`incombat=0` always**: training dummies never report `UnitAffectingCombat`, not even the one being hit. 0.17.3 also counts attackable plates within range of the spec's spell (`ns.meleeSpell`, or `ns.countRangeSpell` = Eruption for Augmentation). `inrange=` on the status line will show whether nameplate range checks are readable in combat.
* **Owner's group-dummy log (0.17.3, Frost, all nameplates shown, followed the highlight):**
  * **Enemy count works:** `enemies=5 (np=7-8 attackable=6-7 incombat=0 inrange=5)` before and all through combat. Range checks on nameplates are readable in combat.
  * **The highlight does its own AoE:** once Frostwyrm's Fury and Empower Rune Weapon were used it alternated Frostscythe, Glacial Advance and Howling Blast (no Obliterate) with 5 dummies in melee, and Pillar of Frost when ready. The addon's 3-target Frostscythe correction never had to fire. So the highlight reads the enemy count itself.
  * Out of melee (`melee=nil`) it showed Obliterate.
  * **Opener bug:** after combat ended with Empower Rune Weapon and Pillar on cooldown, the rebuilt opener skipped steps 1-4, then the idle reset (keyed to opener casts a minute earlier) rebuilt it, every frame. Fixed in 0.17.4: a rebuild clears the last-cast time.
* **Owner's log with "show all nameplates" off (0.17.4, Frost, group of dummies):** `np=1 enemies=1` (only the target's plate), yet the highlight still ran its AoE rotation. The highlight counts enemies itself; addons only see enemies with a nameplate. `rp=hidden/100` throughout, in and out of combat.
* **Owner's Unholy log (0.18.0):** `rpicon=hidden` whenever the highlight was on a rune spender, so `UnitPowerPercent("player", 6, false, curve)` returns a secret alpha and `SetAlpha` accepts it (no error line). The owner didn't notice the icon: the highlight sat on Graveyard (383269) most of the fight, so it only had ~1s windows, and its default spot (-60, -100) is away from the owner's icons (y -140). Whether the alpha actually reached 1 can't be read; 0.18.1 adds `/ac rptest` (no highlight/combat gating) to check by eye.
* **Runic power icon confirmed (0.18.1):** with `/ac rptest` the owner saw it appear at the threshold and disappear after spending. 0.18.2 shows Unholy's whenever at the threshold in combat unless the highlight already says Death Coil / Epidemic.
* **Owner's Unholy log (0.19.0):** the main icon turned blue-bordered at 80 RP on single target. On the AoE dummies the highlight sat on **Graveyard (383269), which replaces Epidemic** in the owner's build (cast 2-3 times in a row), so the layer correctly stayed off (`rpicon=waiting`). Death Coil is replaced by Necrotic Coil (1242174). 0.19.1 shows the button's spell (override) on the layer and the readable-RP rule.
* **0.19.0:** at the owner's request the runic power icon became a layer over the next-cast icon (child frame, alpha from the curve), hidden for the opener and for corrections listed before the runic power rule.
* **Runic power icon (0.18.0):** `UnitPowerPercent(unit, powerType, usePredicted, curve)` assumed by analogy with `UnitHealthPercent(unit, usePredicted, curve)`. Step curve on both 0-1 and 0-100 scales.
  * The highlight stayed on Pillar of Frost (never pressed), so its AoE switch still wasn't observed.
* **Empower ranks:** the highlight never says how far to empower. SimC's optimal list: Fire Breath to rank 1 while Upheaval is ready, else rank 3; Upheaval to rank 1; Tip the Scales makes the next one instant at max rank. The addon shows that number on the icon (`ns.empowerRank`). Upheaval's cooldown (40s) is timed from your casts in combat; talents that speed up empowered cooldowns during Ebon Might can make it ready sooner, so at worst it says 3 where 1 was slightly better.
* Fire Breath, Upheaval and Eruption aren't held for Ebon Might windows by the highlight. Not corrected: the gain depends on allies' cooldowns.

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

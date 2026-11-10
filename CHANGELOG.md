# Assist Companion

## 0.27.4

* **Brewmaster: Celestial Infusion no longer back to back.** It now waits while an Empty Barrel is up (Bring Me Another: any brew fills it, your next Keg Smash throws it), as SimC's optimal list does. Simmed: +0 / +0.9 / +1.2% at 1 / 3 / 5 targets over using it whenever a charge is ready (owner asked).
* Confirmed in game (tanking dummies): stagger is readable in combat, so Purifying Brew isn't shown at 0 stagger; brew charge counts matched every cast; Empty the Cellar shown and cast from the Exploding Keg button (1263438); Blackout Combo Tiger Palm on 4 targets. Energy is hidden from addons for Brewmaster, so the "wait for energy" rule can't fire yet. Stagger level (light / moderate / heavy) is hidden in combat; the game itself glows Purifying Brew at high stagger.
* Debug log: `barrel=` (Empty Barrel up).

## 0.27.3

* **Fixed: Brewmaster stuck on Purifying Brew with no stagger** (owner: on dummies that don't hit you it can't be pressed). It's no longer shown at 0 stagger when the game lets the addon read stagger. If the game hides stagger and refuses a Purifying Brew, it stays off the icon for 4 seconds and its charges are kept (0.27.1 wrongly set them to 0).

## 0.27.2

* Brewmaster debug log: `stagger=` (your stagger amount) and `level=` (light / moderate / heavy), or `hidden` if the game hides them in combat. To find out whether a "Purifying Brew at heavy stagger" option is possible.

## 0.27.1

* **Fixed: Brewmaster stuck on Celestial Infusion** (owner's log). Black Ox Brew grants one Celestial Brew / Infusion charge, but the addon refilled both (Endless Draught), so it kept showing Infusion with none left and nothing else came up. Now Black Ox Brew adds one charge and refills Purifying Brew.
* **Brews correct themselves:** if you press a brew the game says isn't ready, its count drops to 0 and the icon moves on.
* Confirmed in game: the opener (skipping Fortifying Brew and Niuzao while on cooldown), brew charges read before the pull (Endless Draught: 2), Blackout Combo tracking, enemy count on 4 dummies.

## 0.27.0

**Brewmaster Monk (first test build).** The game's highlight never uses a brew or Invoke Niuzao, spends energy before Keg Smash can come back, and only spends Blackout Combo on 1–2 targets. In the sims it's 32–64% behind SimC's optimal rotation; with these rules, 2–6% (Master of Harmony, `tools/brewmaster_rules_sim.py`). Every rule helps with the others on.

* **Celestial Brew / Celestial Infusion** when a charge is ready: +18 to +36% (Master of Harmony turns it into damage).
* **Purifying Brew** whenever a charge is ready: +3 to +6%.
* **Black Ox Brew** when Celestial Brew is out of charges: +4 to +11%.
* **Invoke Niuzao** when ready: +2 to +4%.
* **Empty the Cellar** while it's on your Exploding Keg button: +1 to +3%.
* **Blackout Combo on 3+ targets:** Tiger Palm to spend it (the highlight only does on 1–2): +14% at 3 targets, +58% at 5.
* **Save energy for Keg Smash:** below 65 energy a filler Tiger Palm or Spinning Crane Kick shows grayed out (wait): +1.5 to +2.5%.
* Brew charges are counted from your casts, including Tiger Palm (-1s, -1.5s with Face Palm) and Keg Smash (-3s, -5s with Blackout Combo) speeding them up. Dodges also speed them up and can't be seen, so a brew can show a little late, never early.
* **Opener** (SimC, Master of Harmony): Blackout Kick, Fortifying Brew, Chi Burst, Invoke Niuzao, Tiger Palm, Breath of Fire.
* Debug log: `pb=` `cb=` (brew charges), `combo=`, `bob=` / `niu=` (seconds until ready), `keg=` (what's on the Exploding Keg button).
* Recommended build: Master of Harmony (the rankings page's "Best for optimal rotation" build). With these rules it's 7–33% ahead of the page's Shado-Pan "Best for highlight" build.
* Core: charge counts can take the game's own recharge time (read out of combat) and be sped up or refilled by other casts.

## 0.26.3

* **Windwalker, 4+ targets: Spinning Crane Kick replaces Rising Sun Kick only at 4+ chi**, so 2 chi stay for Fists of Fury (3 chi). Owner's log: at any chi it looped Tiger Palm / Spinning Crane Kick at 0–2 chi and Fists of Fury went 45 seconds uncast. Simmed: +4% Shado-Pan, +1 to +2% Conduit of the Celestials with season 1 gear (-3% for Conduit only in top raid gear).
* Confirmed in game: the enemy count now reads 3–4 on the dummies (Fists of Fury range), and the 3-target and 4+ Spinning Crane Kick rules fire.

## 0.26.2

* **Windwalker enemy count reaches 8 yards** (Fists of Fury's range, the same as Spinning Crane Kick's radius) instead of Tiger Palm's melee range. Owner's log: on 4 dummies it counted 2 while the game's own highlight saw 4+, so the 3-target and 4+ Spinning Crane Kick rules never fired.
* Confirmed in game (Conduit of the Celestials): Invoke Xuen opener step and ready prompt (90s with Xuen's Bond), Celestial Conduit right after Xuen (cast as 443028), Zenith charges now match the game's own cooldown to the second. The Zenith button glows before its charge is back (Tigereye Brew, most likely); the addon ignores it.

## 0.26.1

* **Fixed: Zenith shown while on cooldown** (owner's log). When Rushing Wind Kick took over the Rising Sun Kick button, the game told addons "spells changed", and the addon reset its charge counts mid-fight, so it thought Zenith had 2 charges again. Counts are now kept in combat (this also protects Blood Boil and Prescience).
* Confirmed in game (Shado-Pan, 1 target): the Dance of Chi-Ji glow is readable and the rule fires; the opener plays in full; chi is readable in combat.

## 0.26.0

**Windwalker Monk.** The game's highlight in game is 23–52% behind SimC's optimal rotation. With the addon's rules it's 6–16% behind, ahead of SimC's own version of the highlight (which presses every cooldown). Simmed for both hero trees at 1–5 targets (`tools/windwalker_rules_sim.py`).

* **Zenith when a charge is ready** and Zenith isn't running. The highlight never shows it. This is the biggest gain: +19 to +37%. Charges are counted from your casts (90s each, -20s Spiritual Focus, -10s Efficient Training).
* **Invoke Xuen when ready** (90s with Xuen's Bond) and **Celestial Conduit once after each Xuen** (Conduit of the Celestials). Neither is ever shown by the highlight. +4 to +7% and +1 to +4%.
* **Spinning Crane Kick at 3 targets** in place of Tiger Palm or Blackout Kick (the highlight starts at 4): +20 to +27% at 3 targets.
* **Spinning Crane Kick over Rising Sun Kick at 4+ targets**: +18% for Conduit, +1.5% for Shado-Pan at 5.
* **Dance of Chi-Ji at 1 stack on 1–2 targets** (the highlight waits for 2): +2 to +5%. The proc is read from the glow on your Spinning Crane Kick button, so this one needs confirming in game.
* The Spinning Crane Kick corrections never repeat your last ability (Combo Strikes) and check your chi.
* **Opener** (SimC's current one): Tiger Palm, Invoke Xuen (Conduit), Zenith, Fists of Fury, Rising Sun Kick, Whirling Dragon Punch.
* Debug log: `zen=` (Zenith charges / seconds left), `glow=` (Dance of Chi-Ji glow: y / n / ?), `last=` (last ability), `xuen=`, plus `glow on/off` lines.

## 0.25.2

* **New icon** in the game's AddOns list, the addon compartment and on the minimap button: the gold arrow panel from the CurseForge art (`icon.tga`, 64×64, transparent outside its frame), replacing the generic gear.

## 0.25.1

* **Mistweaver Monk, first step:** the addon now runs for Mistweaver (listed in the options, Tiger Palm as the melee range check), so its debug log works. No corrections yet. The game's Mistweaver highlight is damage only, and its Blackout Kick rule needs more than 4 stacks of Teachings of the Monastery, which caps at 4, so it may never suggest Blackout Kick. The debug status shows `tp=` (stacks counted from your Tiger Palms) and `totm=` (the buff's own count, when the game lets addons read it), to confirm in game.
* Talent database: Mistweaver and Discipline included (`docs/talents/monk.md`, `priest.md`).

## 0.25.0

Unholy audit (talent database, current SimC, owner's Rider and San'layn logs). Death Knight is finished.

* **The runic power rule (Death Coil / Epidemic at 80+) is now San'layn only, and only in place of your rune spenders** (Scourge Strike, Festering Strike and what their buttons cast: Vampiric Strike, Festering Scythe). It no longer covers Putrefy, Soul Reaper or Outbreak.
  * Rider of the Apocalypse: the rule cost 0.3–1.3% damage in every sim, at 80, 90 or 100 runic power, so it's off.
  * San'layn: +0.1 to +2.8% this way, against 0 to +1.7% when it covered everything.
* Opener unchanged: SimC's current opener matches it for both hero trees. Talents: Unholy's rules don't time any cooldowns, so none of them affect it.
* The Blightfall fix still works (owner's San'layn log: shown and pressed twice).

## 0.24.1

* **"Not enough resource" shading works in combat again (all classes).** The game hides its usable check in combat, so the icon never turned blue (owner: Heart Strike with no runes stayed full color). Now the addon reads the spell's cost and checks it:
  * **Runes:** counted directly, and the icon turns blue when you don't have enough.
  * **Readable resources** (energy, focus, rage...): compared directly; the icon turns blue.
  * **Hidden resources** (runic power, essence...): a blue tint over the icon that the game shows when you're below the cost, the same way the runic power icon works.
* **Rune count fixed.** It read 6 all the time (owner's logs). Now it counts ready runes, as Blizzard's rune bar does. This also fixes Blood's "Death's Caress when low on runes" and the Death Strike hold's "nothing else to press".
* Debug log: `short=` (short / ok / tint / n).

## 0.24.0

Frost audit (talent database + current SimC):

* **Frost opener for Rider of the Apocalypse** (SimC's current optimal): Empower Rune Weapon, Obliterate, Pillar of Frost, Breath of Sindragosa, Empower Rune Weapon, Obliterate, Frost Strike, Obliterate, Empower Rune Weapon, Obliterate, Frostwyrm's Fury. It uses all three Empower Rune Weapon charges. Riders used to get the Deathbringer order. Deathbringer is unchanged: Empower Rune Weapon, Pillar, Reaper's Mark, Breath, Obliterate, Frostwyrm's Fury, Obliterate ×3.
* **Breath of Sindragosa window with Chosen of Frostbrood:** Frostwyrm's Fury during Pillar of Frost extends it by 2 seconds, and the Breath prompt now lasts that long too. The Long Winter's extension comes from auto-attack crits, which addons can't see, so it isn't counted (the prompt never runs past the real Pillar).
* Simmed (`tools/frost_rules_sim.py`): the highlight in game is 8–10% behind optimal (no Breath of Sindragosa). With the addon's rules it's 1–2% behind, for both hero trees.

## 0.23.2

* **The opener label ("Opener 1/8") is now above the bar's first icon**, on one line. Beside the bar it covered the next-cast icon when the bar sat next to it.
* From the owner's 0.23.1 Blood log: the out-of-order fix worked (Raise Dead before Death's Caress kept Death's Caress and Vampiric Blood); the opener bar's cooldown numbers matched the talents (Raise Dead 90s, Dancing Rune Weapon 90s, Vampiric Blood with Red Thirst).

## 0.23.1

* **Opener bar: spells on cooldown are grayed out with their seconds left** (all specs). This replaces the "00:35 until full opener is available" line above the icon.
* **Before the pull, a step on cooldown stays on the bar** (grayed) instead of being dropped. It's only skipped if it's still on cooldown once combat starts, so the opener doesn't wait for it.

## 0.23.0

* **Blood: "Hold runic power for Death Strike" option** (off by default; Options > Blood). When the highlight asks for Death Strike, the icon shows Blood Boil (with a charge) or Heart Strike instead, with a gold border, unless you're within 20 runic power of max or at 50% health or lower. Then it's Death Strike again, with a red border at low health. That keeps runic power banked for several Death Strikes after a big hit. Runic power and health are hidden from addons, so the game decides: two layers over the icon, their visibility set from your runic power and health. Simmed on steady damage: −0.4% to +0.6% damage, about equal damage taken; the benefit is for damage spikes, which the sim doesn't model.
* The runic power and hold layers have their own global cooldown swipe and cover the icon's keybind with their own.
* Death Coil (Blood's other runic power spender) instead of the highlight's Death Strike was simmed and rejected: 15–20% less damage and 1.7–5× the damage taken.
* Debug log: Blood status lines show `hold=` (off / waiting / on:<spell> / nothing else).

## 0.22.1

From the owner's Blood log (0.22.0):

* **Opener steps cast out of order stay in the opener.** Pressing Raise Dead before Death's Caress used to drop Death's Caress and Vampiric Blood. Now the step you cast is ticked off and the ones before it stay. A step is only dropped once you've cast two later steps past it, so one you skip on purpose doesn't hold the opener up. All specs.
* **The empower rank number is big and outlined** (the same style as the Tip the Scales "x2"). The keybind, rank and "x2" now draw above the global cooldown swipe, so they aren't darkened. Consumption's "1" went unseen.
* Looked at, not changed: holding Death Strike until within 20 runic power of max or below 50% health (instead of the highlight's 80+). Simmed with all Blood rules: −0.4% to +0.6% damage and slightly more damage taken. Not worth it, and SimC's own Deathbringer list spends Death Strike before Heart Strike and Blood Boil anyway.

## 0.22.0

* **Opener countdown (all specs):** out of combat, if any spell in your opener is still on cooldown, a timer above the next-cast icon counts down to when the whole opener is available: "00:35 until full opener is available". It counts every opener step, including ones the opener bar skipped because they were on cooldown. Global-cooldown-length waits don't count. It hides in combat and when the opener is off.

## 0.21.7

Blood audit (talent database + current SimC):

* **Bone Shield refresh counts every way Bone Shield gains charges.** Dancing Rune Weapon with Insatiable Blade (+5 charges), Reaper's Mark with Grim Reaper (+3) and grips with Bone Collector all restart its 30 seconds, like Marrowrend and Death's Caress. The addon no longer asks for a Marrowrend right after a Dancing Rune Weapon.
* **Vampiric Blood with Red Thirst:** each Death Strike takes 9 seconds off Vampiric Blood (8 with Ossuary): 2s per 10 runic power spent. The prompt used to wait the full 90 seconds.
* **Raise Dead with Death's Messenger** (Deathbringer): 90-second cooldown (was 120), for Blood and Frost.
* **New Blood opener** from SimC's current optimal list: Death's Caress, Vampiric Blood (only while its rule is on), Raise Dead, Dancing Rune Weapon, then Heart Strike x4 (San'layn), or Death and Decay, Reaper's Mark, Marrowrend, Death Strike (Deathbringer). The old one had no Dancing Rune Weapon.
* **Consumption shows a "1"** (empower rank badge, Blood's options): SimC always holds it to rank 1.
* **Debug log:** Blood status lines show `bs=` (seconds since Bone Shield last gained charges) and `vb=` (Red Thirst seconds off Vampiric Blood).
* Simmed (`tools/blood_rules_sim.py`): the highlight in game is 12-24% behind optimal; with the addon's rules, 2-9%, with optimal's damage taken in AoE.

## 0.21.6

From simming the addon's Devastation rules (`tools/dev_addon_sim.py`; results in `docs/FINDINGS.md`):

* **Essence cap keeps Azure Sweep for Flameshaper on 3+ targets.** Spending essence instead of Azure Sweep lost 1.2% there (Flameshaper at 3 targets now -6.3% from optimal, was -7.4%). Everywhere else it still spends.
* **Pyre at 3 targets (Flameshaper) needs Volatility at rank 2, or Feed the Flames**, like SimC. The rank is read from your talent loadout; if the game won't give it, only Feed the Flames counts. Also applies to the Fire Breath rank 1 "Pyre plan".

## 0.21.5

* **Augmentation: the Tip the Scales macro's "x2" is big.** With the `tipMacro` option on, when the icon says to press the macro twice, "x2" now shows large and outlined in gold in the icon's bottom right (about 45% of the icon's size, so it scales with the icon) instead of small text after the keybind. The keybind stays in the top right.

## 0.21.4

* **Evoker passed the dummy test** (0.21.3 log): enemy count 1 on the isolated dummy and before the pull, 3-4 on the group; the opener ran once; Deep Breath was shown within ~2s of when you could cast it (every ~50s with Onyx Legacy and Wingleader).
* **Devastation talents the addon didn't account for:**
  * **Concentrated Power** (Scalecommander): Mass Disintegrate strikes 4 targets, so Wingleader takes up to 4s off Deep Breath per Disintegrate (was capped at 3, Deep Breath shown late on 4+ targets).
  * **Animosity:** each empower during Dragonrage extends it (5s, then 25% less each time); cancelled empowers don't count. Flameshaper's Fire Breath rank 2 lasts as long as Dragonrage really does.
  * **Rising Fury** (third rank): Rising Fury stays 4s per stack after Dragonrage ends (a stack at the start and every 6s, max 5), and SimC keeps Flameshaper's Fire Breath at rank 2 while it lasts.
* **Debug log:** Devastation status lines show `dr=`: seconds left of Dragonrage (plus Rising Fury after it).

## 0.21.3

* **Ranged enemy count works on training dummies again.** Your log showed dummies report neither combat nor threat (`incombat=0 threat=0`, even the one being hit), so 0.21.2's count would have read 1 on a group of dummies. Now, for Devastation and Augmentation:
  * before the pull: your target only (no more Eternity Surge rank 4 from dummies standing nearby);
  * in combat with enemies that report combat (real fights): your target plus enemies in combat within range;
  * in combat when nothing reports combat (dummies): everything within range.
* Your last log was recorded with 0.21.1: the opener reset you saw is the one 0.21.2 fixed (it now waits 6 seconds out of combat).

## 0.21.2

* **A short combat drop no longer resets the fight.** Deep Breath flew you off the dummies and combat dropped for a moment: the opener restarted from step 1 and the addon forgot your cooldowns. Now it waits until you've been out of combat for 6 seconds; back in combat sooner, it's the same fight (debug log: "combat resumed"). Deaths and boss kills/wipes still reset right away. All specs.
* **Ranged enemy count (Devastation, Augmentation) only counts enemies you're fighting:** your target, enemies you have threat on, and enemies in combat within range. Before the pull, 8 dummies within 25 yards made Eternity Surge say rank 4; now it's your target only until the fight starts. Melee specs are unchanged.

## 0.21.1

* **Devastation: Wingleader counted for Deep Breath.** Each empower gives a Mass Disintegrate stack; the next Disintegrate uses it and takes 1 second per target struck (up to 3) off Deep Breath's cooldown (game data). Cancelled empowers give no stack.
* **Debug log:** Devastation status lines show the Deep Breath cooldown estimate (`db=`), Mass Disintegrate stacks (`mass=`) and the seconds Wingleader cut (`wl=`).
* **Devastation opener** (SimC's optimal list), shown on the opener bar before and at the pull:
  * **Scalecommander:** Living Flame (before the pull), Dragonrage, Eternity Surge, Tip the Scales, Fire Breath, Deep Breath (with Melt Armor or Maneuverability), Disintegrate.
  * **Flameshaper:** Living Flame, Dragonrage, Tip the Scales, Eternity Surge, Fire Breath, Disintegrate x2.
  * Font of Magic's versions of Fire Breath and Eternity Surge count as the same steps.

## 0.21.0

* **Devastation: Dragonrage, Deep Breath and Tip the Scales.** Your debug log confirmed the in-game highlight never suggests them (2 minutes single target plus the 5-target tests), like on Augmentation. Now:
  * **Dragonrage** whenever it's ready in combat.
  * **Deep Breath** when it's ready on 2+ targets, or any time with Melt Armor, Maneuverability or Imminent Destruction (SimC's optimal list). Counts Onyx Legacy (-1 minute) and the steerable Maneuverability version. With Wingleader it can come back a little sooner than shown.
  * **Tip the Scales** when the highlight asks for Fire Breath and Tip is ready: Fire Breath is then instant at max rank.
  * Each can be turned off under Evoker > Devastation.
* **Enemy count for ranged specs (Devastation, Augmentation):** counts the enemies you're actually fighting (on their threat table) instead of every enemy within 25 yards. In your log a second dummy nearby made single target read 2 and Fire Breath said rank 2. When the game doesn't say (or before the first hit), it falls back to the old count. Debug log: `threat=` on the enemy line.
* Confirmed in your log: essence cap (Disintegrate at 5/5), Eternity Surge rank 3 with Eternity's Span on 6 targets, Scalecommander Fire Breath rank 1 on 5+, and that the highlight switches to Pyre / Azure Strike in AoE by itself (even with nameplates off).

## 0.20.3

* **Augmentation: Ebon Might before Fire Breath, one more case.** With Ebon Might in its refresh window (about 4 seconds left) and ready again within a global cooldown, the icon now says Ebon Might first, then the empower. In your L'ura kill it showed Fire Breath rank 3 with 3 seconds of Ebon Might left, half a second before Ebon Might was ready.
* **Augmentation: Tip the Scales no longer shows early.** Its learned speed could only ever go up (an early press proves it recovered faster; a late press proves nothing), so it crept up to 4% faster than the game data and Tip showed about 1.5 seconds before it was ready. It's now capped at 2%, and a press the game refuses ("not ready yet") steps it back down. The debug log notes when that happens.
* Confirmed in a boss fight: Time Skip's real channel length is used (both casts logged 2.00s).

## 0.20.2

* **Debug log keeps 5000 lines** (was 500), enough for a whole boss fight (about 3 lines a second). Clear it between fights with ctrl-click on the minimap button.

## 0.20.1

* **Augmentation: Time Skip is counted for as long as you actually channel it.** The addon assumed every Time Skip lasted its full 2 seconds and gave all your cooldowns 18 seconds for it. In your raid log (The Lost Explorers), one Time Skip ended the moment it started, and the addon then showed Ebon Might, Fire Breath and Upheaval about 13-17 seconds early and Breath of Eons about 19 seconds early. Under Fury of the Aspects the channel was also shorter (1.37s, haste). The addon now sees when the channel ends and counts only that.
* **Debug log:** "channel ended: Time Skip after X s".

## 0.20.0

* **Devastation Evoker support:**
  * **Essence cap:** when your essence is full and the highlight asks for Living Flame or Azure Strike, the icon shows **Disintegrate** (**Pyre** on 4+ targets). The highlight keeps building essence at max (24% wasted in sims vs 8-12% optimal).
  * **Pyre at 3 targets** for Flameshaper (Legacy of the Lifebinder) with Volatility or Feed the Flames. The highlight only uses Pyre on 4+.
  * **Empower rank on the icon** for **Eternity Surge** (the lowest rank that hits every enemy: one target per rank, two with Eternity's Span, up to 4 with Font of Magic) and **Fire Breath** (Flameshaper: 1 on one target, 2 on two or in Dragonrage, else 3; Scalecommander: one rank per target, 1 on 5+). From SimC's optimal list. No number after Tip the Scales or when the enemy count is unknown.
  * Each can be turned off in the options menu under Evoker > Devastation. Target counts need enemy nameplates on.
* **The icon shows what your button casts right now**, e.g. **Azure Sweep** while it replaces Azure Strike.

## 0.19.1

* **Unholy: runic power shows the spell on your button.** If a talent replaces Death Coil or Epidemic (Necrotic Coil, Graveyard), the icon now shows that spell instead of the plain one.
* Confirmed in game: the main icon turns blue-bordered at 80 runic power. In AoE it stays out of the way because the highlight already asks for Graveyard (Epidemic's replacement), which spends it.

## 0.19.0

* **Runic power is now part of the main icon.** Instead of a separate icon off to the side, the next-cast icon itself turns into Death Coil / Epidemic (Unholy) or Death Strike (Blood) with a **blue border** at the threshold, and goes back to the highlight's suggestion once you spend. The game still decides when (the addon can't see your runic power). Nothing extra to place.
* It steps aside for the opener and for corrections that matter more (Unholy's Blightfall, Blood's Bone Shield refresh). The GCD swipe still shows over it.
* `/ac rptest` now shows "RP test" above the main icon.

## 0.18.2

* **Runic power icon confirmed working** (tested with `/ac rptest`).
* **Unholy: the runic power icon is easier to see.** It used to show only while the highlight asked for a rune spender, so it flashed for a second at a time while the highlight was on cooldowns like Graveyard. It now shows whenever you're at 80+ runic power in combat, unless the highlight already says Death Coil or Epidemic.

## 0.18.1

* **`/ac rptest`: runic power icon test.** The icon follows your runic power only, in or out of combat, whatever the highlight says, with "RP test" under it. Build runic power without spending it and the blue-bordered icon should fade in at your threshold (80 for Unholy). `/ac rptest` again to stop.
* Your first Unholy log shows the game accepts the runic power icon (`rpicon=hidden`: the game handled the value out of the addon's sight).

## 0.18.0

* **Runic power icon (Unholy and Blood).** The game now hides your runic power from addons, so the "runic power cap" suggestions stopped showing. While it's hidden, a separate icon with a **blue border** appears instead: Death Coil (Epidemic on 4+ targets) for Unholy when the highlight asks for a rune spender, Death Strike for Blood within 20 of max. The addon can't see the number, so it hands the threshold to the game and the game makes the icon visible. Move it with `/ac unlock`. It's turned on or off with the same "Runic power cap" box in the options menu. This is a first try: if the game blocks it, the debug log says so (`rpicon=` on the status lines).
* Unholy's target count (Death Coil vs Epidemic) needs enemy nameplates turned on: addons can only count enemies that have a nameplate.

## 0.17.4

* **Opener fix after a fight on a dummy:** with some of its cooldowns still running, the opener skipped those steps, then reset itself again every frame (it filled the debug log). Steps skipped for cooldowns no longer count as casts, so it settles on the first step that's ready.

## 0.17.3

* **Enemy count works on training dummies.** Dummies never report being in combat, so the count was always 0. Enemies within range of your spell now count too (melee range for Death Knights, Eruption's range for Augmentation). This drives the 3-target corrections (Frost Frostscythe, Unholy Death Coil / Epidemic).
* **Debug log:** the enemy breakdown also shows how many are in range (`inrange=`).

## 0.17.2

* **Debug log:** status lines show what the enemy count sees (`np=` nameplates, then how many had a unit, were attackable, in combat, or hidden by the game), and `rp=hidden` when the game hides your runic power from addons.

## 0.17.1

* **Strata option:** choose which layer the icons, opener bar and text box draw on (BACKGROUND up to TOOLTIP; HIGH by default). In the options menu under Icons, or `/ac strata <name>` (e.g. `/ac strata medium`).

## 0.17.0

* **Augmentation: seven more talents counted in the timing** (only if you have them):
  * **Tomorrow, Today:** Time Skip lasts 3 seconds, so cooldowns come back ~27 seconds sooner instead of 18.
  * **Instability Matrix:** Fire Breath and Upheaval come back ~3 seconds sooner per cast (it's random, 0–6).
  * **Interwoven Threads:** all cooldowns 10% shorter.
  * **Dream of Spring:** Emerald Blossom extends Ebon Might by 1 second.
  * **Nozdormu Adept:** Prescience recharges in 10 seconds instead of 12.
  * **Overlord:** Breath of Eons' Eruption extends Ebon Might and counts for Accretion.
  * **Wingleader:** each Mass Eruption takes 1.5 seconds off Breath of Eons.
  
  Overlord and Wingleader assume one target (enemy counts aren't readable in combat), so with more targets the addon can only be a little late, never early.
* The learned cooldown speeds start over once, because they're now kept per set of these talents.
* **Debug log:** the start of each fight lists which of these timing talents you have.

## 0.16.8

* **Augmentation: Fire Breath rank 1 when Ebon Might is about to end.** With under ~2.5 seconds of Ebon Might left, a rank 3 Fire Breath would land after it ends and lose its extension, so the icon says rank 1.

## 0.16.7

* **Augmentation: Tip the Scales waits for Prescience and Ebon Might.** At the pull it could show while the highlight was still asking for Prescience. It now waits for those, like Breath of Eons does, so the empower it pairs with goes out inside Ebon Might.
* **Debug log:** status lines show the Time Skip and Breath of Eons cooldown estimates (`ts=`, `boe=`).

## 0.16.6

* **Augmentation: Ebon Might timing fixed.** The addon's estimate of when Ebon Might ends now counts:
  * your **mastery**, which lengthens your helpful auras including Ebon Might (13.8% turns 10s into 11.4s), read from its tooltip;
  * your **crit chance**: each extension can crit for 50% more.
  
  Replaying an earlier fight, the estimate now lands within half a second of when Ebon Might really ended (it used to be 8 seconds early), so the "refresh Ebon Might" and "Ebon Might before empowers" suggestions come at the right time.
* **Debug log:** status lines show the mastery multiplier (`emdur=`) and crit (`crit=`) in use.

## 0.16.5

* **Minimap button fix:** clicking it (shift-click, ctrl-click and others) made it disappear from a minimap button bar such as EllesmereUI's. Every click re-placed it on the minimap's edge, pulling it out of the bar. Clicks no longer move it, and if another addon has taken the button into its own bar, Assist Companion leaves its position alone.

## 0.16.4

* **Augmentation: learned cooldown speeds are remembered** between sessions (saved with your settings), so the first Fire Breath / Upheaval and Tip the Scales of a session are timed right. They start over when Accretion, Chronoboon or Temporal Burst changes.

## 0.16.3

* **Minimap button shortcuts:** **Shift-click** starts or stops the debug log (the icon is red while it's recording), **Ctrl-click** clears the debug log. The tooltip lists all the clicks.

## 0.16.2

* Options menu wording: "Next-cast icon" (on/off), then "When to show it:" (Always / In combat or with an enemy targeted / Only in combat).

## 0.16.1

* **Cancelled empowers are ignored.** The game reports Fire Breath and Upheaval as cast when you *start* them. If you cancel one, it doesn't go on cooldown, and the addon now undoes it: the cooldown timing, the Ebon Might extension, and Tip the Scales being used up.
* **Steadier learning.** The learned Fire Breath / Upheaval and Tip the Scales speeds average each new reading with the old one, and impossible readings are dropped instead of capped.

## 0.16.0

* **Minimap button.** Left-click opens the options menu, right-click locks or unlocks the frames, drag moves it around the minimap (square minimaps too). Hide it in the options menu or with `/ac minimap`.
* Assist Companion is also in the minimap's **addon menu** (Blizzard's addon compartment).

## 0.15.3

* **Augmentation: Fire Breath rank 3, found the real cause.** The highlight keeps showing Upheaval for a moment after you cast it. The addon took that as "Upheaval is ready again". It now ignores those first seconds.
* **Augmentation: Tip the Scales learns from your presses.** If you press Tip the Scales while the addon still thought it had time left, it recovers faster than modelled. The addon learns the ratio and shows it sooner next time.
* **Debug log:** status lines also show the learned Tip the Scales speed (`tx=`) and your haste (`haste=`).

## 0.15.2

* **Tip the Scales macro** (only with the cancel-macro option on): when it's time to press the macro (no empower ready), the icon shows **"x2"** right after the keybind (for example `F x2`), and the note under the icon says "macro". With the option off, nothing changes.

## 0.15.1

* **Augmentation: Fire Breath rank 3 (third try).** Once you've cast Upheaval, it's timed from your cast. Your action button reports a different Upheaval spell that always reads "ready", and the addon was taking that.
* **Augmentation: Accretion.** Each Eruption takes 1 second off Upheaval's cooldown, and the addon now counts it.
* **Tip the Scales macro:** the note under the icon says **"macro x2"**. The `/cancelaura` line only works on a second press, because on the first the buff isn't there yet. The cooldown is now timed from your macro press even if your next empower comes much later.
* **Debug log:** status lines show the Upheaval spell on your button (`upb=`) and the Tip the Scales cooldown estimate (`tip=`, or `w` while its buff waits).

## 0.15.0

* **Augmentation: Tip the Scales cancel-macro option** (options menu, under Augmentation; off by default). For the Icy Veins Chronowarden macro (`/cast Tip the Scales` + `/cancelaura Tip the Scales`):
  * When Fire Breath or Upheaval is ready within a global cooldown, Tip the Scales shows with **"+ empower"** under the icon: press plain Tip the Scales, then the empower (instant, max rank).
  * Otherwise it shows on cooldown with **"macro"** under the icon: press your macro.
  * With the option off, Tip the Scales still shows with Fire Breath, as before.
* **Tip the Scales' cooldown** is now timed from when its buff is used up (by an empower, or cancelled), not from when you press it, and counts **Chronoboon** (-30 seconds).

## 0.14.3

* **Augmentation: Fire Breath rank 3 works now.** In combat the game reported Upheaval as ready right after you cast it (an empowered spell's cooldown only starts when you release it), so the addon always said rank 1. In-combat cooldown reads are now ignored; cooldowns are timed from your casts.
* **Augmentation: hold empowers for Ebon Might.** When the highlight asks for Fire Breath or Upheaval but Ebon Might will have run out and comes back within about 6 seconds, the icon fills the wait with **Eruption** (or **Chrono Flames** if you can't afford it). Within a global cooldown it shows **Ebon Might**. Then the empower goes out inside Ebon Might.

## 0.14.2

* **Augmentation: Breath of Eons, Tip the Scales and Time Skip now count Time Skip and Temporal Burst.** Breath of Eons was being held up to ~20 seconds after it was really ready.
* **Augmentation: Fire Breath rank fixed (again).** The Upheaval estimate always read 0, so Fire Breath always said rank 1. The Font of Magic version of Upheaval, which you may not have, was being read as "ready".

## 0.14.1

* **Augmentation: Fire Breath rank fixed.** It often said rank 3 when Upheaval was ready. The addon now accounts for what speeds up your cooldowns:
  * **Time Skip** (10× recovery for 2 seconds);
  * **Temporal Burst** after Tip the Scales (size and fade time read from its tooltip);
  * the hidden empower-cooldown reset after a Tip the Scales empower.
  
  It also learns how fast your Fire Breath and Upheaval really recover from when the highlight offers them. Rank 1 now shows when Upheaval will be ready within about 1.5 seconds.
* **Augmentation: Ebon Might before empowers.** If the highlight asks for Fire Breath or Upheaval in the last 1.5 seconds before Ebon Might comes back, and Ebon Might has run out or is about to, the icon shows Ebon Might first.
* **Debug log:** Augmentation status lines also show the Upheaval and Ebon Might cooldown estimates (`up=`, `emcd=`) and the learned recovery speed (`x=`).

## 0.14.0

* **Augmentation: empower rank on the icon.** Fire Breath and Upheaval show the rank to hold them to: Fire Breath **1** while Upheaval is ready, otherwise **3**; Upheaval **1**. No number right after Tip the Scales (the next empower is instant at max rank). Turn it off under Augmentation in the options menu.
* **Augmentation: Tip the Scales and Time Skip.** The in-game highlight never suggests them (confirmed with a debug log), although both are in its rule list.
  * **Tip the Scales** shows when the highlight asks for Fire Breath and Tip the Scales is ready.
  * **Time Skip** shows once Fire Breath and Upheaval are spent, when Breath of Eons is 15+ seconds away or Tip the Scales is on cooldown (with Chronoboon, only the latter).
* **Debug log:** Augmentation status lines show the addon's Ebon Might estimate (`em=`), and a rule that hits an error is logged once instead of failing silently.

## 0.13.0

* **Augmentation Evoker** support:
  * **Ebon Might** when it's ready with about 4 seconds left (the highlight only recasts it after it drops). Timed from your own casts: Eruption, Fire Breath, Upheaval and Breath of Eons extend it.
  * **Breath of Eons**: the highlight's Deep Breath suggestions show as Breath of Eons, and it also shows when it's ready.
  * **Prescience** in a group when both charges are ready.
* **Options menu** (`/ac`, or Esc > Options > AddOns > Assist Companion): icon settings, when to show the icon, show while dead, opener and debug settings, and a class > spec > ability tree to turn each correction on or off.
* **Cooldowns the highlight never suggests:** Frost Raise Dead; Blood Vampiric Blood and Raise Dead. Breath of Sindragosa now uses its real 90-second cooldown.
* Rule toggles are now per spec. `/ac help` lists the commands.

# Assist Companion

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

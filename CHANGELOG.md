# Assist Companion

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

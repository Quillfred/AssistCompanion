# Assist Companion

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

# Assist Companion

A World of Warcraft (retail, Midnight 12.1.5) addon for **Blood, Frost and Unholy Death Knight** and **Devastation and Augmentation Evoker** that sits alongside Blizzard's **Assisted Highlight**.

It shows the highlight's suggested spell as one icon with its keybind, the way a "single button" display does but without the Single-Button Assistant's global cooldown penalty. Where the highlight's own rules are known to be wrong, the icon shows the correct spell instead. It also shows an opener bar before and at the start of a pull.

The addon only displays information. You press every button yourself.

## What it corrects

| Spec | Highlight problem | Assist Companion shows |
|---|---|---|
| Blood | Bone Shield is only refreshed by stack count, so its 30s timer runs out (~90% uptime) | **Marrowrend** (or **Death's Caress** when low on runes) with ~5s left |
| Blood | Blood Boil is only cast to apply Blood Plague (7–13 casts vs 52–56 optimal) | **Blood Boil** instead of Heart Strike whenever a charge is available |
| Blood | Runic power overcaps in AoE (7–12% wasted) | **Death Strike** within 20 runic power of max |
| Unholy | With the **Blightfall** talent, the highlight asks for **Outbreak** forever after Dark Transformation (its rule checks the Blightfall buff, which Outbreak never clears) | **Blightfall** |
| Unholy | Runic power only gets spent on procs, so it overcaps (about 15% wasted in 5-target sims) | **Death Coil** (1–3 targets) or **Epidemic** (4+) at 80+ runic power |
| Frost | **Breath of Sindragosa** is never suggested (about 7% DPS) | **Breath** during Pillar of Frost, as a bare 48px icon |
| Frost, Blood | **Raise Dead** is never suggested | **Raise Dead** in combat whenever it's ready |
| Blood | **Vampiric Blood** is never suggested (no defensive is) | **Vampiric Blood** in combat whenever it's ready |
| Augmentation | **Ebon Might** is only recast after it drops (optimal refreshes with ~4s left) | **Ebon Might** when it's ready with about 4s left, timed from your casts (Eruption, empowers and Breath of Eons extend it) |
| Augmentation | **Breath of Eons** isn't in the highlight's list (it has Deep Breath, which Breath of Eons replaces) | Deep Breath suggestions show as **Breath of Eons**; it also shows when ready, after Ebon Might and Prescience |
| Augmentation | **Tip the Scales** and **Time Skip** are never suggested in game (both are in the highlight's list) | **Tip the Scales** before Fire Breath (or, with the cancel-macro option, on cooldown: with an empower if one is ready within a GCD, else through the macro); **Time Skip** once the empowers are spent, away from Breath of Eons |
| Augmentation | Fire Breath and Upheaval can be suggested just before Ebon Might comes back, so they land outside it | Hold them: **Eruption** or **Chrono Flames** to fill the wait, then **Ebon Might**, then the empower |
| Augmentation | The highlight never says which **empower rank** to use | A number on **Fire Breath** (1 while Upheaval is ready, else 3) and **Upheaval** (1) |
| Augmentation | **Prescience** is only cast when none is active, so its second charge sits capped | In a group, **Prescience** when both charges are ready |
| Frost | At exactly 3 targets the highlight never uses Frostscythe (its rule starts above 3) | **Frostscythe** instead of Obliterate |
| Devastation | The highlight keeps building essence at max (24% wasted vs 8–12% optimal) | **Disintegrate** (or **Pyre** on 4+ targets) at full essence when it asks for Living Flame or Azure Strike |
| Devastation | **Pyre** only at 4+ targets, but Flameshaper builds with Volatility or Feed the Flames want it at 3 | **Pyre** instead of Disintegrate at exactly 3 targets |
| Devastation | **Dragonrage**, **Deep Breath** and **Tip the Scales** are never suggested in game (all three are in the highlight's list) | **Dragonrage** when ready; **Deep Breath** when ready on 2+ targets (or always with Melt Armor, Maneuverability or Imminent Destruction); **Tip the Scales** with Fire Breath |
| Devastation | The highlight never says which **empower rank** to use | A number on **Eternity Surge** (one rank per target, two with Eternity's Span) and **Fire Breath** (by targets, hero talents and Dragonrage, from SimC's optimal list) |
| Frost | **Empower Rune Weapon** is suggested while you're still running in (it has no range check, Pillar does) | Empower Rune Weapon **grayed out and red** until you're in melee |

The game hides runic power from addons, so for the two runic power rows above the game itself decides: at the threshold the next-cast icon turns into the spender with a **blue border**, and back once you spend. Target counts (Unholy, Frost, Devastation) need enemy nameplates turned on.

Corrections have a gold border. While an opener is running, the icon follows the opener instead and has a blue border. Like Blizzard's action bars, the icon turns **red** when your target is out of range, **blue** when you don't have enough runes or runic power, and **dark gray** when it can't be used for another reason. A global cooldown swipe runs over it. On the opener bar, a spell still on cooldown is grayed out with its seconds left; before the pull it stays on the bar, and it is only skipped if it is still on cooldown once combat starts. See [`docs/FINDINGS.md`](docs/FINDINGS.md) for the sims and game data behind each rule.

**Blood low-health icon:** a separate Death Strike icon fades in as your health drops (fully visible at 35%, hidden above 50%). Health is hidden from addons in combat, so the game itself sets the icon's transparency from your health; the addon never reads it.

## Install

1. Download this repository (**Code → Download ZIP**) or a release zip.
2. Copy the **`AssistCompanion`** folder (the one containing `AssistCompanion.toc`) into
   `World of Warcraft\_retail_\Interface\AddOns\`
3. Restart the game or type `/reload`.

If the game says the addon is out of date, tick **Load out of date AddOns** on the AddOns screen.

## Options menu

Click the **minimap button**, type **`/ac`**, or open **Esc → Options → AddOns → Assist Companion** (also in the minimap's addon menu).

* **Icons:** show or hide the next-cast icon, and when to show it (always, in combat or with an enemy targeted, or only in combat); show while dead; global cooldown swipe; text alerts; lock or unlock frames for moving; icon size and scale; test icon; reset positions.
* **Opener:** opener bar on or off, whether the next-cast icon follows it, restart it.
* **Debug:** debug log on or off, also print to chat, clear the log.
* **Abilities:** a tree of classes and specs. Open a spec to turn each of its corrections on or off (hover one for what it does), plus spec settings such as Blood's low-health icon. Your current class and spec open by themselves.

## Commands

| Command | What it does |
|---|---|
| `/ac` | Open the options menu. `/ac help` lists the commands |
| `/ac strata <name>` | Layer the icons, opener bar and text box draw on: background, low, medium, high (default), dialog, fullscreen, fullscreen dialog, tooltip |
| `/ac minimap` | Show or hide the minimap button (left-click: options, shift-click: start/stop the debug log, ctrl-click: clear it, right-click: lock/unlock, drag: move) |
| `/ac unlock`, `/ac lock` | Move the next-cast icon and opener bar |
| `/ac test` | Show a sample icon |
| `/ac icon` | Turn the next-cast icon on or off. `/ac icon 56` sets its size (default 48) |
| `/ac text` | Turn text alerts on or off (off by default) |
| `/ac hp` | Blood: turn the low-health Death Strike icon on or off. `/ac hp 35 50` sets fully-visible / hidden health % |
| `/ac gcd` | Turn the global cooldown swipe on the icon on or off (on by default) |
| `/ac opener` | Turn the opener bar on or off. `/ac opener reset` restarts it. `/ac opener icon` stops the next-cast icon following the opener |
| `/ac rp 80` | Unholy: runic power level that triggers a spend warning |
| `/ac cds` | Frost: turn the "use trinkets, potion and racial" reminder during Pillar on or off |
| `/ac rules`, `/ac toggle <key>` | List your current spec's rules, or turn one on or off for your current spec |
| `/ac scale <n>`, `/ac reset` | Scale everything, or reset positions |
| `/ac debug` | Log what the addon sees (icon changes and why, casts, opener steps, combat start/end, status each second) to its saved file. `/ac debug chat` also prints it to chat |
| `/ac log` | Show the debug log's size. `/ac log clear` empties it |

## Sending a debug log

1. Type `/ac debug` and play (the last 5000 lines are kept, enough for a whole boss fight).
2. `/reload` or log out. WoW then writes the log to
   `World of Warcraft\_retail_\WTF\Account\<ACCOUNT>\SavedVariables\AssistCompanion.lua`
3. Share that file. `/ac debug` again turns logging off.

## Keybinds

The keybind on the icon comes from Blizzard's action bar bindings. For bar addons with their own binding systems (EllesmereUI bars 9–10, Bartender, ElvUI, …) it reads the keybind text the bar addon prints on the button, scanned out of combat. If a bar hides its keybind text, the icon shows no key for spells on that bar.

## Limits

* Midnight hides some combat information from addons. Counting nearby enemies (used for the 3-target and 1–3 vs 4+ choices) may not work in combat; when it doesn't, those parts stay quiet.
* The openers come from SimC's optimal single-target rotation for SimC's default builds. Steps for spells you don't have are skipped.
* When combat drops (or you die, or an encounter ends) the opener restarts. Opener spells pressed out of combat rewind after 10 seconds.
* Cooldowns are hidden from addons in combat, so the addon reads them out of combat and remembers them. Opener steps still on cooldown (e.g. Pillar of Frost after a quick reset on a dummy) are skipped, and the cooldown icons (Breath, Raise Dead, Vampiric Blood) only show when the spell is ready. In combat they're timed from your last cast using the spell's base cooldown, so talents that shorten a cooldown make its icon come back a little late, never early. After a raid wipe the game resets cooldowns, and the addon sees that.
* This has been tested against a mocked WoW API (see below), not yet in the live game. Please report anything that behaves differently.

## Tests

The rules and display logic are tested against a mock of the WoW API with Lua 5.1 (the version WoW uses):

```bash
lua5.1 tests/harness.lua AssistCompanion
```

GitHub Actions runs the same tests on every push.

## License

[MIT](LICENSE) © 2026 Quillfred

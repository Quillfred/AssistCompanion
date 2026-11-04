# Assist Companion

A World of Warcraft (retail, Midnight 12.1.5) addon for **Frost and Unholy Death Knight** that sits alongside Blizzard's **Assisted Highlight**.

It shows the highlight's suggested spell as one icon with its keybind, the way a "single button" display does but without the Single-Button Assistant's global cooldown penalty. Where the highlight's own rules are known to be wrong, the icon shows the correct spell instead. It also shows an opener bar before and at the start of a pull.

The addon only displays information. You press every button yourself.

## What it corrects

| Spec | Highlight problem | Assist Companion shows |
|---|---|---|
| Unholy | With the **Blightfall** talent, the highlight asks for **Outbreak** forever after Dark Transformation (its rule checks the Blightfall buff, which Outbreak never clears) | **Blightfall** |
| Unholy | Runic power only gets spent on procs, so it overcaps (about 15% wasted in 5-target sims) | **Death Coil** (1–3 targets) or **Epidemic** (4+) at 80+ runic power |
| Frost | **Breath of Sindragosa** is never suggested (about 7% DPS) | **Breath** during Pillar of Frost, as a bare 48px icon |
| Frost | At exactly 3 targets the highlight never uses Frostscythe (its rule starts above 3) | **Frostscythe** instead of Obliterate |
| Frost | **Empower Rune Weapon** is suggested while you're still running in (it has no range check, Pillar does) | Empower Rune Weapon **grayed out and red** until you're in melee |

Corrections have a gold border. While an opener is running, the icon follows the opener instead and has a blue border. The icon turns red when your target is out of range. See [`docs/FINDINGS.md`](docs/FINDINGS.md) for the sims and game data behind each rule.

## Install

1. Download this repository (**Code → Download ZIP**) or a release zip.
2. Copy the **`AssistCompanion`** folder (the one containing `AssistCompanion.toc`) into
   `World of Warcraft\_retail_\Interface\AddOns\`
3. Restart the game or type `/reload`.

If the game says the addon is out of date, tick **Load out of date AddOns** on the AddOns screen.

## Commands

| Command | What it does |
|---|---|
| `/ac unlock`, `/ac lock` | Move the next-cast icon and opener bar |
| `/ac test` | Show a sample icon |
| `/ac icon` | Turn the next-cast icon on or off. `/ac icon 56` sets its size (default 48) |
| `/ac text` | Turn text alerts on or off (off by default) |
| `/ac gcd` | Turn the global cooldown swipe on the icon on or off (on by default) |
| `/ac opener` | Turn the opener bar on or off. `/ac opener reset` restarts it. `/ac opener icon` stops the next-cast icon following the opener |
| `/ac rp 80` | Unholy: runic power level that triggers a spend warning |
| `/ac cds` | Frost: turn the "use trinkets, potion and racial" reminder during Pillar on or off |
| `/ac rules`, `/ac toggle <key>` | List rules or turn one off |
| `/ac scale <n>`, `/ac reset` | Scale everything, or reset positions |
| `/ac debug` | Print the highlight's suggestion, keybind, runic power, enemy count and range every second |

## Keybinds

The keybind on the icon comes from Blizzard's action bar bindings. For bar addons with their own binding systems (EllesmereUI bars 9–10, Bartender, ElvUI, …) it reads the keybind text the bar addon prints on the button, scanned out of combat. If a bar hides its keybind text, the icon shows no key for spells on that bar.

## Limits

* Midnight hides some combat information from addons. Counting nearby enemies (used for the 3-target and 1–3 vs 4+ choices) may not work in combat; when it doesn't, those parts stay quiet.
* The openers come from SimC's optimal single-target rotation for SimC's default builds. Steps for spells you don't have are skipped.
* When combat drops (or you die, or an encounter ends) the opener restarts and every ability is treated as off cooldown, as after a raid wipe. Opener spells pressed out of combat rewind after 10 seconds.
* This has been tested against a mocked WoW API (see below), not yet in the live game. Please report anything that behaves differently.

## Tests

The rules and display logic are tested against a mock of the WoW API with Lua 5.1 (the version WoW uses):

```bash
lua5.1 tests/harness.lua AssistCompanion
```

GitHub Actions runs the same tests on every push.

## License

[MIT](LICENSE) © 2026 Quillfred

# Talent, mastery and racial database

Generated from the game's own data (SimC's copy of the client tables, build 12.1.5.70688) by
`tools/talent_db.py`, so every choice that can change what the addon should suggest is listed in one
place: class, spec and hero talents, each spec's mastery, and every race's racials.

| File | What's in it |
|---|---|
| `<class>.md` (13 files) | Specs and their hero trees, each spec's mastery, the class tree, then per spec its spec tree and hero trees. Per talent: spell ID, choice/tiered node, what it replaces or turns its button into, tooltip, and **Can affect the addon** flags. |
| `masteries.md` | Every spec's mastery, marked by whether it changes a duration, cooldown, resource or charges (most only add damage). |
| `racials.md` | Every racial by race, with its cooldown (on-use racials are reminder candidates) and stat effects (haste and the like change cooldown and cast timings). |

**Can affect the addon** is a keyword match on the tooltip: cooldown, resource, empower, charges,
duration, targets. It points at talents to check, not a verdict. **In addon** means the spell ID is
already used in `AssistCompanion/Rules.lua`.

Healer specs are left out (not planned yet; Mistweaver and Discipline come last). Add them with
`--healers`.

Regenerate after a game patch (with an updated SimC checkout):

    SIMC=/path/to/simc python3 tools/talent_db.py warrior paladin hunter rogue priest deathknight shaman mage warlock monk druid demonhunter evoker

**How to use it for a spec:** read its spec tree and both hero trees for talents flagged *cooldown*,
*empower*, *charges* or *duration*, plus anything that replaces a button the highlight suggests. Those
are what the addon's timing (cooldown-ready icons, Ebon Might-style estimates) and corrections must
account for. Augmentation's seven timing talents (Tomorrow, Today, Instability Matrix, …) were found
this way by hand; this database makes that search quick for every class.

-- Assist Companion: spec rules.
--
-- Each rule looks at the game state (ctx) and, if Blizzard's Assisted Highlight is about to
-- steer you wrong, returns an alert: { spell = <spellID for the icon>, text = "...", sub = "..." }.
-- Rules are checked top to bottom; the first one that fires is shown.
--
-- ctx fields (built every tick by Core.lua; any of them may be nil if the game hides it):
--   ctx.next        spell ID the Assisted Highlight is suggesting right now
--   ctx.power       your current runic power
--   ctx.powerMax    your max runic power (cached out of combat)
--   ctx.enemies     number of hostile in-combat nameplates, or nil if it can't be counted
--   ctx.inMelee     true/false: is your target in Obliterate range? nil if no target or unknown
--   ctx.now         GetTime()
--   ctx.knows(id)   true if you have that spell/talent
--   ctx.override(id) the spell currently on that ability's button (e.g. Dark Transformation -> Blightfall)
--   ctx.lastCast[id] GetTime() of your last successful cast of that spell this session
--   ctx.onCooldown(id) true/false if the game told us (out of combat) whether it's on cooldown, else nil
--   ctx.db          saved settings (thresholds, toggles)

local _, ns = ...

local S = {
  -- Unholy
  OUTBREAK            = 77575,
  DARK_TRANSFORMATION = 1233448,
  BLIGHTFALL          = 1271967,
  DEATH_COIL          = 47541,
  EPIDEMIC            = 207317,
  SCOURGE_STRIKE      = 55090,
  FESTERING_STRIKE    = 85948,
  PUTREFY             = 1247378,
  SOUL_REAPER         = 343294,
  -- Frost
  PILLAR_OF_FROST     = 51271,
  BREATH              = 1249658,
  OBLITERATE          = 49020,
  FROSTSCYTHE         = 207230,
  EMPOWER_RUNE_WEAPON = 47568,
  -- Frost and Blood
  RAISE_DEAD          = 46585, -- the 60s ghoul (Unholy's permanent pet is 46584)
  -- Blood
  MARROWREND          = 195182,
  DEATHS_CARESS       = 195292,
  DEATH_STRIKE        = 49998,
  BLOOD_BOIL          = 50842,
  HEART_STRIKE        = 206930,
  RUNE_STRIKE         = 316239, -- the highlight's data uses this ID; Heart Strike replaces it
  DEATH_AND_DECAY     = 43265,
  VAMPIRIC_BLOOD      = 55233,
}
ns.S = S

local PILLAR_DURATION = 12   -- seconds (game data: Pillar of Frost id 51271)

-- Unholy rune spenders the highlight prefers over spending runic power.
-- Whatever currently sits on the Scourge Strike button (Clawing Shadows, Vampiric Strike, ...)
-- is added at runtime via ctx.override, so those IDs don't need to be hard-coded.
local function isRuneSpender(ctx, id)
  if not id then return false end
  if id == S.SCOURGE_STRIKE or id == S.FESTERING_STRIKE or id == S.PUTREFY or id == S.SOUL_REAPER then
    return true
  end
  local onScourgeButton = ctx.override(S.SCOURGE_STRIKE)
  return onScourgeButton ~= nil and id == onScourgeButton
end

ns.rules = {}

---------------------------------------------------------------------------
-- Unholy Death Knight (spec 252)
---------------------------------------------------------------------------
ns.rules[252] = {
  {
    key = "blightfall",
    name = "Blightfall loop",
    spell = S.BLIGHTFALL,
    desc = "Shows Blightfall when the highlight keeps asking for Outbreak after Dark Transformation.",
    -- Blizzard's data says "Outbreak if Blightfall buff is up". The buff only turns
    -- Dark Transformation into Blightfall, and Outbreak doesn't clear it, so the
    -- highlight asks for Outbreak forever. Press Blightfall instead.
    check = function(ctx)
      if ctx.next ~= S.OUTBREAK then return end
      if ctx.override(S.DARK_TRANSFORMATION) ~= S.BLIGHTFALL then return end
      return {
        spell = S.BLIGHTFALL,
        text = "Press Blightfall",
        sub = "Not Outbreak. It's on your Dark Transformation button.",
      }
    end,
  },
  {
    key = "rpcap",
    name = "Runic power cap",
    spell = S.DEATH_COIL,
    desc = "Shows Death Coil (1-3 targets) or Epidemic (4+) when runic power is about to cap.",
    -- The highlight only spends runic power on procs, or when you're out of runes.
    check = function(ctx)
      local p = ctx.power
      if not p or p < ctx.db.unholyRP then return end
      if not isRuneSpender(ctx, ctx.next) then return end
      local n = ctx.enemies
      if n and n >= 4 and ctx.knows(S.EPIDEMIC) then
        return { spell = S.EPIDEMIC, text = "Spend: Epidemic", sub = ("Runic power %d"):format(p) }
      elseif n and n <= 3 then
        return { spell = S.DEATH_COIL, text = "Spend: Death Coil", sub = ("Runic power %d"):format(p) }
      end
      return {
        spell = S.DEATH_COIL,
        text = "Spend runic power",
        sub = ("%d RP. Death Coil on 1-3 targets, Epidemic on 4+"):format(p),
      }
    end,
  },
}

---------------------------------------------------------------------------
-- Blood Death Knight (spec 250)
-- Simmed against the in-game highlight with these three corrections on top (1/3/5 targets):
-- DPS loss vs optimal 13/19/19% -> 5/11/9%, damage taken 12.9/10.6/7.8M -> 11.7/6.3/4.2M per sec.
---------------------------------------------------------------------------
local BONE_SHIELD_DURATION = 30 -- game data: Bone Shield (195181)
local BONE_SHIELD_REFRESH = 25  -- refresh with ~5s left, like the optimal rotation

local function isHeartStrike(ctx, id)
  if not id then return false end
  return id == S.HEART_STRIKE or id == S.RUNE_STRIKE
      or id == ctx.override(S.RUNE_STRIKE) or id == ctx.override(S.HEART_STRIKE)
end

ns.rules[250] = {
  {
    key = "boneshield",
    name = "Bone Shield refresh",
    spell = S.MARROWREND,
    desc = "Shows Marrowrend (or Death's Caress when low on runes) with about 5 seconds of Bone Shield left.",
    -- The highlight refreshes Bone Shield by stack count only, so it often lets the 30s
    -- timer run out (Bone Shield ~90% uptime instead of 100%). We time it from your casts.
    check = function(ctx)
      if not ctx.inCombat or not ctx.knows(S.MARROWREND) then return end
      if ctx.next == S.MARROWREND or ctx.next == S.DEATHS_CARESS then return end
      local a, b = ctx.lastCast[S.MARROWREND], ctx.lastCast[S.DEATHS_CARESS]
      local last = (a and b) and math.max(a, b) or a or b
      if not last then return end
      local age = ctx.now - last
      if age < BONE_SHIELD_REFRESH or age > BONE_SHIELD_DURATION + 5 then return end
      if ctx.runes and ctx.runes < 2 and ctx.knows(S.DEATHS_CARESS) then
        return { spell = S.DEATHS_CARESS, text = "Refresh Bone Shield", sub = "Death's Caress (low on runes)" }
      end
      return { spell = S.MARROWREND, text = "Refresh Bone Shield", sub = "Marrowrend before it expires" }
    end,
  },
  {
    key = "rpcap",
    name = "Death Strike at runic power cap",
    spell = S.DEATH_STRIKE,
    desc = "Shows Death Strike within 20 runic power of max.",
    -- Optimal spends Death Strike within 20 runic power of max; the highlight wastes 7-12% in AoE.
    check = function(ctx)
      local p = ctx.power
      if not p or ctx.next == S.DEATH_STRIKE then return end
      if p < (ctx.powerMax or 100) - 20 then return end
      return { spell = S.DEATH_STRIKE, text = "Death Strike", sub = ("Runic power %d, don't cap"):format(p) }
    end,
  },
  {
    key = "bloodboil",
    name = "Blood Boil charges",
    spell = S.BLOOD_BOIL,
    desc = "Shows Blood Boil instead of Heart Strike whenever a charge is available.",
    -- The highlight only casts Blood Boil to apply Blood Plague (7-13 casts vs 52-56 optimal).
    -- Use a charge instead of Heart Strike whenever one is available.
    check = function(ctx)
      if not isHeartStrike(ctx, ctx.next) then return end
      if ctx.inMelee == false then return end -- Blood Boil hits within 10 yards
      local c = ctx.charges(S.BLOOD_BOIL)
      if not c or c < 1 then return end
      return { spell = S.BLOOD_BOIL, text = "Blood Boil", sub = "Use the charge instead of Heart Strike" }
    end,
  },
}

---------------------------------------------------------------------------
-- Frost Death Knight (spec 251)
---------------------------------------------------------------------------
ns.rules[251] = {
  {
    key = "erwrange",
    name = "Empower Rune Weapon out of range",
    spell = S.EMPOWER_RUNE_WEAPON,
    desc = "Grays Empower Rune Weapon out and tints it red until you're in melee.",
    -- Pillar's highlight rule needs the target within 8 yards; Empower Rune Weapon's has no
    -- range check, so it gets suggested while you're still running in. Don't waste it.
    check = function(ctx)
      if ctx.next ~= S.EMPOWER_RUNE_WEAPON then return end
      if ctx.inMelee ~= false then return end -- only when the range check clearly says "out of range"
      -- wait = true: the next-cast icon keeps showing Empower Rune Weapon, tinted red.
      return { spell = S.PILLAR_OF_FROST, wait = true,
               text = "Wait: get in melee", sub = "Then Empower Rune Weapon + Pillar of Frost" }
    end,
  },
  {
    key = "frostscythe",
    name = "Frostscythe on 3 targets",
    spell = S.FROSTSCYTHE,
    desc = "Shows Frostscythe instead of Obliterate at exactly 3 targets.",
    -- The highlight's Frostscythe rule only starts above 3 enemies.
    check = function(ctx)
      if ctx.enemies ~= 3 then return end
      if ctx.next ~= S.OBLITERATE then return end
      if not ctx.knows(S.FROSTSCYTHE) then return end
      return { spell = S.FROSTSCYTHE, text = "Frostscythe", sub = "3 targets: Frostscythe instead of Obliterate" }
    end,
  },
}

---------------------------------------------------------------------------
-- Openers: the first casts of SimC's optimal single-target rotation (patch 12.1.5,
-- SimC's default build for the spec). Steps for spells you don't know are skipped.
-- skipIfPet = skip this step when your pet is already out.
-- waitForMelee = on the next-cast icon, gray this step out until your target is in melee range.
---------------------------------------------------------------------------
ns.openers = {}
ns.openers[251] = {                     -- Frost
  { id = S.EMPOWER_RUNE_WEAPON, waitForMelee = true }, -- don't press while running in
  { id = S.PILLAR_OF_FROST, waitForMelee = true },
  { id = 439843 },                      -- Reaper's Mark (Deathbringer)
  { id = S.BREATH },
  { id = S.OBLITERATE },
  { id = 279302 },                      -- Frostwyrm's Fury
  { id = S.OBLITERATE },
  { id = S.OBLITERATE },
  { id = S.OBLITERATE },
}
ns.openers[252] = {                     -- Unholy
  { id = 46584, skipIfPet = true },     -- Raise Dead (before the pull)
  { id = S.OUTBREAK },
  { id = S.FESTERING_STRIKE },
  { id = S.FESTERING_STRIKE },
  { id = 42650 },                       -- Army of the Dead
  { id = S.DARK_TRANSFORMATION },
  { id = S.PUTREFY },
  { id = S.DEATH_COIL },
  { id = S.PUTREFY },
  { id = S.DEATH_COIL },
}

ns.openers[250] = {                     -- Blood
  { id = S.DEATHS_CARESS },             -- before the pull (ranged; applies Bone Shield)
  { id = 46585, skipIfPet = true },     -- Raise Dead
  { id = S.MARROWREND },
  { id = S.MARROWREND },
  { id = S.BLOOD_BOIL },
  { id = S.DEATH_AND_DECAY },
  { id = S.BLOOD_BOIL },
  { id = S.HEART_STRIKE },
  { id = S.DEATH_STRIKE },
}

---------------------------------------------------------------------------
-- Cooldowns the in-game highlight never suggests: missing from the spec's Assisted Combat
-- list, or in it but marked "automation only" (SimC: "This is for Blizzard automation").
-- Each entry becomes a rule that puts the spell on the next-cast icon (bare icon, gold
-- border) while it's ready. Ready = the game said so out of combat; in combat, where
-- cooldowns are hidden, timed from your own last cast.
--
--   after      (per spec) key of the rule these go after; nil = before all other rules
--   key, name  rule key for /ac toggle, and its name in /ac rules
--   spell      spell ID
--   cooldown   seconds, game data. Only used to time it from your cast while combat hides the
--              real cooldown; talents that shorten it make the icon come back late, never early.
--   when(ctx)  optional extra condition
--   anytime    true = also out of combat (default: in combat only)
--
-- Checked against simc/ActionPriorityLists/assisted_combat/*.simc (game build 12.1.5.70688):
--   Frost:  Breath (automation only), Raise Dead (missing). Optimal: Breath during Pillar,
--           Raise Dead on cooldown.
--   Blood:  Vampiric Blood, Raise Dead (both missing; no defensive is in the list).
--           Optimal: both on cooldown.
--   Unholy: none (Raise Dead is its permanent pet, in the list).
--   Devastation: none. Dragonrage, Tip the Scales, Deep Breath, Fire Breath and Eternity
--           Surge are all in the list, with no automation-only entries. Its gaps are
--           conditions and button overrides (see docs/NEXT_STEPS.md, step 2).
---------------------------------------------------------------------------
ns.readyCooldowns = {
  [251] = {                                                  -- Frost
    after = "erwrange",
    {
      key = "breath", name = "Breath of Sindragosa", spell = S.BREATH,
      desc = "Shows Breath of Sindragosa during Pillar of Frost when it's ready. The in-game highlight never suggests it.",
      cooldown = 90, -- game data (1249658)
      anytime = true, -- the Pillar window already limits it
      -- Right after Pillar of Frost, once per Pillar.
      when = function(ctx)
        local pillar = ctx.lastCast[S.PILLAR_OF_FROST]
        if not pillar or ctx.now - pillar > PILLAR_DURATION then return false end
        local breath = ctx.lastCast[S.BREATH]
        return not (breath and breath >= pillar)
      end,
    },
    { key = "raisedead", name = "Raise Dead", spell = S.RAISE_DEAD, cooldown = 120 }, -- game data (46585)
  },
  [250] = {                                                  -- Blood
    after = "boneshield",
    { key = "vampiricblood", name = "Vampiric Blood", spell = S.VAMPIRIC_BLOOD, cooldown = 90 }, -- game data (55233)
    { key = "raisedead", name = "Raise Dead", spell = S.RAISE_DEAD, cooldown = 120 },
  },
}

-- true when the spell is off cooldown: the game's answer (read out of combat) if we have one,
-- else timed from your last cast this session (never cast = ready).
local function cooldownReady(ctx, spell, cooldown)
  local cd = ctx.onCooldown(spell)
  if cd ~= nil then return not cd end
  local last = ctx.lastCast[spell]
  return not last or ctx.now - last >= cooldown
end
ns.cooldownReady = cooldownReady

local function readyCooldownRule(entry)
  return {
    key = entry.key,
    name = entry.name .. " ready",
    spell = entry.spell,
    desc = entry.desc or ("Shows " .. entry.name .. " when it's ready. The in-game highlight never suggests it."),
    check = function(ctx)
      if not ctx.knows(entry.spell) then return end
      if not entry.anytime and not ctx.inCombat then return end
      if ctx.next == entry.spell then return end -- the highlight already says it
      if entry.when and not entry.when(ctx) then return end
      if not cooldownReady(ctx, entry.spell, entry.cooldown) then return end
      return { spell = entry.spell, iconOnly = true, text = entry.name, sub = "Ready" }
    end,
  }
end

-- Spells whose cooldowns rules need (read out of combat, remembered through combat).
-- The cooldown-ready spells are added below.
ns.trackCooldowns = {
  [251] = { S.PILLAR_OF_FROST },
}

for spec, list in pairs(ns.readyCooldowns) do
  local rules = ns.rules[spec] or {}
  ns.rules[spec] = rules
  local at = 1
  if list.after then
    for i, rule in ipairs(rules) do
      if rule.key == list.after then at = i + 1 end
    end
  end
  ns.trackCooldowns[spec] = ns.trackCooldowns[spec] or {}
  for k, entry in ipairs(list) do
    table.insert(rules, at + k - 1, readyCooldownRule(entry))
    table.insert(ns.trackCooldowns[spec], entry.spell)
  end
end

-- Charges counted from your own casts (hidden in combat). recharge = seconds per charge.
ns.chargeTrack = {
  [250] = { [S.BLOOD_BOIL] = { max = 2, recharge = 7.5 } }, -- game data: 2 charges, 7.5s, not hasted
}

-- Max runic power when the game won't say (UnitPowerMax can be hidden). Blood is 115,
-- +10 with Ossuary (219786) = 125 (confirmed in game and in SimC's Blood profile).
ns.powerMaxFallback = {
  [250] = function(knows) return 115 + (knows(219786) and 10 or 0) end,
}

-- Specs the options menu lists, grouped by class (in this order). The game's own names are
-- used when it gives them (GetSpecializationInfoByID); these are the fallbacks.
ns.specInfo = {
  { id = 250, class = "DEATHKNIGHT", className = "Death Knight", name = "Blood" },
  { id = 251, class = "DEATHKNIGHT", className = "Death Knight", name = "Frost" },
  { id = 252, class = "DEATHKNIGHT", className = "Death Knight", name = "Unholy" },
}

-- Spec-specific settings shown under the spec in the options menu (db keys, checkboxes).
ns.specOptions = {
  [250] = { { key = "healthIcon", name = "Low-health Death Strike icon", spell = S.DEATH_STRIKE,
              desc = "A separate Death Strike icon that fades in as your health drops (/ac hp sets the thresholds)." } },
  [251] = { { key = "cooldownReminder", name = "Trinket, potion and racial reminder", spell = S.PILLAR_OF_FROST,
              desc = "Text under the icon for 4 seconds after Pillar of Frost." } },
}

-- Melee spell used for "is my target in melee range?"
ns.meleeSpell = {
  [250] = S.HEART_STRIKE,
  [251] = S.OBLITERATE,
  [252] = S.SCOURGE_STRIKE,
}

-- Low-health icon: fades in as your health drops (the game evaluates your hidden health).
ns.healthIcon = {
  [250] = { spell = S.DEATH_STRIKE },
}

-- Secondary reminder shown under the main alert (never replaces it).
ns.reminders = {}
ns.reminders[251] = function(ctx)
  if not ctx.db.cooldownReminder then return end
  local pillar = ctx.lastCast[S.PILLAR_OF_FROST]
  if pillar and ctx.now - pillar <= 4 then
    return "Pillar: use trinkets, potion and racial"
  end
end

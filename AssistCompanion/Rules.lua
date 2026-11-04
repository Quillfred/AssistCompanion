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
  -- Blood
  MARROWREND          = 195182,
  DEATHS_CARESS       = 195292,
  DEATH_STRIKE        = 49998,
  BLOOD_BOIL          = 50842,
  HEART_STRIKE        = 206930,
  RUNE_STRIKE         = 316239, -- the highlight's data uses this ID; Heart Strike replaces it
  DEATH_AND_DECAY     = 43265,
}
ns.S = S

local PILLAR_DURATION = 12   -- seconds (game data: Pillar of Frost id 51271)
local BREATH_COOLDOWN = 120  -- seconds (game data); only used to avoid nagging while it's on cooldown

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
    key = "breath",
    name = "Breath of Sindragosa",
    -- The in-game highlight never suggests Breath. Press it right after Pillar of Frost.
    check = function(ctx)
      if not ctx.knows(S.BREATH) then return end
      local pillar = ctx.lastCast[S.PILLAR_OF_FROST]
      if not pillar or ctx.now - pillar > PILLAR_DURATION then return end
      local breath = ctx.lastCast[S.BREATH]
      if breath and breath >= pillar then return end                       -- already used this window
      local cd = ctx.onCooldown(S.BREATH)                                  -- read from the game out of combat
      if cd == true then return end
      if cd == nil and breath and ctx.now - breath < BREATH_COOLDOWN then return end -- fallback: our own timing
      return { spell = S.BREATH, iconOnly = true } -- just the 48x48 Breath icon, no text
    end,
  },
  {
    key = "frostscythe",
    name = "Frostscythe on 3 targets",
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

-- Spells whose cooldowns rules need (read out of combat, remembered through combat).
ns.trackCooldowns = {
  [251] = { S.BREATH, S.PILLAR_OF_FROST },
}

-- Charges counted from your own casts (hidden in combat). recharge = seconds per charge.
ns.chargeTrack = {
  [250] = { [S.BLOOD_BOIL] = { max = 2, recharge = 7.5 } }, -- game data: 2 charges, 7.5s, not hasted
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

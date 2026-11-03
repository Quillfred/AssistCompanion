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
      if breath and ctx.now - breath < BREATH_COOLDOWN then return end     -- still on cooldown
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
---------------------------------------------------------------------------
ns.openers = {}
ns.openers[251] = {                     -- Frost
  { id = S.EMPOWER_RUNE_WEAPON },
  { id = S.PILLAR_OF_FROST },
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

-- Secondary reminder shown under the main alert (never replaces it).
ns.reminders = {}
ns.reminders[251] = function(ctx)
  if not ctx.db.cooldownReminder then return end
  local pillar = ctx.lastCast[S.PILLAR_OF_FROST]
  if pillar and ctx.now - pillar <= 4 then
    return "Pillar: use trinkets, potion and racial"
  end
end

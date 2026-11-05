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
  -- Augmentation Evoker
  EBON_MIGHT          = 395152,
  PRESCIENCE          = 409311,
  BREATH_OF_EONS      = 403631,
  DEEP_BREATH         = 357210, -- Breath of Eons replaces it (talent data)
  ERUPTION            = 395160,
  ERUPTION_2          = 1259172,
  FIRE_BREATH         = 357208,
  FIRE_BREATH_FOM     = 382266, -- with Font of Magic
  UPHEAVAL            = 396286,
  UPHEAVAL_FOM        = 408092,
  TIP_THE_SCALES      = 370553,
  TIME_SKIP           = 404977,
  TEMPORAL_BURST      = 431695, -- Chronowarden
  CLEAR_EMPOWER_COOLDOWN = 397374,
  ACCRETION           = 407876,
  MASTERY_TIMEWALKER  = 406380,
  -- talents that change timings (game data values in the comments where they're used)
  TOMORROW_TODAY      = 412723,
  INSTABILITY_MATRIX  = 431484,
  INTERWOVEN_THREADS  = 412713,
  DREAM_OF_SPRING     = 414969,
  EMERALD_BLOSSOM     = 355913,
  NOZDORMU_ADEPT      = 431715,
  OVERLORD            = 410260,
  WINGLEADER          = 441206,
  MASS_ERUPTION       = 438587, -- tooltip: "...your other helpful auras are increased by X%" -- each Eruption: Upheaval's remaining cooldown -1s (game data 411932)
  LIVING_FLAME        = 361469, -- Chrono Flames (431443) replaces it on the button for Chronowarden -- "[DNT] Clear Empower Cooldown": resets Fire Breath and Upheaval
  CHRONOBOON          = 1260484, -- Chronowarden: Tip the Scales' cooldown is shorter
  -- Devastation Evoker
  DISINTEGRATE        = 356995,
  PYRE                = 357211,
  AZURE_STRIKE        = 362969,
  AZURE_SWEEP         = 1265872, -- replaces Azure Strike on the button while its buff is up
  ETERNITY_SURGE      = 359073,
  ETERNITY_SURGE_FOM  = 382411, -- with Font of Magic
  DRAGONRAGE          = 375087,
  FONT_OF_MAGIC_DEV   = 411212, -- Devastation's Font of Magic: empowers get a 4th rank
  ETERNITYS_SPAN      = 375757, -- Eternity Surge hits twice as many targets per rank
  VOLATILITY          = 369089,
  FEED_THE_FLAMES     = 369846,
  MASS_DISINTEGRATE   = 436335, -- Scalecommander
  LEGACY_OF_THE_LIFEBINDER = 1264269, -- Flameshaper
  POWER_NEXUS         = 369908, -- +1 max essence
  DEEP_BREATH_STEER   = 433874, -- Deep Breath with Maneuverability (steerable)
  ONYX_LEGACY         = 386348, -- Deep Breath's cooldown -1 min
  MELT_ARMOR          = 441176, -- Scalecommander
  MANEUVERABILITY     = 433871, -- Scalecommander
  IMMINENT_DESTRUCTION = 370781,
}
ns.S = S

-- Devastation spell groups (used by the empower rank badge and the Devastation rules below)
local DEV_GENERATORS = { [S.LIVING_FLAME] = true, [S.AZURE_STRIKE] = true, [S.AZURE_SWEEP] = true }
local DEV_FIRE_BREATHS = { [S.FIRE_BREATH] = true, [S.FIRE_BREATH_FOM] = true }
local DEV_SURGES = { [S.ETERNITY_SURGE] = true, [S.ETERNITY_SURGE_FOM] = true }
local DRAGONRAGE_DURATION = 18 -- game data (375087)

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

-- The spell your button actually casts for `id` (talents replace some: Epidemic -> Graveyard,
-- Death Coil -> Necrotic Coil in the owner's build), so the icon matches your bar.
local function onButton(ctx, id)
  local o = ctx.override(id)
  if type(o) == "number" and o ~= 0 then return o end
  return id
end

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
    desc = "Shows Death Coil (1-3 targets) or Epidemic (4+) when runic power is about to cap. While the game hides runic power, the next-cast icon turns into Death Coil / Epidemic with a blue border whenever you're at the threshold in combat, unless the highlight already says Death Coil or Epidemic (the game decides when). Counting targets needs enemy nameplates on.",
    -- The highlight only spends runic power on procs, or when you're out of runes.
    check = function(ctx)
      local p = ctx.power
      if not p or p < ctx.db.unholyRP then return end
      if not isRuneSpender(ctx, ctx.next) then return end
      local n = ctx.enemies
      if n and n >= 4 and ctx.knows(S.EPIDEMIC) then
        return { spell = onButton(ctx, S.EPIDEMIC), text = "Spend: Epidemic", sub = ("Runic power %d"):format(p) }
      elseif n and n <= 3 then
        return { spell = onButton(ctx, S.DEATH_COIL), text = "Spend: Death Coil", sub = ("Runic power %d"):format(p) }
      end
      return {
        spell = onButton(ctx, S.DEATH_COIL),
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
    desc = "Shows Death Strike within 20 runic power of max. While the game hides runic power, the next-cast icon turns into Death Strike with a blue border instead (the game decides when).",
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
-- Augmentation Evoker (spec 1473)
--
-- Ebon Might's buff is hidden in combat, but everything that changes it is your own cast, so we
-- keep our own estimate of when it runs out (game data, Sands of Time 395153):
--   Ebon Might: 10s; recasting keeps up to 3s of what's left (pandemic, 30% of 10s)
--   Eruption +1s, empowered spells (Fire Breath, Upheaval) +2s, Breath of Eons / Deep Breath +5s
--   (Breath of Eons also grants 5s of Ebon Might if it isn't up)
-- Each extension has your crit chance to be 50% longer, which we can't see, so the estimate runs
-- a little short: the refresh reminder can come slightly early, never late.
---------------------------------------------------------------------------
local EM_DURATION, EM_PANDEMIC = 10, 0.3 -- base seconds; pandemic keeps up to 30% of the duration

-- What stretches Ebon Might for you (owner's screenshots, SimC): mastery (Timewalker) lengthens the
-- duration of your helpful auras, Ebon Might's base 10s included (13.8% -> 11.4s); and each Sands of
-- Time extension can crit for +50% (crit 20.6% -> extensions ~10% longer on average). Both read out
-- of combat: mastery from its tooltip, crit from your character. Re-running the owner's first log
-- with these puts the end at +34.7s, exactly when the highlight asked for Ebon Might (the old
-- estimate said +26s).
local emMod = { duration = 1, crit = 0, readAt = nil }
ns.ebonMightMods = emMod

local function readEbonMightMods(ctx)
  if ctx.inCombat or (emMod.readAt and ctx.now - emMod.readAt < 5) then return end
  emMod.readAt = ctx.now
  local d = ctx.description and ctx.description(S.MASTERY_TIMEWALKER)
  if d then
    local last -- the aura-duration bonus is the last percentage in the tooltip
    for num in d:gmatch("(%d+[%.,]?%d*)%s*%%") do last = num end
    local pct = last and tonumber((last:gsub(",", ".")))
    if pct and pct >= 0 and pct < 200 then emMod.duration = 1 + pct / 100 end
  end
  if GetSpellCritChance then
    local best
    for school = 2, 7 do -- spell schools; Augmentation's spells are several of them
      local ok, c = pcall(GetSpellCritChance, school)
      if ok and not (issecretvalue and issecretvalue(c)) and type(c) == "number" then
        best = math.max(best or 0, c)
      end
    end
    if best then emMod.crit = math.max(0, math.min(1, best / 100)) end
  end
end
local EM_REFRESH = 4     -- optimal refreshes with 40% (4s) left
local EM_COOLDOWN = 30   -- game data (395152)
local EM_HOLD = 6        -- hold an empower for Ebon Might if it's back within this many seconds
local GCD = 1.5
local EM_EXTEND = {
  [S.ERUPTION] = 1, [S.ERUPTION_2] = 1,
  [S.FIRE_BREATH] = 2, [S.FIRE_BREATH_FOM] = 2, [S.UPHEAVAL] = 2, [S.UPHEAVAL_FOM] = 2,
  [S.BREATH_OF_EONS] = 5, [S.DEEP_BREATH] = 5,
}
local ebonMight = { expires = 0 }
ns.ebonMight = ebonMight

local FIRE_BREATH_COOLDOWN = 30 -- game data (357208)
local UPHEAVAL_COOLDOWN = 40    -- game data (396286)
local FIRE_BREATH_IDS = { S.FIRE_BREATH, S.FIRE_BREATH_FOM }
local UPHEAVAL_IDS = { S.UPHEAVAL, S.UPHEAVAL_FOM }
local EBON_MIGHT_IDS = { S.EBON_MIGHT }
local FIRE_BREATHS = { [S.FIRE_BREATH] = true, [S.FIRE_BREATH_FOM] = true }
local UPHEAVALS = { [S.UPHEAVAL] = true, [S.UPHEAVAL_FOM] = true }
local EMPOWERS = { [S.FIRE_BREATH] = true, [S.FIRE_BREATH_FOM] = true, [S.UPHEAVAL] = true, [S.UPHEAVAL_FOM] = true }

---------------------------------------------------------------------------
-- Augmentation cooldowns in combat (hidden from addons). Timed from your casts, plus what speeds
-- them up (game data):
--   Time Skip (404977): cooldowns recover 10x as fast for its 2s channel (SimC models it as 10x)
--   Temporal Burst (431695, Chronowarden): after Tip the Scales, cooldown recovery +30%, fading to 0
--   over 30s in game data; the owner's tooltip says 34.1s, so it's read from the tooltip (above)
--   "[DNT] Clear Empower Cooldown" (397374): resets Fire Breath and Upheaval (owner's log: it fired
--   right after a Tip the Scales Fire Breath; both were ready again within 3s)
-- Empowered cooldowns also recover faster from things we can't see (the 4-piece set bonus during
-- Ebon Might, possibly haste), so we learn a factor from the highlight: the first time it suggests
-- Fire Breath or Upheaval after a cast, that spell is ready, which bounds how fast they recover.
---------------------------------------------------------------------------
local TS_SECONDS, TS_EXTRA = 2, 9        -- 10x recovery = 9 extra seconds per second
local TOMORROW_TODAY_EXTRA = 1           -- Tomorrow, Today: Time Skip channels 1s longer (412723: 1000 ms)
local INSTABILITY_AVG = 3                -- Instability Matrix: each empower -0..6s off its own cooldown (431484)
local INTERWOVEN_SCALE = 0.9             -- Interwoven Threads: your cooldowns -10% (412713)
local WINGLEADER_CUT = 1.5               -- Wingleader: Mass Eruption -1.5s Breath of Eons per target (441206)

-- Talents that change timings, refreshed every update (onCast has no ctx). Counts of enemies aren't
-- readable, so Overlord and Wingleader assume one target: the estimate can only run long, not short.
local tal = {}
local function readTalents(ctx)
  if not ctx.knows then return end
  tal.tomorrow = ctx.knows(S.TOMORROW_TODAY)
  tal.instability = ctx.knows(S.INSTABILITY_MATRIX)
  tal.interwoven = ctx.knows(S.INTERWOVEN_THREADS)
  tal.dreamOfSpring = ctx.knows(S.DREAM_OF_SPRING)
  tal.overlord = ctx.knows(S.OVERLORD)
  tal.wingleader = ctx.knows(S.WINGLEADER) and ctx.knows(S.MASS_ERUPTION)
end
ns.augTalents = tal

-- Interwoven Threads shortens every cooldown.
local function cdScale() return tal.interwoven and INTERWOVEN_SCALE or 1 end
ns.augCdScale = cdScale

-- Wingleader: Breath of Eons cooldown cuts from Mass Eruptions (the first Eruption after an empower).
local boeCuts = {}
local function wingleaderBetween(a, b)
  local x = 0
  for _, t in ipairs(boeCuts) do if t > a and t <= b then x = x + WINGLEADER_CUT end end
  return x
end
-- Temporal Burst's size and fade time: game data says 30% over 30s, but the in-game tooltip can say
-- otherwise (the owner's says 34.1s), so read both from the tooltip out of combat when we can.
local tb = { seconds = 30, max = 0.30, readAt = nil }
ns.temporalBurst = tb

local function readTemporalBurst(ctx)
  if ctx.inCombat or (tb.readAt and ctx.now - tb.readAt < 5) then return end
  tb.readAt = ctx.now
  local d = ctx.description and ctx.description(S.TEMPORAL_BURST)
  if not d then return end
  local pct = tonumber((d:match("(%d+[%.,]?%d*)%s*%%") or ""):gsub(",", ".") .. "")
  local last -- the duration is the last number in the text that isn't a percentage
  for num, after in d:gmatch("(%d+[%.,]?%d*)(%s*%%?)") do
    if not after:find("%%") then last = num end
  end
  local secs = last and tonumber((last:gsub(",", ".")))
  if pct and pct >= 5 and pct <= 100 then tb.max = pct / 100 end
  if secs and secs >= 10 and secs <= 90 then tb.seconds = secs end
end
local speedEvents = {}                   -- { kind = "ts" | "tb", t = time }
local aug = { empowerFactor = 1, empowerReset = 0, readyNow = {} }
ns.augCooldowns = aug

-- Extra seconds of recovery between a and b from Time Skip and Temporal Burst.
local function extraBetween(ctx, a, b)
  local x = 0
  local hasBurst = ctx.knows(S.TEMPORAL_BURST)
  for _, e in ipairs(speedEvents) do
    if e.kind == "ts" then
      local s, f = math.max(a, e.t), math.min(b, e.t + (e.dur or TS_SECONDS))
      if f > s then x = x + (f - s) * TS_EXTRA end
    elseif hasBurst then
      local s, f = math.max(a, e.t), math.min(b, e.t + tb.seconds)
      if f > s then
        -- bonus(u) = max * (1 - u / seconds), u = time since Tip the Scales
        local function F(t) local u = t - e.t return tb.max * (u - u * u / (2 * tb.seconds)) end
        x = x + F(f) - F(s)
      end
    end
  end
  return x
end

local function lastOfIds(ctx, ids)
  local t, which
  for _, id in ipairs(ids) do
    local c = ctx.lastCast[id]
    if c and (not t or c > t) then t, which = c, id end
  end
  return t, which
end

-- Accretion: seconds taken off Upheaval by Eruptions cast after `from`.
local eruptions = {}
local ACCRETION_PER_ERUPTION = 1 -- game data 411932: -1000 ms
local function accretionSince(ctx, from)
  if not ctx.knows(S.ACCRETION) then return 0 end
  local n = 0
  for _, t in ipairs(eruptions) do if t > from then n = n + 1 end end
  return n * ACCRETION_PER_ERUPTION
end

-- Seconds until one of these spells (the same ability's IDs) is ready. Once you've cast it this
-- session: timed from that cast with the speed-ups above (in combat the game's reads are hidden or
-- wrong; out of combat we take the game's read of the ID you cast). Before that: the game's read of
-- the spell on your button.
local function cooldownLeft(ctx, ids, cooldown, isEmpower)
  local last, castId = lastOfIds(ctx, ids)
  if not last then
    local onButton = (ctx.override and ctx.override(ids[1])) or ids[1]
    return (ctx.readyIn and ctx.readyIn(onButton)) or 0
  end
  if not ctx.inCombat then
    local r = ctx.readyIn and ctx.readyIn(castId)
    if r ~= nil then return r end
  end
  if aug.readyNow[ids[1]] and aug.readyNow[ids[1]] > last then return 0 end -- the highlight said so
  if isEmpower and aug.empowerReset > last then return 0 end
  local recovered = (ctx.now - last) + extraBetween(ctx, last, ctx.now)
  if isEmpower then recovered = recovered * aug.empowerFactor end
  if ids == UPHEAVAL_IDS then recovered = recovered + accretionSince(ctx, last) end
  if isEmpower and tal.instability then recovered = recovered + INSTABILITY_AVG end
  return math.max(0, cooldown * cdScale() - recovered)
end
ns.augCooldownLeft = cooldownLeft

-- Time Skip and Temporal Burst speed up every cooldown, so the cooldown-ready rules (Breath of Eons,
-- Tip the Scales, Time Skip) use them too.
ns.cooldownSpeedup = ns.cooldownSpeedup or {}
ns.cooldownSpeedup[1473] = function(ctx, a, b, spell)
  return extraBetween(ctx, a, b) + (spell == S.BREATH_OF_EONS and tal.wingleader and wingleaderBetween(a, b) or 0)
end
ns.cooldownScale = ns.cooldownScale or {}
ns.cooldownScale[1473] = cdScale

-- Called by Core.lua for each of your successful casts.
ns.onCast = function(spec, id, now)
  if spec ~= 1473 then return end
  local left = ebonMight.expires - now
  aug.undo = { id = id, expires = ebonMight.expires, tipConsumed = aug.tipConsumed, massPending = aug.massPending }
  local critMul = 1 + 0.5 * emMod.crit -- average with crits
  local ext = EM_EXTEND[id]
  if id == S.EMERALD_BLOSSOM and tal.dreamOfSpring then ext = 1 end -- Dream of Spring (414969): +1s
  if id == S.EBON_MIGHT then
    local duration = EM_DURATION * emMod.duration
    ebonMight.expires = now + duration + math.max(0, math.min(left, duration * EM_PANDEMIC))
  elseif id == S.BREATH_OF_EONS and left <= 0 then
    ebonMight.expires = now + ext * critMul
  elseif ext and left > 0 then
    ebonMight.expires = ebonMight.expires + ext * critMul
  end
  if id == S.BREATH_OF_EONS and tal.overlord then
    -- Overlord: Breath of Eons casts Eruption on the first (up to 3) enemies it hits. They aren't your
    -- casts, but each extends Ebon Might and counts for Accretion. One assumed (enemies unknown).
    ebonMight.expires = ebonMight.expires + EM_EXTEND[S.ERUPTION] * critMul
    eruptions[#eruptions + 1] = now
  end
  if tal.wingleader then
    if EMPOWERS[id] then aug.massPending = true                     -- the next Eruption is a Mass Eruption
    elseif (id == S.ERUPTION or id == S.ERUPTION_2) and aug.massPending then
      aug.massPending = false
      boeCuts[#boeCuts + 1] = now
      while boeCuts[1] and now - boeCuts[1] > 300 do table.remove(boeCuts, 1) end
    end
  end
  if id == S.TIME_SKIP then
    -- full channel until the game says it ended (ns.onChannelStop)
    speedEvents[#speedEvents + 1] = { kind = "ts", t = now, dur = TS_SECONDS + (tal.tomorrow and TOMORROW_TODAY_EXTRA or 0), open = true }
  end
  if id == S.TIP_THE_SCALES then
    speedEvents[#speedEvents + 1] = { kind = "tb", t = now }
    -- remember the previous cycle: this press proves Tip the Scales was ready (learned in onTick)
    aug.tipPress = { at = now, prevCast = aug.tipCast, prevConsumed = aug.tipConsumed }
    aug.tipCast, aug.tipConsumed = now, nil
  elseif EMPOWERS[id] and aug.tipCast and not aug.tipConsumed then
    aug.tipConsumed = now -- the first empower after Tip the Scales uses it up
  end
  if id == S.CLEAR_EMPOWER_COOLDOWN then aug.empowerReset = now end
  if id == S.ERUPTION or id == S.ERUPTION_2 then
    eruptions[#eruptions + 1] = now
    while eruptions[1] and now - eruptions[1] > 120 do table.remove(eruptions, 1) end
  end
  while speedEvents[1] and now - speedEvents[1].t > 600 do table.remove(speedEvents, 1) end
end

-- Learn from what the highlight suggests (called by Core.lua every update, before the rules).
local LEARN_AFTER = 3 -- the highlight keeps showing an empower for a moment after you cast it (owner's log)
local function learnEmpower(ctx, ids, cooldown)
  local last = lastOfIds(ctx, ids)
  if not last or aug.empowerReset > last then return end
  if ctx.now - last < LEARN_AFTER then return end -- still the cast you just made, not "ready again"
  if aug.readyNow[ids[1]] and aug.readyNow[ids[1]] > last then return end -- already learned for this cast
  aug.readyNow[ids[1]] = ctx.now
  local took = (ctx.now - last) + extraBetween(ctx, last, ctx.now)
  local needed = cooldown * cdScale() - (ids == UPHEAVAL_IDS and accretionSince(ctx, last) or 0)
      - (tal.instability and INSTABILITY_AVG or 0)
  if took > 1 and took < needed then
    -- ready no later than now: the real factor is at least this
    aug.empowerFactor = aug.blend(aug.empowerFactor, needed / took)
  end
end

-- A cancelled empower (Core.lua, UNIT_SPELLCAST_EMPOWER_STOP): undo what its cast did here.
-- Your channel ended (UNIT_SPELLCAST_CHANNEL_STOP / INTERRUPTED). Time Skip only speeds up
-- cooldowns while you channel it, and the channel can be much shorter than 2s: haste shortens it
-- (1.37s under Fury of the Aspects) and moving or another cast ends it (owner's raid log: one ended
-- the moment it started, but the addon had credited 18s of recovery). Returns the length, or nil.
ns.onChannelStop = function(spec, id, now)
  if spec ~= 1473 or id ~= S.TIME_SKIP then return end
  for i = #speedEvents, 1, -1 do
    local e = speedEvents[i]
    if e.kind == "ts" and e.open then
      e.open = nil
      e.dur = math.max(0, math.min(e.dur, now - e.t))
      return e.dur
    end
  end
end

ns.onCastCancelled = function(spec, id)
  if spec ~= 1473 then return end
  local u = aug.undo
  if not u or u.id ~= id then return end
  ebonMight.expires = u.expires    -- no Ebon Might extension
  aug.tipConsumed = u.tipConsumed  -- Tip the Scales still waiting
  aug.massPending = u.massPending  -- no Mass Eruption from it
  aug.undo = nil
end

-- Learned factors: a new reading is averaged with the old one, and readings beyond the plausible
-- range are dropped instead of capped (owner's log: a cancelled Fire Breath read as "4s cooldown").
local FACTOR_MAX = 1.6
-- Tip the Scales' learned speed can only be learned upward from presses (an early press proves it
-- recovered faster; a late one proves nothing), so it ratchets. Capped: the owner's L'ura log had it
-- at 1.04 and Tip shown ~1.5s before it was ready; 1.02 fits the logs. A press the game refuses
-- (not ready) steps it back down (ns.onCastFailed).
local TIP_FACTOR_MAX = 1.02
local TIP_FACTOR_STEP_DOWN = 0.01
local function blend(old, reading)
  if reading > FACTOR_MAX then return old end
  return (old + math.max(1, reading)) / 2
end
aug.blend = blend

ns.onTick = ns.onTick or {}
-- Learned factors are saved with your settings (db.augLearned), so a session starts calibrated
-- (owner's log: the first Upheaval of a session came ~5s before the uncorrected estimate). They're
-- reset when the talents they depend on change.
local function learnedSignature(ctx)
  return (ctx.knows(S.ACCRETION) and "A" or "-") .. (ctx.knows(S.CHRONOBOON) and "C" or "-")
      .. (ctx.knows(S.TEMPORAL_BURST) and "T" or "-") .. (ctx.knows(S.TOMORROW_TODAY) and "M" or "-")
      .. (ctx.knows(S.INSTABILITY_MATRIX) and "I" or "-") .. (ctx.knows(S.INTERWOVEN_THREADS) and "W" or "-")
end

local function syncLearned(ctx)
  local db = ctx.db
  if not db then return end
  -- Right after login the spellbook/talents may not be loaded yet; a wrong signature then would
  -- wipe the saved values. Wait until a baseline Augmentation spell is known.
  if not ctx.knows(S.EBON_MIGHT) then return end
  local sig = learnedSignature(ctx)
  local saved = db.augLearned
  if not aug.learnedLoaded then
    aug.learnedLoaded = true
    if saved and saved.sig == sig then
      aug.empowerFactor, aug.tipFactor = saved.empower or 1, math.min(saved.tip or 1, TIP_FACTOR_MAX)
    end
  elseif saved and saved.sig ~= sig then
    aug.empowerFactor, aug.tipFactor = 1, 1 -- talents changed: start over
  end
  if not saved or saved.sig ~= sig or saved.empower ~= aug.empowerFactor or saved.tip ~= aug.tipFactor then
    db.augLearned = { sig = sig, empower = aug.empowerFactor, tip = aug.tipFactor }
  end
end
aug.syncLearned = syncLearned

ns.onTick[1473] = function(ctx)
  readTalents(ctx)
  readTemporalBurst(ctx)
  readEbonMightMods(ctx)
  syncLearned(ctx)
  if ns.augLearnTip then ns.augLearnTip(ctx) end
  local n = ctx.next
  if not ctx.inCombat or not n then return end
  if FIRE_BREATHS[n] then learnEmpower(ctx, FIRE_BREATH_IDS, FIRE_BREATH_COOLDOWN) end
  if UPHEAVALS[n] then learnEmpower(ctx, UPHEAVAL_IDS, UPHEAVAL_COOLDOWN) end
  if n == S.EBON_MIGHT then
    -- The highlight only asks for Ebon Might once its buff is down: it's ready, and not running.
    aug.readyNow[S.EBON_MIGHT] = ctx.now
    if ebonMight.expires > ctx.now then ebonMight.expires = ctx.now end
  end
end

---------------------------------------------------------------------------
-- Tip the Scales (Icy Veins, Augmentation guide): its 2-minute cooldown starts when the buff is used
-- up, by an empowered spell or cancelled (/cancelaura macro), not when you press it. Chronoboon
-- (Chronowarden) takes 30s off (game data 1260484, -30000 ms). Time Skip / Temporal Burst speed it up.
-- With the "cancel macro" option (db.tipMacro): pair it with an empower that's ready within a global
-- cooldown, else use it on cooldown through the macro (Temporal Burst and Time Skip stay in sync).
-- Without it: as before, with Fire Breath when the highlight asks for it.
---------------------------------------------------------------------------
local TIP_COOLDOWN, CHRONOBOON_CDR = 120, 30
local TIP_CONSUME_WINDOW = 2 -- macro: an empower this soon after Tip used it; otherwise the macro cancelled it

-- waiting = pressed and its buff not used yet (its cooldown hasn't started); start = when it started.
-- When a Tip the Scales press's cooldown started: when an empower used the buff, or (macro option)
-- the press itself if no empower followed within the window. nil = still waiting, at time `now`.
local function tipStartOf(ctx, cast, consumed, now)
  local macro = ctx.db and ctx.db.tipMacro
  if consumed and (not macro or consumed - cast <= TIP_CONSUME_WINDOW) then return consumed end
  if macro and now - cast > TIP_CONSUME_WINDOW then return cast end
  return nil
end

local function tipState(ctx)
  local cast = ctx.lastCast[S.TIP_THE_SCALES]
  if not cast or aug.tipCast ~= cast then return false, nil end -- not pressed this pull
  local start = tipStartOf(ctx, cast, aug.tipConsumed, ctx.now)
  if start then return false, start end
  return true, nil
end

local function tipCooldown(ctx)
  return (TIP_COOLDOWN - (ctx.knows(S.CHRONOBOON) and CHRONOBOON_CDR or 0)) * cdScale()
end
aug.tipFactor = 1 -- learned from your presses: how much faster Tip the Scales really recovers

local function tipCooldownLeft(ctx)
  local waiting, start = tipState(ctx)
  if waiting then return math.huge end
  if not start then
    local r = ctx.readyIn and ctx.readyIn(S.TIP_THE_SCALES) -- read before the pull
    return r or 0
  end
  local recovered = ((ctx.now - start) + extraBetween(ctx, start, ctx.now)) * aug.tipFactor
  return math.max(0, tipCooldown(ctx) - recovered)
end

-- A press proves it was ready: if our estimate still had time left, it recovers faster than we
-- model (owner's log: ready ~5-10s before our estimate). Learn the ratio for next time.
local function learnTip(ctx)
  local p = aug.tipPress
  if not p then return end
  aug.tipPress = nil
  if not p.prevCast then return end
  local start = tipStartOf(ctx, p.prevCast, p.prevConsumed, p.at)
  if not start then return end
  local took = (p.at - start) + extraBetween(ctx, start, p.at)
  local cd = tipCooldown(ctx)
  if took > 5 and took * aug.tipFactor < cd - 0.5 then
    aug.tipFactor = math.min(TIP_FACTOR_MAX, aug.blend(aug.tipFactor, cd / took))
  end
end
ns.augLearnTip = learnTip

-- One of your casts failed (UNIT_SPELLCAST_FAILED). Tip the Scales refused while the addon thought it
-- was ready: the estimate runs fast, so step the learned speed back toward the game data. Returns a
-- note for the debug log, or nil.
ns.onCastFailed = function(spec, id, ctx)
  if spec ~= 1473 or id ~= S.TIP_THE_SCALES or not ctx then return end
  if tipState(ctx) then return end                      -- its buff is up: pressed again for the macro
  if tipCooldownLeft(ctx) > 0 then return end           -- the addon didn't think it was ready either
  local was = aug.tipFactor
  aug.tipFactor = math.max(1, aug.tipFactor - TIP_FACTOR_STEP_DOWN)
  return ("Tip the Scales not ready yet: learned speed %.2f -> %.2f"):format(was, aug.tipFactor)
end
ns.augTip = { state = tipState, cooldownLeft = tipCooldownLeft }

local tipRule = {
  key = "tipthescales",
  name = "Tip the Scales ready",
  spell = S.TIP_THE_SCALES,
  desc = "Shows Tip the Scales with Fire Breath (the in-game highlight never suggests it). With the cancel-macro option: "
      .. "with Fire Breath or Upheaval when one is ready within a global cooldown, otherwise on cooldown through your macro.",
  check = function(ctx)
    if not ctx.inCombat or not ctx.knows(S.TIP_THE_SCALES) or ctx.next == S.TIP_THE_SCALES then return end
    -- After the highlight's Prescience and Ebon Might, like Breath of Eons: the empower it pairs with
    -- should go out inside Ebon Might (owner's log: shown at the pull while Prescience was asked for).
    if ctx.next == S.PRESCIENCE or ctx.next == S.EBON_MIGHT then return end
    if tipCooldownLeft(ctx) > 0 then return end
    local fbSoon = FIRE_BREATHS[ctx.next] or cooldownLeft(ctx, FIRE_BREATH_IDS, FIRE_BREATH_COOLDOWN, true) <= GCD
    local upSoon = UPHEAVALS[ctx.next] or cooldownLeft(ctx, UPHEAVAL_IDS, UPHEAVAL_COOLDOWN, true) <= GCD
    if not ctx.db.tipMacro then
      if FIRE_BREATHS[ctx.next] then
        return { spell = S.TIP_THE_SCALES, text = "Tip the Scales", sub = "Then Fire Breath: instant, max rank" }
      end
      return
    end
    -- Chronowarden plays it with either empower; Scalecommander pairs it with Fire Breath.
    if fbSoon or (upSoon and ctx.knows(S.TEMPORAL_BURST)) then
      return { spell = S.TIP_THE_SCALES, note = "+ empower",
               text = "Tip the Scales", sub = "Then the empower: instant, max rank" }
    end
    return { spell = S.TIP_THE_SCALES, note = "macro",
             keySuffix = "x2", -- after the keybind: the /cancelaura line only works on a 2nd press
             text = "Tip the Scales (macro)", sub = "No empower ready: cancel it right away" }
  end,
}
ns.augTipRule = tipRule

ns.rules[1473] = {
  {
    key = "ebonmight",
    name = "Ebon Might refresh",
    spell = S.EBON_MIGHT,
    desc = "Shows Ebon Might when it's ready and has about 4 seconds left. The highlight only recasts it after it drops.",
    check = function(ctx)
      if not ctx.inCombat or not ctx.knows(S.EBON_MIGHT) then return end
      if ctx.next == S.EBON_MIGHT then return end
      local left = ebonMight.expires - ctx.now
      if left <= 0 or left > EM_REFRESH then return end -- dropped: the highlight asks for it itself
      if cooldownLeft(ctx, EBON_MIGHT_IDS, EM_COOLDOWN) > 0 then return end
      return { spell = S.EBON_MIGHT, text = "Refresh Ebon Might", sub = ("About %.0fs left"):format(left) }
    end,
  },
  {
    key = "ebonfirst",
    name = "Ebon Might before empowers",
    spell = S.EBON_MIGHT,
    desc = "When the highlight asks for Fire Breath or Upheaval but Ebon Might will have run out and comes back within "
        .. "about 6 seconds, holds the empower: Eruption or Chrono Flames to fill the wait, then Ebon Might, then the empower "
        .. "(empowers should go out inside Ebon Might, and they extend it). Also Ebon Might first when it's in its "
        .. "refresh window (about 4 seconds left) and back within a global cooldown.",
    check = function(ctx)
      if not ctx.inCombat or not ctx.knows(S.EBON_MIGHT) then return end
      if not EMPOWERS[ctx.next] then return end
      -- Only while it's still on cooldown: once it's ready, the highlight asks for it itself if the
      -- buff is down (so if it says an empower instead, the buff is still up).
      local cd = cooldownLeft(ctx, EBON_MIGHT_IDS, EM_COOLDOWN)
      if cd <= 0 or cd > EM_HOLD then return end
      local left = ebonMight.expires - ctx.now
      -- Still in its refresh window and back within a global cooldown: refresh it first, then the
      -- empower (owner's L'ura log: Fire Breath rank 3 shown with 3s of Ebon Might left and its
      -- cooldown 0.5s away; the refresh came half a second later and the breath was cancelled).
      local refreshFirst = left <= EM_REFRESH and cd <= GCD
      if left > cd + 0.5 and not refreshFirst then return end -- still up when Ebon Might is back
      if cd <= GCD then
        return { spell = S.EBON_MIGHT, text = "Ebon Might first", sub = "Then the empower, inside Ebon Might" }
      end
      -- More than a global cooldown to wait: fill it.
      local filler = ctx.usable(S.ERUPTION) and S.ERUPTION or (ctx.override(S.LIVING_FLAME) or S.LIVING_FLAME)
      return { spell = filler, text = "Hold the empower", sub = ("Ebon Might back in %.0fs"):format(cd) }
    end,
  },
  {
    key = "prescience",
    name = "Prescience charges",
    spell = S.PRESCIENCE,
    desc = "In a group, shows Prescience when both charges are ready. The highlight only casts it when none is active, so a charge sits capped.",
    check = function(ctx)
      if not ctx.inCombat or not ctx.inGroup or not ctx.knows(S.PRESCIENCE) then return end
      if ctx.next == S.PRESCIENCE then return end
      local c = ctx.charges(S.PRESCIENCE)
      if not c or c < 2 then return end
      return { spell = S.PRESCIENCE, text = "Prescience", sub = "Both charges ready: put one on a DPS ally" }
    end,
  },
}

-- Empower rank to hold Fire Breath / Upheaval to (the highlight never says). From SimC's optimal list:
--   Fire Breath: rank 1 while Upheaval is ready (get to Upheaval sooner), else rank 3
--   Upheaval: rank 1
--   right after Tip the Scales: none (the next empower is instant at max rank)
-- "Upheaval ready" allows 1.5s: a rank 1 Fire Breath takes about that long, so Upheaval is up after it.
local UPHEAVAL_SOON = 1.5
-- A rank 3 Fire Breath takes ~2-2.5s to charge. If Ebon Might ends before then, the breath lands
-- outside it and its +2s extension is lost; a quick rank 1 lands inside and extends it (owner's log:
-- rank 3 shown with ~1-2s of Ebon Might left).
local RANK3_TIME = 2.5

ns.empowerRank = {
  -- Devastation, from SimC's optimal list (es, fb_fs, fb_sc).
  [1467] = function(ctx, spell)
    local surge, breath = DEV_SURGES[spell], DEV_FIRE_BREATHS[spell]
    if not surge and not breath then return nil end
    -- Tip the Scales pressed since your last empower: the next one is instant at max rank.
    local tip = ctx.lastCast[S.TIP_THE_SCALES]
    if tip then
      local last = 0
      for id in pairs(DEV_FIRE_BREATHS) do last = math.max(last, ctx.lastCast[id] or 0) end
      for id in pairs(DEV_SURGES) do last = math.max(last, ctx.lastCast[id] or 0) end
      if tip > last then return nil end
    end
    local n = ctx.enemies
    if not n or n < 1 then return nil end
    local maxRank = ctx.knows(S.FONT_OF_MAGIC_DEV) and 4 or 3
    if surge then
      -- one target per rank, two with Eternity's Span: the lowest rank that hits them all
      local per = ctx.knows(S.ETERNITYS_SPAN) and 2 or 1
      return math.min(maxRank, math.ceil(n / per))
    end
    if ctx.knows(S.MASS_DISINTEGRATE) then -- Scalecommander (fb_sc): one rank per target, rank 1 on 5+
      if n > 4 then return 1 end
      return math.min(n, maxRank)
    end
    -- Flameshaper (fb_fs): rank 1 on one target (or when Pyre is the plan), 2 on two or in
    -- Dragonrage, else 3 (SimC: "R4 is just sort of bad for all cases")
    local usePyre = ctx.knows(S.LEGACY_OF_THE_LIFEBINDER)
      and (n >= 5 or (n >= 3 and (ctx.knows(S.VOLATILITY) or ctx.knows(S.FEED_THE_FLAMES))))
    if n == 1 or usePyre then return 1 end
    local rage = ctx.lastCast[S.DRAGONRAGE]
    if n == 2 or (rage and ctx.now - rage < DRAGONRAGE_DURATION) then return 2 end
    return 3
  end,
  [1473] = function(ctx, spell)
    if not FIRE_BREATHS[spell] and not UPHEAVALS[spell] then return nil end
    if (tipState(ctx)) then return nil end -- Tip the Scales is waiting: instant, max rank
    if UPHEAVALS[spell] then return 1 end
    local emLeft = ebonMight.expires - ctx.now
    if emLeft > 0 and emLeft < RANK3_TIME then return 1 end -- land it inside Ebon Might
    return cooldownLeft(ctx, UPHEAVAL_IDS, UPHEAVAL_COOLDOWN, true) <= UPHEAVAL_SOON and 1 or 3
  end,
}

-- Extra text for the once-a-second debug status line.
ns.debugStatus = {
  -- Devastation: es/fb = the ranks the badge would show (n = no badge); db = Deep Breath cooldown
  -- estimate; mass = Mass Disintegrate stacks; wl = seconds Wingleader has cut in the last 5 minutes
  [1467] = function(ctx)
    local f = ns.empowerRank[1467]
    local cut = 0
    for _, c in ipairs(ns.devState.cuts) do cut = cut + c.s end
    return ("es=%s fb=%s db=%.0f mass=%d wl=%.0f"):format(tostring(f(ctx, S.ETERNITY_SURGE) or "n"),
      tostring(f(ctx, S.FIRE_BREATH) or "n"), ns.devDeepBreathLeft(ctx), ns.devState.mass, cut)
  end,
  -- em = our Ebon Might estimate (seconds left); up/emcd = Upheaval / Ebon Might cooldown estimates;
  -- x = learned empower recovery factor; upb = the Upheaval ID on your button; tip = Tip the Scales
  -- cooldown estimate ("w" = pressed, buff not used yet); tx = learned Tip the Scales factor; haste %;
  -- emdur = Ebon Might duration multiplier from mastery; crit = crit % used for extension crits;
  -- ts / boe = Time Skip / Breath of Eons cooldown estimates
  [1473] = function(ctx)
    local waiting = ns.augTip.state(ctx)
    local haste = GetHaste and select(2, pcall(GetHaste))
    if issecretvalue and issecretvalue(haste) then haste = nil end
    return ("em=%.1f emcd=%.1f up=%.1f x=%.2f upb=%s tip=%s tx=%.2f haste=%s emdur=%.2f crit=%.0f ts=%.0f boe=%.0f"):format(
      math.max(0, ebonMight.expires - ctx.now),
      cooldownLeft(ctx, EBON_MIGHT_IDS, EM_COOLDOWN), cooldownLeft(ctx, UPHEAVAL_IDS, UPHEAVAL_COOLDOWN, true),
      aug.empowerFactor, tostring(ctx.override(S.UPHEAVAL)),
      waiting and "w" or ("%.1f"):format(ns.augTip.cooldownLeft(ctx)), aug.tipFactor,
      type(haste) == "number" and ("%.1f"):format(haste) or "?", emMod.duration, emMod.crit * 100,
      ns.cooldownLeft(ctx, S.TIME_SKIP, 180), ns.cooldownLeft(ctx, S.BREATH_OF_EONS, 120))
  end,
}

-- Logged at the start of each fight: which timing-related talents you have.
ns.debugTalents = {
  [1473] = function(knows)
    local list = {
      { S.ACCRETION, "Accretion" }, { S.TIME_SKIP, "Time Skip" }, { S.TOMORROW_TODAY, "Tomorrow, Today" },
      { S.INTERWOVEN_THREADS, "Interwoven Threads" }, { S.TEMPORAL_BURST, "Temporal Burst" },
      { S.CHRONOBOON, "Chronoboon" }, { S.INSTABILITY_MATRIX, "Instability Matrix" },
      { S.DREAM_OF_SPRING, "Dream of Spring" }, { S.NOZDORMU_ADEPT, "Nozdormu Adept" },
      { S.OVERLORD, "Overlord" }, { S.WINGLEADER, "Wingleader" }, { S.MASS_ERUPTION, "Mass Eruption" },
    }
    local have = {}
    for _, t in ipairs(list) do if knows(t[1]) then have[#have + 1] = t[2] end end
    return #have > 0 and table.concat(have, ", ") or "none of the timing talents"
  end,
}

-- Talent replacements the highlight's data doesn't know about: when it suggests the first spell and
-- you have the second, show the second (its button is the one you press).
ns.replacedBy = {
  [S.DEEP_BREATH] = S.BREATH_OF_EONS,
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

-- Devastation, from SimC's optimal list (Scalecommander list `sc`, Flameshaper list `fs`); Living
-- Flame is SimC's pre-pull cast. Scalecommander: Dragonrage, Eternity Surge, Tip the Scales into Fire
-- Breath, Deep Breath (with Melt Armor / Maneuverability, as in the Deep Breath rule), then the Mass
-- Disintegrate. Flameshaper: Dragonrage, Tip the Scales into
-- Eternity Surge (SimC: Tip during Dragonrage when Eternity Surge comes before Fire Breath), Fire
-- Breath, Disintegrate.
ns.openers[1467] = {
  { id = S.LIVING_FLAME },                                              -- before the pull
  { id = S.DRAGONRAGE },
  { id = S.TIP_THE_SCALES, without = S.MASS_DISINTEGRATE },             -- Flameshaper: Tip first
  { id = S.ETERNITY_SURGE, alt = S.ETERNITY_SURGE_FOM },
  { id = S.TIP_THE_SCALES, needs = S.MASS_DISINTEGRATE },               -- Scalecommander: Tip then Fire Breath
  { id = S.FIRE_BREATH, alt = S.FIRE_BREATH_FOM },
  { id = S.DEEP_BREATH, alt = S.DEEP_BREATH_STEER, needs = { S.MELT_ARMOR, S.MANEUVERABILITY } }, -- Scalecommander
  { id = S.DISINTEGRATE },
  { id = S.DISINTEGRATE, without = S.MASS_DISINTEGRATE },
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
--   Augmentation: Breath of Eons (not in the list; it replaces Deep Breath, which is, but the owner's
--           debug log shows the highlight doesn't suggest it either way). Tip the Scales and Time Skip
--           ARE in the list, but the same log shows the in-game highlight never suggests them.
--           Optimal: Breath of Eons on cooldown after Prescience and Ebon Might; Tip the Scales right
--           before Fire Breath; Time Skip when Breath of Eons is 15+ s away or Tip the Scales is on
--           cooldown (with Chronoboon only the latter).
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
  [1473] = {                                                 -- Augmentation
    after = "ebonfirst",
    {
      key = "breatheons", name = "Breath of Eons", spell = S.BREATH_OF_EONS,
      cooldown = 120, -- game data (403631)
      desc = "Shows Breath of Eons when it's ready, after the highlight's Ebon Might and Prescience. "
          .. "The highlight's list has Deep Breath, which Breath of Eons replaces; if it suggests that, the icon shows Breath of Eons.",
      when = function(ctx) return ctx.next ~= S.EBON_MIGHT and ctx.next ~= S.PRESCIENCE end,
    },
    ns.augTipRule, -- a full rule (Tip the Scales' cooldown starts when its buff is used up)
    {
      key = "timeskip", name = "Time Skip", spell = S.TIME_SKIP,
      cooldown = 180, -- game data (404977)
      desc = "Shows Time Skip once Fire Breath and Upheaval are spent, when Breath of Eons is 15+ seconds away "
          .. "or Tip the Scales is on cooldown (with Chronoboon: only then). The in-game highlight never suggests it.",
      when = function(ctx)
        local n = ctx.next
        -- after the highlight's Ebon Might, Prescience and empowers: only on filler
        if n == S.EBON_MIGHT or n == S.PRESCIENCE or n == S.FIRE_BREATH or n == S.FIRE_BREATH_FOM
            or n == S.UPHEAVAL or n == S.UPHEAVAL_FOM then
          return false
        end
        local tipWaiting = ns.augTip.state(ctx)
        local tipDown = ctx.knows(S.TIP_THE_SCALES) and not tipWaiting and ns.augTip.cooldownLeft(ctx) >= 6
        if tipDown and not tipWaiting then return true end
        if ctx.knows(S.CHRONOBOON) then return false end
        return not ctx.knows(S.BREATH_OF_EONS) or ns.cooldownLeft(ctx, S.BREATH_OF_EONS, 120) >= 15
      end,
    },
  },
  -- Devastation: the owner's debug log (2 min single target, then 5 targets) never had the highlight
  -- suggest Dragonrage, Tip the Scales or Deep Breath, though all three are in its list (as on
  -- Augmentation). Cooldowns from game data; SimC's optimal list for when.
  [1467] = {
    { key = "dragonrage", name = "Dragonrage", spell = S.DRAGONRAGE, cooldown = 120 }, -- game data (375087)
    {
      key = "devdeepbreath", name = "Deep Breath", spell = S.DEEP_BREATH,
      desc = "Shows Deep Breath when it's ready: on 2+ targets, or any time with Melt Armor, Maneuverability or "
          .. "Imminent Destruction (SimC's optimal list). The in-game highlight never suggests it. Counts Onyx Legacy "
          .. "(-1 min) and Wingleader (each Mass Disintegrate: -1s per target struck, up to 3).",
      check = function(ctx)
        if not ctx.inCombat then return end
        if not (ctx.knows(S.DEEP_BREATH) or ctx.knows(S.DEEP_BREATH_STEER)) then return end
        local n = ctx.next
        if n == S.DEEP_BREATH or n == S.DEEP_BREATH_STEER then return end -- the highlight already says it
        local always = ctx.knows(S.MELT_ARMOR) or ctx.knows(S.MANEUVERABILITY) or ctx.knows(S.IMMINENT_DESTRUCTION)
        if not always and not (ctx.enemies and ctx.enemies >= 2) then return end
        if ns.devDeepBreathLeft(ctx) > 0 then return end
        return { spell = S.DEEP_BREATH, iconOnly = true, text = "Deep Breath", sub = "Ready" }
      end,
    },
    {
      key = "devtip", name = "Tip the Scales", spell = S.TIP_THE_SCALES, cooldown = 120, -- game data (370553)
      desc = "Shows Tip the Scales when the highlight asks for Fire Breath and Tip is ready (the highlight's own rule, "
          .. "which it never shows in game): the Fire Breath is then instant at max rank.",
      when = function(ctx) return DEV_FIRE_BREATHS[ctx.next] end,
    },
  },
  [250] = {                                                  -- Blood
    after = "boneshield",
    { key = "vampiricblood", name = "Vampiric Blood", spell = S.VAMPIRIC_BLOOD, cooldown = 90 }, -- game data (55233)
    { key = "raisedead", name = "Raise Dead", spell = S.RAISE_DEAD, cooldown = 120 },
  },
}

-- true when the spell is off cooldown: the game's answer (read out of combat) if we have one,
-- else timed from your last cast this session (never cast = ready).
-- Seconds of cooldown recovered between two times, beyond the time itself, from effects the spec
-- tracks (ns.cooldownSpeedup[spec](ctx, from, to), e.g. Augmentation's Time Skip and Temporal Burst).
local function speedup(ctx, from, to, spell)
  local f = ns.cooldownSpeedup and ctx.spec and ns.cooldownSpeedup[ctx.spec]
  return f and f(ctx, from, to, spell) or 0
end

-- Cooldown multiplier from the spec's talents (ns.cooldownScale[spec](ctx), e.g. Interwoven Threads).
local function scaled(ctx, cooldown)
  local f = ns.cooldownScale and ctx.spec and ns.cooldownScale[ctx.spec]
  return cooldown * (f and f(ctx) or 1)
end

-- Seconds until the spell is ready (0 = ready): the game's answer (read out of combat) if we have
-- one, else timed from your last cast this session (never cast = ready).
local function cooldownLeft(ctx, spell, cooldown)
  local r = ctx.readyIn and ctx.readyIn(spell)
  if r ~= nil then return r end
  local last = ctx.lastCast[spell]
  if not last then return 0 end
  return math.max(0, scaled(ctx, cooldown) - (ctx.now - last) - speedup(ctx, last, ctx.now, spell))
end
ns.cooldownLeft = cooldownLeft

-- true when the spell is off cooldown (same sources; a second of grace on the game's answer).
local function cooldownReady(ctx, spell, cooldown)
  local cd = ctx.onCooldown(spell)
  if cd ~= nil then return not cd end
  local last = ctx.lastCast[spell]
  return not last or ctx.now - last + speedup(ctx, last, ctx.now, spell) >= scaled(ctx, cooldown)
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
  [1473] = { S.UPHEAVAL, S.UPHEAVAL_FOM, S.EBON_MIGHT }, -- Fire Breath rank, Ebon Might timing
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
    -- an entry with its own check is a full rule; otherwise build one from the template
    table.insert(rules, at + k - 1, entry.check and entry or readyCooldownRule(entry))
    table.insert(ns.trackCooldowns[spec], entry.spell)
  end
end

---------------------------------------------------------------------------
-- Devastation Evoker (spec 1467)
-- From the game's highlight rules (assisted_combat.inc) vs SimC's optimal list (docs/FINDINGS.md):
--   * essence waste 24% vs 8-12% optimal: the highlight keeps generating at max essence;
--   * Pyre only at 4+ targets (">3"), while Flameshaper builds with Volatility / Feed the Flames
--     want it at 3;
--   * it never says which rank to hold Fire Breath and Eternity Surge to.
-- Enemy counts come from nameplates (needs enemy nameplates on).
---------------------------------------------------------------------------

local function isGenerator(ctx, id)
  if not id then return false end
  return DEV_GENERATORS[id] or id == ctx.override(S.LIVING_FLAME) or id == ctx.override(S.AZURE_STRIKE)
end

-- Flameshaper Pyre at 3+ targets (SimC's use_pyre_fs: Legacy of the Lifebinder and Volatility or
-- Feed the Flames; Volatility's rank isn't readable, so any rank counts).
local function pyreAtThree(ctx)
  return ctx.knows(S.LEGACY_OF_THE_LIFEBINDER) and (ctx.knows(S.VOLATILITY) or ctx.knows(S.FEED_THE_FLAMES))
end

-- Essence spender for this many targets: Pyre at 4+ (like the highlight) or 3 (Flameshaper above).
local function devSpender(ctx)
  local n = ctx.enemies
  if ctx.knows(S.PYRE) and n and (n >= 4 or (n == 3 and pyreAtThree(ctx))) then return S.PYRE end
  return S.DISINTEGRATE
end

-- Deep Breath's cooldown, from your casts. Wingleader (441206, Scalecommander; Devastation uses effect 1:
-- 1000 ms): each Mass Disintegrate takes 1s per target struck off it. Mass Disintegrate (436335): each
-- empower gives a stack (its buff 436336); the next Disintegrate uses one and strikes up to 3 targets
-- (effect 1). Targets struck = the enemy count at that moment, capped at 3. (SimC sc_evoker.cpp:
-- empowers trigger mass_disintegrate_stacks; Disintegrate adjusts cooldown.deep_breath.)
local MASS_DISINTEGRATE_TARGETS, WINGLEADER_DEV_CUT = 3, 1.0
local dev = { mass = 0, cuts = {}, enemies = nil, undo = nil }
ns.devState = dev

function ns.devDeepBreathLeft(ctx)
  local cd = 120 - (ctx.knows(S.ONYX_LEGACY) and 60 or 0) -- game data (357210, 386348)
  local a, b = ctx.lastCast[S.DEEP_BREATH], ctx.lastCast[S.DEEP_BREATH_STEER]
  local last = (a and b) and math.max(a, b) or a or b
  if not last then
    local r = ctx.readyIn and ctx.readyIn(S.DEEP_BREATH)
    return r or 0
  end
  local cut = 0
  for _, c in ipairs(dev.cuts) do if c.t > last then cut = cut + c.s end end
  return math.max(0, cd - (ctx.now - last) - cut)
end

local augOnCast, augOnCancel = ns.onCast, ns.onCastCancelled
ns.onCast = function(spec, id, now)
  if spec ~= 1467 then return augOnCast(spec, id, now) end
  dev.undo = nil
  if DEV_FIRE_BREATHS[id] or DEV_SURGES[id] then
    if dev.hasMass then dev.mass = dev.mass + 1; dev.undo = id end
  elseif id == S.DISINTEGRATE and dev.mass > 0 then
    dev.mass = dev.mass - 1
    if dev.hasWingleader then
      local n = math.max(1, math.min(MASS_DISINTEGRATE_TARGETS, dev.enemies or 1))
      dev.cuts[#dev.cuts + 1] = { t = now, s = n * WINGLEADER_DEV_CUT }
      while dev.cuts[1] and now - dev.cuts[1].t > 300 do table.remove(dev.cuts, 1) end
    end
  end
end
ns.onCastCancelled = function(spec, id, now)
  if spec ~= 1467 then return augOnCancel(spec, id, now) end
  if dev.undo == id and dev.mass > 0 then dev.mass = dev.mass - 1 end -- a cancelled empower gives no stack
  dev.undo = nil
end

ns.onTick = ns.onTick or {}
ns.onTick[1467] = function(ctx)
  dev.hasMass = ctx.knows(S.MASS_DISINTEGRATE)
  dev.hasWingleader = ctx.knows(S.WINGLEADER)
  dev.enemies = ctx.enemies
  if not ctx.inCombat then dev.mass = 0 end
end

-- Added after the cooldown-ready rules (ns.readyCooldowns, which build ns.rules[1467] above):
-- the major cooldowns come first.
local devRules = {
  {
    key = "essencecap",
    name = "Essence cap",
    spell = S.DISINTEGRATE,
    desc = "Shows Disintegrate (Pyre on 4+ targets, or 3 with Flameshaper's Volatility / Feed the Flames) when your essence is full and the highlight asks for Living Flame or Azure Strike. The highlight keeps building essence at max (24% wasted vs 8-12%).",
    check = function(ctx)
      local p, max = ctx.power, ctx.powerMax
      if not p or not max or p < max then return end
      if not isGenerator(ctx, ctx.next) then return end
      local spell = devSpender(ctx)
      if ctx.usable(spell) == false then return end
      return { spell = spell, text = "Spend essence", sub = ("Essence %d/%d"):format(p, max) }
    end,
  },
  {
    key = "pyre3",
    name = "Pyre at 3 targets",
    spell = S.PYRE,
    desc = "Shows Pyre instead of Disintegrate at exactly 3 targets with Flameshaper (Legacy of the Lifebinder) and Volatility or Feed the Flames. The highlight only uses Pyre on 4+. Needs enemy nameplates on.",
    check = function(ctx)
      if ctx.enemies ~= 3 or ctx.next ~= S.DISINTEGRATE then return end
      if not ctx.knows(S.PYRE) or not pyreAtThree(ctx) then return end
      if ctx.usable(S.PYRE) == false then return end
      return { spell = S.PYRE, text = "Pyre", sub = "3 targets" }
    end,
  },
}
ns.rules[1467] = ns.rules[1467] or {}
for _, rule in ipairs(devRules) do table.insert(ns.rules[1467], rule) end

-- Charges counted from your own casts (hidden in combat). recharge = seconds per charge.
ns.chargeTrack = {
  -- game data: 2 charges, 12s; Nozdormu Adept -2s (431715: s3 = -2000 ms); Interwoven Threads -10%
  [1473] = { [S.PRESCIENCE] = { max = 2, recharge = function(knows)
    return (12 - (knows(S.NOZDORMU_ADEPT) and 2 or 0)) * (knows(S.INTERWOVEN_THREADS) and 0.9 or 1)
  end } },
  [250] = { [S.BLOOD_BOIL] = { max = 2, recharge = 7.5 } }, -- game data: 2 charges, 7.5s, not hasted
}

-- Max runic power when the game won't say (UnitPowerMax can be hidden). Blood is 115,
-- +10 with Ossuary (219786) = 125 (confirmed in game and in SimC's Blood profile).
ns.powerMaxFallback = {
  [250] = function(knows) return 115 + (knows(219786) and 10 or 0) end,
  [1467] = function(knows) return 5 + (knows(S.POWER_NEXUS) and 1 or 0) end, -- essence
}

-- Specs the options menu lists, grouped by class (in this order). The game's own names are
-- used when it gives them (GetSpecializationInfoByID); these are the fallbacks.
ns.specInfo = {
  { id = 250, class = "DEATHKNIGHT", className = "Death Knight", name = "Blood" },
  { id = 251, class = "DEATHKNIGHT", className = "Death Knight", name = "Frost" },
  { id = 252, class = "DEATHKNIGHT", className = "Death Knight", name = "Unholy" },
  { id = 1467, class = "EVOKER", className = "Evoker", name = "Devastation" },
  { id = 1473, class = "EVOKER", className = "Evoker", name = "Augmentation" },
}

-- Resource read into ctx.power, if not runic power (Enum.PowerType: Essence = 19).
ns.powerType = {
  [1467] = 19,
  [1473] = 19,
}

-- Spec-specific settings shown under the spec in the options menu (db keys, checkboxes).
ns.specOptions = {
  [250] = { { key = "healthIcon", name = "Low-health Death Strike icon", spell = S.DEATH_STRIKE,
              desc = "A separate Death Strike icon that fades in as your health drops (/ac hp sets the thresholds)." } },
  [251] = { { key = "cooldownReminder", name = "Trinket, potion and racial reminder", spell = S.PILLAR_OF_FROST,
              desc = "Text under the icon for 4 seconds after Pillar of Frost." } },
  [1467] = { { key = "empowerRank", name = "Empower rank on the icon", spell = S.FIRE_BREATH,
               desc = "A number on Fire Breath and Eternity Surge saying which rank to hold them to, from the number of enemies (SimC's optimal list): Eternity Surge hits one target per rank (two with Eternity's Span); Fire Breath by targets, hero talents and Dragonrage. Hidden after Tip the Scales (instant, max rank) and when the enemy count is unknown (needs enemy nameplates on). Shared with Augmentation's setting." } },
  [1473] = { { key = "tipMacro", name = "I use a Tip the Scales cancel macro", spell = S.TIP_THE_SCALES,
               desc = "For a /cast Tip the Scales + /cancelaura Tip the Scales macro (Icy Veins, Chronowarden with Time Skip). "
                   .. "On: Tip the Scales with an empower ready within a global cooldown (note \"+ empower\": press plain Tip the Scales), "
                   .. "otherwise on cooldown (note \"macro\": press your macro). Off: with Fire Breath, as before." },
             { key = "empowerRank", name = "Empower rank on the icon", spell = S.FIRE_BREATH,
               desc = "A number on Fire Breath and Upheaval saying which rank to hold them to: Fire Breath 1 while Upheaval is ready, else 3; Upheaval 1. Hidden right after Tip the Scales (instant, max rank)." } },
}

-- Melee spell used for "is my target in melee range?"
ns.meleeSpell = {
  [250] = S.HEART_STRIKE,
  [251] = S.OBLITERATE,
  [252] = S.SCOURGE_STRIKE,
}

-- Spell whose range decides which nearby enemies count (Core.lua countEnemies), when it isn't the
-- melee spell above. Augmentation: Eruption (25 yd).
ns.countRangeSpell = {
  [1467] = S.DISINTEGRATE, -- 25 yd
  [1473] = S.ERUPTION,
}

-- Low-health icon: fades in as your health drops (the game evaluates your hidden health).
ns.healthIcon = {
  [250] = { spell = S.DEATH_STRIKE },
}

-- Runic power layer (Core.lua): runic power is hidden from addons, so these rules' thresholds go
-- to the game as a curve, and a layer over the next-cast icon shows the spender at or above them. `rule` = the rule it
-- stands in for (its on/off toggle covers this icon), `when` = readable conditions,
-- `at` = runic power to show at.
ns.powerIcon = {
  [252] = {
    rule = "rpcap",
    -- Returns the spell to show (what's on your button) and the base spell to check you know.
    spell = function(ctx)
      if ctx.enemies and ctx.enemies >= 4 and ctx.knows(S.EPIDEMIC) then
        return onButton(ctx, S.EPIDEMIC), S.EPIDEMIC
      end
      return onButton(ctx, S.DEATH_COIL), S.DEATH_COIL
    end,
    -- Any time you're at the threshold, unless the highlight already asks to spend (owner: the
    -- rune-spender-only version flashed for a second at a time while the highlight sat on cooldowns).
    when = function(ctx)
      local n = ctx.next
      if not n then return true end
      return n ~= S.DEATH_COIL and n ~= S.EPIDEMIC
        and n ~= ctx.override(S.DEATH_COIL) and n ~= ctx.override(S.EPIDEMIC)
    end,
    at = function(ctx) return ctx.db.unholyRP end,
  },
  [250] = {
    rule = "rpcap",
    spell = S.DEATH_STRIKE,
    when = function(ctx) return ctx.next ~= S.DEATH_STRIKE end,
    at = function(ctx) return (ctx.powerMax or 100) - 20 end,
  },
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

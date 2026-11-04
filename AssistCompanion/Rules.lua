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
  LIVING_FLAME        = 361469, -- Chrono Flames (431443) replaces it on the button for Chronowarden -- "[DNT] Clear Empower Cooldown": resets Fire Breath and Upheaval
  CHRONOBOON          = 1260484, -- Chronowarden: Tip the Scales' cooldown is shorter
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
local EM_DURATION, EM_PANDEMIC = 10, 3
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
      local s, f = math.max(a, e.t), math.min(b, e.t + TS_SECONDS)
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
  local t
  for _, id in ipairs(ids) do
    local c = ctx.lastCast[id]
    if c and (not t or c > t) then t = c end
  end
  return t
end

-- Seconds until one of these spells (the same ability's IDs) is ready: the game's own answer if
-- we read one out of combat, else timed from your last cast with the speed-ups above.
local function cooldownLeft(ctx, ids, cooldown, isEmpower)
  -- Only the spell on your button (Font of Magic swaps it): the other ID reads as "ready" out of
  -- combat because you don't have it.
  local onButton = (ctx.override and ctx.override(ids[1])) or ids[1]
  local r = ctx.readyIn and ctx.readyIn(onButton)
  if r ~= nil then return r end
  local last = lastOfIds(ctx, ids)
  if not last then return 0 end
  if aug.readyNow[ids[1]] and aug.readyNow[ids[1]] > last then return 0 end -- the highlight said so
  if isEmpower and aug.empowerReset > last then return 0 end
  local recovered = (ctx.now - last) + extraBetween(ctx, last, ctx.now)
  if isEmpower then recovered = recovered * aug.empowerFactor end
  return math.max(0, cooldown - recovered)
end
ns.augCooldownLeft = cooldownLeft

-- Time Skip and Temporal Burst speed up every cooldown, so the cooldown-ready rules (Breath of Eons,
-- Tip the Scales, Time Skip) use them too.
ns.cooldownSpeedup = ns.cooldownSpeedup or {}
ns.cooldownSpeedup[1473] = extraBetween

-- Called by Core.lua for each of your successful casts.
ns.onCast = function(spec, id, now)
  if spec ~= 1473 then return end
  local left = ebonMight.expires - now
  if id == S.EBON_MIGHT then
    ebonMight.expires = now + EM_DURATION + math.max(0, math.min(left, EM_PANDEMIC))
  elseif id == S.BREATH_OF_EONS and left <= 0 then
    ebonMight.expires = now + EM_EXTEND[id]
  elseif EM_EXTEND[id] and left > 0 then
    ebonMight.expires = ebonMight.expires + EM_EXTEND[id]
  end
  if id == S.TIME_SKIP then speedEvents[#speedEvents + 1] = { kind = "ts", t = now } end
  if id == S.TIP_THE_SCALES then speedEvents[#speedEvents + 1] = { kind = "tb", t = now } end
  if id == S.CLEAR_EMPOWER_COOLDOWN then aug.empowerReset = now end
  while speedEvents[1] and now - speedEvents[1].t > 600 do table.remove(speedEvents, 1) end
end

-- Learn from what the highlight suggests (called by Core.lua every update, before the rules).
local function learnEmpower(ctx, ids, cooldown)
  local last = lastOfIds(ctx, ids)
  if not last or aug.empowerReset > last then return end
  if aug.readyNow[ids[1]] and aug.readyNow[ids[1]] > last then return end -- already learned for this cast
  aug.readyNow[ids[1]] = ctx.now
  local took = (ctx.now - last) + extraBetween(ctx, last, ctx.now)
  if took > 1 and took < cooldown then
    -- ready no later than now: the real factor is at least this (capped against odd cases)
    aug.empowerFactor = math.max(1, math.min(1.6, cooldown / took))
  end
end

ns.onTick = ns.onTick or {}
ns.onTick[1473] = function(ctx)
  readTemporalBurst(ctx)
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
        .. "(empowers should go out inside Ebon Might, and they extend it).",
    check = function(ctx)
      if not ctx.inCombat or not ctx.knows(S.EBON_MIGHT) then return end
      if not EMPOWERS[ctx.next] then return end
      -- Only while it's still on cooldown: once it's ready, the highlight asks for it itself if the
      -- buff is down (so if it says an empower instead, the buff is still up).
      local cd = cooldownLeft(ctx, EBON_MIGHT_IDS, EM_COOLDOWN)
      if cd <= 0 or cd > EM_HOLD then return end
      if ebonMight.expires - ctx.now > cd + 0.5 then return end -- still up when Ebon Might is back
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

ns.empowerRank = {
  [1473] = function(ctx, spell)
    if not FIRE_BREATHS[spell] and not UPHEAVALS[spell] then return nil end
    local tip = ctx.lastCast[S.TIP_THE_SCALES]
    if tip then
      local used = math.max(lastOfIds(ctx, FIRE_BREATH_IDS) or 0, lastOfIds(ctx, UPHEAVAL_IDS) or 0)
      if tip > used then return nil end -- Tip the Scales is waiting: instant, max rank
    end
    if UPHEAVALS[spell] then return 1 end
    return cooldownLeft(ctx, UPHEAVAL_IDS, UPHEAVAL_COOLDOWN, true) <= UPHEAVAL_SOON and 1 or 3
  end,
}

-- Extra text for the once-a-second debug status line.
ns.debugStatus = {
  -- em = our Ebon Might estimate (seconds left); up/emcd = Upheaval / Ebon Might cooldown estimates;
  -- x = learned empower recovery factor
  [1473] = function(ctx)
    return ("em=%.1f emcd=%.1f up=%.1f x=%.2f"):format(math.max(0, ebonMight.expires - ctx.now),
      cooldownLeft(ctx, EBON_MIGHT_IDS, EM_COOLDOWN), cooldownLeft(ctx, UPHEAVAL_IDS, UPHEAVAL_COOLDOWN, true),
      aug.empowerFactor)
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
    {
      key = "tipthescales", name = "Tip the Scales", spell = S.TIP_THE_SCALES,
      cooldown = 120, -- game data (370553); Chronoboon shortens it, so the icon may come back late
      desc = "Shows Tip the Scales when the highlight asks for Fire Breath and Tip the Scales is ready. "
          .. "The game's list has it right before Fire Breath, but the in-game highlight never suggests it.",
      when = function(ctx) return ctx.next == S.FIRE_BREATH or ctx.next == S.FIRE_BREATH_FOM end,
    },
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
        local tip = ctx.lastCast[S.TIP_THE_SCALES]
        local fb = math.max(ctx.lastCast[S.FIRE_BREATH] or 0, ctx.lastCast[S.FIRE_BREATH_FOM] or 0)
        local tipWaiting = tip and tip > fb
        local tipDown = ctx.knows(S.TIP_THE_SCALES) and ns.cooldownLeft(ctx, S.TIP_THE_SCALES, 120) >= 6
        if tipDown and not tipWaiting then return true end
        if ctx.knows(S.CHRONOBOON) then return false end
        return not ctx.knows(S.BREATH_OF_EONS) or ns.cooldownLeft(ctx, S.BREATH_OF_EONS, 120) >= 15
      end,
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
local function speedup(ctx, from, to)
  local f = ns.cooldownSpeedup and ctx.spec and ns.cooldownSpeedup[ctx.spec]
  return f and f(ctx, from, to) or 0
end

-- Seconds until the spell is ready (0 = ready): the game's answer (read out of combat) if we have
-- one, else timed from your last cast this session (never cast = ready).
local function cooldownLeft(ctx, spell, cooldown)
  local r = ctx.readyIn and ctx.readyIn(spell)
  if r ~= nil then return r end
  local last = ctx.lastCast[spell]
  if not last then return 0 end
  return math.max(0, cooldown - (ctx.now - last) - speedup(ctx, last, ctx.now))
end
ns.cooldownLeft = cooldownLeft

-- true when the spell is off cooldown (same sources; a second of grace on the game's answer).
local function cooldownReady(ctx, spell, cooldown)
  local cd = ctx.onCooldown(spell)
  if cd ~= nil then return not cd end
  local last = ctx.lastCast[spell]
  return not last or ctx.now - last + speedup(ctx, last, ctx.now) >= cooldown
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
    table.insert(rules, at + k - 1, readyCooldownRule(entry))
    table.insert(ns.trackCooldowns[spec], entry.spell)
  end
end

-- Charges counted from your own casts (hidden in combat). recharge = seconds per charge.
ns.chargeTrack = {
  [1473] = { [S.PRESCIENCE] = { max = 2, recharge = 12 } }, -- game data: 2 charges, 12s
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
  { id = 1473, class = "EVOKER", className = "Evoker", name = "Augmentation" },
}

-- Resource read into ctx.power, if not runic power (Enum.PowerType: Essence = 19).
ns.powerType = {
  [1473] = 19,
}

-- Spec-specific settings shown under the spec in the options menu (db keys, checkboxes).
ns.specOptions = {
  [250] = { { key = "healthIcon", name = "Low-health Death Strike icon", spell = S.DEATH_STRIKE,
              desc = "A separate Death Strike icon that fades in as your health drops (/ac hp sets the thresholds)." } },
  [251] = { { key = "cooldownReminder", name = "Trinket, potion and racial reminder", spell = S.PILLAR_OF_FROST,
              desc = "Text under the icon for 4 seconds after Pillar of Frost." } },
  [1473] = { { key = "empowerRank", name = "Empower rank on the icon", spell = S.FIRE_BREATH,
               desc = "A number on Fire Breath and Upheaval saying which rank to hold them to: Fire Breath 1 while Upheaval is ready, else 3; Upheaval 1. Hidden right after Tip the Scales (instant, max rank)." } },
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

-- Assist Companion: core. Reads the Assisted Highlight's suggestion and your own state,
-- runs the spec rules from Rules.lua, and shows:
--   * a "next cast" icon: the highlight's suggestion, replaced by a correction when a rule fires
--   * an opener bar before and at the start of a pull
--   * optional text alerts (off by default)
-- It never casts anything; you press every button.

local ADDON, ns = ...

local DEFAULTS = {
  point = { "CENTER", "UIParent", "CENTER", 0, -160 },       -- text alert box
  nextPoint = { "CENTER", "UIParent", "CENTER", 0, -100 },   -- next-cast icon
  openerPoint = { "CENTER", "UIParent", "CENTER", 0, -230 }, -- opener bar
  scale = 1.0,
  locked = true,
  iconSize = 48,           -- next-cast icon size in pixels
  nextIcon = true,         -- show the next-cast icon
  showMode = "always",     -- next-cast icon: "always", "target" (in combat or enemy targeted), "combat"
  showWhenDead = false,    -- keep everything on screen while dead or a ghost
  showText = false,        -- show text alerts as well (off: the icon carries the corrections)
  unholyRP = 80,           -- warn at or above this runic power when the highlight wants a rune spender
  cooldownReminder = true, -- Frost: trinkets/potion/racial reminder when Pillar goes out
  opener = true,           -- show the opening sequence before and at the start of a pull
  openerIcon = true,       -- the next-cast icon follows the opener while it's running
  gcdSwipe = true,         -- global cooldown swipe on the next-cast icon
  empowerRank = true,      -- empower rank badge on Fire Breath / Upheaval (Rules.lua: ns.empowerRank)
  healthIcon = true,       -- Blood: Death Strike icon that fades in as your health drops
  healthFull = 35,         -- health % at or below which it's fully visible
  healthNone = 50,         -- health % at or above which it's invisible
  healthPoint = { "CENTER", "UIParent", "CENTER", 60, -100 },
  disabled = {},           -- rules turned off, as "<specID>:<key>" (options menu or /ac toggle <key>)
  debug = false,
}

local db
local specID
local lastCast = {}
local knownCache = {}
local powerMaxCache
local RUNIC_POWER = (Enum and Enum.PowerType and Enum.PowerType.RunicPower) or 6

---------------------------------------------------------------------------
-- Secret-value safety. In Midnight, some APIs return "secret" values during combat
-- that addons can't compare. Treat those as unknown (nil) instead of erroring.
---------------------------------------------------------------------------
local function readable(v)
  if v == nil then return nil end
  if issecretvalue and issecretvalue(v) then return nil end
  return v
end

local function try(fn, ...)
  local ok, a, b = pcall(fn, ...)
  if not ok then return nil end
  return readable(a), readable(b)
end

---------------------------------------------------------------------------
-- Game state helpers
---------------------------------------------------------------------------
local function currentSpecID()
  local get = (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) or GetSpecialization
  local info = (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo) or GetSpecializationInfo
  if not get or not info then return nil end
  local index = try(get)
  if not index then return nil end
  return (try(info, index))
end

local function knows(id)
  local v = knownCache[id]
  if v == nil then
    v = false
    if C_SpellBook and C_SpellBook.IsSpellKnown then
      v = try(C_SpellBook.IsSpellKnown, id) and true or false
    end
    if not v and IsPlayerSpell then v = try(IsPlayerSpell, id) and true or false end
    knownCache[id] = v
  end
  return v
end

local function override(id)
  if not (C_Spell and C_Spell.GetOverrideSpell) then return nil end
  return (try(C_Spell.GetOverrideSpell, id))
end

local function nextSpell()
  if not (C_AssistedCombat and C_AssistedCombat.GetNextCastSpell) then return nil end
  return (try(C_AssistedCombat.GetNextCastSpell, false))
end

local function powerType()
  return (ns.powerType and specID and ns.powerType[specID]) or RUNIC_POWER
end

local function power()
  return (try(UnitPower, "player", powerType()))
end

local function cachePowerMax()
  local m = try(UnitPowerMax, "player", powerType())
  if m and m > 0 then powerMaxCache = m end
end

-- Max runic power: the game's number when readable (UnitPowerMax may be hidden even out of
-- combat), else the spec's known value from talents (Rules.lua: ns.powerMaxFallback), and
-- never less than the most runic power we've actually seen you hold.
local powerSeenMax = 0
local function effectiveMaxPower(current)
  if type(current) == "number" and current > powerSeenMax then powerSeenMax = current end
  local m = powerMaxCache
  if not m then
    local fb = ns.powerMaxFallback and specID and ns.powerMaxFallback[specID]
    m = (type(fb) == "function" and fb(knows)) or fb or 100
  end
  return math.max(m, powerSeenMax)
end

---------------------------------------------------------------------------
-- Cooldown tracking. Cooldowns are hidden from addons in combat, but readable out of
-- combat. We note when each tracked spell will be ready whenever we can read it, and keep
-- that answer through combat. readyAt[id] = GetTime() when ready (0 = ready now).
---------------------------------------------------------------------------
local readyAt = {}
local GCD_GRACE = 1.6 -- cooldowns this short are just the global cooldown

local function num(v) v = readable(v) return type(v) == "number" and v or nil end

local function snapshotCooldown(id)
  -- Charge spells (e.g. Empower Rune Weapon): ready if a charge is available.
  if C_Spell and C_Spell.GetSpellCharges then
    local ok, info = pcall(C_Spell.GetSpellCharges, id)
    if ok and type(info) == "table" and readable(info) then
      local cur, maxc = num(info.currentCharges), num(info.maxCharges)
      if cur and maxc and maxc > 1 then
        if cur > 0 then readyAt[id] = 0 return end
        local st, du = num(info.cooldownStartTime), num(info.cooldownDuration)
        if st and du then readyAt[id] = st + du end
        return
      end
    end
  end
  if C_Spell and C_Spell.GetSpellCooldown then
    local ok, info = pcall(C_Spell.GetSpellCooldown, id)
    if ok and type(info) == "table" and readable(info) then
      local st, du = num(info.startTime), num(info.duration)
      if st and du then
        if st == 0 or du <= GCD_GRACE then readyAt[id] = 0 else readyAt[id] = st + du end
      end
    end
  end
end

-- true = on cooldown, false = ready, nil = unknown. A second of grace so a spell coming
-- off cooldown right now still counts as ready.
local function onCooldown(id)
  local r = readyAt[id]
  if r == nil then return nil end
  return r - GetTime() > 1.0
end

-- Seconds until ready as the game last told us (0 = ready), or nil if we don't know.
local function readyIn(id)
  local r = readyAt[id]
  if r == nil then return nil end
  return math.max(0, r - GetTime())
end

-- Counts hostile, in-combat enemies with visible nameplates. Returns nil if the game
-- hides that information, so rules that need an exact count simply stay quiet.
local function countEnemies()
  if not (C_NamePlate and C_NamePlate.GetNamePlates) then return nil end
  local plates = try(C_NamePlate.GetNamePlates)
  if type(plates) ~= "table" then return nil end
  local n = 0
  for _, plate in ipairs(plates) do
    local unit = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
    if unit then
      local attack = try(UnitCanAttack, "player", unit)
      local combat = try(UnitAffectingCombat, unit)
      local dead = try(UnitIsDead, unit)
      if attack == nil or combat == nil then return nil end
      if attack and combat and not dead then n = n + 1 end
    end
  end
  return n
end

local function hostileTarget()
  return try(UnitExists, "target") and try(UnitCanAttack, "player", "target") and not try(UnitIsDead, "target")
end

local inCombat, combatStart = false, 0
local function combatOrTarget() return inCombat or hostileTarget() end

-- Should the next-cast icon be on screen right now? (db.showMode)
local function iconVisibleNow()
  if db.showMode == "combat" then return inCombat end
  if db.showMode == "target" then return combatOrTarget() end
  return true
end

-- Rule on/off, per spec (the same key, e.g. "raisedead", exists in several specs).
function ns.ruleEnabled(spec, key)
  return not (db and db.disabled[spec .. ":" .. key])
end
function ns.setRuleEnabled(spec, key, on)
  db.disabled[spec .. ":" .. key] = (not on) or nil
end

---------------------------------------------------------------------------
-- Debug log (/ac debug). Kept in saved variables, so WoW writes it to
-- WTF\Account\<ACCOUNT>\SavedVariables\AssistCompanion.lua on /reload or logout.
-- Chat echo is optional (/ac debug chat).
---------------------------------------------------------------------------
local LOG_MAX = 500
local function dlog(fmt, ...)
  if not db or not db.debug then return end
  local ok, msg = pcall(string.format, fmt, ...)
  if not ok then msg = tostring(fmt) end
  local stamp = date and date("%H:%M:%S") or ""
  local t = inCombat and string.format(" +%.1fs", GetTime() - combatStart) or ""
  local line = stamp .. t .. "  " .. msg
  db.debugLog = db.debugLog or {}
  local L = db.debugLog
  L[#L + 1] = line
  while #L > LOG_MAX do table.remove(L, 1) end
  if db.debugChat then print("|cff66ccffAC|r " .. line) end
end

-- Is the current target in melee range? Uses a melee spell of your spec (Rules.lua: ns.meleeSpell).
-- Returns nil when there's no hostile target or the game won't say.
local function inMelee()
  if not (C_Spell and C_Spell.IsSpellInRange) then return nil end
  if not hostileTarget() then return nil end
  local spell = ns.meleeSpell and specID and ns.meleeSpell[specID]
  if not spell then return nil end -- ranged spec: no melee check
  return (try(C_Spell.IsSpellInRange, spell, "target"))
end

local RUNES = (Enum and Enum.PowerType and Enum.PowerType.Runes) or 5
local function runes() return (try(UnitPower, "player", RUNES)) end

---------------------------------------------------------------------------
-- Charge tracking (Rules.lua: ns.chargeTrack). Charges are hidden in combat, so we read
-- them out of combat and then count your own casts against a fixed recharge time. Talents
-- that speed recharges up only make the real count higher, so this never claims a charge
-- you don't have.
---------------------------------------------------------------------------
local chargeState = {} -- id -> { charges, max, nextAt }

local function chargeInfo(id)
  local t = ns.chargeTrack and specID and ns.chargeTrack[specID] and ns.chargeTrack[specID][id]
  if not t then return nil end
  local st = chargeState[id]
  if not st then st = { charges = t.max, max = t.max, nextAt = nil }; chargeState[id] = st end
  return st, t
end

local function syncCharges()
  local list = ns.chargeTrack and specID and ns.chargeTrack[specID]
  if not list then return end
  local now = GetTime()
  for id, t in pairs(list) do
    local st = chargeInfo(id)
    -- Readable (usually out of combat)? Take the game's numbers.
    if C_Spell and C_Spell.GetSpellCharges then
      local ok, info = pcall(C_Spell.GetSpellCharges, id)
      if ok and type(info) == "table" and readable(info) then
        local cur, maxc = readable(info.currentCharges), readable(info.maxCharges)
        local cst, cdu = readable(info.cooldownStartTime), readable(info.cooldownDuration)
        if type(cur) == "number" and type(maxc) == "number" then
          st.charges, st.max = cur, maxc
          st.nextAt = (cur < maxc and type(cst) == "number" and type(cdu) == "number") and (cst + cdu) or nil
        end
      end
    end
    -- Otherwise advance our own count.
    while st.charges < st.max and st.nextAt and now >= st.nextAt do
      st.charges = st.charges + 1
      st.nextAt = (st.charges < st.max) and (st.nextAt + t.recharge) or nil
    end
  end
end

local function spendCharge(id)
  local st, t = chargeInfo(id)
  if not st then return end
  if st.charges >= st.max or not st.nextAt then st.nextAt = GetTime() + t.recharge end
  st.charges = math.max(0, st.charges - 1)
end

local function charges(id)
  local st = chargeInfo(id)
  return st and st.charges or nil
end

local function spellIcon(id)
  if C_Spell and C_Spell.GetSpellTexture then
    local t = try(C_Spell.GetSpellTexture, id)
    if t then return t end
  end
  return 134400 -- question mark
end

local function spellName(id)
  if not id then return "none" end
  if C_Spell and C_Spell.GetSpellName then
    local n = try(C_Spell.GetSpellName, id)
    if n then return n end
  end
  return tostring(id)
end

---------------------------------------------------------------------------
-- Keybinds: find the spell on Blizzard's action bars and read that button's key.
-- (Bar addons like Bartender/ElvUI use their own bindings; the icon then shows no key.)
---------------------------------------------------------------------------
local SLOT_BINDINGS = {
  { first = 1,   last = 12,  cmd = "ACTIONBUTTON" },
  { first = 25,  last = 36,  cmd = "MULTIACTIONBAR3BUTTON" },
  { first = 37,  last = 48,  cmd = "MULTIACTIONBAR4BUTTON" },
  { first = 49,  last = 60,  cmd = "MULTIACTIONBAR2BUTTON" },
  { first = 61,  last = 72,  cmd = "MULTIACTIONBAR1BUTTON" },
  { first = 145, last = 156, cmd = "MULTIACTIONBAR5BUTTON" },
  { first = 157, last = 168, cmd = "MULTIACTIONBAR6BUTTON" },
  { first = 169, last = 180, cmd = "MULTIACTIONBAR7BUTTON" },
}

local function shortKey(key)
  if not key then return nil end
  key = key:gsub("SHIFT%-", "S"):gsub("CTRL%-", "C"):gsub("ALT%-", "A"):gsub("META%-", "M")
  key = key:gsub("MOUSEWHEELUP", "WU"):gsub("MOUSEWHEELDOWN", "WD"):gsub("BUTTON", "M")
  key = key:gsub("NUMPADPLUS", "N+"):gsub("NUMPADMINUS", "N-"):gsub("NUMPAD", "N")
  key = key:gsub("SPACE", "Spc"):gsub("BACKSPACE", "Bs"):gsub("CAPSLOCK", "Cap")
  return key
end

local slotCache, keyCache = {}, {}
local hotkeyText = {}       -- slot -> keybind text printed on some bar addon's button
local hotkeyScanned = false -- rebuilt out of combat whenever bindings or bars change
local function clearBindingCache()
  wipe(slotCache); wipe(keyCache)
  hotkeyScanned = false
end

-- Fallback for bar addons with their own keybind systems (e.g. EllesmereUI bars 9-10,
-- Bartender, ElvUI): scan every action button on screen and read the keybind text the
-- bar addon prints on it. Runs only out of combat, so it never causes a combat hitch.
local RANGE_DOT = RANGE_INDICATOR or "\226\151\143" -- the "●" some bars show instead of a key
local function scanButtonHotkeys()
  if hotkeyScanned or not EnumerateFrames then return end
  if InCombatLockdown and InCombatLockdown() then return end
  wipe(hotkeyText)
  local f = EnumerateFrames()
  while f do
    local ok, slot = pcall(function()
      local a = f.action
      if type(a) ~= "number" and f.GetAttribute then a = f:GetAttribute("action") end
      return a
    end)
    slot = readable(slot)
    if type(slot) == "number" and slot > 0 and not hotkeyText[slot] then
      local hk = f.HotKey or (f.GetName and f:GetName() and _G[f:GetName() .. "HotKey"])
      local text = hk and hk.GetText and readable(select(2, pcall(hk.GetText, hk)))
      local shown = not f.IsVisible or select(2, pcall(f.IsVisible, f))
      if type(text) == "string" and text ~= "" and text ~= RANGE_DOT and shown then
        hotkeyText[slot] = text
      end
    end
    f = EnumerateFrames(f)
  end
  hotkeyScanned = true
end

-- First action bar slot holding this spell (checks the spell and what it overrides into).
local function actionSlot(id)
  if not id then return nil end
  local cached = slotCache[id]
  if cached ~= nil then return cached or nil end
  local slot = false
  if C_ActionBar and C_ActionBar.FindSpellActionButtons then
    for _, candidate in ipairs({ id, override(id) }) do
      local slots = try(C_ActionBar.FindSpellActionButtons, candidate)
      if type(slots) == "table" and slots[1] then
        -- prefer a slot that has a keybind (Blizzard binding, or text on a bar addon's button)
        for _, s in ipairs(slots) do
          if hotkeyText[s] then slot = s break end
          for _, b in ipairs(SLOT_BINDINGS) do
            if s >= b.first and s <= b.last and GetBindingKey and GetBindingKey(b.cmd .. (s - b.first + 1)) then
              slot = s break
            end
          end
          if slot then break end
        end
        slot = slot or slots[1]
        break
      end
    end
  end
  slotCache[id] = slot
  return slot or nil
end

local function keybindFor(id)
  if not id then return nil end
  local cached = keyCache[id]
  if cached ~= nil then return cached or nil end
  scanButtonHotkeys()
  local key = false
  local slot = actionSlot(id)
  if slot and GetBindingKey then
    for _, b in ipairs(SLOT_BINDINGS) do
      if slot >= b.first and slot <= b.last then
        key = shortKey(GetBindingKey(b.cmd .. (slot - b.first + 1))) or false
        break
      end
    end
  end
  if not key and slot and hotkeyText[slot] then
    key = hotkeyText[slot] -- already abbreviated by the bar addon
  end
  -- Don't cache a miss while the button scan hasn't run yet (e.g. first look happened in combat).
  if key or hotkeyScanned then keyCache[id] = key end
  return key or nil
end

-- true = in range, false = out of range, nil = no range / unknown.
local function inRangeFor(id)
  local slot = actionSlot(id)
  if slot and C_ActionBar and C_ActionBar.IsActionInRange then
    local r = try(C_ActionBar.IsActionInRange, slot)
    if r ~= nil then return r end
  end
  if C_Spell and C_Spell.IsSpellInRange and hostileTarget() then
    return (try(C_Spell.IsSpellInRange, id, "target"))
  end
  return nil
end

---------------------------------------------------------------------------
-- Shared frame helpers
---------------------------------------------------------------------------
local function makeMovable(f, pointKey)
  f:SetMovable(true)
  f:SetClampedToScreen(true)
  -- HIGH strata: above the action bars and most of the UI, below dialogs, menus and tooltips.
  -- A high frame level keeps it above other HIGH frames.
  f:SetFrameStrata("HIGH")
  f:SetFrameLevel(9000)
  f:SetToplevel(true)
  f:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and not db.locked then self:StartMoving() end
  end)
  f:SetScript("OnMouseUp", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint()
    db[pointKey] = { p, "UIParent", rp, x, y }
  end)
  f:Hide()
end

local function placeFrame(f, pointKey)
  f:ClearAllPoints()
  local p = db[pointKey]
  f:SetPoint(p[1], UIParent, p[3], p[4], p[5])
  f:SetScale(db.scale)
  f:EnableMouse(not db.locked)
  if db.locked then
    f:SetBackdrop(nil)
  else
    f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    f:SetBackdropColor(0, 0, 0, 0.5)
  end
end

---------------------------------------------------------------------------
-- Next-cast icon: the highlight's suggestion, or our correction (gold border),
-- or the suggestion tinted red when you should wait.
---------------------------------------------------------------------------
local nf = CreateFrame("Frame", "AssistCompanionNext", UIParent, "BackdropTemplate")
makeMovable(nf, "nextPoint")

-- 2px black border hugging an icon, drawn above any colored border (which sits outside it).
local BLACK_EDGE = 2
local function blackBorder(parent, icon)
  local b = parent:CreateTexture(nil, "BORDER", nil, 1)
  b:SetColorTexture(0, 0, 0, 1)
  b:SetPoint("TOPLEFT", icon, -BLACK_EDGE, BLACK_EDGE)
  b:SetPoint("BOTTOMRIGHT", icon, BLACK_EDGE, -BLACK_EDGE)
  return b
end

nf.border = nf:CreateTexture(nil, "BORDER", nil, 0) -- colored (gold/blue), outside the black edge
nf.border:SetColorTexture(1, 0.82, 0, 1)
nf.icon = nf:CreateTexture(nil, "ARTWORK")
nf.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
nf.icon:SetPoint("CENTER")
nf.black = blackBorder(nf, nf.icon)
nf.border:SetPoint("TOPLEFT", nf.icon, -BLACK_EDGE - 2, BLACK_EDGE + 2)
nf.border:SetPoint("BOTTOMRIGHT", nf.icon, BLACK_EDGE + 2, -BLACK_EDGE - 2)
-- GCD swipe over the icon. Cooldown timings can be "secret" in combat, but cooldown
-- frames are allowed to display secret values, so we pass them straight through and
-- never read or compare them ourselves.
local GCD_SPELL = 61304 -- the game's global cooldown spell
nf.gcd = CreateFrame("Cooldown", nil, nf, "CooldownFrameTemplate")
nf.gcd:SetAllPoints(nf.icon)
nf.gcd:SetDrawEdge(false)
nf.gcd:SetDrawBling(false)
nf.gcd:SetHideCountdownNumbers(true)
nf.gcd:SetFrameLevel(nf:GetFrameLevel() + 1)

local function updateGCD()
  if not db or not db.gcdSwipe then nf.gcd:Hide() return end
  nf.gcd:Show()
  -- Preferred: duration object (Midnight API).
  if C_Spell and C_Spell.GetSpellCooldownDuration and nf.gcd.SetCooldownFromDurationObject then
    local ok, dur = pcall(C_Spell.GetSpellCooldownDuration, GCD_SPELL)
    if ok and dur ~= nil and pcall(nf.gcd.SetCooldownFromDurationObject, nf.gcd, dur, true) then return end
  end
  -- Fallback: start/duration (possibly secret) passed straight to the cooldown frame.
  if C_Spell and C_Spell.GetSpellCooldown then
    local ok, info = pcall(C_Spell.GetSpellCooldown, GCD_SPELL)
    if ok and type(info) == "table" then
      pcall(nf.gcd.SetCooldown, nf.gcd, info.startTime, info.duration, info.modRate)
    end
  end
end

nf.key = nf:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
nf.key:SetPoint("TOPRIGHT", nf.icon, "TOPRIGHT", -2, -2)
nf.key:SetJustifyH("RIGHT")
-- Empower rank to hold the spell to (bottom left), when the spec says (ns.empowerRank).
nf.rank = nf:CreateFontString(nil, "OVERLAY", "NumberFontNormalLarge")
nf.rank:SetPoint("BOTTOMLEFT", nf.icon, "BOTTOMLEFT", 3, 2)
nf.rank:SetJustifyH("LEFT")
nf.rank:SetTextColor(1, 0.82, 0)
nf.note = nf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
nf.note:SetPoint("TOP", nf.icon, "BOTTOM", 0, -4)
nf.note:SetTextColor(0.6, 0.85, 1)

local function layoutNext()
  local s = db.iconSize
  nf:SetSize(s + 8, s + 8)
  nf.icon:SetSize(s, s)
  placeFrame(nf, "nextPoint")
end

-- alert: rule result or nil. note: reminder text or nil.
local function showNext(ctx, alert, note)
  local spell, corrected, wait = ctx.next, false, false
  if alert and alert.opener then
    spell, wait = alert.spell, alert.wait -- opener step; "wait" = don't press it until in melee
  elseif alert and alert.wait then
    wait = true                    -- keep the suggestion, but say "not yet"
  elseif alert then
    spell, corrected = alert.spell, true
  end
  -- Border: blue = opener step, gold = correction, none = plain highlight suggestion.
  if alert and alert.opener then
    nf.border:SetColorTexture(0.3, 0.6, 1, 1)
    corrected = true
  else
    nf.border:SetColorTexture(1, 0.82, 0, 1)
  end
  if alert and alert.iconOnly then note = nil end -- e.g. Breath: just the icon, nothing else
  local idle = false
  if db.nextIcon and not spell then
    -- No suggestion right now: keep the last one on screen, grayed out.
    spell, idle, corrected, wait = nf.lastSpell, true, false, false
  end
  if not db.nextIcon or not spell or not iconVisibleNow() then
    nf.note:SetText("")
    nf.rank:SetText("")
    nf:SetShown(not db.locked)
    return nil, "hidden"
  end
  if not idle then nf.lastSpell = spell end
  nf.icon:SetTexture(spellIcon(spell))
  nf.border:SetShown(corrected)
  nf.key:SetText(keybindFor(spell) or "")
  local rank
  local rankFor = db.empowerRank and not idle and ns.empowerRank and specID and ns.empowerRank[specID]
  if rankFor then
    local ok, r = pcall(rankFor, ctx, spell)
    if ok then rank = r end
  end
  nf.rank:SetText(rank and tostring(rank) or "")
  -- Shading, in priority order (same colors as Blizzard's action bars):
  --   red   = wait / out of range
  --   blue  = not enough runes or runic power
  --   gray  = unusable for another reason
  local range = inRangeFor(spell)
  local usable, noPower
  if C_Spell and C_Spell.IsSpellUsable then usable, noPower = try(C_Spell.IsSpellUsable, spell) end
  if wait or range == false then
    nf.icon:SetVertexColor(1, 0.3, 0.3)
  elseif noPower then
    nf.icon:SetVertexColor(0.5, 0.5, 1)
  elseif usable == false then
    nf.icon:SetVertexColor(0.4, 0.4, 0.4)
  else
    nf.icon:SetVertexColor(1, 1, 1)
  end
  nf.icon:SetDesaturated(wait or idle)
  nf.note:SetText(note or "")
  nf:Show()
  local mode = idle and "idle" or (alert and alert.opener and "opener") or wait and "wait"
    or (alert and "correction") or "highlight"
  return spell, mode, rank
end

---------------------------------------------------------------------------
-- Text alert box (optional, off by default)
---------------------------------------------------------------------------
local frame = CreateFrame("Frame", "AssistCompanionFrame", UIParent, "BackdropTemplate")
frame:SetSize(260, 52)
makeMovable(frame, "point")

frame.icon = frame:CreateTexture(nil, "ARTWORK")
frame.icon:SetSize(44, 44)
frame.icon:SetPoint("LEFT", 2, 0)
frame.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

frame.border = frame:CreateTexture(nil, "OVERLAY")
frame.border:SetPoint("TOPLEFT", frame.icon, -2, 2)
frame.border:SetPoint("BOTTOMRIGHT", frame.icon, 2, -2)
frame.border:SetColorTexture(1, 0.82, 0, 0.9)
frame.border:SetDrawLayer("BORDER")

frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
frame.text:SetPoint("TOPLEFT", frame.icon, "TOPRIGHT", 8, -2)
frame.text:SetPoint("RIGHT", frame, "RIGHT", -4, 0)
frame.text:SetJustifyH("LEFT")

frame.sub = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
frame.sub:SetPoint("TOPLEFT", frame.text, "BOTTOMLEFT", 0, -3)
frame.sub:SetPoint("RIGHT", frame, "RIGHT", -4, 0)
frame.sub:SetJustifyH("LEFT")

local function showText(alert)
  if not db.showText then frame:Hide() return end -- off: hidden, even while unlocked
  if not alert and not db.locked then
    -- unlocked with nothing to show: a labeled placeholder so you can position it
    frame.icon:Hide(); frame.border:Hide()
    frame.text:SetText("Text alerts"); frame.sub:SetText("Drag to move")
    frame:Show()
    return
  end
  if alert and alert.iconOnly then
    frame.icon:SetTexture(spellIcon(alert.spell))
    frame.icon:SetSize(48, 48)
    frame.icon:Show(); frame.border:Hide()
    frame.text:SetText(""); frame.sub:SetText("")
  elseif alert then
    frame.icon:SetTexture(spellIcon(alert.spell))
    frame.icon:SetSize(44, 44)
    frame.icon:Show(); frame.border:Show()
    frame.text:SetText(alert.text or "")
    frame.sub:SetText(alert.sub or "")
  else
    frame.icon:Hide(); frame.border:Hide()
    frame.text:SetText(""); frame.sub:SetText("")
  end
  frame:SetShown(alert ~= nil or not db.locked)
end

---------------------------------------------------------------------------
-- Opener: a row of icons for the optimal opening casts. The first icon is the
-- next cast (large, gold border); it advances as you cast each step.
---------------------------------------------------------------------------
local OPENER_SLOTS = 6
local OPENER_COMBAT_WINDOW = 25 -- seconds after the pull before the opener hides
local opener = { steps = {}, index = 1 }

local ob = CreateFrame("Frame", "AssistCompanionOpener", UIParent, "BackdropTemplate")
ob:SetSize(44 + (OPENER_SLOTS - 1) * 30 + OPENER_SLOTS * 8 + 8, 62)
makeMovable(ob, "openerPoint")
ob.label = ob:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
ob.label:SetPoint("RIGHT", ob, "LEFT", -4, 0) -- beside the bar, so it can't overlap anything above
ob.label:SetJustifyH("RIGHT")
ob.slots, ob.blacks = {}, {}
for i = 1, OPENER_SLOTS do
  local t = ob:CreateTexture(nil, "ARTWORK")
  t:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  ob.slots[i] = t
  ob.blacks[i] = blackBorder(ob, t)
end
ob.border = ob:CreateTexture(nil, "BORDER", nil, 0) -- gold on the current step, outside the black edge
ob.border:SetColorTexture(1, 0.82, 0, 0.9)

local function buildOpener()
  if opener.index > 1 and opener.index <= #opener.steps then
    dlog("opener: reset (was at step %d/%d)", opener.index, #opener.steps)
  end
  wipe(opener.steps)
  opener.index = 1
  local list = specID and ns.openers and ns.openers[specID]
  if not list then return end
  local hasPet = try(UnitExists, "pet")
  for _, step in ipairs(list) do
    if knows(step.id) and not (step.skipIfPet and hasPet) then
      opener.steps[#opener.steps + 1] = step
    end
  end
end

-- Called on each of your successful casts. Accepts the next step, or one of the two
-- after it (so a skipped or reordered cast doesn't strand the opener).
local function advanceOpener(id)
  local steps = opener.steps
  for k = opener.index, math.min(opener.index + 2, #steps) do
    local want = steps[k].id
    if id == want or id == override(want) then
      dlog("opener: step %d/%d done (%s)%s", k, #steps, spellName(want),
        k > opener.index and (" - skipped ahead from step " .. opener.index) or "")
      opener.index = k + 1
      opener.lastAdvance = GetTime()
      return
    end
  end
end

-- Fresh start for the next pull, assuming everything is off cooldown (as after a raid wipe):
-- opener back to step 1, and forget cast times so cooldown-based rules (Breath) treat
-- abilities as ready.
local OPENER_IDLE_RESET = 10 -- seconds out of combat after an opener cast before it resets
local function resetForNextPull()
  wipe(lastCast)
  buildOpener()
end

-- Draws the opener bar. Returns the current opener step while the opener is active
-- (so the next-cast icon can follow it), or nil.
local function renderOpener()
  local steps = opener.steps
  -- Opener spells pressed out of combat (testing on a dummy, a pull that never started):
  -- start over once you've been idle out of combat for a while.
  if not inCombat and opener.index > 1 and opener.lastAdvance
     and GetTime() - opener.lastAdvance >= OPENER_IDLE_RESET then
    buildOpener() -- opener only; cast history is cleared by real combat drops, deaths and encounter ends
  end
  -- Keep cooldown knowledge fresh for the opener's spells (readable out of combat; in combat
  -- this keeps the last known value unless the game happens to allow reading it).
  for k = opener.index, #steps do snapshotCooldown(steps[k].id) end
  -- Skip steps that are still on cooldown (e.g. Pillar after a quick reset on a dummy),
  -- so they don't hold up the rest of the opener.
  while opener.index <= #steps and onCooldown(steps[opener.index].id) do
    dlog("opener: skipped step %d/%d (%s on cooldown, ready in %.0fs)", opener.index, #steps,
      spellName(steps[opener.index].id), (readyAt[steps[opener.index].id] or 0) - GetTime())
    opener.index = opener.index + 1
  end
  local visible = db.opener and #steps > 0 and opener.index <= #steps
    and ((not inCombat and hostileTarget()) or (inCombat and GetTime() - combatStart <= OPENER_COMBAT_WINDOW))
  if not visible then ob:SetShown(not db.locked) return nil end
  local x = 6
  for i = 1, OPENER_SLOTS do
    local t, step = ob.slots[i], steps[opener.index + i - 1]
    t:ClearAllPoints()
    if step then
      local size = (i == 1) and 44 or 30
      t:SetSize(size, size)
      t:SetPoint("LEFT", ob, "LEFT", x, 0)
      t:SetTexture(spellIcon(step.id))
      t:SetAlpha(i == 1 and 1 or 0.65)
      t:Show()
      ob.blacks[i]:Show()
      if i == 1 then
        ob.border:ClearAllPoints()
        ob.border:SetPoint("TOPLEFT", t, -BLACK_EDGE - 2, BLACK_EDGE + 2)
        ob.border:SetPoint("BOTTOMRIGHT", t, BLACK_EDGE + 2, -BLACK_EDGE - 2)
        ob.border:Show()
      end
      x = x + size + 8 -- room for black edges and the current step's gold border
    else
      t:Hide()
      ob.blacks[i]:Hide()
    end
  end
  ob.label:SetText(("Opener\n%d/%d"):format(opener.index, #steps))
  ob:Show()
  return steps[opener.index]
end

---------------------------------------------------------------------------
-- Low-health icon (Rules.lua: ns.healthIcon, e.g. Death Strike for Blood). Your health is
-- hidden from addons in combat, but the game will evaluate a curve on it and the result can
-- drive a texture's alpha. So the GAME fades this icon in as your health drops; the addon
-- never sees the number. The curve covers both 0-1 and 0-100 health scales, since the API
-- docs don't say which UnitHealthPercent uses.
---------------------------------------------------------------------------
local hf = CreateFrame("Frame", "AssistCompanionHealth", UIParent, "BackdropTemplate")
makeMovable(hf, "healthPoint")
hf.icon = hf:CreateTexture(nil, "ARTWORK")
hf.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
hf.icon:SetPoint("CENTER")
hf.black = blackBorder(hf, hf.icon)
hf.glow = hf:CreateTexture(nil, "BORDER", nil, 0)
hf.glow:SetColorTexture(0.9, 0.1, 0.1, 1)
hf.glow:SetPoint("TOPLEFT", hf.icon, -BLACK_EDGE - 2, BLACK_EDGE + 2)
hf.glow:SetPoint("BOTTOMRIGHT", hf.icon, BLACK_EDGE + 2, -BLACK_EDGE - 2)
hf.key = hf:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
hf.key:SetPoint("TOPRIGHT", hf.icon, "TOPRIGHT", -2, -2)

local healthCurve, healthCurveFor
-- Fully visible at or below `full` %, invisible at or above `none` %, fading in between.
local function buildHealthCurve(full, none)
  if not (C_CurveUtil and C_CurveUtil.CreateCurve) then return nil end
  local ok, c = pcall(C_CurveUtil.CreateCurve)
  if not ok or not c then return nil end
  if c.SetType and Enum and Enum.LuaCurveType then pcall(c.SetType, c, Enum.LuaCurveType.Linear) end
  local f, n = full / 100, none / 100
  -- 0-1 scale
  c:AddPoint(0, 1); c:AddPoint(f, 1); c:AddPoint(n, 0); c:AddPoint(0.999, 0)
  -- 0-100 scale (x = 1.0 is read as full health on the 0-1 scale, so it stays hidden there)
  c:AddPoint(1.0, 0); c:AddPoint(1.001, 1); c:AddPoint(full, 1); c:AddPoint(none, 0); c:AddPoint(100, 0)
  return c
end

local function layoutHealth()
  local s = db.iconSize
  hf:SetSize(s + 8, s + 8)
  hf.icon:SetSize(s, s)
  placeFrame(hf, "healthPoint")
end

local function updateHealthIcon()
  local cfg = ns.healthIcon and specID and ns.healthIcon[specID]
  if not cfg or not db.healthIcon or not knows(cfg.spell) then hf:Hide() return end
  local key = db.healthFull .. ":" .. db.healthNone
  if healthCurveFor ~= key then healthCurve, healthCurveFor = buildHealthCurve(db.healthFull, db.healthNone), key end
  hf.icon:SetTexture(spellIcon(cfg.spell))
  hf.key:SetText(keybindFor(cfg.spell) or "")
  hf:Show()
  if not db.locked then hf:SetAlpha(1) return end -- fully visible while positioning
  if not healthCurve or not UnitHealthPercent then hf:SetAlpha(0) return end
  local ok, alpha = pcall(UnitHealthPercent, "player", true, healthCurve)
  if not ok or alpha == nil or not pcall(hf.SetAlpha, hf, alpha) then hf:SetAlpha(0) end
end

local function layoutAll()
  layoutNext()
  layoutHealth()
  placeFrame(frame, "point")
  placeFrame(ob, "openerPoint")
end

---------------------------------------------------------------------------
-- Main loop
---------------------------------------------------------------------------
local ctx = { lastCast = lastCast, knows = knows, override = override, onCooldown = onCooldown, readyIn = readyIn,
              charges = charges }
local elapsed, debugElapsed = 0, 0
local ruleErrorLogged = {}
local lastIconKey
local testUntil = 0

local function playerDead()
  local f = UnitIsDeadOrGhost or UnitIsDead
  return f and try(f, "player") or false
end

local function tick()
  if not db then return end
  -- Dead or a ghost: hide everything until you're back up (unless you want it shown).
  if not db.showWhenDead and playerDead() then
    nf:Hide(); ob:Hide(); hf:Hide(); frame:Hide()
    return
  end
  local openerStep = renderOpener()

  ctx.db = db
  ctx.now = GetTime()
  if ns.trackCooldowns and specID and ns.trackCooldowns[specID] then
    for _, id in ipairs(ns.trackCooldowns[specID]) do snapshotCooldown(id) end
  end
  syncCharges()
  updateHealthIcon()
  ctx.next = nextSpell()
  -- Talent replacements (Rules.lua): show the spell that's actually on your button.
  local rep = ctx.next and ns.replacedBy and ns.replacedBy[ctx.next]
  if rep and knows(rep) then ctx.next = rep end
  ctx.inGroup = (IsInGroup and try(IsInGroup)) and true or false
  ctx.power = power()
  ctx.powerMax = effectiveMaxPower(ctx.power)
  ctx.runes = runes()
  ctx.inCombat = inCombat
  ctx.enemies = countEnemies()
  ctx.inMelee = inMelee()

  local alert, note, alertKey
  local rules = specID and ns.rules[specID]
  if rules then
    for _, rule in ipairs(rules) do
      if ns.ruleEnabled(specID, rule.key) then
        local ok, result = pcall(rule.check, ctx)
        if ok and result then alert, alertKey = result, rule.key break end
        if not ok and not ruleErrorLogged[rule.key] then
          ruleErrorLogged[rule.key] = true -- once per rule per session, so a broken rule can't flood the log
          dlog("rule %s error: %s", rule.key, tostring(result))
        end
      end
    end
    local reminder = ns.reminders[specID]
    if reminder then
      local ok, r = pcall(reminder, ctx)
      if ok then note = r end
    end
  end
  -- While the opener is running, the next-cast icon follows it instead of the highlight.
  local iconAlert = alert
  if openerStep and db.openerIcon then
    iconAlert = {
      spell = openerStep.id,
      opener = true,
      wait = openerStep.waitForMelee and ctx.inMelee == false or false,
      -- keep "just the icon" when a rule wants that for this same spell (e.g. Breath)
      iconOnly = alert and alert.iconOnly and alert.spell == openerStep.id or nil,
    }
  end
  local shown, mode, rank = showNext(ctx, iconAlert, note)
  showText(alert)

  if db.debug then
    -- Log every change of the main icon, with why it shows that spell.
    local key = tostring(mode) .. ":" .. tostring(shown) .. ":" .. tostring(rank)
    if key ~= lastIconKey then
      lastIconKey = key
      local why = mode
      if mode == "correction" or mode == "wait" then why = mode .. ", rule " .. tostring(alertKey) end
      if mode ~= "highlight" and ctx.next and ctx.next ~= shown then
        why = why .. ", highlight said " .. spellName(ctx.next)
      end
      dlog("icon: %s%s (%s)", shown and spellName(shown) or "none", rank and (" rank " .. rank) or "", why)
    end
    -- Status once a second while fighting or targeting an enemy.
    debugElapsed = debugElapsed + 1
    if debugElapsed >= 10 then
      debugElapsed = 0
      if combatOrTarget() then
        local bb = charges(50842)
        local extra = ""
        local status = ns.debugStatus and specID and ns.debugStatus[specID]
        if status then
          local ok, s = pcall(status, ctx)
          if ok and s then extra = " " .. s end
        end
        dlog("status: highlight=%s rp=%s/%s%s runes=%s enemies=%s melee=%s opener=%s%s%s%s",
          ctx.next and (spellName(ctx.next) .. " " .. ctx.next) or "none",
          tostring(ctx.power), tostring(ctx.powerMax), powerMaxCache and "" or "(fb)",
          tostring(ctx.runes), tostring(ctx.enemies), tostring(ctx.inMelee),
          openerStep and (opener.index .. "/" .. #opener.steps) or "off",
          bb and (" bloodboil=" .. bb) or "",
          (specID == 252) and (" DT->" .. tostring(override(ns.S.DARK_TRANSFORMATION))) or "", extra)
      end
    end
  end
end

local driver = CreateFrame("Frame")
driver:SetScript("OnUpdate", function(_, dt)
  elapsed = elapsed + dt
  if elapsed >= 0.1 then
    elapsed = 0
    if GetTime() >= testUntil then tick() end
  end
end)

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
events:RegisterEvent("TRAIT_CONFIG_UPDATED")
events:RegisterEvent("SPELLS_CHANGED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_DEAD")
events:RegisterEvent("SPELL_UPDATE_COOLDOWN")
events:RegisterEvent("ENCOUNTER_END")
events:RegisterEvent("UPDATE_BINDINGS")
events:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
events:RegisterUnitEvent("UNIT_PET", "player")
events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")

-- Spec/talent/spellbook changes. The game also fires SPELLS_CHANGED mid-combat (e.g. when a
-- buff that swaps a button ends), so never rebuild the opener in combat, and out of combat only
-- rebuild on a real spec/talent change or when the opener hasn't been started.
local function refresh(event)
  wipe(knownCache)
  clearBindingCache()
  specID = currentSpecID()
  powerMaxCache = nil -- talents/spec may have changed it; re-read (or fall back) fresh
  cachePowerMax()
  wipe(chargeState) -- re-read charges for the (possibly new) spec
  powerSeenMax = 0  -- talents/spec may have lowered the max
  if event == "PLAYER_SPECIALIZATION_CHANGED" or event == "TRAIT_CONFIG_UPDATED" or event == "PLAYER_LOGIN" then
    dlog("%s: spec %s", event, tostring(specID))
  end
  if inCombat then return end
  if event ~= "SPELLS_CHANGED" or opener.index == 1 then
    buildOpener()
  end
end

events:SetScript("OnEvent", function(_, event, arg1, _, spellID)
  if event == "ADDON_LOADED" and arg1 == ADDON then
    AssistCompanionDB = AssistCompanionDB or {}
    db = AssistCompanionDB
    -- 0.11 and older: alwaysShow (true/false) became showMode.
    if db.showMode == nil and db.alwaysShow == false then db.showMode = "target" end
    db.alwaysShow = nil
    for k, v in pairs(DEFAULTS) do
      if db[k] == nil then db[k] = type(v) == "table" and CopyTable(v) or v end
    end
    -- 0.11 and older: rule toggles were stored by key only; now per spec ("250:raisedead").
    for k in pairs(CopyTable(db.disabled)) do
      if type(k) == "string" and not k:find(":", 1, true) then
        for spec, rules in pairs(ns.rules) do
          for _, rule in ipairs(rules) do
            if rule.key == k then db.disabled[spec .. ":" .. k] = true end
          end
        end
        db.disabled[k] = nil
      end
    end
    layoutAll()
    if ns.initOptions then
      ns.initOptions({
        db = function() return db end,
        specID = function() return specID end,
        layoutAll = layoutAll,
        updateGCD = updateGCD,
        updateHealthIcon = updateHealthIcon,
        buildOpener = buildOpener,
        logSize = function() return db.debugLog and #db.debugLog or 0, LOG_MAX end,
      })
    end
  elseif event == "SPELL_UPDATE_COOLDOWN" then
    updateGCD()
  elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
    updateGCD()
    local id = readable(spellID)
    if id then
      lastCast[id] = GetTime()
      -- Casting it just started its cooldown, which may be hidden in combat. Forget the old
      -- "ready" answer so rules fall back to timing from this cast until we can read it again.
      readyAt[id] = nil
      dlog("cast: %s (%d)", spellName(id), id)
      spendCharge(id)
      advanceOpener(id)
      if ns.onCast then pcall(ns.onCast, specID, id, GetTime()) end
    end
  elseif event == "PLAYER_REGEN_DISABLED" then
    inCombat, combatStart = true, GetTime()
    dlog("---- combat start ----")
  elseif event == "PLAYER_REGEN_ENABLED" then
    dlog("---- combat end (%.0fs) ----", GetTime() - combatStart)
    inCombat = false
    cachePowerMax()
    if not hotkeyScanned then clearBindingCache() end -- rescan buttons now that combat is over
    resetForNextPull()
  elseif event == "PLAYER_DEAD" or event == "ENCOUNTER_END" then
    dlog("%s", event)
    resetForNextPull() -- wipe or kill: next pull starts from a full opener
  elseif event == "UNIT_PET" then
    if not inCombat and opener.index == 1 then buildOpener() end
  elseif event == "UPDATE_BINDINGS" or event == "ACTIONBAR_SLOT_CHANGED" then
    clearBindingCache()
  elseif db then
    refresh(event)
  end
end)

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
local function say(msg) print("|cff66ccffAssist Companion:|r " .. msg) end

SLASH_ASSISTCOMPANION1 = "/ac"
SLASH_ASSISTCOMPANION2 = "/assistcompanion"
SlashCmdList.ASSISTCOMPANION = function(input)
  local cmd, arg = (input or ""):lower():match("^(%S*)%s*(.-)$")
  if cmd == "unlock" then
    db.locked = false; layoutAll(); nf:Show(); ob:Show(); frame:SetShown(db.showText); updateHealthIcon()
    say("Unlocked. Drag the next-cast icon and the opener bar, then type /ac lock.")
  elseif cmd == "lock" then
    db.locked = true; layoutAll(); say("Locked.")
  elseif cmd == "hp" then
    local full, none = arg:match("^(%d+)%s+(%d+)$")
    full, none = tonumber(full), tonumber(none)
    if full and none and full < none and none <= 99 then
      db.healthFull, db.healthNone = full, none
      say(("Death Strike icon: fully visible at %d%% health, hidden above %d%%."):format(full, none))
    else
      db.healthIcon = not db.healthIcon
      say("Low-health Death Strike icon " .. (db.healthIcon and "on." or "off."))
    end
    updateHealthIcon()
  elseif cmd == "gcd" then
    db.gcdSwipe = not db.gcdSwipe; updateGCD()
    say("GCD swipe " .. (db.gcdSwipe and "on." or "off."))
  elseif cmd == "text" then
    db.showText = not db.showText; say("Text alerts " .. (db.showText and "on." or "off."))
  elseif cmd == "icon" then
    if tonumber(arg) then
      db.iconSize = math.max(24, math.min(128, tonumber(arg))); layoutAll()
      say(("Next-cast icon size %d."):format(db.iconSize))
    else
      db.nextIcon = not db.nextIcon; say("Next-cast icon " .. (db.nextIcon and "on." or "off."))
    end
  elseif cmd == "opener" then
    if arg == "reset" then buildOpener(); say("Opener restarted.") return end
    if arg == "icon" then
      db.openerIcon = not db.openerIcon
      say("Next-cast icon " .. (db.openerIcon and "follows the opener." or "ignores the opener (shows the highlight)."))
      return
    end
    db.opener = not db.opener; say("Opener " .. (db.opener and "on." or "off."))
  elseif cmd == "rp" and tonumber(arg) then
    db.unholyRP = tonumber(arg); say(("Unholy runic power warning at %d."):format(db.unholyRP))
  elseif cmd == "scale" and tonumber(arg) then
    db.scale = math.max(0.5, math.min(2.5, tonumber(arg))); layoutAll()
    say(("Scale %.2f."):format(db.scale))
  elseif cmd == "cds" then
    db.cooldownReminder = not db.cooldownReminder
    say("Frost cooldown reminder " .. (db.cooldownReminder and "on." or "off."))
  elseif cmd == "toggle" and arg ~= "" then
    if not specID then say("No spec yet.") return end
    local on = not ns.ruleEnabled(specID, arg)
    ns.setRuleEnabled(specID, arg, on)
    say(("Rule '%s' %s for this spec."):format(arg, on and "on" or "off"))
  elseif cmd == "rules" then
    local rules = specID and ns.rules[specID]
    if not rules then say("No rules for this spec.") return end
    for _, r in ipairs(rules) do
      say(("%s  (%s)  %s"):format(r.key, r.name, ns.ruleEnabled(specID, r.key) and "|cff66ff66on|r" or "|cffff6666off|r"))
    end
  elseif cmd == "debug" then
    if arg == "chat" then
      db.debugChat = not db.debugChat
      say("Debug lines " .. (db.debugChat and "also printed to chat." or "no longer printed to chat."))
      return
    end
    db.debug = not db.debug
    if db.debug then
      local version = "?"
      local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
      if getMeta then version = select(2, pcall(getMeta, ADDON, "Version")) or "?" end
      lastIconKey = nil
      dlog("==== debug on: Assist Companion %s, spec %s ====", tostring(version), tostring(specID))
      say("Debug logging on. Play, then /reload (or log out) to write it to")
      say("WTF\\Account\\<ACCOUNT>\\SavedVariables\\AssistCompanion.lua  (/ac debug chat to also see it in chat)")
    else
      db.debug = true; dlog("==== debug off ===="); db.debug = false
      say("Debug logging off. /reload to save the log file.")
    end
  elseif cmd == "log" then
    db.debugLog = db.debugLog or {}
    if arg == "clear" then wipe(db.debugLog); say("Debug log cleared.") return end
    say(("Debug log: %d of %d lines kept. Logging is %s."):format(#db.debugLog, LOG_MAX, db.debug and "on" or "off"))
    say("Saved on /reload or logout to WTF\\Account\\<ACCOUNT>\\SavedVariables\\AssistCompanion.lua")
  elseif cmd == "test" then
    testUntil = GetTime() + 4
    local sample = (specID == 252) and ns.S.BLIGHTFALL or ns.S.BREATH
    nf.icon:SetTexture(spellIcon(sample)); nf.border:Show(); nf.key:SetText("F"); nf.rank:SetText("")
    nf.icon:SetVertexColor(1, 1, 1); nf.icon:SetDesaturated(false); nf.note:SetText("Reminders appear here")
    nf:Show()
  elseif cmd == "" or cmd == "options" or cmd == "config" then
    if ns.openOptions and ns.openOptions() then return end
    say("The options menu isn't available. /ac help lists the commands.")
  elseif cmd == "reset" then
    db.point = CopyTable(DEFAULTS.point); db.openerPoint = CopyTable(DEFAULTS.openerPoint)
    db.nextPoint = CopyTable(DEFAULTS.nextPoint); db.iconSize = DEFAULTS.iconSize
    db.healthPoint = CopyTable(DEFAULTS.healthPoint)
    db.scale = DEFAULTS.scale; layoutAll(); say("Position and size reset.")
  else
    say("commands (/ac on its own opens the options menu):")
    say("/ac unlock | lock  - move the icon and opener bar")
    say("/ac test  - show a sample icon")
    say("/ac icon  - toggle the next-cast icon (/ac icon 48 sets its size, now " .. db.iconSize .. ")")
    say("/ac text  - toggle text alerts (now " .. (db.showText and "on" or "off") .. ")")
    say("/ac gcd  - toggle the GCD swipe on the icon")
    say("/ac hp  - Blood: toggle the low-health Death Strike icon (/ac hp 35 50 sets full/hidden health %)")
    say("/ac rp <n>  - Unholy: warn at this runic power (now " .. db.unholyRP .. ")")
    say("/ac cds  - Frost: toggle trinket/potion/racial reminder")
    say("/ac opener  - toggle the opener bar (/ac opener reset to restart it)")
    say("/ac opener icon  - toggle the next-cast icon following the opener")
    say("/ac rules | toggle <key>  - list or turn off rules")
    say("/ac debug  - log what the addon sees to its saved file (/ac debug chat also prints it)")
    say("/ac log  - show debug log size (/ac log clear empties it)")
    say("/ac scale <n> | reset")
  end
end

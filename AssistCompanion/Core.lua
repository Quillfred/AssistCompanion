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
  showText = false,        -- show text alerts as well (off: the icon carries the corrections)
  unholyRP = 80,           -- warn at or above this runic power when the highlight wants a rune spender
  cooldownReminder = true, -- Frost: trinkets/potion/racial reminder when Pillar goes out
  opener = true,           -- show the opening sequence before and at the start of a pull
  openerIcon = true,       -- the next-cast icon follows the opener while it's running
  gcdSwipe = true,         -- global cooldown swipe on the next-cast icon
  disabled = {},           -- rule keys turned off with /ac toggle <key>
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

local function power()
  return (try(UnitPower, "player", RUNIC_POWER))
end

local function cachePowerMax()
  local m = try(UnitPowerMax, "player", RUNIC_POWER)
  if m and m > 0 then powerMaxCache = m end
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

-- Is the current target in melee range? Uses Obliterate's range (works for both DK specs).
-- Returns nil when there's no hostile target or the game won't say.
local function inMelee()
  if not (C_Spell and C_Spell.IsSpellInRange) then return nil end
  if not hostileTarget() then return nil end
  return (try(C_Spell.IsSpellInRange, 49020, "target"))
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
  -- Draw above everything else on screen: highest strata, near-max level within it.
  f:SetFrameStrata("TOOLTIP")
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

nf.border = nf:CreateTexture(nil, "BORDER")
nf.border:SetColorTexture(1, 0.82, 0, 1)
nf.icon = nf:CreateTexture(nil, "ARTWORK")
nf.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
nf.icon:SetPoint("CENTER")
nf.border:SetPoint("TOPLEFT", nf.icon, -2, 2)
nf.border:SetPoint("BOTTOMRIGHT", nf.icon, 2, -2)
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
  if not db.nextIcon or not spell or not combatOrTarget() then
    nf.note:SetText("")
    nf:SetShown(not db.locked)
    return
  end
  nf.icon:SetTexture(spellIcon(spell))
  nf.border:SetShown(corrected)
  nf.key:SetText(keybindFor(spell) or "")
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
  nf.icon:SetDesaturated(wait)
  nf.note:SetText(note or "")
  nf:Show()
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
ob:SetSize(OPENER_SLOTS * 34 + 20, 62)
makeMovable(ob, "openerPoint")
ob.label = ob:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
ob.label:SetPoint("RIGHT", ob, "LEFT", -4, 0) -- beside the bar, so it can't overlap anything above
ob.label:SetJustifyH("RIGHT")
ob.slots = {}
for i = 1, OPENER_SLOTS do
  local t = ob:CreateTexture(nil, "ARTWORK")
  t:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  ob.slots[i] = t
end
ob.border = ob:CreateTexture(nil, "BORDER")
ob.border:SetColorTexture(1, 0.82, 0, 0.9)

local function buildOpener()
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
    opener.index = opener.index + 1
  end
  local visible = db.opener and #steps > 0 and opener.index <= #steps
    and ((not inCombat and hostileTarget()) or (inCombat and GetTime() - combatStart <= OPENER_COMBAT_WINDOW))
  if not visible then ob:SetShown(not db.locked) return nil end
  local x = 4
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
      if i == 1 then
        ob.border:ClearAllPoints()
        ob.border:SetPoint("TOPLEFT", t, -2, 2)
        ob.border:SetPoint("BOTTOMRIGHT", t, 2, -2)
        ob.border:Show()
      end
      x = x + size + 4
    else
      t:Hide()
    end
  end
  ob.label:SetText(("Opener\n%d/%d"):format(opener.index, #steps))
  ob:Show()
  return steps[opener.index]
end

local function layoutAll()
  layoutNext()
  placeFrame(frame, "point")
  placeFrame(ob, "openerPoint")
end

---------------------------------------------------------------------------
-- Main loop
---------------------------------------------------------------------------
local ctx = { lastCast = lastCast, knows = knows, override = override, onCooldown = onCooldown }
local elapsed, debugElapsed = 0, 0
local testUntil = 0

local function tick()
  if not db then return end
  local openerStep = renderOpener()

  ctx.db = db
  ctx.now = GetTime()
  if ns.trackCooldowns and specID and ns.trackCooldowns[specID] then
    for _, id in ipairs(ns.trackCooldowns[specID]) do snapshotCooldown(id) end
  end
  ctx.next = nextSpell()
  ctx.power = power()
  ctx.powerMax = powerMaxCache
  ctx.enemies = countEnemies()
  ctx.inMelee = inMelee()

  local alert, note
  local rules = specID and ns.rules[specID]
  if rules then
    for _, rule in ipairs(rules) do
      if not db.disabled[rule.key] then
        local ok, result = pcall(rule.check, ctx)
        if ok and result then alert = result break end
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
  showNext(ctx, iconAlert, note)
  showText(alert)

  if db.debug then
    debugElapsed = debugElapsed + 1
    if debugElapsed >= 10 then -- about once a second
      debugElapsed = 0
      print(("|cff66ccffAC|r next=%s (%s) key=%s rp=%s enemies=%s melee=%s DT->%s Scourge->%s"):format(
        spellName(ctx.next), tostring(ctx.next), tostring(keybindFor(ctx.next)), tostring(ctx.power),
        tostring(ctx.enemies), tostring(ctx.inMelee),
        tostring(override(ns.S.DARK_TRANSFORMATION)), tostring(override(ns.S.SCOURGE_STRIKE))))
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
  cachePowerMax()
  if inCombat then return end
  if event ~= "SPELLS_CHANGED" or opener.index == 1 then
    buildOpener()
  end
end

events:SetScript("OnEvent", function(_, event, arg1, _, spellID)
  if event == "ADDON_LOADED" and arg1 == ADDON then
    AssistCompanionDB = AssistCompanionDB or {}
    db = AssistCompanionDB
    for k, v in pairs(DEFAULTS) do
      if db[k] == nil then db[k] = type(v) == "table" and CopyTable(v) or v end
    end
    layoutAll()
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
      advanceOpener(id)
    end
  elseif event == "PLAYER_REGEN_DISABLED" then
    inCombat, combatStart = true, GetTime()
  elseif event == "PLAYER_REGEN_ENABLED" then
    inCombat = false
    cachePowerMax()
    if not hotkeyScanned then clearBindingCache() end -- rescan buttons now that combat is over
    resetForNextPull()
  elseif event == "PLAYER_DEAD" or event == "ENCOUNTER_END" then
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
    db.locked = false; layoutAll(); nf:Show(); ob:Show(); frame:SetShown(db.showText)
    say("Unlocked. Drag the next-cast icon and the opener bar, then type /ac lock.")
  elseif cmd == "lock" then
    db.locked = true; layoutAll(); say("Locked.")
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
    db.disabled[arg] = not db.disabled[arg] or nil
    say(("Rule '%s' %s."):format(arg, db.disabled[arg] and "off" or "on"))
  elseif cmd == "rules" then
    local rules = specID and ns.rules[specID]
    if not rules then say("No rules for this spec.") return end
    for _, r in ipairs(rules) do
      say(("%s  (%s)  %s"):format(r.key, r.name, db.disabled[r.key] and "|cffff6666off|r" or "|cff66ff66on|r"))
    end
  elseif cmd == "debug" then
    db.debug = not db.debug; say("Debug " .. (db.debug and "on: prints the highlight's suggestion every second." or "off."))
  elseif cmd == "test" then
    testUntil = GetTime() + 4
    local sample = (specID == 252) and ns.S.BLIGHTFALL or ns.S.BREATH
    nf.icon:SetTexture(spellIcon(sample)); nf.border:Show(); nf.key:SetText("F")
    nf.icon:SetVertexColor(1, 1, 1); nf.icon:SetDesaturated(false); nf.note:SetText("Reminders appear here")
    nf:Show()
  elseif cmd == "reset" then
    db.point = CopyTable(DEFAULTS.point); db.openerPoint = CopyTable(DEFAULTS.openerPoint)
    db.nextPoint = CopyTable(DEFAULTS.nextPoint); db.iconSize = DEFAULTS.iconSize
    db.scale = DEFAULTS.scale; layoutAll(); say("Position and size reset.")
  else
    say("commands:")
    say("/ac unlock | lock  - move the icon and opener bar")
    say("/ac test  - show a sample icon")
    say("/ac icon  - toggle the next-cast icon (/ac icon 48 sets its size, now " .. db.iconSize .. ")")
    say("/ac text  - toggle text alerts (now " .. (db.showText and "on" or "off") .. ")")
    say("/ac gcd  - toggle the GCD swipe on the icon")
    say("/ac rp <n>  - Unholy: warn at this runic power (now " .. db.unholyRP .. ")")
    say("/ac cds  - Frost: toggle trinket/potion/racial reminder")
    say("/ac opener  - toggle the opener bar (/ac opener reset to restart it)")
    say("/ac opener icon  - toggle the next-cast icon following the opener")
    say("/ac rules | toggle <key>  - list or turn off rules")
    say("/ac scale <n> | reset | debug")
  end
end

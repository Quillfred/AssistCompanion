-- Assist Companion: health probe (/ac probe). Finds out which ways of seeing the player's health change
-- over time work in combat (owner's question). Health is a secret value in combat: an addon can't read
-- or compare it, but some widgets may accept it for display.
--
-- Read probes (each debug status line, docs/HIDDEN_RESOURCES.md):
--   health / max / pct     UnitHealth, UnitHealthMax, UnitHealthPercent (no curve): number or "hidden"
--   absorb / inc           UnitGetTotalAbsorbs, UnitGetIncomingHeals
--   ev                     how many health events fired since the last line (the count is ours, so readable
--                          even if their contents aren't): UNIT_HEALTH, UNIT_MAXHEALTH, absorbs, heal
--                          prediction, UNIT_COMBAT (with its last action and whether the amount is readable)
--   cleu                   the combat log: "blocked" if it can't be registered, else events seen and whether a
--                          damage amount on you was readable
--   meter                  C_DamageMeter (Midnight's built-in meter): "none" or its function count (names
--                          logged once when the probe starts)
-- Display probes (the probe panel next to the next-cast icon; ok / err / noapi in the log):
--   bar     StatusBar:SetMinMaxValues + SetValue fed UnitHealthMax / UnitHealth
--   text    FontString:SetText (then SetFormattedText) fed UnitHealth
--   pcttext FontString:SetFormattedText fed UnitHealthPercent through a 0-100 curve
--   color   a color curve (C_CurveUtil.CreateColorCurve) through UnitHealthPercent into SetVertexColor
local _, ns = ...

local probe = { on = false, locked = true, ev = {}, uc = nil, cleu = nil, widgets = {} }
ns.probe = probe

local function secret(v) return v ~= nil and issecretvalue and issecretvalue(v) end
local function show(v)
  if v == "?" then return "?" end
  if secret(v) then return "hidden" end
  if v == nil then return "nil" end
  if type(v) == "number" then return ("%.0f"):format(v) end
  if type(v) == "boolean" then return v and "y" or "n" end
  return tostring(v)
end
local function read(fn, ...)
  if type(fn) ~= "function" then return "?" end
  local ok, v = pcall(fn, ...)
  if not ok then return "?" end
  return v
end

---------------------------------------------------------------------------
-- Events (registered while the probe is on)
---------------------------------------------------------------------------
local EVENTS = { "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_ABSORB_AMOUNT_CHANGED", "UNIT_HEAL_PREDICTION", "UNIT_COMBAT" }
local SHORT = { UNIT_HEALTH = "health", UNIT_MAXHEALTH = "max", UNIT_ABSORB_AMOUNT_CHANGED = "absorb",
                UNIT_HEAL_PREDICTION = "healpred", UNIT_COMBAT = "combat" }
local ef = CreateFrame("Frame")
ef.acProbe = true -- (test harness: not Core's event frame)
ef:SetScript("OnEvent", function(_, event, unit, a2, a3, a4)
  if event == "COMBAT_LOG_EVENT_UNFILTERED" then
    local c = probe.cleu
    c.n = c.n + 1
    if CombatLogGetCurrentEventInfo then
      local ok, _, sub, _, _, _, _, _, destGUID, _, _, _, x12, x13, x14, x15 = pcall(CombatLogGetCurrentEventInfo)
      if ok and destGUID ~= nil and not secret(destGUID) and UnitGUID and destGUID == UnitGUID("player")
          and type(sub) == "string" and sub:find("DAMAGE") then
        local amount = sub == "SWING_DAMAGE" and x12 or x15
        c.amt = secret(amount) and "hidden" or show(amount)
      end
    end
    return
  end
  if unit ~= "player" then return end
  probe.ev[event] = (probe.ev[event] or 0) + 1
  if event == "UNIT_COMBAT" then probe.uc = { action = show(a2), amount = show(a4) } end
end)

---------------------------------------------------------------------------
-- The probe panel: widgets fed the hidden health, so the owner can see what they display
---------------------------------------------------------------------------
local panel
local pctCurve, colorCurve

local function buildPanel()
  if panel then return end
  local anchor = _G.AssistCompanionNext or UIParent
  panel = CreateFrame("Frame", "AssistCompanionProbe", UIParent)
  panel:SetSize(140, 64)
  local saved = AssistCompanionDB and AssistCompanionDB.probePoint
  if saved then
    panel:SetPoint(saved[1], UIParent, saved[2], saved[3], saved[4])
  else
    panel:SetPoint("LEFT", anchor, "RIGHT", 12, 0)
  end
  -- /ac probe unlock: drag it anywhere (position saved); locked, it ignores the mouse (never blocks clicks)
  panel:SetMovable(true)
  panel:SetClampedToScreen(true)
  panel:RegisterForDrag("LeftButton")
  panel:SetScript("OnDragStart", function(self) if not probe.locked then self:StartMoving() end end)
  panel:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint()
    if AssistCompanionDB then AssistCompanionDB.probePoint = { p, rp, x, y } end
  end)
  local bg = panel:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(); bg:SetColorTexture(0, 0, 0, 0.5)
  panel.bg = bg
  local label = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  label:SetPoint("TOPLEFT", 4, -3); label:SetText("AC probe: health")
  panel.label = label
  panel.bar = CreateFrame("StatusBar", nil, panel)
  panel.bar:SetPoint("TOPLEFT", 4, -16); panel.bar:SetSize(132, 10)
  panel.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  panel.bar:SetStatusBarColor(0.2, 0.8, 0.2)
  panel.text = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  panel.text:SetPoint("TOPLEFT", 4, -30)
  panel.pct = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  panel.pct:SetPoint("TOPLEFT", 74, -30)
  panel.swatch = panel:CreateTexture(nil, "ARTWORK")
  panel.swatch:SetPoint("TOPLEFT", 4, -46); panel.swatch:SetSize(132, 12)
  panel.swatch:SetColorTexture(1, 1, 1, 1)
  if C_CurveUtil and C_CurveUtil.CreateCurve then
    local ok, c = pcall(C_CurveUtil.CreateCurve)
    if ok and c then
      if c.SetType and Enum and Enum.LuaCurveType then pcall(c.SetType, c, Enum.LuaCurveType.Linear) end
      -- 0-1 and 0-100 scales both map to 0-100
      pcall(c.AddPoint, c, 0, 0); pcall(c.AddPoint, c, 1, 100); pcall(c.AddPoint, c, 1.001, 1.001); pcall(c.AddPoint, c, 100, 100)
      pctCurve = c
    end
  end
  if C_CurveUtil and C_CurveUtil.CreateColorCurve and CreateColor then
    local ok, c = pcall(C_CurveUtil.CreateColorCurve)
    if ok and c then
      if c.SetType and Enum and Enum.LuaCurveType then pcall(c.SetType, c, Enum.LuaCurveType.Linear) end
      pcall(c.AddPoint, c, 0, CreateColor(1, 0, 0, 1)); pcall(c.AddPoint, c, 0.5, CreateColor(1, 1, 0, 1))
      pcall(c.AddPoint, c, 1, CreateColor(0, 1, 0, 1))
      colorCurve = c
    end
  end
end

local function try(name, fn)
  local ok, err = pcall(fn)
  if ok then probe.widgets[name] = "ok"
  elseif probe.widgets[name] ~= "ok" then
    probe.widgets[name] = "err"
    if ns.dlog and not probe.widgets[name .. "_logged"] then
      probe.widgets[name .. "_logged"] = true
      ns.dlog("probe: %s failed: %s", name, tostring(err))
    end
  end
end

local function updatePanel()
  if not panel then return end
  local hp, max = UnitHealth and UnitHealth("player"), UnitHealthMax and UnitHealthMax("player")
  try("bar", function() panel.bar:SetMinMaxValues(0, max); panel.bar:SetValue(hp) end)
  try("text", function()
    if not pcall(panel.text.SetText, panel.text, hp) then panel.text:SetFormattedText("%d", hp) end
  end)
  if pctCurve and UnitHealthPercent then
    try("pcttext", function() panel.pct:SetFormattedText("%.0f%%", UnitHealthPercent("player", true, pctCurve)) end)
  else
    probe.widgets.pcttext = "noapi"
  end
  if colorCurve and UnitHealthPercent then
    try("color", function()
      local c = UnitHealthPercent("player", true, colorCurve)
      local r, g, b = c:GetRGB()
      panel.swatch:SetVertexColor(r, g, b)
    end)
  else
    probe.widgets.color = "noapi"
  end
end

local elapsed = 0
local ticker = CreateFrame("Frame")
ticker.acProbe = true
ticker:SetScript("OnUpdate", function(_, dt)
  if not probe.on then return end
  elapsed = elapsed + dt
  if elapsed >= 0.2 then elapsed = 0; updatePanel() end
end)

---------------------------------------------------------------------------
-- Damage meter probe (0.27.10): Midnight's C_DamageMeter exists for addons (owner's 0.27.9 log). Logs what
-- its functions return and which fields are readable, in and out of combat, as "meter:" lines every 5
-- status lines. Argument lists are guesses: each function's first error is logged once (Blizzard's errors
-- usually name the expected arguments).
---------------------------------------------------------------------------
local function describe(v, depth, budget)
  budget = budget or { n = 700 }
  if budget.n <= 0 then return "..." end
  local out
  if v == nil then out = "nil"
  elseif secret(v) then out = "hidden"
  elseif type(v) == "number" then out = (v == math.floor(v)) and tostring(v) or ("%.2f"):format(v)
  elseif type(v) == "string" then out = '"' .. v:sub(1, 24) .. '"'
  elseif type(v) == "boolean" then out = v and "true" or "false"
  elseif type(v) == "table" then
    if (depth or 0) >= 3 then out = "{...}" else
      local keys = {}
      for k in pairs(v) do keys[#keys + 1] = k end
      table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
      local parts, shown = {}, 0
      for _, k in ipairs(keys) do
        shown = shown + 1
        if shown > 12 then parts[#parts + 1] = ("+%d more"):format(#keys - 12) break end
        if type(k) == "number" and k > 2 then -- arrays: the first two entries are enough
          parts[#parts + 1] = ("[%d entries]"):format(#v) break
        end
        parts[#parts + 1] = tostring(k) .. "=" .. describe(v[k], (depth or 0) + 1, budget)
      end
      out = "{" .. table.concat(parts, " ") .. "}"
    end
  else out = type(v) end
  budget.n = budget.n - #out
  return out
end

local meterErr = {}
local function meterCall(name, ...)
  local fn = type(C_DamageMeter) == "table" and C_DamageMeter[name]
  if type(fn) ~= "function" then return "noapi" end
  local ok, a, b = pcall(fn, ...)
  if not ok then
    if not meterErr[name] and ns.dlog then meterErr[name] = true; ns.dlog("meter: %s error: %s", name, tostring(a)) end
    return "err"
  end
  return describe(a) .. (b ~= nil and (" / " .. describe(b)) or "")
end

-- Enum tables the meter uses (names containing "DamageMeter"), as { name = { key = value } }.
local function meterEnums()
  local found = {}
  if type(Enum) == "table" then
    for name, t in pairs(Enum) do
      if type(name) == "string" and name:find("DamageMeter") and type(t) == "table" then found[name] = t end
    end
  end
  return found
end

local function meterProbe(inCombatNow)
  if not ns.dlog or type(C_DamageMeter) ~= "table" then return end
  ns.dlog("meter: %s available=%s sessions=%s", inCombatNow and "in combat" or "out of combat",
    meterCall("IsDamageMeterAvailable"), meterCall("GetAvailableCombatSessions"))
  local enums = meterEnums()
  local sessionTypes, meterTypes = {}, {}
  for name, t in pairs(enums) do
    for k, v in pairs(t) do
      if name:find("Session") then sessionTypes[#sessionTypes + 1] = { k, v }
      elseif name:find("Type") then meterTypes[#meterTypes + 1] = { k, v } end
    end
  end
  table.sort(sessionTypes, function(a, b) return a[2] < b[2] end)
  table.sort(meterTypes, function(a, b) return a[2] < b[2] end)
  local guid = UnitGUID and UnitGUID("player")
  for _, st in ipairs(sessionTypes) do
    ns.dlog("meter: duration[%s]=%s", st[1], meterCall("GetSessionDurationSeconds", st[2]))
    for _, mt in ipairs(meterTypes) do
      if mt[1]:find("Damage") or mt[1]:find("Heal") then -- damage done / taken, healing
        ns.dlog("meter: session[%s,%s]=%s", st[1], mt[1], meterCall("GetCombatSessionFromType", st[2], mt[2]))
        ns.dlog("meter: me[%s,%s]=%s", st[1], mt[1], meterCall("GetCombatSessionSourceFromType", st[2], mt[2], guid))
      end
    end
  end
  if #sessionTypes == 0 then -- no enums found: try plain numbers
    ns.dlog("meter: session[0,0]=%s", meterCall("GetCombatSessionFromType", 0, 0))
    ns.dlog("meter: me[0,0]=%s", meterCall("GetCombatSessionSourceFromType", 0, 0, guid))
  end
end
probe.meterProbe = meterProbe

---------------------------------------------------------------------------
-- On / off and the status text (Core.lua calls ns.probeStatus for each debug status line)
---------------------------------------------------------------------------
function ns.probeToggle()
  probe.on = not probe.on
  if probe.on then
    for _, e in ipairs(EVENTS) do pcall(ef.RegisterEvent, ef, e) end
    probe.cleu = { n = 0, amt = "none" }
    if not pcall(ef.RegisterEvent, ef, "COMBAT_LOG_EVENT_UNFILTERED") then probe.cleu.blocked = true end
    local okB, errB = pcall(buildPanel)
    if not okB then
      panel = nil
      if ns.dlog then ns.dlog("probe: panel failed: %s", tostring(errB)) end
    end
    if panel then panel:Show(); ns.probeLock(probe.locked) end
    if ns.dlog then
      local names = {}
      if type(C_DamageMeter) == "table" then
        for k, v in pairs(C_DamageMeter) do if type(v) == "function" then names[#names + 1] = k end end
        table.sort(names)
      end
      ns.dlog("probe on: C_DamageMeter %s", #names > 0 and table.concat(names, ", ") or "none")
      for name, t in pairs(meterEnums()) do ns.dlog("probe on: Enum.%s = %s", name, describe(t)) end
      meterErr = {}
      pcall(meterProbe, false)
    end
  else
    pcall(ef.UnregisterAllEvents, ef)
    if panel then panel:Hide() end
    if ns.dlog then ns.dlog("probe off") end
  end
  return probe.on
end

-- Lock / unlock the panel for moving (true = locked). Returns the new state, or nil if the probe is off.
function ns.probeLock(locked)
  probe.locked = locked
  if not panel then return nil end
  pcall(panel.EnableMouse, panel, not locked)
  panel.label:SetText(locked and "AC probe: health" or "AC probe: drag to move")
  panel.bg:SetColorTexture(locked and 0 or 0.1, locked and 0 or 0.3, locked and 0 or 0.6, locked and 0.5 or 0.7)
  return locked
end

function ns.probeStatus()
  if not probe.on then return nil end
  local pct = read(UnitHealthPercent, "player")
  local ev = {}
  for _, e in ipairs(EVENTS) do ev[#ev + 1] = SHORT[e] .. ":" .. (probe.ev[e] or 0) end
  probe.ev = {}
  local uc = probe.uc and ("(" .. probe.uc.action .. " amt=" .. probe.uc.amount .. ")") or ""
  local c = probe.cleu or {}
  local cleu = c.blocked and "blocked" or ("n:" .. (c.n or 0) .. " amt=" .. (c.amt or "none"))
  if probe.cleu then probe.cleu.n = 0 end
  local meter = type(C_DamageMeter) == "table" and "yes" or "none"
  probe.lines = (probe.lines or 0) + 1
  if probe.lines % 5 == 0 then pcall(meterProbe, UnitAffectingCombat and UnitAffectingCombat("player")) end
  local w = probe.widgets
  return ("hp: health=%s max=%s pct=%s absorb=%s inc=%s ev=%s%s cleu=%s meter=%s widgets: bar=%s text=%s pcttext=%s color=%s"):format(
    show(read(UnitHealth, "player")), show(read(UnitHealthMax, "player")), show(pct),
    show(read(UnitGetTotalAbsorbs, "player")), show(read(UnitGetIncomingHeals, "player")),
    table.concat(ev, ","), uc, cleu, meter, w.bar or "-", w.text or "-", w.pcttext or "-", w.color or "-")
end

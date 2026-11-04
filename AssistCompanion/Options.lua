-- Assist Companion: options menu (Esc > Options > AddOns > Assist Companion, or /ac).
--
-- Top: general settings for the icons. Below: a tree of classes > specs > abilities, where
-- each correction rule (Rules.lua) can be turned on or off for that spec.
-- Built the first time the panel is shown; every widget re-reads the saved settings when the
-- panel opens or anything changes, so slash commands and the menu always agree.

local _, ns = ...

local C            -- Core.lua's helpers, handed over in ns.initOptions
local panel, category
local content, built
local widgets = {} -- everything with a :refresh()
local rows = {}    -- the class/spec/ability tree, in display order
local expanded = {}
local treeTop = 0

local function db() return C.db() end
local function cmd(text) SlashCmdList.ASSISTCOMPANION(text) end

local ROW = 26     -- height of one line
local INDENT = 22  -- per tree level

---------------------------------------------------------------------------
-- Widget helpers
---------------------------------------------------------------------------
local function refreshAll()
  for _, w in ipairs(widgets) do w:refresh() end
end

local function tooltip(frame, title, text)
  if not text then return end
  frame:SetScript("OnEnter", function(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(title, 1, 1, 1)
    GameTooltip:AddLine(text, nil, nil, nil, true)
    GameTooltip:Show()
  end)
  frame:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
end

local function spellTexture(id)
  if C_Spell and C_Spell.GetSpellTexture then
    local ok, t = pcall(C_Spell.GetSpellTexture, id)
    if ok and t then return t end
  end
  return 134400 -- question mark
end

-- A checkbox with a label (and an optional spell icon between them).
-- get() returns the current value; set(v) stores it.
local function checkbox(label, desc, get, set, spell)
  local cb = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
  cb:SetSize(24, 24)
  local anchor, gap = cb, 4
  if spell then
    cb.icon = cb:CreateTexture(nil, "ARTWORK")
    cb.icon:SetSize(18, 18)
    cb.icon:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    cb.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    cb.icon:SetTexture(spellTexture(spell))
    anchor, gap = cb.icon, 6
  end
  cb.label = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  cb.label:SetPoint("LEFT", anchor, "RIGHT", gap, 0)
  cb.label:SetText(label)
  cb:SetScript("OnClick", function(self)
    set(self:GetChecked() and true or false)
    refreshAll()
  end)
  tooltip(cb, label, desc)
  function cb:refresh() self:SetChecked(get() and true or false) end
  widgets[#widgets + 1] = cb
  return cb
end

local function button(label, width, onClick)
  local b = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
  b:SetSize(width, 22)
  b:SetText(label)
  b:SetScript("OnClick", function() onClick(); refreshAll() end)
  return b
end

-- "Label  [-] value [+]"
local function stepper(label, desc, get, set, step, lo, hi, fmt)
  local f = CreateFrame("Frame", nil, content)
  f:SetSize(300, 24)
  f.label = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  f.label:SetPoint("LEFT", f, "LEFT", 4, 0)
  f.label:SetText(label)
  local function nudge(d)
    local v = math.floor((get() + d) / step + 0.5) * step
    set(math.max(lo, math.min(hi, v)))
  end
  f.minus = button("-", 24, function() nudge(-step) end)
  f.minus:SetParent(f)
  f.minus:SetPoint("LEFT", f, "LEFT", 130, 0)
  f.value = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  f.value:SetPoint("LEFT", f.minus, "RIGHT", 6, 0)
  f.value:SetWidth(44)
  f.plus = button("+", 24, function() nudge(step) end)
  f.plus:SetParent(f)
  f.plus:SetPoint("LEFT", f.value, "RIGHT", 6, 0)
  tooltip(f, label, desc)
  function f:refresh() self.value:SetText(fmt:format(get())) end
  widgets[#widgets + 1] = f
  return f
end

local function label(text, font)
  local fs = content:CreateFontString(nil, "ARTWORK", font or "GameFontNormal")
  fs:SetJustifyH("LEFT")
  fs:SetText(text)
  return fs
end

---------------------------------------------------------------------------
-- General settings (a simple top-to-bottom column)
---------------------------------------------------------------------------
local y = 0
local function place(frame, x, h)
  frame:ClearAllPoints()
  frame:SetPoint("TOPLEFT", content, "TOPLEFT", x or 16, -y)
  y = y + (h or ROW)
end

local function heading(text)
  y = y + 8
  place(label(text, "GameFontNormalLarge"), 16, 26)
end

local function buildGeneral()
  local title = label("Assist Companion", "GameFontNormalHuge")
  place(title, 16, 30)
  place(label("Settings are saved per character. /ac opens this menu; /ac help lists the commands.",
    "GameFontHighlightSmall"), 16, 22)

  heading("Icons")
  place(checkbox("Show the next-cast icon", "The highlight's suggestion, or a correction with a gold border.",
    function() return db().nextIcon end, function(v) db().nextIcon = v end), 16)

  place(label("Show the next-cast icon:", "GameFontHighlight"), 44, 22)
  local modes = {
    { "always", "Always" },
    { "target", "In combat or with an enemy targeted" },
    { "combat", "Only in combat" },
  }
  for _, m in ipairs(modes) do
    local value = m[1]
    local rb = checkbox(m[2], nil, function() return db().showMode == value end,
      function() db().showMode = value end)
    place(rb, 44)
  end
  place(checkbox("Show while dead", "Keep the icons on screen while you're dead or a ghost.",
    function() return db().showWhenDead end, function(v) db().showWhenDead = v end), 16)
  place(checkbox("Global cooldown swipe", "A cooldown swipe over the icon during the global cooldown.",
    function() return db().gcdSwipe end, function(v) db().gcdSwipe = v; C.updateGCD() end), 16)
  place(checkbox("Text alerts", "A text box explaining each correction, as well as the icon.",
    function() return db().showText end, function(v) db().showText = v end), 16)
  place(checkbox("Lock frames", "Uncheck to drag the icons, the opener bar and the text box.",
    function() return db().locked end, function(v) cmd(v and "lock" or "unlock") end), 16)
  place(stepper("Icon size", "Next-cast icon size in pixels.",
    function() return db().iconSize end,
    function(v) db().iconSize = v; C.layoutAll(); C.updateHealthIcon() end, 4, 24, 128, "%d"), 16)
  place(stepper("Scale", "Scales the icons, opener bar and text box together.",
    function() return db().scale end,
    function(v) db().scale = v; C.layoutAll() end, 0.05, 0.5, 2.5, "%.2f"), 16)
  local test = button("Show a test icon", 150, function() cmd("test") end)
  place(test, 20, 28)
  local reset = button("Reset positions", 150, function() cmd("reset") end)
  reset:SetPoint("LEFT", test, "RIGHT", 10, 0)

  heading("Opener")
  place(checkbox("Opener bar", "A row of icons with the optimal opening casts, before and at the start of a pull.",
    function() return db().opener end, function(v) db().opener = v end), 16)
  place(checkbox("Next-cast icon follows the opener", "While the opener runs, the next-cast icon shows its steps (blue border).",
    function() return db().openerIcon end, function(v) db().openerIcon = v end), 16)
  local restart = button("Restart opener", 150, function() C.buildOpener() end)
  place(restart, 20, 28)

  heading("Debug")
  place(checkbox("Debug log", "Logs what the addon sees to its saved file. /reload or log out to write it.",
    function() return db().debug end,
    function(v) if v ~= (db().debug and true or false) then cmd("debug") end end), 16)
  place(checkbox("Also print debug lines to chat", nil,
    function() return db().debugChat end, function(v) db().debugChat = v end), 16)
  local clear = button("Clear debug log", 150, function() cmd("log clear") end)
  place(clear, 20, 28)
  local size = clear:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  size:SetPoint("LEFT", clear, "RIGHT", 10, 0)
  widgets[#widgets + 1] = { refresh = function()
    local n, max = C.logSize()
    size:SetText(("%d of %d lines"):format(n, max))
  end }

  heading("Abilities")
  place(label("Turn each correction on or off for a spec. Click a class or spec to open it.",
    "GameFontHighlightSmall"), 16, 22)
  treeTop = y
end

---------------------------------------------------------------------------
-- Class > spec > ability tree
---------------------------------------------------------------------------
local function specName(info)
  if GetSpecializationInfoByID then
    local ok, _, name, _, icon, _, _, className = pcall(GetSpecializationInfoByID, info.id)
    if ok and type(name) == "string" then return name, icon, className end
  end
  return info.name, nil, info.className
end

local function classColor(class)
  local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
  if c then return c.r, c.g, c.b end
  return 1, 0.82, 0
end

-- Rebuild the tree's positions: only rows whose parents are open are shown.
local function layoutTree()
  local yy = treeTop
  for _, r in ipairs(rows) do
    local open = (not r.class or expanded[r.class]) and (not r.spec or expanded[r.spec])
    r.frame:SetShown(open)
    if open then
      r.frame:ClearAllPoints()
      r.frame:SetPoint("TOPLEFT", content, "TOPLEFT", 16 + r.depth * INDENT, -yy)
      yy = yy + ROW
    end
    if r.arrow then r.arrow:SetText(expanded[r.key] and "-" or "+") end
  end
  content:SetHeight(yy + 20)
end

-- A clickable class or spec line that opens/closes the lines under it.
local function branch(key, text, depth, parentClass, icon, r, g, b)
  local f = CreateFrame("Button", nil, content)
  f:SetSize(360, ROW - 2)
  local arrow = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  arrow:SetPoint("LEFT", f, "LEFT", 4, 0)
  arrow:SetWidth(14)
  local anchor = arrow
  if icon then
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetSize(20, 20)
    f.icon:SetPoint("LEFT", arrow, "RIGHT", 6, 0)
    f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    f.icon:SetTexture(icon)
    anchor = f.icon
  end
  f.text = f:CreateFontString(nil, "ARTWORK", depth == 0 and "GameFontNormalLarge" or "GameFontNormal")
  f.text:SetPoint("LEFT", anchor, "RIGHT", 6, 0)
  f.text:SetText(text)
  if r then f.text:SetTextColor(r, g, b) end
  f:SetScript("OnClick", function()
    expanded[key] = not expanded[key]
    layoutTree()
  end)
  rows[#rows + 1] = { frame = f, depth = depth, class = parentClass, key = key, arrow = arrow }
  return f
end

local function buildTree()
  local seenClass = {}
  for _, info in ipairs(ns.specInfo or {}) do
    local name, icon, className = specName(info)
    local classKey = "class:" .. info.class
    if not seenClass[info.class] then
      seenClass[info.class] = true
      branch(classKey, className or info.className, 0, nil, nil, classColor(info.class))
    end
    local specKey = "spec:" .. info.id
    local spec = branch(specKey, name, 1, classKey, icon)
    -- "3 of 4 on" after the spec name
    spec.count = spec:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    spec.count:SetPoint("LEFT", spec.text, "RIGHT", 8, 0)
    local id = info.id
    widgets[#widgets + 1] = { refresh = function()
      local on, total = 0, 0
      for _, rule in ipairs(ns.rules[id] or {}) do
        total = total + 1
        if ns.ruleEnabled(id, rule.key) then on = on + 1 end
      end
      spec.count:SetText(("%d of %d on"):format(on, total))
    end }
    for _, rule in ipairs(ns.rules[id] or {}) do
      local key = rule.key
      local cb = checkbox(rule.name, rule.desc,
        function() return ns.ruleEnabled(id, key) end,
        function(v) ns.setRuleEnabled(id, key, v) end, rule.spell)
      rows[#rows + 1] = { frame = cb, depth = 2, class = classKey, spec = specKey, ruleKey = key, specID = id }
    end
    for _, opt in ipairs(ns.specOptions and ns.specOptions[id] or {}) do
      local key = opt.key
      local cb = checkbox(opt.name, opt.desc,
        function() return db()[key] end,
        function(v) db()[key] = v; C.updateHealthIcon() end, opt.spell)
      rows[#rows + 1] = { frame = cb, depth = 2, class = classKey, spec = specKey, optionKey = key, specID = id }
    end
  end
  -- Open the class and spec you're playing.
  local current = C.specID()
  for _, info in ipairs(ns.specInfo or {}) do
    if info.id == current then
      expanded["class:" .. info.class] = true
      expanded["spec:" .. info.id] = true
    end
  end
  layoutTree()
end

---------------------------------------------------------------------------
-- Panel and registration
---------------------------------------------------------------------------
local function makeScroll()
  -- Newer clients: ScrollFrameTemplate; older: UIPanelScrollFrameTemplate; else a plain
  -- scroll frame driven by the mouse wheel.
  for _, template in ipairs({ "ScrollFrameTemplate", "UIPanelScrollFrameTemplate" }) do
    local ok, f = pcall(CreateFrame, "ScrollFrame", nil, panel, template)
    if ok and f then return f end
  end
  local f = CreateFrame("ScrollFrame", nil, panel)
  f:EnableMouseWheel(true)
  f:SetScript("OnMouseWheel", function(self, delta)
    local range = self:GetVerticalScrollRange() or 0
    self:SetVerticalScroll(math.max(0, math.min(range, self:GetVerticalScroll() - delta * 40)))
  end)
  return f
end

local function build()
  if built then return end
  built = true
  local scroll = makeScroll()
  scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -6)
  scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -28, 6)
  content = CreateFrame("Frame", nil, scroll)
  content:SetSize(600, 1000)
  scroll:SetScrollChild(content)
  buildGeneral()
  buildTree()
end

function ns.initOptions(core)
  C = core
  if panel then return end
  panel = CreateFrame("Frame", "AssistCompanionOptions")
  panel.name = "Assist Companion"
  panel:SetScript("OnShow", function()
    build()
    refreshAll()
  end)
  if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
    category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
  elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
  end
end

-- Opens the menu. Returns true if it could.
function ns.openOptions()
  if category and Settings and Settings.OpenToCategory then
    local id = (category.GetID and category:GetID()) or category.ID
    return (pcall(Settings.OpenToCategory, id))
  elseif panel and InterfaceOptionsFrame_OpenToCategory then
    return (pcall(InterfaceOptionsFrame_OpenToCategory, panel))
  end
  return false
end

-- For tests.
ns.optionsRows = rows
ns.optionsExpanded = expanded
ns.optionsWidgets = widgets

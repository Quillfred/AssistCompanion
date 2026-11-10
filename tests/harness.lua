-- Minimal mock of the WoW API, enough to load Assist Companion and drive its rules.
local dir = arg[1]
local now = 100
local state = { bars = {}, spec = 252, next = nil, rp = 0, known = {}, overrides = {}, plates = {} }
local printed = {}

-- frames
local function newFrame()
  local f = { scripts = {}, shown = false, size = {} }
  local function tex()
    local t = { shown = true, size = {} }
    function t:SetSize(w, h) self.size = { w, h } end
    function t:SetPoint(point, rel, x, y)
      self.pts = self.pts or {}
      if type(rel) == "table" then self.pts[point] = { x or 0, y or 0 } end
    end
    function t:SetTexCoord() end
    function t:SetAllPoints() end
    function t:SetColorTexture(r, g, b) self.color = { r, g, b } end
    function t:SetDrawLayer() end
    function t:SetTexture(x) self.texture = x end
    function t:SetAlpha(a) self.alpha = a end
    function t:SetVertexColor(r, g, b) self.color = { r, g, b } end
    function t:SetDesaturated(v) self.desat = v end
    function t:SetShown(v) self.shown = v and true or false end
    function t:ClearAllPoints() end
    function t:Show() self.shown = true end
    function t:Hide() self.shown = false end
    return t
  end
  local function fs()
    local s = { text = "" }
    function s:SetPoint() end
    function s:SetJustifyH() end
    function s:SetTextColor() end
    function s:SetText(x) self.text = x end
    function s:SetWidth() end
    function s:ClearAllPoints() end
    return s
  end
  function f:CreateTexture() return tex() end
  function f:CreateFontString() return fs() end
  function f:SetSize() end
  function f:SetMovable() end
  function f:SetAlpha(a) self.alpha = a end
  function f:SetFrameStrata(x) self.strata = x end
  function f:SetFrameLevel(x) self.level = x end
  function f:GetFrameLevel() return self.level or 1 end
  function f:SetAllPoints() end
  function f:SetDrawEdge() end
  function f:SetDrawBling() end
  function f:SetHideCountdownNumbers() end
  function f:SetCooldown(st, d, m)
    if st == "SECRET_COMPARE_TRAP" then error("addon compared a secret") end
    self.cd = { start = st, duration = d, via = "SetCooldown" }
  end
  function f:SetCooldownFromDurationObject(obj) self.cd = { obj = obj, via = "duration" } end
  function f:SetToplevel(x) self.toplevel = x end
  function f:SetClampedToScreen() end
  function f:Show() self.shown = true end
  function f:Hide() self.shown = false end
  function f:SetShown(v) self.shown = v and true or false end
  function f:SetScript(n, fn) self.scripts[n] = fn end
  function f:ClearAllPoints() end
  function f:SetPoint(...) self.point = { ... } end
  function f:SetScale() end
  function f:EnableMouse() end
  function f:SetBackdrop() end
  function f:SetBackdropColor() end
  function f:RegisterEvent() end
  function f:RegisterUnitEvent() end
  -- options menu widgets
  function f:SetChecked(v) self.checked = v end
  function f:GetChecked() return self.checked end
  function f:SetText(x) self.text = x end
  function f:SetParent(p) self.parent = p end
  function f:GetParent() return self.parent end
  function f:IsShown() return self.shown end
  function f:SetWidth() end
  function f:SetHeight(h) self.height = h end
  function f:SetScrollChild(c) self.child = c end
  function f:EnableMouseWheel() end
  function f:GetVerticalScrollRange() return 0 end
  function f:GetVerticalScroll() return 0 end
  function f:SetVerticalScroll() end
  function f:Click(b) if self.scripts.OnClick then self.scripts.OnClick(self, b or "LeftButton") end end
  function f:RegisterForClicks() end
  function f:RegisterForDrag() end
  function f:SetHighlightTexture() end
  return f
end
local frames = {}
function CreateFrame(_, name, parent)
  local f = newFrame(); f.parent = parent; frames[#frames + 1] = f; if name then _G[name] = f end; return f
end
UIParent = {}
function GetTime() return now end
function print(...) printed[#printed + 1] = table.concat({ ... }, " ") end
function wipe(t) for k in pairs(t) do t[k] = nil end return t end
function CopyTable(t) local c = {} for k, v in pairs(t) do c[k] = type(v) == "table" and CopyTable(v) or v end return c end
SlashCmdList = {}
Enum = { PowerType = { RunicPower = 6 } }
C_SpecializationInfo = {
  GetSpecialization = function() return 1 end,
  GetSpecializationInfo = function() return state.spec end,
}
C_SpellBook = { IsSpellKnown = function(id) return state.known[id] or false end }
C_Spell = {
  GetOverrideSpell = function(id) return state.overrides[id] or id end,
  GetSpellTexture = function(id) return "icon:" .. id end,
  GetSpellName = function(id) return "spell" .. id end,
  IsSpellInRange = function(id) state.rangeAsked = state.rangeAsked or {}; state.rangeAsked[id] = true; return state.inRange end,
}
C_ActionBar = {
  FindSpellActionButtons = function(id) return state.bars[id] and { state.bars[id] } or {} end,
  IsActionInRange = function() return state.barRange end,
}
C_AssistedCombat = { GetNextCastSpell = function() return state.next end }
function UnitPower() return state.rp end
function UnitPowerMax() if state.rpmaxSecret then return "SECRET" end return state.rpmax or 100 end
C_NamePlate = { GetNamePlates = function()
  local t = {} for i = 1, state.plates do t[i] = { namePlateUnitToken = "nameplate" .. i } end return t end }
function UnitCanAttack() return true end
function UnitAffectingCombat() return true end
function UnitIsDead() return false end
function UnitExists(u)
  if u == "pet" then return state.pet or false end
  return state.target ~= false
end

local settings = {}
Settings = {
  RegisterCanvasLayoutCategory = function(frame, name)
    settings.panel, settings.name = frame, name
    return { GetID = function() return 77 end }
  end,
  RegisterAddOnCategory = function(cat) settings.registered = cat end,
  OpenToCategory = function(id) settings.opened = id end,
}

Minimap = newFrame()
function Minimap:GetWidth() return 140 end
function Minimap:GetCenter() return 1000, 500 end
function Minimap:GetEffectiveScale() return 1 end
local cursor = { 0, 0 }
function GetCursorPosition() return cursor[1], cursor[2] end

-- load addon files with a shared namespace
local ns = {}
for _, file in ipairs({ "Rules.lua", "Core.lua", "Options.lua", "Minimap.lua" }) do
  local chunk = assert(loadfile(dir .. "/" .. file))
  chunk("AssistCompanion", ns)
end
local display, ob, nf = AssistCompanionFrame, AssistCompanionOpener, AssistCompanionNext
local driver, events
for _, f in ipairs(frames) do
  if f.scripts.OnEvent then events = f elseif f.scripts.OnUpdate and not driver and f ~= nf then driver = f end
end
events.scripts.OnEvent(events, "ADDON_LOADED", "AssistCompanion")
expect_default_text = AssistCompanionDB.showText
expect_default_size = AssistCompanionDB.iconSize
AssistCompanionDB.showText = true -- the rule tests below read the text alert box
expect_default_openericon = AssistCompanionDB.openerIcon
AssistCompanionDB.openerIcon = false -- rule tests check the icon without the opener taking over
events.scripts.OnEvent(events, "PLAYER_LOGIN")

local function step() now = now + 0.2; driver.scripts.OnUpdate(driver, 0.2) end
local function cast(id) events.scripts.OnEvent(events, "UNIT_SPELLCAST_SUCCEEDED", "player", "guid", id) end
local function seen() return display.shown and display.icon.shown and display.icon.texture or "nothing",
  display.text.text, display.icon.size[1] end

local pass, fail = 0, 0
local function expect(label, want, got)
  if want == got then pass = pass + 1; print(("PASS  %s"):format(label))
  else fail = fail + 1; print(("FAIL  %s: wanted %s, got %s"):format(label, tostring(want), tostring(got))) end
end

expect("Display: strata is HIGH", "HIGH", display.strata)
expect("Display: frame level is high", 9000, display.level)

-- UNHOLY -----------------------------------------------------------------
state.spec = 252; state.known = { [207317] = true, [433901] = true }
events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED")
-- Blightfall loop: DT button is Blightfall and the highlight says Outbreak
state.overrides = { [1233448] = 1271967 }; state.next = 77575; state.rp = 30; step()
expect("Unholy: Outbreak loop -> Blightfall icon", "icon:1271967", (seen()))
-- after pressing Blightfall the button reverts; Outbreak suggestion is now legit
state.overrides = {}; step()
expect("Unholy: real Outbreak -> no alert", "nothing", (seen()))
-- RP cap, single target, highlight wants Scourge Strike
state.next = 55090; state.rp = 90; state.plates = 1; step()
expect("Unholy: 90 RP + Scourge, 1 target -> Death Coil", "icon:47541", (seen()))
-- RP cap at 5 targets -> Epidemic
state.plates = 5; step()
expect("Unholy: 90 RP + Scourge, 5 targets -> Epidemic", "icon:207317", (seen()))
-- Clawing Shadows replacing Scourge Strike counts as a rune spender
state.overrides = { [55090] = 207311 }; state.next = 207311; state.plates = 1; step()
expect("Unholy: Clawing Shadows override counts as spender", "icon:47541", (seen()))
-- Below threshold -> nothing
state.rp = 60; step()
expect("Unholy: 60 RP -> no alert", "nothing", (seen()))
-- Highlight already suggests Death Coil -> nothing
state.rp = 95; state.next = 47541; step()
expect("Unholy: highlight already says Death Coil -> no alert", "nothing", (seen()))

-- FROST ------------------------------------------------------------------
state.spec = 251; state.known = { [1249658] = true, [207230] = true }
events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED")
state.overrides = {}; state.next = 49143; state.plates = 1
step()
expect("Frost: no Pillar yet -> no alert", "nothing", (seen()))
cast(51271); step()
local icon, text, size = seen()
expect("Frost: Pillar cast -> Breath icon", "icon:1249658", icon)
expect("Frost: Breath alert has no text", "", text)
expect("Frost: Breath icon is 48px", 48, size)
expect("Frost: no trinket note while Breath icon shows", "", nf.note.text)
cast(1249658); step()
expect("Frost: Breath cast -> icon gone", "nothing", (seen()))
now = now + 50; cast(51271); step()
expect("Frost: next Pillar while Breath on cooldown -> no Breath icon", "nothing", (seen()))
expect("Frost: trinket reminder shows instead", "Pillar: use trinkets, potion and racial", nf.note.text)
now = now + 80; cast(51271); step()
expect("Frost: Pillar after Breath cooldown -> Breath icon again", "icon:1249658", (seen()))
now = now + 13; step()
expect("Frost: Pillar window over -> icon gone", "nothing", (seen()))
-- Chosen of Frostbrood (rank 2): Frostwyrm's Fury during Pillar extends it 2s
state.known[1265633] = true; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED")
now = now + 200; cast(51271); now = now + 3; cast(279302); now = now + 10.5; step()
expect("Frost: Chosen of Frostbrood -> Breath still shown 13.5s into Pillar (14s with Frostwyrm's Fury)", "icon:1249658", (seen()))
now = now + 1; step()
expect("Frost: ...gone after 14s", "nothing", (seen()))
state.known[1265633] = nil; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED")
state.plates = 3; state.next = 49020; step()
expect("Frost: 3 targets + Obliterate -> Frostscythe", "icon:207230", (seen()))
state.plates = 5; step()
expect("Frost: 5 targets -> no Frostscythe nag", "nothing", (seen()))
-- Owner's logs: training dummies never report "in combat"; count enemies within melee range instead
local savedCombat = UnitAffectingCombat
UnitAffectingCombat = function() return false end
state.plates = 3; state.inRange = true; step()
expect("Count: 3 dummies in melee range, none 'in combat' -> 3 (Frostscythe)", "icon:207230", (seen()))
state.inRange = false; step()
expect("Count: 3 dummies out of range and not in combat -> 0 (no Frostscythe)", "nothing", (seen()))
state.inRange = nil; step()
expect("Count: range hidden and not in combat -> unknown (no Frostscythe)", "nothing", (seen()))
UnitAffectingCombat = savedCombat; state.inRange = nil
-- Breath not talented: no alert even after Pillar
state.known = { [207230] = true }; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED"); state.plates = 1
now = now + 200; cast(51271); step()
expect("Frost: Breath not talented -> no Breath icon", "nothing", (seen()))

-- Empower Rune Weapon suggested while out of melee range
state.known = { [1249658] = true, [207230] = true }; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED")
now = now + 200; state.plates = 1; state.next = 47568; state.inRange = false; step()
local i2, t2 = seen()
expect("Frost: ERW suggested out of range -> Pillar icon", "icon:51271", i2)
expect("Frost: ERW out of range text", "Wait: get in melee", t2)
state.inRange = true; step()
expect("Frost: ERW in melee -> no alert", "nothing", (seen()))
state.inRange = nil; step()
expect("Frost: ERW with unknown range -> no alert", "nothing", (seen()))
state.inRange = false; state.target = false; step()
expect("Frost: ERW with no target -> no alert", "nothing", (seen()))
state.target = nil

-- OPENER ----------------------------------------------------------------
-- combat(false) is a real end of fight: out of combat long enough (6s) for the next-pull reset.
-- combat(false, true) is a short drop (e.g. Deep Breath flying off dummies).
local function combat(on, shortDrop)
  events.scripts.OnEvent(events, on and "PLAYER_REGEN_DISABLED" or "PLAYER_REGEN_ENABLED")
  if not on and not shortDrop then now = now + 6.1; driver.scripts.OnUpdate(driver, 0.2) end
end
local function openerIcons() local t = {} for i = 1, 6 do local s = ob.slots[i]; if s.shown then t[#t+1] = s.texture end end return table.concat(t, ",") end
state.spec = 251; state.inRange = true; state.target = nil
state.known = { [47568]=true, [51271]=true, [1249658]=true, [49020]=true, [279302]=true, [49143]=true } -- no Reaper's Mark
events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED"); now = now + 300; step()
expect("Opener: Frost shows before pull with hostile target", true, ob.shown)
expect("Opener: Frost Rider (no Reaper's Mark): ERW, Obliterate, Pillar, Breath, ERW, Obliterate",
  "icon:47568,icon:49020,icon:51271,icon:1249658,icon:47568,icon:49020", openerIcons())
expect("Opener: Rider is 11 steps", "Opener 1/11", ob.label.text)
state.known[439843] = true; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED"); step()
expect("Opener: Frost Deathbringer: ERW, Pillar, Reaper's Mark, Breath, Obliterate, Frostwyrm's Fury",
  "icon:47568,icon:51271,icon:439843,icon:1249658,icon:49020,icon:279302", openerIcons())
expect("Opener: label", "Opener 1/9", ob.label.text)
expect("Opener: first icon is large", 44, ob.slots[1].size[1])
combat(true); cast(47568); step()
expect("Opener: advances after first cast", "Opener 2/9", ob.label.text)
cast(1249658); step() -- pressed Breath before Pillar and Reaper's Mark: Breath ticked off, those still pending
expect("Opener: out-of-order cast keeps the skipped steps pending", "Opener 2/9", ob.label.text)
expect("Opener: ...Pillar first, Breath gone", "icon:51271,icon:439843,icon:49020,icon:279302,icon:49020,icon:49020", openerIcons())
cast(49020); step()   -- a second cast past Pillar and Reaper's Mark: dropped
expect("Opener: a step passed by two later casts is dropped", "Opener 6/9", ob.label.text)
cast(279302); cast(49020); cast(49020); cast(49020); step()
expect("Opener: finished -> hidden", false, ob.shown)
combat(false); step()
expect("Opener: resets after combat", "Opener 1/9", ob.label.text)
state.target = false; step()
expect("Opener: hidden with no target out of combat", false, ob.shown)
state.target = nil; combat(true); now = now + 30; step()
expect("Opener: hidden 25s into combat", false, ob.shown)
combat(false)
-- Unholy: Raise Dead skipped when the ghoul is out
state.spec = 252; state.pet = true
state.known = { [46584]=true, [77575]=true, [85948]=true, [42650]=true, [1233448]=true, [1247378]=true, [47541]=true }
events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED"); step()
expect("Opener: Unholy with ghoul out starts at Outbreak", "icon:77575", ob.slots[1].texture)
expect("Opener: Unholy length without Raise Dead", "Opener 1/9", ob.label.text)
state.pet = false; events.scripts.OnEvent(events, "UNIT_PET", "player"); step()
expect("Opener: Unholy with no ghoul starts at Raise Dead", "icon:46584", ob.slots[1].texture)
-- Dark Transformation turned into Blightfall still counts for that step
state.pet = true; events.scripts.OnEvent(events, "UNIT_PET", "player"); combat(true)
cast(77575); cast(85948); cast(85948); cast(42650); state.overrides = { [1233448] = 1271967 }; cast(1271967); step()
expect("Opener: Blightfall cast counts as the Dark Transformation step", "icon:1247378", ob.slots[1].texture)
combat(false); state.overrides = {}

-- NEXT-CAST ICON ---------------------------------------------------------
expect("Defaults: text alerts off", false, expect_default_text)
expect("Defaults: icon size 48", 48, expect_default_size)
expect("Next icon: 48px", 48, nf.icon.size[1])
expect("Next icon: HIGH strata", "HIGH", nf.strata)
expect("Opener bar: HIGH strata", "HIGH", AssistCompanionOpener.strata)
expect("Low-health icon: HIGH strata", "HIGH", AssistCompanionHealth.strata)
function GetBindingKey(cmd)
  local map = { ACTIONBUTTON3 = "F", MULTIACTIONBAR1BUTTON2 = "SHIFT-2" }
  return map[cmd]
end
state.spec = 252; state.known = { [207317] = true, [433901] = true }; state.pet = true
events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED")
state.bars = { [55090] = 3, [47541] = 62, [77575] = 5 }; state.target = nil; state.overrides = {}
state.next = 55090; state.rp = 30; state.plates = 1; state.barRange = true; step()
expect("Next icon: shows highlight's suggestion", "icon:55090", nf.icon.texture)
expect("Next icon: keybind from main bar slot", "F", nf.key.text)
expect("Next icon: no border when not corrected", false, nf.border.shown)
state.rp = 95; step()
expect("Next icon: RP cap corrects to Death Coil", "icon:47541", nf.icon.texture)
expect("Next icon: correction has gold border", true, nf.border.shown)
expect("Next icon: shortened modifier keybind", "S2", nf.key.text)
state.rp = 30; state.barRange = false; step()
expect("Next icon: out of range tinted red", 0.3, nf.icon.color[2])
state.barRange = true; step()
expect("Next icon: in range normal color", 1, nf.icon.color[2])
state.overrides = { [1233448] = 1271967 }; state.next = 77575; step()
expect("Next icon: Blightfall loop corrected", "icon:1271967", nf.icon.texture)
state.overrides = {}
-- Frost ERW out of range: keep ERW, tint + desaturate, no gold border
state.spec = 251; state.known = { [1249658] = true, [207230] = true }
events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED")
now = now + 400; state.next = 47568; state.inRange = false; state.barRange = nil; step()
expect("Next icon: ERW out of range keeps ERW icon", "icon:47568", nf.icon.texture)
expect("Next icon: ERW wait is desaturated", true, nf.icon.desat)
expect("Next icon: ERW wait has no gold border", false, nf.border.shown)
expect("Text alert: clearer ERW wording", "Then Empower Rune Weapon + Pillar of Frost", display.sub.text)
-- Breath during Pillar shows on the next icon
state.inRange = true; state.next = 49020; cast(51271); step()
expect("Next icon: Breath correction during Pillar", "icon:1249658", nf.icon.texture)
expect("Next icon: no reminder text under the Breath icon", "", nf.note.text)
cast(1249658); step()
expect("Next icon: reminder shows once Breath is used", "Pillar: use trinkets, potion and racial", nf.note.text)
-- no target, out of combat: hidden
state.target = false; now = now + 30; step()
expect("Always show: visible with no target out of combat", true, nf.shown)
expect("Always show: default mode", "always", AssistCompanionDB.showMode)
local lastIcon = nf.icon.texture
state.next = nil; step()
expect("Always show: no suggestion keeps last icon", lastIcon, nf.icon.texture)
expect("Always show: kept icon is grayed out", true, nf.icon.desat)
expect("Always show: still visible", true, nf.shown)
state.next = 49020; step()
expect("Always show: new suggestion not grayed", false, nf.icon.desat)
AssistCompanionDB.showMode = "target"; step()
expect("Show mode target: hidden with no target out of combat", false, nf.shown)
state.target = nil; step()
expect("Show mode target: shown with an enemy targeted", true, nf.shown)
AssistCompanionDB.showMode = "combat"; step()
expect("Show mode combat: hidden out of combat even with a target", false, nf.shown)
events.scripts.OnEvent(events, "PLAYER_REGEN_DISABLED"); step()
expect("Show mode combat: shown in combat", true, nf.shown)
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED")
AssistCompanionDB.showMode = "always"
state.target = nil

-- KEYBIND FALLBACK: a bar addon with its own bindings (e.g. EllesmereUI bar 9) ----
local fakeButtons = {
  { action = 121, HotKey = { GetText = function() return "SF" end }, IsVisible = function() return true end },
  { action = 122, HotKey = { GetText = function() return RANGE_INDICATOR end }, IsVisible = function() return true end },
  { action = 123, HotKey = { GetText = function() return "Q" end }, IsVisible = function() return false end },
}
RANGE_INDICATOR = "\226\151\143"
function EnumerateFrames(prev)
  if not prev then return fakeButtons[1] end
  for i, f in ipairs(fakeButtons) do if f == prev then return fakeButtons[i + 1] end end
end
function InCombatLockdown() return false end
state.spec = 252; state.known = { [207317] = true, [433901] = true }; state.pet = true; state.overrides = {}
state.bars = { [85948] = 121 }       -- Festering Strike only on a custom bar slot
events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED")
events.scripts.OnEvent(events, "UPDATE_BINDINGS")
state.next = 85948; state.rp = 10; state.barRange = true; state.target = nil; now = now + 50; step()
expect("Keybind fallback: reads bar addon's button text", "SF", nf.key.text)
state.bars = { [85948] = 122 }; events.scripts.OnEvent(events, "ACTIONBAR_SLOT_CHANGED"); step()
expect("Keybind fallback: ignores range dot", "", nf.key.text)
state.bars = { [85948] = 123 }; events.scripts.OnEvent(events, "ACTIONBAR_SLOT_CHANGED"); step()
expect("Keybind fallback: ignores hidden buttons", "", nf.key.text)
-- In combat: no scan yet -> no key, and the miss isn't cached forever
function InCombatLockdown() return true end
state.bars = { [85948] = 121 }; events.scripts.OnEvent(events, "ACTIONBAR_SLOT_CHANGED"); step()
expect("Keybind fallback: in combat, uses last out-of-combat scan", "SF", nf.key.text)
function InCombatLockdown() return false end
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED"); step()
expect("Keybind fallback: scans after combat ends", "SF", nf.key.text)
-- Blizzard binding still wins when present
state.bars = { [85948] = 3 }; events.scripts.OnEvent(events, "UPDATE_BINDINGS"); step()
expect("Keybind: Blizzard binding (EllesmereUI bars 1-8) still used", "F", nf.key.text)

-- NEXT-CAST ICON FOLLOWS THE OPENER -------------------------------------
expect("Defaults: icon follows opener", true, expect_default_openericon)
AssistCompanionDB.openerIcon = true
function InCombatLockdown() return false end
state.spec = 251; state.target = nil; state.pet = true; state.overrides = {}
state.known = { [47568]=true, [51271]=true, [439843]=true, [1249658]=true, [49020]=true, [279302]=true }
state.bars = { [47568] = 1, [51271] = 2 }
events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED")
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED")
now = now + 500; state.next = 51271; state.inRange = true; state.barRange = nil; step()
expect("Opener icon: in range, icon shows opener step (ERW), not highlight (Pillar)", "icon:47568", nf.icon.texture)
expect("Opener icon: blue border", 0.3, nf.border.color and nf.border.color[1] or nil)
expect("Opener icon: border shown", true, nf.border.shown)
expect("Opener icon: not grayed in melee", false, nf.icon.desat)
state.inRange = false; step()
expect("Opener icon: out of melee, ERW step grayed out", true, nf.icon.desat)
state.inRange = true; combat(true); cast(47568); step()
expect("Opener icon: advances to Pillar after ERW", "icon:51271", nf.icon.texture)
cast(51271); cast(439843); step()
expect("Opener icon: Breath step has no note under it", "", nf.note.text)
expect("Opener icon: Breath step shown", "icon:1249658", nf.icon.texture)
cast(1249658); cast(49020); cast(279302); cast(49020); cast(49020); cast(49020); state.next = 49143; step()
expect("Opener icon: after opener, back to highlight", "icon:49143", nf.icon.texture)
expect("Opener icon: gold border color restored", 1, nf.border.color[1])
combat(false)
AssistCompanionDB.openerIcon = false

-- RESET FOR THE NEXT PULL (cooldowns assumed reset, as after a wipe) --------
AssistCompanionDB.openerIcon = true
state.spec = 251; state.target = nil; state.overrides = {}; state.inRange = true
state.known = { [47568]=true, [51271]=true, [1249658]=true, [49020]=true, [279302]=true, [439843]=true }
events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED")
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED")
now = now + 600; state.next = 49143; step()
-- pull: Pillar + Breath used, then combat drops (wipe)
combat(true); cast(47568); cast(51271); cast(1249658); step()
expect("Reset: mid-opener before wipe (Reaper's Mark still pending)", "Opener 3/9", ob.label.text)
combat(false); step()
expect("Reset: combat drop -> opener back to step 1", "Opener 1/9", ob.label.text)
-- next pull right away: Breath must count as ready even though it was cast <120s ago
AssistCompanionDB.openerIcon = false
combat(true); now = now + 5; cast(51271); state.next = 49020; step()
expect("Reset: Breath treated as off cooldown after combat drop", "icon:1249658", nf.icon.texture)
combat(false); AssistCompanionDB.openerIcon = true
-- a short combat drop (Deep Breath flying off dummies) is the same fight: nothing resets
combat(true); cast(47568); cast(51271); step()
expect("Short drop: mid-opener", "Opener 3/9", ob.label.text)
combat(false, true); now = now + 3; step(); combat(true); step()
expect("Short drop: back in combat within 6s -> opener kept", "Opener 3/9", ob.label.text)
combat(false)
-- death resets mid-pull
combat(true); cast(47568); cast(51271); step()
events.scripts.OnEvent(events, "PLAYER_DEAD"); step()
expect("Reset: death -> opener back to step 1", "Opener 1/9", ob.label.text)
combat(false)
-- encounter end resets
combat(true); cast(47568); step()
events.scripts.OnEvent(events, "ENCOUNTER_END"); combat(false); step()
expect("Reset: encounter end -> step 1", "Opener 1/9", ob.label.text)
-- out-of-combat press: stays advanced briefly, resets after 10s idle
cast(47568); step()
expect("Reset: out-of-combat press advances", "Opener 2/9", ob.label.text)
now = now + 5; step()
expect("Reset: still advanced after 5s", "Opener 2/9", ob.label.text)
now = now + 6; step()
expect("Reset: reset after 10s idle out of combat", "Opener 1/9", ob.label.text)
AssistCompanionDB.openerIcon = false

-- OPENER SURVIVES MID-COMBAT SPELLBOOK UPDATES ----------------------------
AssistCompanionDB.openerIcon = true
state.spec = 251; state.target = nil; state.overrides = {}; state.inRange = true
state.known = { [47568]=true, [51271]=true, [439843]=true, [1249658]=true, [49020]=true, [279302]=true }
events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED")
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED"); now = now + 700; step()
combat(true)
cast(47568); cast(51271); cast(439843); cast(1249658); cast(49020); cast(279302); cast(49020); step()
expect("Opener bug: at step 8 of 9 (two Obliterates left)", "Opener 8/9", ob.label.text)
events.scripts.OnEvent(events, "SPELLS_CHANGED"); step() -- e.g. Pillar of Frost ends
expect("Opener bug: SPELLS_CHANGED mid-combat does not reset", "Opener 8/9", ob.label.text)
events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED"); step()
expect("Opener bug: talent event mid-combat does not reset", "Opener 8/9", ob.label.text)
cast(49020); cast(49020); step()
expect("Opener bug: finishes normally", false, ob.shown)
combat(false); step()
expect("Opener bug: still resets on combat drop", "Opener 1/9", ob.label.text)
-- out of combat, mid-opener: SPELLS_CHANGED keeps progress; a real talent change rebuilds
cast(47568); events.scripts.OnEvent(events, "SPELLS_CHANGED"); step()
expect("Opener bug: SPELLS_CHANGED out of combat keeps progress", "Opener 2/9", ob.label.text)
events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED"); step()
expect("Opener bug: talent change out of combat rebuilds", "Opener 1/9", ob.label.text)
AssistCompanionDB.openerIcon = false

-- GCD SWIPE ----------------------------------------------------------------
local gcdFrame = nf.gcd
expect("GCD: swipe frame exists on the icon", true, gcdFrame ~= nil)
C_Spell.GetSpellCooldownDuration = function(id) if id == 61304 then return { kind = "durationObject" } end end
events.scripts.OnEvent(events, "SPELL_UPDATE_COOLDOWN")
expect("GCD: uses duration object when available", "duration", gcdFrame.cd and gcdFrame.cd.via)
expect("GCD: shown when enabled", true, gcdFrame.shown)
-- fallback path with secret values: passed through untouched, never compared
C_Spell.GetSpellCooldownDuration = nil
C_Spell.GetSpellCooldown = function(id) return { startTime = "SECRET", duration = "SECRET", modRate = 1 } end
events.scripts.OnEvent(events, "SPELL_UPDATE_COOLDOWN")
expect("GCD: fallback SetCooldown", "SetCooldown", gcdFrame.cd.via)
expect("GCD: secret start passed straight through", "SECRET", gcdFrame.cd.start)
-- swipe refreshes on your own casts too
gcdFrame.cd = nil; cast(49020)
expect("GCD: refreshed on cast", "SetCooldown", gcdFrame.cd and gcdFrame.cd.via)
-- API missing entirely: no error
C_Spell.GetSpellCooldown = nil; gcdFrame.cd = nil
local okNoApi = pcall(events.scripts.OnEvent, events, "SPELL_UPDATE_COOLDOWN")
expect("GCD: no cooldown API -> no error", true, okNoApi)
-- toggle off
SlashCmdList.ASSISTCOMPANION("gcd")
expect("GCD: /ac gcd hides swipe", false, gcdFrame.shown)
SlashCmdList.ASSISTCOMPANION("gcd")

-- RESOURCE SHADING ON THE NEXT-CAST ICON ----------------------------------
state.usable, state.noPower = {}, {}
C_Spell.IsSpellUsable = function(id) return state.usable[id] ~= false, state.noPower[id] or false end
AssistCompanionDB.openerIcon = false
state.spec = 252; state.known = { [207317] = true, [433901] = true }; state.pet = true; state.overrides = {}
events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED")
state.bars = {}; state.target = nil; state.next = 55090; state.rp = 10; state.plates = 1; state.barRange = true; state.inRange = true
now = now + 800; step()
expect("Shading: usable -> normal", 1, nf.icon.color[3] == 1 and nf.icon.color[1] or 0)
state.usable[55090] = false; state.noPower[55090] = true; step()
expect("Shading: not enough runes -> blue", "0.5,0.5,1", table.concat(nf.icon.color, ","))
state.noPower[55090] = false; step()
expect("Shading: unusable for other reason -> gray", "0.4,0.4,0.4", table.concat(nf.icon.color, ","))
-- The game hides its usable check in combat (owner: Heart Strike with no runes stayed full color).
-- Runes come from GetRuneCooldown (UnitPower reads 6 all the time); hidden resources tint via a curve.
do
  local savedUsable, savedSecret = C_Spell.IsSpellUsable, issecretvalue
  issecretvalue = function(v) return v == "SECRET" end
  C_Spell.IsSpellUsable = function() return "SECRET", "SECRET" end
  local ready = { true, true, false, false, false, false }
  GetRuneCooldown = function(i) return 0, 10, ready[i] end
  local costs = { [55090] = { { type = 5, cost = 1 } }, [47541] = { { type = 6, cost = 30 } } }
  C_Spell.GetSpellPowerCost = function(id) return costs[id] end
  state.usable[55090] = nil; state.noPower[55090] = nil
  step()
  expect("Short: usable check hidden, 2 runes ready, costs 1 -> normal", 1, nf.icon.color[1])
  ready = { false, false, false, false, false, false }; step()
  expect("Short: no runes ready -> blue", "0.5,0.5,1", table.concat(nf.icon.color, ","))
  ready = { true, false, false, false, false, false }
  -- runic power hidden: the blue tint's alpha comes from the game's curve (below cost/max -> 0.55)
  state.next = 47541; state.rp = "SECRET"; state.rpmax = 100
  local pct = 0.2
  local savedCurve = C_CurveUtil
  C_CurveUtil = { CreateCurve = function()
    local c = { pts = {} }
    function c:SetType() end
    function c:AddPoint(x, y) self.pts[#self.pts + 1] = { x, y } end
    function c:Evaluate(x)
      table.sort(self.pts, function(a, b) return a[1] < b[1] end)
      local p = self.pts
      if x <= p[1][1] then return p[1][2] end
      for i = 2, #p do if x <= p[i][1] then local a, b = p[i - 1], p[i]
        return a[2] + (b[2] - a[2]) * (x - a[1]) / (b[1] - a[1]) end end
      return p[#p][2]
    end
    return c
  end }
  UnitPowerPercent = function(unit, ptype, predicted, curve) return curve:Evaluate(pct) end
  step()
  expect("Short: hidden runic power 20 < 30 -> tint shown", 0.55, nf.short.alpha)
  expect("Short: ...icon itself stays normal", 1, nf.icon.color[1])
  pct = 0.5; step()
  expect("Short: 50 >= 30 -> no tint", 0, nf.short.alpha)
  C_Spell.IsSpellUsable, issecretvalue = savedUsable, savedSecret
  GetRuneCooldown, C_Spell.GetSpellPowerCost, UnitPowerPercent, C_CurveUtil = nil, nil, nil, savedCurve
  state.next = 55090; state.rp = 10; state.rpmax = nil; step()
  expect("Short: usable check readable again -> tint cleared", 0, nf.short.alpha)
end
state.noPower[55090] = true; state.barRange = false; state.inRange = false; step()
expect("Shading: out of range beats no-power (red)", "1,0.3,0.3", table.concat(nf.icon.color, ","))
state.barRange = true; state.inRange = true; state.usable, state.noPower = {}, {}

-- OPENER SKIPS SPELLS STILL ON COOLDOWN ------------------------------------
state.cd, state.charges = {}, {}
C_Spell.GetSpellCooldown = function(id)
  local c = state.cd[id]
  if c == "SECRET" then return { startTime = "SECRET", duration = "SECRET" } end
  if c then return { startTime = c[1], duration = c[2] } end
  return { startTime = 0, duration = 0 }
end
C_Spell.GetSpellCharges = function(id)
  local c = state.charges[id]
  if c then return { currentCharges = c[1], maxCharges = c[2], cooldownStartTime = c[3], cooldownDuration = c[4] } end
end
AssistCompanionDB.openerIcon = true
state.spec = 251; state.target = nil; state.overrides = {}; state.inRange = true
state.known = { [47568]=true, [51271]=true, [439843]=true, [1249658]=true, [49020]=true, [279302]=true }
events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED")
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED"); now = now + 900
-- dummy: Pillar used 10s ago (45s cooldown); ERW has 1 of 2 charges
state.cd[51271] = { now - 10, 45 }; state.charges[47568] = { 1, 2, now - 5, 90 }
step()
expect("CD skip: ERW with a charge left stays first", "icon:47568", nf.icon.texture)
cast(47568); step()
expect("CD gray: out of combat, Pillar on cooldown stays on the bar", "Opener 2/9", ob.label.text)
expect("CD gray: ...grayed out", true, ob.slots[1].desat)
expect("CD gray: ...with its seconds left", "35", ob.cds[1].text)
expect("CD gray: ready steps aren't gray", false, ob.slots[2].desat)
expect("CD gray: ...and have no number", "", ob.cds[2].text)
now = now + 5; step()
expect("CD gray: counts down", "30", ob.cds[1].text)
combat(true); step()
expect("CD skip: in combat, Pillar still on cooldown is skipped", "icon:439843", nf.icon.texture)
expect("CD skip: opener moves on past Pillar", "Opener 3/9", ob.label.text)
combat(false); now = now + 40; step()
expect("CD gray: back to full color once ready", false, ob.slots[1].desat)
-- GCD-length cooldown isn't treated as "on cooldown"
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED"); state.cd = { [51271] = { now - 0.2, 1.5 } }; state.charges = {}
now = now + 20; step()
cast(47568); step()
expect("CD skip: GCD-only cooldown does not skip Pillar", "icon:51271", nf.icon.texture)
-- cooldown read out of combat is remembered when combat hides it
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED"); now = now + 20
state.cd = { [51271] = { now, 45 } }; step()          -- out of combat: readable, 45s left
combat(true); state.cd = { [51271] = "SECRET" }; step()
expect("CD skip: in combat, opener still starts at ERW", "icon:47568", nf.icon.texture)
cast(47568); step()
expect("CD skip: Pillar still skipped in combat", "icon:439843", nf.icon.texture)
combat(false)
-- Owner's 0.17.3 log: after a fight on a dummy, the rebuilt opener skipped its cooldown steps,
-- then the idle reset (from casts long ago) rebuilt it again, every frame.
AssistCompanionDB.debug = true; AssistCompanionDB.debugLog = {}
now = now + 30; combat(true); cast(47568); now = now + 30   -- opener cast 30s ago
state.charges = {}; state.cd = { [47568] = { now, 20 }, [51271] = { now, 45 } }; combat(false)
for _ = 1, 20 do step() end
local resets, skips = 0, 0
for _, l in ipairs(AssistCompanionDB.debugLog) do
  if l:find("opener: reset", 1, true) then resets = resets + 1 end
  if l:find("opener: skipped step 2/", 1, true) then skips = skips + 1 end
end
expect("CD skip: rebuilt opener isn't reset again every frame (and out of combat nothing is skipped)", true, resets <= 1 and skips == 0)
expect("CD gray: rebuilt opener keeps its cooldown steps, grayed", true, ob.label.text == "Opener 1/9" and ob.slots[1].desat == true)
AssistCompanionDB.debug = false; AssistCompanionDB.debugLog = nil
-- Breath icon respects Breath's real cooldown after a combat drop on a dummy
AssistCompanionDB.openerIcon = false
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED"); now = now + 20
state.cd = { [1249658] = { now - 30, 120 } }; step()   -- Breath used 30s ago
combat(true); cast(51271); state.next = 49020; step()
expect("Breath: not shown while Breath is on its real cooldown", "icon:49020", nf.icon.texture)
combat(false)
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED"); now = now + 20
state.cd = {}; step()                                    -- wipe: game reset the cooldown
combat(true); cast(51271); step()
expect("Breath: shown when the game says Breath is ready", "icon:1249658", nf.icon.texture)
combat(false)
-- Bug: Breath suggested while on cooldown after being cast in the same pull
AssistCompanionDB.openerIcon = false
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED"); now = now + 30
state.cd = {}; step()                                     -- out of combat: Breath reads as ready
combat(true); state.cd = { [1249658] = "SECRET", [51271] = "SECRET" }  -- combat hides cooldowns
cast(51271); step()
expect("Breath bug: first Pillar of the pull -> Breath", "icon:1249658", nf.icon.texture)
cast(1249658); state.next = 49020; step()
now = now + 60; cast(51271); step()                       -- next Pillar 60s later, Breath has ~60s left
expect("Breath bug: not suggested while its cooldown is still running", "icon:49020", nf.icon.texture)
now = now + 65; cast(51271); step()                       -- 125s after Breath: ready again
expect("Breath bug: suggested again once its cooldown has passed", "icon:1249658", nf.icon.texture)
combat(false)
C_Spell.GetSpellCooldown, C_Spell.GetSpellCharges = nil, nil

-- TEXT BOX HIDDEN WHEN TEXT ALERTS ARE OFF (even unlocked) -----------------
AssistCompanionDB.showText = false
SlashCmdList.ASSISTCOMPANION("unlock"); step()
expect("Text box: hidden when text alerts off, even unlocked", false, display.shown)
expect("Unlocked: next-cast icon still shown for positioning", true, nf.shown)
AssistCompanionDB.showText = true; state.next = nil; step()
expect("Text box: unlocked placeholder when text alerts on", "Text alerts", display.text.text)
expect("Text box: no stray yellow square on placeholder", false, display.border.shown)
SlashCmdList.ASSISTCOMPANION("lock"); step()
expect("Text box: locked with no alert -> hidden", false, display.shown)

-- 2PX BLACK BORDERS ---------------------------------------------------------
expect("Black border: main icon has one", true, nf.black ~= nil)
expect("Black border: main icon is black", "0,0,0", nf.black and table.concat(nf.black.color, ",") or nil)
expect("Black border: main icon 2px", "-2,2", nf.black and table.concat(nf.black.pts.TOPLEFT, ","))
expect("Black border: colored border sits outside it", "-4,4", table.concat(nf.border.pts.TOPLEFT, ","))
AssistCompanionDB.openerIcon = true
state.spec = 251; state.target = nil; state.overrides = {}
state.known = { [47568]=true, [51271]=true, [1249658]=true, [49020]=true, [279302]=true }
events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED")
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED"); now = now + 2000; step()
expect("Black border: opener icons have them", true, ob.blacks[1].shown and ob.blacks[6].shown)
expect("Black border: opener border is black 2px", "-2,2", table.concat(ob.blacks[2].pts.TOPLEFT, ","))
expect("Black border: opener gold sits outside it", "-4,4", table.concat(ob.border.pts.TOPLEFT, ","))
combat(true); for _, id in ipairs({47568, 51271, 1249658, 49020}) do cast(id) end; step()
expect("Black border: empty opener slots hide their border", false, ob.blacks[6].shown)
combat(false); AssistCompanionDB.openerIcon = false

-- BLOOD ---------------------------------------------------------------------
-- curve mock: linear interpolation, clamped at the ends (as documented)
C_CurveUtil = { CreateCurve = function()
  local c = { pts = {} }
  function c:SetType(t) self.type = t end
  function c:AddPoint(x, y) self.pts[#self.pts + 1] = { x, y } end
  function c:Evaluate(x)
    local p = self.pts
    table.sort(p, function(a, b) return a[1] < b[1] end)
    if x <= p[1][1] then return p[1][2] end
    for i = 2, #p do
      if x <= p[i][1] then
        local a, b = p[i - 1], p[i]
        return a[2] + (b[2] - a[2]) * (x - a[1]) / (b[1] - a[1])
      end
    end
    return p[#p][2]
  end
  return c
end }
Enum.LuaCurveType = { Linear = 0 }
state.hp, state.hpScale = 1.0, 1
function UnitHealthPercent(unit, predicted, curve)
  if state.hpSecret then return "SECRET_ALPHA" end
  return curve:Evaluate(state.hp * state.hpScale)
end
local hf = AssistCompanionHealth
AssistCompanionDB.openerIcon = false
state.spec = 250; state.pet = true; state.overrides = {}; state.target = nil; state.inRange = true; state.barRange = true
state.known = { [195182]=true, [195292]=true, [49998]=true, [50842]=true, [206930]=true, [46585]=true, [43265]=true }
state.charges = { [50842] = { 2, 2, 0, 0 } }
C_Spell.GetSpellCharges = function(id)
  local c = state.charges and state.charges[id]
  if c then return { currentCharges = c[1], maxCharges = c[2], cooldownStartTime = c[3], cooldownDuration = c[4] } end
end
events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED")
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED"); now = now + 3000
state.next = 206930; state.rp = 10; state.rangeAsked = {}; step()
expect("Blood: melee range uses Heart Strike", true, state.rangeAsked[206930] or false)
expect("Blood: melee range doesn't use Obliterate", false, state.rangeAsked[49020] or false)
expect("Blood: 2 Blood Boil charges -> Blood Boil over Heart Strike", "icon:50842", nf.icon.texture)
state.next = 316239; step()
expect("Blood: Rune Strike ID (Heart Strike in game data) also corrected", "icon:50842", nf.icon.texture)
-- combat hides charges: count from casts
combat(true); state.charges = nil
cast(46585) -- Raise Dead at the pull, so its cooldown-ready icon stays out of these tests
cast(50842); cast(50842); step()
expect("Blood: both charges used -> Heart Strike stays", "icon:316239", nf.icon.texture)
now = now + 7.6; step()
expect("Blood: one charge back after 7.5s", "icon:50842", nf.icon.texture)
state.inRange = false; step()
expect("Blood: out of melee -> no Blood Boil", "icon:316239", nf.icon.texture)
state.inRange = true
-- runic power cap -> Death Strike (max 100 in mock -> threshold 80)
state.rp = 85; step()
expect("Blood: 85 RP -> Death Strike", "icon:49998", nf.icon.texture)
state.rp = 70; step()
expect("Blood: 70 RP -> no Death Strike override", "icon:50842", nf.icon.texture)
-- Bone Shield timing
cast(195182); now = now + 20; state.next = 49998; state.rp = 40; step()
expect("Blood: 20s after Marrowrend -> no refresh yet", "icon:49998", nf.icon.texture)
now = now + 6; step()
expect("Blood: 26s after Marrowrend -> refresh with Marrowrend", "icon:195182", nf.icon.texture)
state.runesLeft = 1; UnitPower = function(u, t) if t == 5 then return state.runesLeft end return state.rp end; step()
expect("Blood: low runes -> Death's Caress instead", "icon:195292", nf.icon.texture)
state.next = 195182; step()
expect("Blood: highlight already says Marrowrend -> no override", "icon:195182", nf.icon.texture)
state.next = 49998; now = now + 15; step()
expect("Blood: long expired (highlight handles it) -> no override", "icon:49998", nf.icon.texture)
cast(195292); now = now + 26; step()
expect("Blood: Death's Caress also counts as the refresh", "icon:195292", nf.icon.texture)
-- Bone Shield charges from talents restart its 30s too (SimC: bone_shield->trigger)
state.runesLeft = 6; cast(195182); now = now + 20; cast(49028); now = now + 8; step()
expect("Blood: Dancing Rune Weapon without Insatiable Blade -> still refresh (28s since Marrowrend)", "icon:195182", nf.icon.texture)
state.known[377637] = true; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED"); step()
expect("Blood: with Insatiable Blade the Dancing Rune Weapon 8s ago counts -> no refresh", "icon:49998", nf.icon.texture)
state.known[377637] = nil; state.known[434905] = true; cast(439843); now = now + 26; step()
expect("Blood: Reaper's Mark with Grim Reaper counts as a refresh (26s later -> refresh)", "icon:195182", nf.icon.texture)
state.known[434905] = nil; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED")
function UnitPower() return state.rp end
combat(false)
-- Opener
state.pet = false; events.scripts.OnEvent(events, "UNIT_PET", "player"); state.target = nil; now = now + 100; step()
expect("Blood opener: starts with Death's Caress", "icon:195292", ob.slots[1].texture)
expect("Blood opener: then Raise Dead when no ghoul", "icon:46585", ob.slots[2].texture)
state.pet = true; events.scripts.OnEvent(events, "UNIT_PET", "player"); step()
expect("Blood opener: ghoul out -> skips Raise Dead (San'layn: Heart Strike next)", "icon:206930", ob.slots[2].texture)
state.known[49028] = true; state.known[55233] = true; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED"); step()
expect("Blood opener: Vampiric Blood (rule on) second", "icon:55233", ob.slots[2].texture)
expect("Blood opener: then Dancing Rune Weapon", "icon:49028", ob.slots[3].texture)
ns.setRuleEnabled(250, "vampiricblood", false); step()
expect("Blood opener: Vampiric Blood rule off -> not in the opener", "icon:49028", ob.slots[2].texture)
state.known[439843] = true; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED"); step()
expect("Blood opener (Deathbringer): Death and Decay after Dancing Rune Weapon", "icon:43265", ob.slots[3].texture)
expect("Blood opener (Deathbringer): then Reaper's Mark", "icon:439843", ob.slots[4].texture)
ns.setRuleEnabled(250, "vampiricblood", true)
-- Owner's 0.22.0 log: Raise Dead pressed before Death's Caress dropped Death's Caress and Vampiric Blood
state.pet = false; events.scripts.OnEvent(events, "UNIT_PET", "player"); step()
cast(46585); step()
expect("Blood opener: Raise Dead first -> Death's Caress still next", "icon:195292", ob.slots[1].texture)
expect("Blood opener: ...then Vampiric Blood", "icon:55233", ob.slots[2].texture)
cast(195292); step()
expect("Blood opener: Death's Caress -> Vampiric Blood next (not skipped)", "icon:55233", ob.slots[1].texture)
state.pet = true; events.scripts.OnEvent(events, "UNIT_PET", "player")
state.known[49028] = nil; state.known[55233] = nil; state.known[439843] = nil
events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED"); step()
-- Low-health Death Strike icon (alpha driven by the game's curve)
step()
expect("HP icon: shown for Blood", true, hf.shown)
expect("HP icon: Death Strike", "icon:49998", hf.icon.texture)
for _, c in ipairs({ { 1.0, 1, 0, "full health (0-1 scale)" }, { 0.6, 1, 0, "60% (0-1 scale)" },
                     { 0.3, 1, 1, "30% (0-1 scale)" }, { 0.425, 1, 0.5, "42.5% fades in (0-1 scale)" },
                     { 1.0, 100, 0, "full health (0-100 scale)" }, { 0.6, 100, 0, "60% (0-100 scale)" },
                     { 0.3, 100, 1, "30% (0-100 scale)" }, { 0.05, 100, 1, "5% (0-100 scale)" } }) do
  state.hp, state.hpScale = c[1], c[2]; step()
  expect("HP icon alpha at " .. c[4], c[3], math.floor(hf.alpha * 100 + 0.5) / 100)
end
state.hpSecret = true; step()
expect("HP icon: hidden (secret) alpha passed straight to the game", "SECRET_ALPHA", hf.alpha)
state.hpSecret = false
SlashCmdList.ASSISTCOMPANION("hp 20 30"); state.hp, state.hpScale = 0.25, 1; step()
expect("HP icon: /ac hp 20 30 moves the thresholds", 0.5, math.floor(hf.alpha * 100 + 0.5) / 100)
SlashCmdList.ASSISTCOMPANION("hp 35 50")
local saved = UnitHealthPercent; UnitHealthPercent = nil; step()
expect("HP icon: API missing -> invisible, no error", 0, hf.alpha)
UnitHealthPercent = saved
state.spec = 251; events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED"); step()
expect("HP icon: not shown for Frost", false, hf.shown)
C_Spell.GetSpellCharges = nil

-- MAX RUNIC POWER WHEN UnitPowerMax IS HIDDEN -------------------------------
issecretvalue = function(v) return v == "SECRET" end
state.rpmaxSecret = true
state.spec = 250; state.pet = true; state.target = nil; state.overrides = {}; state.inRange = true
state.known = { [195182]=true, [195292]=true, [49998]=true, [50842]=true, [206930]=true, [219786]=true }
events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED"); events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED")
state.next = 206930; state.charges = nil; now = now + 60
state.rp = 100; step()
expect("RP max: hidden max + Ossuary -> 125, so 100 RP doesn't trigger", false, nf.icon.texture == "icon:49998")
state.rp = 106; step()
expect("RP max: 106 of 125 -> Death Strike", "icon:49998", nf.icon.texture)
state.known[219786] = nil; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED")
state.rp = 94; step()
expect("RP max: without Ossuary 115 -> 94 doesn't trigger", false, nf.icon.texture == "icon:49998")
state.rp = 96; step()
expect("RP max: without Ossuary 96 of 115 -> Death Strike", "icon:49998", nf.icon.texture)
state.rp = 130; step(); state.rp = 108; step()
expect("RP max: seen 130 -> max raised, 108 doesn't trigger", false, nf.icon.texture == "icon:49998")
state.rpmaxSecret = false; state.rpmax = 125; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED")
state.rp = 104; step()
expect("RP max: readable 125 used directly, 104 doesn't trigger", false, nf.icon.texture == "icon:49998")
state.rpmax = nil; issecretvalue = nil; state.rp = 10

-- DEBUG LOG (saved variables) -------------------------------------------------
date = os.date
C_AddOns = { GetAddOnMetadata = function(_, k) if k == "Version" then return "test" end end }
local printedBefore = #printed
AssistCompanionDB.debugLog = nil; AssistCompanionDB.debug = false; AssistCompanionDB.debugChat = nil
AssistCompanionDB.openerIcon = true
state.spec = 251; state.pet = true; state.target = nil; state.overrides = {}; state.inRange = true
state.known = { [47568]=true, [51271]=true, [1249658]=true, [49020]=true, [279302]=true }
events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED"); events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED")
SlashCmdList.ASSISTCOMPANION("debug")
local log = AssistCompanionDB.debugLog
local function logHas(pat) for _, l in ipairs(log) do if l:find(pat, 1, true) then return true end end return false end
expect("Debug log: header with version and spec", true, logHas("debug on: Assist Companion test, spec 251"))
now = now + 3000; state.next = 49020
combat(true); for _ = 1, 12 do step() end
cast(47568); step()
expect("Debug log: combat start", true, logHas("---- combat start ----"))
expect("Debug log: casts with name and id", true, logHas("cast: spell47568 (47568)"))
expect("Debug log: opener step done", true, logHas("opener: step 1/10 done (spell47568)"))
expect("Debug log: icon change with reason", true, logHas("(opener, highlight said spell49020)"))
expect("Debug log: status line once a second", true, logHas("status: highlight=spell49020 49020"))
expect("Debug log: lines show time into combat", true, log[#log]:find("+%d+%.%ds") ~= nil)
combat(false)
expect("Debug log: combat end", true, logHas("---- combat end"))
local chatAC = 0
for i = printedBefore + 1, #printed do if printed[i]:find("|cff66ccffAC|r", 1, true) then chatAC = chatAC + 1 end end
expect("Debug log: nothing echoed to chat by default", 0, chatAC)
SlashCmdList.ASSISTCOMPANION("debug chat"); cast(51271)
local echoed = false
for i = #printed - 3, #printed do if printed[i] and printed[i]:find("cast: spell51271", 1, true) then echoed = true end end
expect("Debug log: /ac debug chat echoes to chat", true, echoed)
SlashCmdList.ASSISTCOMPANION("debug chat")
for i = 1, 5100 do cast(49020) end
expect("Debug log: capped at 5000 lines (a whole boss fight)", 5000, #log)
SlashCmdList.ASSISTCOMPANION("debug")
expect("Debug log: 'debug off' line written", true, log[#log]:find("debug off", 1, true) ~= nil)
local n = #log; cast(49020)
expect("Debug log: nothing logged while off", n, #log)
SlashCmdList.ASSISTCOMPANION("log clear")
expect("Debug log: /ac log clear empties it", 0, #AssistCompanionDB.debugLog)
AssistCompanionDB.openerIcon = false

-- COOLDOWN-READY TEMPLATE ---------------------------------------------------
AssistCompanionDB.openerIcon = false
state.spec = 250; state.pet = true; state.target = nil; state.overrides = {}; state.inRange = true
state.known = { [195182]=true, [49998]=true, [50842]=true, [206930]=true, [46585]=true, [55233]=true }
state.rp = 10; state.next = 49998; state.charges = nil
events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED")
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED"); now = now + 300; step()
expect("Cooldowns: Blood rules include Vampiric Blood and Raise Dead",
  "boneshield,vampiricblood,raisedead,rpcap,bloodboil",
  (function() local t = {} for _, r in ipairs(ns.rules[250]) do t[#t+1] = r.key end return table.concat(t, ",") end)())
expect("Cooldowns: Frost keeps Breath after the range check, then Raise Dead",
  "erwrange,breath,raisedead,frostscythe",
  (function() local t = {} for _, r in ipairs(ns.rules[251]) do t[#t+1] = r.key end return table.concat(t, ",") end)())
expect("Cooldowns: tracked for Blood", "55233,46585", table.concat(ns.trackCooldowns[250], ","))
expect("Cooldowns: Blood out of combat -> plain highlight", "icon:49998", nf.icon.texture)
combat(true); step()
expect("Cooldowns: Blood pull -> Vampiric Blood first", "icon:55233", nf.icon.texture)
expect("Cooldowns: gold border on the cooldown icon", true, nf.border.shown)
expect("Cooldowns: bare icon, no note", "", nf.note.text)
cast(55233); step()
expect("Cooldowns: Vampiric Blood used -> Raise Dead", "icon:46585", nf.icon.texture)
cast(46585); step()
expect("Cooldowns: both used -> back to the highlight", "icon:49998", nf.icon.texture)
now = now + 89; step()
expect("Cooldowns: Vampiric Blood not back before 90s", "icon:49998", nf.icon.texture)
now = now + 2; step()
expect("Cooldowns: Vampiric Blood back after 90s", "icon:55233", nf.icon.texture)
cast(55233); now = now + 30; step()
expect("Cooldowns: Raise Dead back after 120s", "icon:46585", nf.icon.texture)
state.next = 46585; step()
expect("Cooldowns: highlight already says it -> no correction border", false, nf.border.shown)
state.next = 49998
cast(195182); now = now + 26; step()
expect("Cooldowns: Bone Shield refresh outranks a ready cooldown", "icon:195182", nf.icon.texture)
cast(195182); step()
SlashCmdList.ASSISTCOMPANION("toggle raisedead"); step()
expect("Cooldowns: /ac toggle raisedead turns it off", "icon:49998", nf.icon.texture)
SlashCmdList.ASSISTCOMPANION("toggle raisedead")
-- Red Thirst: Vampiric Blood -2s per 10 runic power; Death Strike = 45 (40 with Ossuary)
cast(46585); cast(55233); state.known[205723] = true; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED")
now = now + 1; for _ = 1, 5 do cast(49998) end                     -- 5 x 45 = 225 RP -> -45s
now = now + 43; step()
expect("Red Thirst: 5 Death Strikes -> Vampiric Blood not back at 44s", "icon:49998", nf.icon.texture)
now = now + 2; step()
expect("Red Thirst: ...back at 46s (90 - 45)", "icon:55233", nf.icon.texture)
cast(55233); state.known[219786] = true; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED"); step()
now = now + 1; for _ = 1, 5 do cast(49998) end                     -- Ossuary: 5 x 40 = 200 -> -40s
now = now + 48; step()
expect("Red Thirst + Ossuary: not back at 49s", "icon:49998", nf.icon.texture)
now = now + 2; step()
expect("Red Thirst + Ossuary: back at 51s (90 - 40)", "icon:55233", nf.icon.texture)
cast(55233); state.known[205723] = nil; state.known[219786] = nil
-- Death's Messenger (Deathbringer): Raise Dead 90s
state.known[437122] = true; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED")
cast(46585); now = now + 89; ns.setRuleEnabled(250, "vampiricblood", false); step()
expect("Death's Messenger: Raise Dead not back at 89s", "icon:49998", nf.icon.texture)
now = now + 2; step()
expect("Death's Messenger: Raise Dead back at 91s", "icon:46585", nf.icon.texture)
ns.setRuleEnabled(250, "vampiricblood", true); state.known[437122] = nil
-- Consumption: rank 1 badge
for _, k in ipairs({ "vampiricblood", "raisedead" }) do ns.setRuleEnabled(250, k, false) end
state.known[1263824] = true; state.next = 1263824; step()
expect("Blood: Consumption -> rank 1 badge", "1", nf.rank.text)
for _, k in ipairs({ "vampiricblood", "raisedead" }) do ns.setRuleEnabled(250, k, true) end
state.next = 49998; state.known[1263824] = nil
combat(false)
-- the game's out-of-combat answer wins over cast timing
state.cd = { [46585] = { now - 10, 120 }, [55233] = { now - 85, 90 } }
C_Spell.GetSpellCooldown = function(id)
  local c = state.cd[id]
  if c == "SECRET" then return { startTime = "SECRET", duration = "SECRET" } end
  if c then return { startTime = c[1], duration = c[2], modRate = 1 } end
  return { startTime = 0, duration = 0, modRate = 1 }
end
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED"); now = now + 1; step() -- wipes cast history
combat(true); state.cd = { [46585] = "SECRET", [55233] = "SECRET" }; step()
expect("Cooldowns: game said both on cooldown -> not shown after a combat drop", "icon:49998", nf.icon.texture)
now = now + 5; step()
expect("Cooldowns: remembered cooldown runs out in combat -> Vampiric Blood", "icon:55233", nf.icon.texture)
combat(false)
C_Spell.GetSpellCooldown = nil
-- Frost: Raise Dead in combat, Breath during Pillar comes first
state.spec = 251; state.known = { [1249658]=true, [51271]=true, [49020]=true, [46585]=true }
state.next = 49020; state.plates = 1
events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED")
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED"); now = now + 300; step()
combat(true); cast(51271); step()
expect("Cooldowns: Frost Pillar -> Breath before Raise Dead", "icon:1249658", nf.icon.texture)
cast(1249658); step()
expect("Cooldowns: Frost Breath used -> Raise Dead", "icon:46585", nf.icon.texture)
cast(46585); step()
expect("Cooldowns: Frost both used -> highlight", "icon:49020", nf.icon.texture)
now = now + 85; cast(51271); step()
expect("Cooldowns: Frost Breath not back before 90s", "icon:49020", nf.icon.texture)
now = now + 6; cast(51271); step()
expect("Cooldowns: Frost Breath back after 90s (game data, was 120s)", "icon:1249658", nf.icon.texture)
combat(false)

-- OPTIONS MENU ----------------------------------------------------------------
expect("Options: registered in the game's settings", "Assist Companion", settings.name)
expect("Options: added to the AddOns list", true, settings.registered ~= nil)
state.spec = 250; events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED")
SlashCmdList.ASSISTCOMPANION("")
expect("Options: /ac opens the menu", 77, settings.opened)
local panel = settings.panel
panel.scripts.OnShow(panel)
local rowsBy = function(spec, key)
  for _, r in ipairs(ns.optionsRows) do
    if r.specID == spec and (r.ruleKey == key or r.optionKey == key) then return r end
  end
end
local branchRow = function(key) for _, r in ipairs(ns.optionsRows) do if r.key == key then return r end end end
expect("Options: Death Knight class shown", true, branchRow("class:DEATHKNIGHT").frame.shown)
expect("Options: current class opens by itself", true, ns.optionsExpanded["class:DEATHKNIGHT"] or false)
expect("Options: Frost spec listed under it", true, branchRow("spec:251").frame.shown)
expect("Options: current spec's abilities shown (Blood Raise Dead)", true, rowsBy(250, "raisedead").frame.shown)
expect("Options: other specs closed (Frost Raise Dead hidden)", false, rowsBy(251, "raisedead").frame.shown)
expect("Options: ability has its spell icon", "icon:46585", rowsBy(250, "raisedead").frame.icon.texture)
expect("Options: Blood lists every rule", 5,
  (function() local n = 0 for _, r in ipairs(ns.optionsRows) do if r.specID == 250 and r.ruleKey then n = n + 1 end end return n end)())
expect("Options: Blood has the low-health icon option", true, rowsBy(250, "healthIcon") ~= nil)
expect("Options: spec shows how many rules are on", "5 of 5 on", branchRow("spec:250").frame.count.text)
branchRow("spec:251").frame:Click()
expect("Options: clicking Frost opens it", true, rowsBy(251, "raisedead").frame.shown)
branchRow("class:DEATHKNIGHT").frame:Click()
expect("Options: closing the class hides its specs", false, branchRow("spec:251").frame.shown)
expect("Options: ...and their abilities", false, rowsBy(250, "raisedead").frame.shown)
branchRow("class:DEATHKNIGHT").frame:Click()
local rd = rowsBy(250, "raisedead").frame
expect("Options: checkbox starts on", true, rd.checked)
rd.checked = false; rd:Click()
expect("Options: unchecking turns the rule off for Blood", false, ns.ruleEnabled(250, "raisedead"))
expect("Options: ...but not for Frost", true, ns.ruleEnabled(251, "raisedead"))
expect("Options: count updates", "4 of 5 on", branchRow("spec:250").frame.count.text)
rd.checked = true; rd:Click()
expect("Options: checking turns it back on", true, ns.ruleEnabled(250, "raisedead"))
SlashCmdList.ASSISTCOMPANION("toggle rpcap"); panel.scripts.OnShow(panel)
expect("Options: /ac toggle changes the current spec only", true, ns.ruleEnabled(252, "rpcap") and not ns.ruleEnabled(250, "rpcap"))
expect("Options: menu re-reads it when opened", false, rowsBy(250, "rpcap").frame.checked)
SlashCmdList.ASSISTCOMPANION("toggle rpcap")
local function widget(text) for _, w in ipairs(ns.optionsWidgets) do if w.label and w.label.text == text then return w end end end
expect("Options: icon on/off reads 'Next-cast icon'", true, widget("Next-cast icon") ~= nil)
local dead = widget("Show while dead")
dead.checked = true; dead:Click()
expect("Options: 'Show while dead' checkbox", true, AssistCompanionDB.showWhenDead)
dead.checked = false; dead:Click()
widget("Only in combat").checked = true; widget("Only in combat"):Click()
expect("Options: visibility choice", "combat", AssistCompanionDB.showMode)
expect("Options: choices act like radio buttons", false, widget("Always").checked)
widget("Always").checked = true; widget("Always"):Click()
local lock = widget("Lock frames")
lock.checked = false; lock:Click()
expect("Options: unchecking 'Lock frames' unlocks", false, AssistCompanionDB.locked)
lock.checked = true; lock:Click()
expect("Options: checking it locks again", true, AssistCompanionDB.locked)
-- strata option (owner's request): menu, slash command, all frames follow
local strataRow
for _, w in ipairs(ns.optionsWidgets) do if w.label and w.label.text == "Strata" then strataRow = w end end
expect("Strata: in the options menu, HIGH by default", "HIGH", strataRow and strataRow.value.text)
strataRow.minus:Click()
expect("Strata: < steps down to MEDIUM", "MEDIUM", AssistCompanionDB.strata)
expect("Strata: the next-cast icon follows", "MEDIUM", nf.strata)
expect("Strata: ...and the opener bar, low-health icon and text box", "MEDIUM/MEDIUM/MEDIUM",
  AssistCompanionOpener.strata .. "/" .. AssistCompanionHealth.strata .. "/" .. display.strata)
SlashCmdList.ASSISTCOMPANION("strata full screen dialog")
expect("Strata: /ac strata with spaces", "FULLSCREEN_DIALOG", nf.strata)
expect("Strata: menu shows it without underscores", "FULLSCREEN DIALOG", (function() strataRow:refresh() return strataRow.value.text end)())
SlashCmdList.ASSISTCOMPANION("strata nonsense")
expect("Strata: an unknown name is ignored", "FULLSCREEN_DIALOG", AssistCompanionDB.strata)
for _ = 1, 10 do strataRow.plus:Click() end
expect("Strata: > stops at TOOLTIP", "TOOLTIP", AssistCompanionDB.strata)
AssistCompanionDB.strata = "BOGUS"; events.scripts.OnEvent(events, "UPDATE_BINDINGS"); SlashCmdList.ASSISTCOMPANION("lock")
expect("Strata: a bad saved value falls back to HIGH", "HIGH", nf.strata)
SlashCmdList.ASSISTCOMPANION("strata high")
local size = AssistCompanionDB.iconSize
for _, w in ipairs(ns.optionsWidgets) do if w.label and w.label.text == "Icon size" then w.plus:Click() end end
expect("Options: icon size + button", size + 4, AssistCompanionDB.iconSize)
AssistCompanionDB.iconSize = size
-- MINIMAP BUTTON ---------------------------------------------------------------
local mb = ns.minimapButton()
local function at() return math.floor(mb.point[4] + 0.5) .. "," .. math.floor(mb.point[5] + 0.5) end
expect("Minimap: button made and shown by default", true, mb ~= nil and mb.shown)
expect("Minimap: default spot (225 degrees, bottom left)", "-53,-53", at())
settings.opened = nil; mb:Click("LeftButton")
expect("Minimap: left-click opens the options", 77, settings.opened)
local wasLocked = AssistCompanionDB.locked
mb:Click("RightButton")
expect("Minimap: right-click unlocks frames", false, AssistCompanionDB.locked)
mb:Click("RightButton")
expect("Minimap: right-click again locks them", true, AssistCompanionDB.locked)
AssistCompanionDB.locked = wasLocked
cursor[1], cursor[2] = 1100, 500                                  -- right of the minimap centre
mb.scripts.OnDragStart(mb); mb.scripts.OnUpdate(mb, 0.1)
expect("Minimap: dragging moves it around the edge (to the right)", "75,0", at())
expect("Minimap: ...and remembers the angle", 0, math.floor(AssistCompanionDB.minimapAngle + 0.5))
mb.scripts.OnDragStop(mb)
expect("Minimap: drag stops following the cursor", nil, mb.scripts.OnUpdate)
-- shift-click: debug log on/off (icon red while on); ctrl-click: clear the log
local shift, ctrl = false, false
function IsShiftKeyDown() return shift end
function IsControlKeyDown() return ctrl end
local dbgWas = AssistCompanionDB.debug
AssistCompanionDB.debug = false; shift = true; mb:Click("LeftButton")
expect("Minimap: shift-click starts the debug log", true, AssistCompanionDB.debug)
expect("Minimap: icon turns red while logging", 0.35, mb.icon.color and mb.icon.color[2])
settings.opened = nil; mb:Click("LeftButton")
expect("Minimap: shift-click again stops it", false, AssistCompanionDB.debug)
expect("Minimap: icon back to normal", 1, mb.icon.color and mb.icon.color[2])
expect("Minimap: shift-click doesn't open the options", nil, settings.opened)
shift = false; ctrl = true
AssistCompanionDB.debugLog = { "a", "b" }; mb:Click("LeftButton")
expect("Minimap: ctrl-click clears the debug log", 0, #AssistCompanionDB.debugLog)
ctrl = false; SlashCmdList.ASSISTCOMPANION("debug")
expect("Minimap: /ac debug also turns the icon red", 0.35, mb.icon.color and mb.icon.color[2])
SlashCmdList.ASSISTCOMPANION("debug"); AssistCompanionDB.debug = dbgWas; ns.updateMinimap()
-- Owner's report: clicks moved the button out of a minimap button bar (another addon) out of sight.
local before = at()
shift = true; mb:Click("LeftButton"); shift = false; ctrl = true; mb:Click("LeftButton"); ctrl = false
expect("Minimap: shift/ctrl-click don't move the button", before, at())
local bar = newFrame(); mb:SetParent(bar); mb:SetPoint("TOPLEFT", bar, "TOPLEFT", 4, -4)
shift = true; mb:Click("LeftButton"); shift = false; ctrl = true; mb:Click("LeftButton"); ctrl = false
SlashCmdList.ASSISTCOMPANION("debug"); SlashCmdList.ASSISTCOMPANION("debug")
expect("Minimap: in another addon's button bar, clicks leave it there", "TOPLEFT/4", mb.point[1] .. "/" .. mb.point[4])
ns.updateMinimap(true)
expect("Minimap: ...and so does a full update", "TOPLEFT/4", mb.point[1] .. "/" .. mb.point[4])
expect("Minimap: ...and it stays shown", true, mb.shown)
mb:SetParent(Minimap); ns.updateMinimap(true); AssistCompanionDB.debug = dbgWas; ns.updateMinimap()
function GetMinimapShape() return "SQUARE" end
AssistCompanionDB.minimapAngle = 45; ns.updateMinimap(true)
expect("Minimap: square minimap -> sits in the corner", "75,75", at())
GetMinimapShape = nil; AssistCompanionDB.minimapAngle = 225; ns.updateMinimap(true)
SlashCmdList.ASSISTCOMPANION("minimap")
expect("Minimap: /ac minimap hides it", false, mb.shown)
local mmCheck = widget("Minimap button")
mmCheck.checked = true; mmCheck:Click()
expect("Minimap: options checkbox shows it again", true, mb.shown and AssistCompanionDB.minimapButton)
settings.opened = nil; AssistCompanion_OnAddonCompartmentClick()
expect("Minimap: addon compartment entry opens the options", 77, settings.opened)

-- old saved settings carry over
AssistCompanionDB.disabled = { raisedead = true }; AssistCompanionDB.alwaysShow = false; AssistCompanionDB.showMode = nil
events.scripts.OnEvent(events, "ADDON_LOADED", "AssistCompanion")
expect("Migration: old rule toggle applies to every spec with that rule",
  "250:raisedead,251:raisedead", (function() local t = {} for k in pairs(AssistCompanionDB.disabled) do t[#t+1] = k end table.sort(t) return table.concat(t, ",") end)())
expect("Migration: alwaysShow off -> 'in combat or with a target'", "target", AssistCompanionDB.showMode)
expect("Migration: alwaysShow removed", nil, AssistCompanionDB.alwaysShow)
AssistCompanionDB.disabled = {}; AssistCompanionDB.showMode = "always"

-- AUGMENTATION EVOKER ---------------------------------------------------------
function IsInGroup() return state.group or false end
AssistCompanionDB.openerIcon = false
state.spec = 1473; state.pet = false; state.target = nil; state.overrides = {}; state.inRange = true
state.known = { [395152]=true, [409311]=true, [403631]=true }
state.next = 361469; state.group = false; state.rangeAsked = {}
events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED")
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED"); now = now + 300; step()
expect("Aug: rule order", "ebonmight,ebonfirst,breatheons,tipthescales,timeskip,prescience",
  (function() local t = {} for _, r in ipairs(ns.rules[1473]) do t[#t+1] = r.key end return table.concat(t, ",") end)())
expect("Aug: out of combat -> plain highlight", "icon:361469", nf.icon.texture)
expect("Aug: no melee check for a ranged spec", false, state.rangeAsked and state.rangeAsked[49020] or false)
state.next = 357210; step()
expect("Aug: highlight's Deep Breath shows as Breath of Eons", "icon:403631", nf.icon.texture)
expect("Aug: ...as a plain suggestion (no gold border)", false, nf.border.shown)
state.known[403631] = nil; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED"); step()
expect("Aug: without Breath of Eons, Deep Breath stays", "icon:357210", nf.icon.texture)
state.known[403631] = true; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED")
-- Breath of Eons cooldown, after the highlight's Ebon Might
state.next = 395152; combat(true); step()
expect("Aug: highlight wants Ebon Might -> Ebon Might first", "icon:395152", nf.icon.texture)
local t0 = now
cast(395152); state.next = 361469; step()
expect("Aug: then Breath of Eons when ready", "icon:403631", nf.icon.texture)
expect("Aug: Breath of Eons is a correction", true, nf.border.shown)
cast(403631); step()                                    -- Ebon Might 10s + 5s
expect("Aug: Breath of Eons used -> highlight", "icon:361469", nf.icon.texture)
expect("Aug: Breath of Eons extends Ebon Might by 5s", 15, math.floor(ns.ebonMight.expires - t0 + 0.5))
cast(357208); cast(396286)                              -- empowers: +2s each -> 19s
for _ = 1, 12 do cast(395160) end                        -- Eruptions: +1s each -> 31s
expect("Aug: empowers and Eruptions extend it", 31, math.floor(ns.ebonMight.expires - t0 + 0.5))
now = t0 + 26; step()
expect("Aug: 5s left -> no refresh yet", "icon:361469", nf.icon.texture)
now = t0 + 28; step()
expect("Aug: 3s left but Ebon Might on cooldown -> no refresh", "icon:361469", nf.icon.texture)
now = t0 + 30.5; step()
expect("Aug: ready with 0.5s left -> refresh Ebon Might", "icon:395152", nf.icon.texture)
cast(395152); step()
expect("Aug: recast keeps what was left (pandemic)", 41, math.floor(ns.ebonMight.expires - t0 + 0.5))
expect("Aug: refreshed -> highlight again", "icon:361469", nf.icon.texture)
now = t0 + 60; step()
expect("Aug: Ebon Might dropped -> left to the highlight", "icon:361469", nf.icon.texture)
cast(395160); expect("Aug: Eruption doesn't extend a dropped Ebon Might", 41, math.floor(ns.ebonMight.expires - t0 + 0.5))
-- Prescience charges (group only)
step()
expect("Aug: solo -> no Prescience nag", "icon:361469", nf.icon.texture)
state.group = true; step()
expect("Aug: group, both charges -> Prescience", "icon:409311", nf.icon.texture)
cast(409311); step()
expect("Aug: one charge left -> highlight", "icon:361469", nf.icon.texture)
now = now + 12.1; step()
expect("Aug: second charge back after 12s -> Prescience", "icon:409311", nf.icon.texture)
state.next = 409311; step()
expect("Aug: highlight already says Prescience -> plain", false, nf.border.shown)
-- Empower rank badge
state.group = false; now = now + 200; cast(403631) -- Breath of Eons used, so its correction stays out of these
state.next = 357208; step()
expect("Rank: Fire Breath while Upheaval is ready -> 1", "1", nf.rank.text)
state.next = 396286; step()
expect("Rank: Upheaval -> 1", "1", nf.rank.text)
cast(396286); state.next = 357208; step()
expect("Rank: Fire Breath with Upheaval on cooldown -> 3", "3", nf.rank.text)
now = now + 41; step()
expect("Rank: Upheaval back after 40s -> Fire Breath 1 again", "1", nf.rank.text)
cast(370553); step()
expect("Rank: right after Tip the Scales -> no rank (instant, max rank)", "", nf.rank.text)
cast(357208); state.next = 396286; step()
expect("Rank: Tip used up by Fire Breath -> ranks again", "1", nf.rank.text)
state.next = 382266; cast(396286); step()
expect("Rank: Font of Magic Fire Breath ID works too", "3", nf.rank.text)
state.next = 361469; step()
expect("Rank: no badge on other spells", "", nf.rank.text)
AssistCompanionDB.empowerRank = false; state.next = 357208; step()
expect("Rank: option off -> no badge", "", nf.rank.text)
AssistCompanionDB.empowerRank = true
expect("Rank: option listed under Augmentation", true, (function()
  for _, o in ipairs(ns.specOptions[1473]) do if o.key == "empowerRank" then return true end end return false end)())
-- Tip the Scales and Time Skip (never suggested by the in-game highlight; owner's debug log)
state.known = { [395152]=true, [409311]=true, [403631]=true, [370553]=true, [404977]=true }
events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED")
now = now + 300; cast(403631)                           -- Breath of Eons just used: 120s away
ns.ebonMight.expires = 0                                -- keep the Ebon Might refresh out of these
state.next = 357208; step()
expect("Tip: highlight says Fire Breath, Tip ready -> Tip the Scales", "icon:370553", nf.icon.texture)
expect("Tip: it's a correction", true, nf.border.shown)
state.next = 431443; step()
expect("Time Skip: filler, Breath of Eons 120s away -> Time Skip", "icon:404977", nf.icon.texture)
state.next = 396286; step()
expect("Time Skip: not over the highlight's Upheaval", "icon:396286", nf.icon.texture)
state.next = 357208; cast(370553); step()
expect("Tip: used -> Fire Breath, instant (no rank)", "icon:357208", nf.icon.texture)
expect("Tip: no rank badge while Tip waits", "", nf.rank.text)
state.next = 431443; step()
expect("Time Skip: not while Tip the Scales is waiting for its empower", "icon:404977", nf.icon.texture)
-- (still shown: Breath of Eons is far away, which is enough without Chronoboon)
state.known[1260484] = true; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED"); step()
expect("Time Skip with Chronoboon: Tip waiting -> no Time Skip", "icon:431443", nf.icon.texture)
cast(357208); step()
expect("Time Skip with Chronoboon: Tip spent and on cooldown -> Time Skip", "icon:404977", nf.icon.texture)
cast(404977); step()
expect("Time Skip: used -> highlight", "icon:431443", nf.icon.texture)
state.known[1260484] = nil; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED") -- 120s again
now = now + 100; state.next = 357208; step()
expect("Tip: not back before its 120s cooldown", "icon:357208", nf.icon.texture)
now = now + 21; cast(403631); ns.ebonMight.expires = 0; step() -- (Breath of Eons is back too: use it)
expect("Tip: back after 120s", "icon:370553", nf.icon.texture)
state.known[1260484] = nil
now = now + 200; state.next = 431443; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED"); step()
expect("Time Skip: Breath of Eons ready -> Breath of Eons first", "icon:403631", nf.icon.texture)
cast(403631); now = now + 110; step()
expect("Time Skip: Breath of Eons due in 10s, Tip ready -> hold Time Skip", "icon:431443", nf.icon.texture)
-- Cooldown speed-ups and learning (owner's second debug log). Breath of Eons, Tip the Scales and
-- Time Skip come off cooldown between these sections; turn them off so they don't take the icon.
for _, k in ipairs({ "breatheons", "tipthescales", "timeskip" }) do ns.setRuleEnabled(1473, k, false) end
local function augReset()
  ns.augCooldowns.empowerFactor, ns.augCooldowns.empowerReset, ns.augCooldowns.tipFactor = 1, 0, 1
  for k in pairs(ns.augCooldowns.readyNow) do ns.augCooldowns.readyNow[k] = nil end
  ns.ebonMight.expires = 0
end
state.known = { [395152]=true, [409311]=true, [403631]=true, [370553]=true, [404977]=true }
events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED")
now = now + 400; augReset(); cast(403631); cast(370553); cast(357208); cast(395152) -- BoE, Tip, Fire Breath, Ebon Might spent
ns.ebonMight.expires = now + 100                                -- keep the Ebon Might rules quiet here
local u0 = now; cast(396286)                                    -- Upheaval: 40s
now = u0 + 20; state.next = 357208; step()
expect("Speed: Upheaval 20s into 40s -> Fire Breath rank 3", "3", nf.rank.text)
cast(404977); now = u0 + 22.1; state.next = 357208; step()        -- Time Skip: +18s over its 2s channel
expect("Speed: Time Skip brings Upheaval back -> rank 1", "1", nf.rank.text)
-- Owner's raid log: a Time Skip that ended the moment it started gave no recovery (the addon had
-- credited 18s); under Fury of the Aspects one lasted 1.37s (haste). Count only the real channel.
now = now + 300; augReset(); ns.ebonMight.expires = now + 100
local u2 = now; cast(396286)                                     -- Upheaval: 40s
now = u2 + 20; cast(404977)
events.scripts.OnEvent(events, "UNIT_SPELLCAST_CHANNEL_STOP", "player", "guid", 404977) -- ended at once
now = u2 + 22.1; state.next = 357208; step()
expect("Time Skip cut short at once: no recovery -> Upheaval not back, rank 3", "3", nf.rank.text)
now = now + 300; augReset(); ns.ebonMight.expires = now + 100
local u3 = now; cast(396286)
now = u3 + 20; cast(404977); now = u3 + 21.37
events.scripts.OnEvent(events, "UNIT_SPELLCAST_CHANNEL_STOP", "player", "guid", 404977) -- 1.37s: +12.3s
now = u3 + 25.8; step()                                          -- 26 + 12.3 = 38.3 of 40 -> 1.7s left (step adds 0.2s)
expect("Time Skip 1.37s (hasted): +12.3s, 1.7s left -> rank 3", "3", nf.rank.text)
now = u3 + 26.3; step()                                          -- 1.2s left: within 1.5s
expect("Time Skip 1.37s: 1.2s left -> rank 1", "1", nf.rank.text)
events.scripts.OnEvent(events, "UNIT_SPELLCAST_INTERRUPTED", "player", "guid", 404977)
step()
expect("Time Skip: a second stop event changes nothing", "1", nf.rank.text)
-- Temporal Burst: +30% recovery after Tip the Scales, fading over 30s
state.known[431695] = true; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED")
now = now + 300; augReset(); ns.ebonMight.expires = now + 100
cast(370553); cast(357208); local u1 = now; cast(396286)         -- Tip, Fire Breath (uses it), Upheaval
now = u1 + 30; step()                                            -- 30s + 4.5s from Temporal Burst = 34.5 of 40
expect("Speed: Temporal Burst, 5.5s left -> rank 3", "3", nf.rank.text)
now = u1 + 34.6; step()                                          -- 39.1 of 40: within 1.5s
expect("Speed: Temporal Burst, 0.9s left -> rank 1", "1", nf.rank.text)
state.known[431695] = nil; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED")
-- Temporal Burst's size and fade time come from its tooltip (out of combat)
local function tbRead(text, t, keep)
  if not keep then ns.temporalBurst.readAt = nil end
  ns.onTick[1473]({ inCombat = false, now = t, description = function() return text end })
  return ns.temporalBurst.max .. "/" .. ns.temporalBurst.seconds
end
expect("Temporal Burst: owner's tooltip -> 30% over 34.1s", "0.3/34.1", tbRead(
  "Tip the Scales overloads you with temporal energy, increasing your haste, movement speed, and cooldown recovery rate by 30%, decreasing over 34.1 sec.", now))
expect("Temporal Burst: comma decimals and a space before %", "0.25/31.5", tbRead(
  "Erhöht Tempo, Bewegungsgeschwindigkeit und Abklingrate um 25 %, nimmt über 31,5 Sek. ab.", now + 10))
expect("Temporal Burst: unreadable tooltip keeps the last values", "0.25/31.5", tbRead(nil, now + 20))
expect("Temporal Burst: not re-read within 5s", "0.25/31.5", tbRead("by 30%, decreasing over 30 sec.", now + 22, true))
expect("Temporal Burst: not read in combat", "0.25/31.5", (function()
  ns.temporalBurst.readAt = nil
  ns.onTick[1473]({ inCombat = true, now = now + 40, description = function() return "by 30%, over 30 sec." end })
  return ns.temporalBurst.max .. "/" .. ns.temporalBurst.seconds end)())
tbRead("by 30%, decreasing over 34.1 sec.", now + 60)

-- Owner's eleventh log: rank 3 shown with ~1-2s of Ebon Might left (it would land outside it)
now = now + 300; augReset(); cast(395152); cast(396286); state.next = 357208 -- Ebon Might on cooldown
ns.ebonMight.expires = now + 10; step()
expect("Rank: Upheaval far, Ebon Might 10s left -> rank 3", "3", nf.rank.text)
ns.ebonMight.expires = now + 1.8; step()
expect("Rank: Ebon Might under 2.5s left -> rank 1 (lands inside it)", "1", nf.rank.text)
ns.ebonMight.expires = now - 1; step()
expect("Rank: Ebon Might already gone -> rank 3 again", "3", nf.rank.text)
ns.ebonMight.expires = now + 1000

-- Clear Empower Cooldown resets Fire Breath and Upheaval
now = now + 300; augReset(); ns.ebonMight.expires = now + 100
cast(396286); now = now + 5; step()
expect("Reset: Upheaval just used -> rank 3", "3", nf.rank.text)
cast(397374); step()
expect("Reset: Clear Empower Cooldown -> Upheaval ready -> rank 1", "1", nf.rank.text)
-- Learning: the highlight showing Upheaval means it's ready
now = now + 300; augReset(); ns.ebonMight.expires = now + 100
local u2 = now; cast(396286)
now = u2 + 29.2; state.next = 396286; step()                     -- (step adds 0.2s: 29.4)
expect("Learn: Upheaval ready after 29.4s (40/29.4 = 1.36) -> averaged with 1.00: 1.18", 1.18,
  math.floor(ns.augCooldowns.empowerFactor * 100 + 0.5) / 100)
local u2b = now; cast(396286)
now = u2b + 29.2; state.next = 396286; step()                    -- same again: (1.18 + 1.36) / 2
expect("Learn: a second 29.4s reading -> 1.27", 1.27, math.floor(ns.augCooldowns.empowerFactor * 100 + 0.5) / 100)
local u3 = now; cast(396286)
now = u3 + 28; state.next = 357208; step()                       -- 28 * 1.27 = 35.6: 4.4s left
expect("Learn: next Upheaval, 4.4s left -> rank 3", "3", nf.rank.text)
now = u3 + 30.4; step()                                          -- 38.6: 1.4s left
expect("Learn: next Upheaval, 1.4s left -> rank 1", "1", nf.rank.text)
-- an implausible reading (a cancelled empower looked like a 4s cooldown) is dropped, not capped
local f0 = ns.augCooldowns.empowerFactor
local u4 = now; cast(396286); now = u4 + 4; state.next = 396286; step()
expect("Learn: an impossible 4s Upheaval reading is ignored", f0, ns.augCooldowns.empowerFactor)
-- Ebon Might before empowers
now = now + 300; augReset()
local e0 = now; cast(395152)                                     -- Ebon Might: 10s, cooldown 30s
now = e0 + 23; state.next = 357208; step()
expect("Ebon first: Ebon Might 7s from ready -> Fire Breath (too long to hold)", "icon:357208", nf.icon.texture)
now = e0 + 27; step()
expect("Ebon first: Ebon Might 3s from ready, buff gone -> hold: Eruption to fill", "icon:395160", nf.icon.texture)
state.usable[395160] = false; state.overrides[361469] = 431443; step()
expect("Ebon first: no essence for Eruption -> Chrono Flames to fill", "icon:431443", nf.icon.texture)
state.usable[395160] = nil; state.overrides[361469] = nil
ns.ebonMight.expires = now + 10; step()
expect("Ebon first: buff still up when Ebon Might is back -> Fire Breath", "icon:357208", nf.icon.texture)
ns.ebonMight.expires = 0
now = e0 + 29; step()
expect("Ebon first: Ebon Might 1s from ready, buff run out -> Ebon Might first", "icon:395152", nf.icon.texture)
expect("Ebon first: as a correction", true, nf.border.shown)
-- Owner's L'ura log: Fire Breath shown with 3s of Ebon Might left and its cooldown 0.5s away
ns.ebonMight.expires = now + 3.5; now = e0 + 29.3; step()          -- ~3s left, back in ~0.5s
expect("Ebon first: buff in its refresh window, back within a GCD -> Ebon Might first", "icon:395152", nf.icon.texture)
ns.ebonMight.expires = now + 6; step()                             -- 6s left: not in the refresh window
expect("Ebon first: buff with 6s left -> Fire Breath", "icon:357208", nf.icon.texture)
ns.ebonMight.expires = 0
now = e0 + 31; step()
expect("Ebon first: Ebon Might ready but the highlight says Fire Breath (buff up) -> Fire Breath", "icon:357208", nf.icon.texture)
-- The highlight asking for Ebon Might means the buff is down
ns.ebonMight.expires = now + 20; state.next = 395152; step()
expect("Ebon Might: highlight asks for it -> our estimate says it's down", true, ns.ebonMight.expires <= now)
state.next = 431443

-- Tip the Scales: cooldown from when its buff is used up; Chronoboon; the cancel-macro option
ns.setRuleEnabled(1473, "tipthescales", true); AssistCompanionDB.tipMacro = false
state.known[370553] = true; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED")
now = now + 400; augReset(); ns.ebonMight.expires = now + 1000
local t0 = now; cast(370553)                                    -- pressed, not used yet
now = t0 + 130; state.next = 357208; step()
expect("Tip: pressed but not used -> cooldown hasn't started, no Tip", "icon:357208", nf.icon.texture)
expect("Tip: ...and Fire Breath is instant (no rank)", "", nf.rank.text)
local t1 = now; cast(357208)                                    -- Fire Breath uses it: cooldown starts now
now = t1 + 110; state.next = 357208; step()
expect("Tip: 110s after the buff was used -> not ready", "icon:357208", nf.icon.texture)
now = t1 + 120.5; step()
expect("Tip: 120s after the buff was used -> Tip with Fire Breath", "icon:370553", nf.icon.texture)
expect("Tip: macro off -> no note", "", nf.note.text)
expect("Tip: macro off -> no x2", "", nf.suffix.text)
state.next = 409311; step()
expect("Tip: not while the highlight asks for Prescience", "icon:409311", nf.icon.texture)
state.next = 395152; step()
expect("Tip: not while the highlight asks for Ebon Might", "icon:395152", nf.icon.texture)
AssistCompanionDB.tipMacro = true; state.next = 409311; step()
expect("Tip macro: not while the highlight asks for Prescience either", "icon:409311", nf.icon.texture)
AssistCompanionDB.tipMacro = false; state.next = 357208; step()
state.next = 431443; step()
expect("Tip: macro off, highlight not on Fire Breath -> wait (as before)", "icon:431443", nf.icon.texture)
state.known[1260484] = true; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED")
cast(370553); cast(357208); local t2 = now
now = t2 + 89; state.next = 357208; step()
expect("Tip with Chronoboon: 89s -> not ready", "icon:357208", nf.icon.texture)
now = t2 + 90.5; step()
expect("Tip with Chronoboon: 90s -> ready", "icon:370553", nf.icon.texture)
-- macro on
AssistCompanionDB.tipMacro = true; state.known[431695] = true; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED")
cast(357208); cast(396286); state.next = 431443; step()         -- Fire Breath and Upheaval on cooldown
expect("Tip macro: no empower soon -> Tip on cooldown", "icon:370553", nf.icon.texture)
expect("Tip macro: ...with a 'macro' note", "macro", nf.note.text)
expect("Tip macro: big 'x2' on the icon (no keybind here)", "x2", nf.suffix.text)
expect("Tip macro: keybind text stays empty", "", nf.key.text)
state.bars[370553] = 5; function GetBindingKey(cmd) if cmd == "ACTIONBUTTON5" then return "F" end end
events.scripts.OnEvent(events, "UPDATE_BINDINGS"); step()
expect("Tip macro: keybind stays plain", "F", nf.key.text)
expect("Tip macro: ...with the big x2", "x2", nf.suffix.text)
local t3 = now; cast(370553); now = t3 + 3; step()               -- macro: cancelled, no empower followed
expect("Tip macro: cancelled -> no longer waiting (Fire Breath gets a rank again)", false, (ns.augTip.state(
  { lastCast = { [370553] = t3 }, now = now, db = AssistCompanionDB })))
now = t3 + 88; step()
expect("Tip macro: Chronoboon, 88s after the cancel (+Temporal Burst) -> ready again", "icon:370553", nf.icon.texture)
state.next = 357208; step()
expect("Tip macro: Fire Breath ready -> Tip paired with it", "+ empower", nf.note.text)
expect("Tip with an empower: plain keybind, no x2", "F", nf.key.text)
expect("Tip with an empower: x2 cleared", "", nf.suffix.text)
state.bars[370553] = nil; events.scripts.OnEvent(events, "UPDATE_BINDINGS")
cast(370553); cast(357208); now = now + 1; step()
expect("Tip macro: used by Fire Breath -> not waiting", false, (ns.augTip.state(
  { lastCast = { [370553] = now - 1 }, now = now, db = AssistCompanionDB })))
-- Owner's fifth log: macro pressed (twice: cancelled), next empower 18s later -> cooldown from the press
local t4 = now + 100; now = t4; cast(370553); now = t4 + 18; cast(357208); now = t4 + 19
local _, started = ns.augTip.state({ lastCast = { [370553] = t4 }, now = now, db = AssistCompanionDB })
expect("Tip macro: an empower 18s later didn't use it -> cooldown from the press", t4, started)
-- Owner's sixth log: Tip the Scales was ready before our estimate. A press proves it: learn the ratio.
AssistCompanionDB.tipMacro = false; augReset(); state.known[431695] = nil
events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED")         -- Chronoboon on: 90s
local p0 = now + 500; now = p0; cast(370553); cast(357208)       -- used at p0
now = p0 + 60; step()
expect("Tip learn: 60s in, estimate 30s left", 30, math.floor(ns.augTip.cooldownLeft({ lastCast = { [370553] = p0 },
  now = now, db = AssistCompanionDB, knows = function(id) return id == 1260484 end, readyIn = function() end }) + 0.5))
now = p0 + 72; cast(370553); cast(357208); step()                -- pressed at 72s: it was ready
-- (1.25 averaged with 1.00 would be 1.13, but the learned speed is capped at 1.02: owner's L'ura log)
expect("Tip learn: pressed at 72s of 90 -> faster, capped at 1.02", 1.02, math.floor(ns.augCooldowns.tipFactor * 100 + 0.5) / 100)
local p1 = now; now = p1 + 87.5; state.next = 357208; step()
expect("Tip learn: next cycle not ready at 87.5s", "icon:357208", nf.icon.texture)
now = p1 + 88.5; step()
expect("Tip learn: next cycle ready after ~88s (90 / 1.02)", "icon:370553", nf.icon.texture)
now = p1 + 200; cast(370553); cast(357208); step()               -- a late press teaches nothing
expect("Tip learn: a late press doesn't lower the factor", 1.02, math.floor(ns.augCooldowns.tipFactor * 100 + 0.5) / 100)
-- A press the game refuses while the addon thought it ready steps the speed back down.
local p2 = now; now = p2 + 89; state.next = 357208; step()         -- 89 of 88.2: shown as ready
events.scripts.OnEvent(events, "UNIT_SPELLCAST_FAILED", "player", "guid", 370553)
expect("Tip learn: refused press (not ready) -> 1.02 down to 1.01", 1.01, math.floor(ns.augCooldowns.tipFactor * 100 + 0.5) / 100)
now = p2 + 40; step()
events.scripts.OnEvent(events, "UNIT_SPELLCAST_FAILED", "player", "guid", 370553)
expect("Tip learn: refused while the addon also said not ready -> unchanged", 1.01, math.floor(ns.augCooldowns.tipFactor * 100 + 0.5) / 100)
events.scripts.OnEvent(events, "UNIT_SPELLCAST_FAILED", "player", "guid", 357208)
expect("Tip learn: another spell failing -> unchanged", 1.01, math.floor(ns.augCooldowns.tipFactor * 100 + 0.5) / 100)
now = p2 + 300; cast(370553); cast(357208); step()
ns.augCooldowns.tipFactor = 1
AssistCompanionDB.tipMacro = false; state.known[431695] = nil; state.known[1260484] = nil
events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED"); ns.setRuleEnabled(1473, "tipthescales", false)
state.next = 431443

-- Owner's third log: Breath of Eons held ~23s after Time Skip had brought it back
ns.setRuleEnabled(1473, "breatheons", true)
now = now + 400; augReset(); ns.ebonMight.expires = now + 1000
local b0 = now; cast(403631)                                     -- Breath of Eons: 120s
now = b0 + 26; cast(404977)                                      -- Time Skip: +18s for every cooldown
now = b0 + 100; state.next = 431443; step()
expect("Speed: Breath of Eons 100s in, after Time Skip (118 of 120) -> not yet", "icon:431443", nf.icon.texture)
now = b0 + 102.5; step()
expect("Speed: Breath of Eons back 18s early after Time Skip", "icon:403631", nf.icon.texture)
cast(403631); ns.setRuleEnabled(1473, "breatheons", false)
-- Owner's third log: up= was always 0 because the Font of Magic Upheaval (not talented) read as ready
C_Spell.GetSpellCooldown = function() return { startTime = 0, duration = 0, modRate = 1 } end
combat(false); now = now + 300; augReset(); ns.ebonMight.expires = now + 1000; step() -- out of combat: both IDs read ready
combat(true); C_Spell.GetSpellCooldown = function() return { startTime = "SECRET", duration = "SECRET" } end -- hidden in combat
cast(396286); state.next = 357208; step()
expect("Rank: right after Upheaval (Font of Magic ID reads ready) -> Fire Breath rank 3", "3", nf.rank.text)
-- Owner's fourth log: in combat the game read Upheaval as "ready" right after the cast (an empower's
-- cooldown starts on release), so up= stayed 0. In-combat reads are now ignored.
C_Spell.GetSpellCooldown = function() return { startTime = 0, duration = 0, modRate = 1 } end -- readable, "ready"
now = now + 60; cast(396286); state.next = 357208; step(); step()
expect("Rank: in-combat 'ready' read right after Upheaval is ignored -> rank 3", "3", nf.rank.text)
-- ...and out of combat in the first seconds after casting it (a pre-pull empower)
combat(false); now = now + 60; cast(396286); step()
combat(true); state.next = 357208; step()
expect("Rank: pre-pull Upheaval read 'ready' before its cooldown started -> rank 3", "3", nf.rank.text)
C_Spell.GetSpellCooldown = nil; state.next = 431443
-- Owner's fifth log: up= still 0. The button's Upheaval ID differs from the cast ID and reads ready.
C_Spell.GetSpellCooldown = function() return { startTime = 0, duration = 0, modRate = 1 } end
state.overrides[396286] = 408092; ns.trackCooldowns[1473][#ns.trackCooldowns[1473] + 1] = 408092
combat(false); now = now + 300; augReset(); ns.ebonMight.expires = now + 1000; step() -- 408092 reads ready
combat(true); C_Spell.GetSpellCooldown = function() return { startTime = "SECRET", duration = "SECRET" } end
cast(396286); state.next = 357208; step()
expect("Rank: button shows another Upheaval ID that reads ready -> still rank 3 after casting", "3", nf.rank.text)
state.overrides[396286] = nil; table.remove(ns.trackCooldowns[1473]); C_Spell.GetSpellCooldown = nil
-- Owner's sixth log: the highlight keeps showing Upheaval for a moment after the cast; that is not
-- "ready again" (it made up= read 0 all fight)
now = now + 300; augReset(); ns.ebonMight.expires = now + 1000
cast(396286); state.next = 396286; step(); step(); step()        -- highlight still on Upheaval for 0.6s
state.next = 357208; step()
expect("Learn: highlight still on Upheaval right after the cast -> not ready (rank 3)", "3", nf.rank.text)
expect("Learn: ...and nothing learned from it", 1, ns.augCooldowns.empowerFactor)
-- Owner's seventh log: a Fire Breath started and cancelled (no cooldown) must not count
now = now + 300; augReset(); ns.ebonMight.expires = now + 1000
cast(357208); local fb0 = now                                    -- a real Fire Breath
now = fb0 + 40; local em0 = ns.ebonMight.expires
cast(357208); step()                                             -- started...
events.scripts.OnEvent(events, "UNIT_SPELLCAST_EMPOWER_STOP", "player", "guid", 357208, false) -- ...cancelled
expect("Cancel: no Ebon Might extension from it", em0, ns.ebonMight.expires)
now = fb0 + 44; state.next = 357208; step()
expect("Cancel: highlight on Fire Breath 4s later learns nothing", 1, ns.augCooldowns.empowerFactor)
cast(357208); events.scripts.OnEvent(events, "UNIT_SPELLCAST_EMPOWER_STOP", "player", "guid", 357208, true)
expect("Cancel: a completed empower stays", em0 + 2, ns.ebonMight.expires)
-- a cancelled Upheaval doesn't put Upheaval on cooldown: Fire Breath stays rank 1
cast(396286); now = now + 45; cast(396286)                       -- real one 45s ago, then started and cancelled
events.scripts.OnEvent(events, "UNIT_SPELLCAST_EMPOWER_STOP", "player", "guid", 396286, false)
state.next = 357208; step()
expect("Cancel: cancelled Upheaval -> Upheaval still ready -> Fire Breath rank 1", "1", nf.rank.text)
-- Tip the Scales stays waiting if the empower that would use it is cancelled
AssistCompanionDB.tipMacro = false; cast(370553); cast(357208)
events.scripts.OnEvent(events, "UNIT_SPELLCAST_EMPOWER_STOP", "player", "guid", 357208, false)
expect("Cancel: Tip the Scales still waiting after a cancelled empower", true, (ns.augTip.state(
  { lastCast = { [370553] = now }, now = now, db = AssistCompanionDB })))
cast(357208); events.scripts.OnEvent(events, "UNIT_SPELLCAST_EMPOWER_STOP", "player", "guid", 357208, true)
state.next = 431443

-- Accretion: each Eruption takes 1s off Upheaval
now = now + 300; augReset(); ns.ebonMight.expires = now + 1000
local a0 = now; cast(396286)
for i = 1, 10 do now = a0 + i; cast(395160) end
now = a0 + 29; state.next = 357208; step()
expect("Accretion: not talented, 11s left -> rank 3", "3", nf.rank.text)
state.known[407876] = true; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED"); step()
expect("Accretion: 10 Eruptions -> 1s left -> rank 1", "1", nf.rank.text)
state.known[407876] = nil; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED"); state.next = 431443

-- Learned factors are saved and survive a /reload; a talent change resets them
local A = ns.augCooldowns
step()                                                           -- settle the current talents
A.empowerFactor, A.tipFactor = 1.12, 1.02; step()
expect("Saved: learned factors written to the settings", "1.12/1.02",
  AssistCompanionDB.augLearned.empower .. "/" .. AssistCompanionDB.augLearned.tip)
local sig = AssistCompanionDB.augLearned.sig
A.learnedLoaded = false; A.empowerFactor, A.tipFactor = 1, 1; step()   -- as after a /reload
expect("Saved: a new session starts with the learned factors", "1.12/1.02", A.empowerFactor .. "/" .. A.tipFactor)
state.known[407876] = not state.known[407876]; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED"); step()
expect("Saved: Accretion changed -> start over", "1/1", A.empowerFactor .. "/" .. A.tipFactor)
expect("Saved: ...with the new talents remembered", true, AssistCompanionDB.augLearned.sig ~= sig)
A.learnedLoaded = false; AssistCompanionDB.augLearned = { sig = "zzz", empower = 1.5, tip = 1.5 }; step()
expect("Saved: values saved for other talents aren't loaded", "1/1", A.empowerFactor .. "/" .. A.tipFactor)
local saved = AssistCompanionDB.augLearned
state.known[395152] = nil; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED")   -- spellbook not loaded yet
A.learnedLoaded = false; AssistCompanionDB.augLearned = { sig = saved.sig, empower = 1.2, tip = 1.1 }; step()
expect("Saved: nothing loaded or overwritten before the spellbook is ready", 1.2, AssistCompanionDB.augLearned.empower)
state.known[395152] = true; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED"); step()
expect("Saved: ...then loaded once it is (Tip capped at 1.02)", "1.2/1.02", A.empowerFactor .. "/" .. A.tipFactor)
state.known[407876] = nil; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED"); step()
A.empowerFactor, A.tipFactor = 1, 1; step()

-- Ebon Might: mastery stretches its duration, crits stretch extensions (owner's screenshots)
local mods = ns.ebonMightMods
C_Spell.GetSpellDescription = function(id)
  if id == 406380 then
    return "Casting an empower spell grants Shifting Sands to 1 ally, preferring damage dealers, increasing their "
      .. "Versatility by 7.5% for 11.4 sec.\r\n\r\nThe durations of Shifting Sands, Breath of Eons, and your "
      .. "other helpful auras are increased by 13.8%."
  end
end
function GetSpellCritChance(school) return school == 4 and 20.59 or 18 end
combat(false); mods.readAt = nil; step()
expect("Ebon Might mods: mastery tooltip -> duration x1.138", 1.138, math.floor(mods.duration * 1000 + 0.5) / 1000)
expect("Ebon Might mods: crit read (best school)", 20.59, math.floor(mods.crit * 10000 + 0.5) / 100)
combat(true); C_Spell.GetSpellDescription = function() return "changed 50%" end; mods.readAt = nil; step()
expect("Ebon Might mods: not re-read in combat", 1.138, math.floor(mods.duration * 1000 + 0.5) / 1000)
C_Spell.GetSpellDescription = nil; GetSpellCritChance = nil
-- Replay the owner's first log: the buff ended between +33.6s (highlight still below Ebon Might with it
-- off cooldown) and +33.7s (the Upheaval then didn't keep it up). Old estimate: ~+26s.
augReset(); local r0 = now + 100
local casts = { { -0.5, 395152 }, { -0.5, 357208 }, { 1.8, 403631 }, { 4.3, 396286 }, { 7.1, 395160 },
  { 8.5, 395160 }, { 10.0, 395160 }, { 11.5, 395160 }, { 12.9, 395160 }, { 14.4, 395160 }, { 15.8, 395160 },
  { 21.7, 395160 }, { 26.6, 357208 }, { 29.6, 395160 }, { 31.9, 395160 } }
for _, c in ipairs(casts) do now = r0 + c[1]; cast(c[2]) end
local ends = ns.ebonMight.expires - r0
expect("Ebon Might replay: estimate ends within ~0.5s of the real drop (33.6-33.7s)", true, ends > 33.4 and ends < 34.3)
mods.duration, mods.crit, mods.readAt = 1, 0, nil
local ends0 = (function() augReset(); for _, c in ipairs(casts) do now = r0 + 200 + c[1]; cast(c[2]) end
  return ns.ebonMight.expires - (r0 + 200) end)()
expect("Ebon Might replay: without mastery and crit it ended far too early", true, ends0 < 30)
augReset()

-- The seven timing talents (only when talented)
local function talented(id, on) state.known[id] = on or nil; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED"); step() end
ns.setRuleEnabled(1473, "breatheons", true)
-- Tomorrow, Today: Time Skip 3s -> Breath of Eons back 27s early instead of 18s
talented(412723, true); now = now + 400; augReset(); ns.ebonMight.expires = now + 1000
local tt0 = now; cast(403631); now = tt0 + 26; cast(404977)
now = tt0 + 92.5; state.next = 431443; step()
expect("Tomorrow, Today: Breath of Eons not back at 92.5s", "icon:431443", nf.icon.texture)
now = tt0 + 93.6; step()
expect("Tomorrow, Today: Breath of Eons back after 120 - 27 = 93s", "icon:403631", nf.icon.texture)
cast(403631); talented(412723, false)
-- Wingleader (with Mass Eruption): the first Eruption after an empower takes 1.5s off Breath of Eons
talented(441206, true); talented(438587, true); now = now + 400; augReset(); ns.ebonMight.expires = now + 1000
local w0 = now; cast(403631)
for i = 1, 4 do now = w0 + i * 10; cast(357208); now = now + 1; cast(395160); cast(395160) end -- 4 Mass Eruptions
now = w0 + 113.5; state.next = 431443; step()
expect("Wingleader: 4 Mass Eruptions -> Breath of Eons back 6s early (at 114s)", "icon:431443", nf.icon.texture)
now = w0 + 114.2; step()
expect("Wingleader: ...back at 114s", "icon:403631", nf.icon.texture)
cast(403631); talented(441206, false); talented(438587, false)
ns.setRuleEnabled(1473, "breatheons", false)
-- Instability Matrix: ~3s off each empower's own cooldown
now = now + 300; augReset(); ns.ebonMight.expires = now + 1000; cast(395152)
local im0 = now; cast(396286); now = im0 + 36.6; state.next = 357208; step()
expect("Instability Matrix: not talented, Upheaval 3.4s away -> rank 3", "3", nf.rank.text)
talented(431484, true)
expect("Instability Matrix: talented, 0.4s away -> rank 1", "1", nf.rank.text)
talented(431484, false)
-- Interwoven Threads: cooldowns -10% (Upheaval 36s)
now = now + 300; augReset(); ns.ebonMight.expires = now + 1000; cast(395152)
local iw0 = now; cast(396286); now = iw0 + 35; step()
expect("Interwoven Threads: not talented, Upheaval 5s away -> rank 3", "3", nf.rank.text)
talented(412713, true)
expect("Interwoven Threads: talented, 1s away -> rank 1", "1", nf.rank.text)
talented(412713, false)
-- Dream of Spring: Emerald Blossom extends Ebon Might by 1s
now = now + 300; augReset(); cast(395152); local e1 = ns.ebonMight.expires
cast(355913)
expect("Dream of Spring: not talented -> Emerald Blossom doesn't extend Ebon Might", e1, ns.ebonMight.expires)
talented(414969, true); cast(355913)
expect("Dream of Spring: talented -> +1s", e1 + 1, ns.ebonMight.expires)
talented(414969, false)
-- Overlord: Breath of Eons' hidden Eruption extends Ebon Might and counts for Accretion
now = now + 300; augReset(); cast(395152); local o1 = ns.ebonMight.expires; cast(403631)
expect("Overlord: not talented -> Breath of Eons +5s", o1 + 5, ns.ebonMight.expires)
talented(410260, true); augReset(); cast(395152); o1 = ns.ebonMight.expires; cast(403631)
expect("Overlord: talented -> +5s and +1s from its Eruption", o1 + 6, ns.ebonMight.expires)
talented(407876, true); augReset(); ns.ebonMight.expires = now + 1000
local ov0 = now; cast(396286); now = ov0 + 1; cast(403631); now = ov0 + 37.6; state.next = 357208; step()
expect("Overlord + Accretion: its Eruption takes 1s off Upheaval (1.4s away -> rank 1)", "1", nf.rank.text)
talented(410260, false)
talented(407876, false)
-- Nozdormu Adept: Prescience recharges in 10s instead of 12
state.group = true; now = now + 300; augReset(); ns.ebonMight.expires = now + 1000; state.next = 431443
cast(409311); now = now + 10.1; step()
expect("Nozdormu Adept: not talented -> second Prescience charge not back at 10s", "icon:431443", nf.icon.texture)
talented(431715, true); now = now + 15; step(); cast(409311); cast(409311); now = now + 20.1; step()
cast(409311); now = now + 10.1; step()
expect("Nozdormu Adept: talented -> back after 10s", "icon:409311", nf.icon.texture)
talented(431715, false); state.group = false; state.next = 431443
-- the talents are listed at the start of each fight in the debug log
AssistCompanionDB.debugLog = {}; AssistCompanionDB.debug = true; talented(410260, true)
combat(false); combat(true)
local logged = false
for _, l in ipairs(AssistCompanionDB.debugLog) do if l:find("talents: ", 1, true) and l:find("Overlord", 1, true) then logged = true end end
expect("Debug: talents listed at combat start", true, logged)
AssistCompanionDB.debug = false; talented(410260, false)

-- debug log: Ebon Might estimate on the status line, rule errors logged once
local function dbgHas(pat) for _, l in ipairs(AssistCompanionDB.debugLog or {}) do if l:find(pat, 1, true) then return true end end return false end
AssistCompanionDB.debugLog = {}; AssistCompanionDB.debug = true
table.insert(ns.rules[1473], 1, { key = "broken", name = "Broken", check = function() error("boom") end })
for _ = 1, 12 do step() end
expect("Debug: Augmentation status shows the Ebon Might estimate", true, dbgHas(" em="))
expect("Debug: enemy-count diagnosis on the status line", true, dbgHas(" (np="))
do
  local savedPower, savedSecret = UnitPower, issecretvalue
  UnitPower = function() return "SECRET" end; issecretvalue = function(v) return v == "SECRET" end
  local savedLog = AssistCompanionDB.debugLog
  AssistCompanionDB.debugLog = {}; for _ = 1, 12 do step() end
  expect("Debug: a hidden power value reads rp=hidden", true, dbgHas("rp=hidden"))
  UnitPower, issecretvalue = savedPower, savedSecret
  AssistCompanionDB.debugLog = savedLog
end
expect("Debug: ...and the cooldown estimates", true, dbgHas(" up=") and dbgHas(" emcd=") and dbgHas(" x=")
  and dbgHas(" upb=") and dbgHas(" tip=") and dbgHas(" tx=") and dbgHas(" haste=") and dbgHas(" emdur=") and dbgHas(" crit=")
  and dbgHas(" ts=") and dbgHas(" boe="))
expect("Debug: a rule error is logged", true, dbgHas("rule broken error"))
local n = 0 for _, l in ipairs(AssistCompanionDB.debugLog) do if l:find("rule broken error", 1, true) then n = n + 1 end end
expect("Debug: ...only once", 1, n)
expect("Debug: other rules still run after a broken one", "icon:431443", nf.icon.texture)
table.remove(ns.rules[1473], 1); AssistCompanionDB.debug = false
for _, k in ipairs({ "breatheons", "tipthescales", "timeskip" }) do ns.setRuleEnabled(1473, k, true) end
combat(false); state.group = false
state.spec = 1473; panel.scripts.OnShow(panel)
expect("Options: Evoker listed with Augmentation", true, branchRow("spec:1473") ~= nil and branchRow("class:EVOKER") ~= nil)
expect("Options: Augmentation's rules listed", true, rowsBy(1473, "breatheons") ~= nil and rowsBy(1473, "ebonmight") ~= nil)

-- HIDDEN WHILE DEAD ----------------------------------------------------------
function UnitIsDeadOrGhost(u) return u == "player" and state.dead or false end
state.spec = 250; state.pet = true; state.target = nil; state.next = 206930
state.known = { [195182]=true, [195292]=true, [49998]=true, [50842]=true, [206930]=true, [46585]=true, [43265]=true }
events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED")
AssistCompanionDB.showText = true; state.rp = 95; now = now + 50; step()
expect("Dead: everything visible while alive", true, nf.shown and ob.shown and AssistCompanionHealth.shown and display.shown)
state.dead = true; step()
expect("Dead: next-cast icon hidden", false, nf.shown)
expect("Dead: opener bar hidden", false, ob.shown)
expect("Dead: low-health icon hidden", false, AssistCompanionHealth.shown)
expect("Dead: text box hidden", false, display.shown)
AssistCompanionDB.showWhenDead = true; step()
expect("Dead: 'show while dead' keeps the next-cast icon", true, nf.shown)
AssistCompanionDB.showWhenDead = false
state.dead = false; step()
expect("Dead: everything back after resurrection", true, nf.shown and ob.shown and AssistCompanionHealth.shown)
state.rp = 10; AssistCompanionDB.showText = false; UnitIsDeadOrGhost = nil; step()
expect("Dead: API missing -> treated as alive", true, nf.shown)

-- secret values: power returns a secret -> treated as unknown, no error
issecretvalue = function(v) return v == "SECRET" end
state.spec = 252; events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED")
state.rp = "SECRET"; state.next = 55090; step()
expect("Secret runic power -> no alert, no error", "nothing", (seen()))

-- DEVASTATION ----------------------------------------------------------------
do
  AssistCompanionDB.openerIcon = false
  issecretvalue = nil
  state.spec = 1467; state.overrides = {}; state.target = nil; state.inRange = true; state.usable = {}; state.noPower = {}
  state.known = { [356995]=true, [357211]=true, [361469]=true, [362969]=true, [357208]=true, [359073]=true, [370553]=true }
  state.rpmax = 5
  -- the cooldown rules have their own tests below; off for the essence / Pyre / rank tests
  for _, k in ipairs({ "dragonrage", "devdeepbreath", "devtip" }) do ns.setRuleEnabled(1467, k, false) end
  events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED")
  events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED"); now = now + 500
  combat(true)
  state.rpmax = 5; state.rp = 5; state.plates = 1; state.next = 361469; step()
  expect("Devastation: 5/5 essence + Living Flame -> Disintegrate", "icon:356995", nf.icon.texture)
  expect("Devastation: ...as a correction (gold border)", true, nf.border.shown)
  state.rp = 4; step()
  expect("Devastation: 4/5 essence -> Living Flame stays", "icon:361469", nf.icon.texture)
  state.rp = 5; state.next = 356995; step()
  expect("Devastation: full essence, highlight already spends -> no change", "icon:356995", nf.icon.texture)
  expect("Devastation: ...no gold border", false, nf.border.shown)
  state.next = 362969; state.plates = 4; step()
  expect("Devastation: full essence + Azure Strike on 4 targets -> Pyre", "icon:357211", nf.icon.texture)
  state.usable = { [357211] = false }; step()
  expect("Devastation: Pyre not usable -> no correction", "icon:362969", nf.icon.texture)
  state.usable = {}
  -- max essence hidden: 5, or 6 with Power Nexus
  state.rpmaxSecret = true; issecretvalue = function(v) return v == "SECRET" end
  state.plates = 1; state.next = 361469; talented(369908, true)
  state.rp = 5; step()
  expect("Devastation: hidden max + Power Nexus -> 5 essence isn't full", "icon:361469", nf.icon.texture)
  state.rp = 6; step()
  expect("Devastation: ...6 is", "icon:356995", nf.icon.texture)
  state.rpmaxSecret = nil; issecretvalue = nil; talented(369908, false)
  -- Pyre at exactly 3 targets (Flameshaper with Volatility / Feed the Flames)
  state.rp = 3; state.plates = 3; state.next = 356995; step()
  expect("Devastation: 3 targets, no Flameshaper talents -> Disintegrate stays", "icon:356995", nf.icon.texture)
  -- talent ranks read from the loadout (C_Traits)
  local ranks = {}
  local nodeSpell = {}
  C_ClassTalents = { GetActiveConfigID = function() return 1 end }
  C_Traits = {
    GetConfigInfo = function() return { treeIDs = { 7 } } end,
    GetTreeNodes = function() local t = {} nodeSpell = {} for id in pairs(ranks) do t[#t + 1] = #t + 1; nodeSpell[#t] = id end return t end,
    GetNodeInfo = function(_, node) return { activeEntry = { entryID = node }, activeRank = ranks[nodeSpell[node]] } end,
    GetEntryInfo = function(_, e) return { definitionID = e } end,
    GetDefinitionInfo = function(d) return { spellID = nodeSpell[d] } end,
  }
  state.known[1264269] = true; ranks[369089] = 1; talented(369089, true)
  expect("Devastation: 3 targets + Lifebinder + Volatility rank 1 -> Disintegrate stays (SimC: rank 2)", "icon:356995", nf.icon.texture)
  ranks[369089] = 2; talented(369089, true)
  expect("Devastation: 3 targets + Legacy of the Lifebinder + Volatility rank 2 -> Pyre", "icon:357211", nf.icon.texture)
  state.plates = 2; step()
  expect("Devastation: 2 targets -> Disintegrate stays", "icon:356995", nf.icon.texture)
  state.rp = 5; state.plates = 3; state.next = 361469; step()
  expect("Devastation: essence cap on 3 targets with those talents -> Pyre", "icon:357211", nf.icon.texture)
  state.overrides = { [362969] = 1265872 }; state.next = 362969; step()
  expect("Devastation: Flameshaper, 3 targets, full essence + Azure Sweep -> keep Azure Sweep", "icon:1265872", nf.icon.texture)
  state.plates = 1; step()
  expect("Devastation: ...on 1 target -> spend (Disintegrate)", "icon:356995", nf.icon.texture)
  state.overrides = {}; state.plates = 3; state.next = 356995; state.rp = 3
  C_ClassTalents = nil; talented(369089, true)
  expect("Devastation: talent ranks unreadable -> Volatility doesn't count", "icon:356995", nf.icon.texture)
  talented(369846, true)
  expect("Devastation: ...Feed the Flames does", "icon:357211", nf.icon.texture)
  talented(369846, false); C_Traits = nil
  state.known[1264269] = nil; talented(369089, false)
  -- Azure Sweep: the icon shows what the button casts
  state.rp = 2; state.plates = 1; state.overrides = { [362969] = 1265872 }; state.next = 362969; step()
  expect("Devastation: Azure Strike while its button is Azure Sweep -> Azure Sweep icon", "icon:1265872", nf.icon.texture)
  state.overrides = {}
  -- Empower ranks
  state.next = 359073; state.plates = 1; step()
  expect("Devastation rank: Eternity Surge, 1 target -> 1", "1", nf.rank.text)
  state.plates = 3; step()
  expect("Devastation rank: Eternity Surge, 3 targets -> 3", "3", nf.rank.text)
  state.plates = 5; step()
  expect("Devastation rank: Eternity Surge, 5 targets, no Font of Magic -> 3 (max)", "3", nf.rank.text)
  talented(411212, true)
  expect("Devastation rank: ...with Font of Magic -> 4", "4", nf.rank.text)
  state.plates = 3; talented(375757, true)
  expect("Devastation rank: Eternity's Span, 3 targets -> 2", "2", nf.rank.text)
  talented(375757, false); talented(411212, false)
  state.next = 357208; state.plates = 1; step()
  expect("Devastation rank: Fire Breath (Flameshaper), 1 target -> 1", "1", nf.rank.text)
  state.plates = 2; step()
  expect("Devastation rank: Fire Breath, 2 targets -> 2", "2", nf.rank.text)
  state.plates = 3; step()
  expect("Devastation rank: Fire Breath, 3 targets -> 3", "3", nf.rank.text)
  cast(375087); step()
  expect("Devastation rank: Fire Breath, 3 targets in Dragonrage -> 2", "2", nf.rank.text)
  now = now + 19; step()
  expect("Devastation rank: Dragonrage over -> 3", "3", nf.rank.text)
  -- Animosity: each empower in Dragonrage extends it, 5s then 25% less each time (375797)
  talented(375797, true); now = now + 200; cast(375087); step()
  local r0 = now
  cast(359073); step()                                               -- Eternity Surge: +5s (23s)
  cast(357208); events.scripts.OnEvent(events, "UNIT_SPELLCAST_EMPOWER_STOP", "player", "guid", 357208, false); step()
  expect("Animosity: cancelled empower doesn't extend (Dragonrage 23s)", 23, math.floor(ns.devRage.ends - ns.devRage.start + 0.5))
  cast(357208); step()                                               -- +3.75s (26.75s)
  now = r0 + 26; step()
  expect("Animosity: two empowers -> Dragonrage 26.75s, rank 2 at 26s", "2", nf.rank.text)
  now = r0 + 27; step()
  expect("Animosity: ...rank 3 after", "3", nf.rank.text)
  talented(375797, false)
  -- Rising Fury rank 3: persists 4s per stack after Dragonrage (a stack at the start and every 6s: 4 in 18s)
  talented(1271788, true); now = now + 200; cast(375087); step()
  r0 = now
  now = r0 + 33.5; step()
  expect("Rising Fury: rank 2 until Dragonrage + 16s (33.5s)", "2", nf.rank.text)
  now = r0 + 34.5; step()
  expect("Rising Fury: ...rank 3 after", "3", nf.rank.text)
  talented(1271788, false)
  state.known[1264269] = true; talented(369846, true)
  expect("Devastation rank: Flameshaper Pyre plan (Feed the Flames, 3 targets) -> 1", "1", nf.rank.text)
  state.known[1264269] = nil; talented(369846, false)
  talented(436335, true)
  expect("Devastation rank: Scalecommander, 3 targets -> 3", "3", nf.rank.text)
  state.plates = 6; step()
  expect("Devastation rank: Scalecommander, 6 targets -> 1", "1", nf.rank.text)
  talented(436335, false)
  state.plates = 2; cast(370553); step()
  expect("Devastation rank: after Tip the Scales -> no number", "", nf.rank.text)
  cast(357208); step()
  expect("Devastation rank: back after the empower", "2", nf.rank.text)
  state.plates = 0; step()
  expect("Devastation rank: enemy count unknown/0 -> no number", "", nf.rank.text)
  AssistCompanionDB.empowerRank = false; state.plates = 2; step()
  expect("Devastation rank: option off -> no number", "", nf.rank.text)
  AssistCompanionDB.empowerRank = true
  -- Cooldowns the highlight never suggests (owner's log): Dragonrage, Deep Breath, Tip the Scales
  for _, k in ipairs({ "dragonrage", "devdeepbreath", "devtip" }) do ns.setRuleEnabled(1467, k, true) end
  state.known[375087] = true; state.known[357210] = true; talented(370553, true)
  now = now + 300                                                    -- earlier tests used Dragonrage and Tip
  state.rp = 2; state.plates = 1; state.next = 361469; step()
  expect("Devastation CD: Dragonrage ready -> Dragonrage", "icon:375087", nf.icon.texture)
  cast(375087); step()
  expect("Devastation CD: Dragonrage used, 1 target, no Deep Breath talents -> highlight (Living Flame)", "icon:361469", nf.icon.texture)
  state.plates = 3; step()
  expect("Devastation CD: 3 targets -> Deep Breath", "icon:357210", nf.icon.texture)
  cast(433874); step()                                               -- the Maneuverability version
  expect("Devastation CD: Deep Breath cast (steerable ID) -> on cooldown", "icon:361469", nf.icon.texture)
  state.next = 357208; step()
  expect("Devastation CD: highlight says Fire Breath, Tip ready -> Tip the Scales", "icon:370553", nf.icon.texture)
  cast(370553); cast(357208); step()
  expect("Devastation CD: Tip used -> Fire Breath", "icon:357208", nf.icon.texture)
  now = now + 61; state.next = 361469; step()
  expect("Devastation CD: Deep Breath 61s later, no Onyx Legacy -> not yet", "icon:361469", nf.icon.texture)
  talented(386348, true)
  expect("Devastation CD: ...with Onyx Legacy (60s) -> Deep Breath", "icon:357210", nf.icon.texture)
  state.plates = 1; step()
  expect("Devastation CD: 1 target, no Deep Breath talents -> no Deep Breath", "icon:361469", nf.icon.texture)
  talented(441176, true)
  expect("Devastation CD: 1 target with Melt Armor -> Deep Breath anyway", "icon:357210", nf.icon.texture)
  talented(441176, false); talented(386348, false)
  now = now + 60; step()
  expect("Devastation CD: Dragonrage 121s later -> Dragonrage again", "icon:375087", nf.icon.texture)
  -- Wingleader: each Mass Disintegrate takes 1s per target struck (up to 3) off Deep Breath
  state.known[436335] = true; talented(441206, true)                -- Mass Disintegrate + Wingleader
  now = now + 200; state.plates = 5; state.next = 361469; step()
  cast(433874); cast(375087); step()                                 -- Deep Breath: 120s (and Dragonrage, out of the way)
  local d0 = now
  cast(357208); step()                                               -- Fire Breath: a Mass Disintegrate stack
  expect("Wingleader: empower -> 1 Mass Disintegrate stack", 1, ns.devState.mass)
  cast(356995); step()                                               -- Mass Disintegrate on 5 targets: -3s
  expect("Wingleader: Mass Disintegrate used the stack", 0, ns.devState.mass)
  cast(356995); step()                                               -- plain Disintegrate: no cut
  cast(359073); events.scripts.OnEvent(events, "UNIT_SPELLCAST_EMPOWER_STOP", "player", "guid", 359073, false); step()
  expect("Wingleader: cancelled empower gives no stack", 0, ns.devState.mass)
  cast(359073); cast(356995); step()                                 -- another: -3s (6s total)
  now = d0 + 113.5; step()                                           -- 113.7 + 6 = 119.7 of 120: not yet
  expect("Wingleader: Deep Breath 6s sooner, not yet at 113.7s", "icon:361469", nf.icon.texture)
  now = d0 + 114.2; step()
  expect("Wingleader: Deep Breath back at ~114s (6s cut)", "icon:357210", nf.icon.texture)
  talented(1261448, true); cast(357208); cast(356995); step()         -- Concentrated Power: 4 targets
  expect("Wingleader: Concentrated Power, 5 targets -> 4s cut", 4, ns.devState.cuts[#ns.devState.cuts].s)
  talented(1261448, false)
  state.known[436335] = nil; talented(441206, false); state.plates = 1
  expect("Devastation CD: rule order", "dragonrage,devdeepbreath,devtip,essencecap,pyre3", (function()
    local t = {} for _, r in ipairs(ns.rules[1467]) do t[#t + 1] = r.key end return table.concat(t, ",") end)())
  for _, k in ipairs({ "dragonrage", "devdeepbreath", "devtip" }) do ns.setRuleEnabled(1467, k, false) end
  -- Enemy count for ranged specs: enemies you're fighting (threat), not everything within 25 yd
  -- (owner's log: a nearby dummy made single target read 2, Fire Breath rank 2 for Scalecommander)
  talented(436335, true)                                              -- Scalecommander: Fire Breath rank = targets
  state.next = 357208; state.plates = 2
  local threat = { nameplate1 = 1 }
  UnitThreatSituation = function(_, unit) return threat[unit] end
  local savedCombat = UnitAffectingCombat
  UnitAffectingCombat = function(unit) return unit == "nameplate1" end -- the other dummy isn't fighting
  step()
  expect("Enemies (ranged): 2 nearby, threat on 1 -> rank 1", "1", nf.rank.text)
  threat = { nameplate1 = 3, nameplate2 = 0 }; step()
  expect("Enemies (ranged): threat on both -> rank 2", "2", nf.rank.text)
  threat = {}; UnitAffectingCombat = function() return false end
  UnitIsUnit = function(a, b) return a == "nameplate1" and b == "target" end
  state.plates = 8; step()
  expect("Enemies (ranged): before the pull, 8 nearby, none fighting -> just the target (rank 1)", "1", nf.rank.text)
  UnitAffectingCombat = function(unit) return unit == "nameplate1" or unit == "nameplate2" or unit == "nameplate3" end
  threat = { nameplate1 = "SECRET", nameplate2 = "SECRET" }; issecretvalue = function(v) return v == "SECRET" end; step()
  expect("Enemies (ranged): threat hidden -> target + in combat within range (3)", "3", nf.rank.text)
  -- the three cases, explicitly
  issecretvalue = nil; threat = {}; UnitAffectingCombat = function() return false end
  combat(false); state.plates = 8; step()
  expect("Enemies (ranged, out of combat): 8 nearby -> target only (rank 1)", "1", nf.rank.text)
  combat(true); state.plates = 3; step()
  expect("Enemies (ranged, dummies: nothing reports combat): 3 in range -> 3", "3", nf.rank.text)
  UnitAffectingCombat = function(unit) return unit == "nameplate2" end; step()
  expect("Enemies (ranged, real fight): target + 1 in combat -> 2", "2", nf.rank.text)
  UnitThreatSituation = nil; UnitIsUnit = nil; UnitAffectingCombat = savedCombat
  state.plates = 2; talented(436335, false)
  -- Opener (SimC's optimal list): Scalecommander vs Flameshaper order
  combat(false); now = now + 500
  state.known = { [361469]=true, [375087]=true, [370553]=true, [359073]=true, [357208]=true, [356995]=true,
                  [357210]=true, [436335]=true, [441176]=true }          -- Scalecommander with Melt Armor
  events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED"); state.target = true; step()
  expect("Devastation opener (Scalecommander): Living Flame, Dragonrage, Eternity Surge, Tip, Fire Breath, Deep Breath",
    "icon:361469,icon:375087,icon:359073,icon:370553,icon:357208,icon:357210", openerIcons())
  cast(361469); cast(375087); cast(382411); step()                    -- Eternity Surge cast as its Font of Magic ID
  expect("Devastation opener: Font of Magic Eternity Surge counts as the step (4 of 7)", "Opener 4/7", ob.label.text)
  state.known[436335] = nil; state.known[441176] = nil; state.known[1264269] = true  -- Flameshaper
  events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED"); step()
  expect("Devastation opener (Flameshaper): Living Flame, Dragonrage, Tip, Eternity Surge, Fire Breath, Disintegrate",
    "icon:361469,icon:375087,icon:370553,icon:359073,icon:357208,icon:356995", openerIcons())
  state.target = nil
  expect("Devastation: listed in the options tree", true, (function()
    for _, sp in ipairs(ns.specInfo) do if sp.id == 1467 then return true end end return false end)())
  combat(false); state.rpmax = nil; state.rp = 10; state.plates = 0; state.next = nil
  issecretvalue = function(v) return v == "SECRET" end
end

-- RUNIC POWER ICON (runic power hidden: the game evaluates a curve on it) -------------
do
  local pf = AssistCompanionPower
  state.rpPct, state.rpScale = 0.9, 1
  function UnitPowerPercent(unit, ptype, predicted, curve)
    state.rpAskedType = ptype
    return curve:Evaluate(state.rpPct * state.rpScale)
  end
  AssistCompanionDB.locked = true
  state.spec = 252; state.known = { [207317] = true, [47541] = true, [433901] = true }; state.overrides = {}
  events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED")
  state.rp = "SECRET"; state.next = 55090; state.plates = 1
  combat(true); step()
  expect("RP icon: Unholy, hidden 90% RP + Scourge -> Death Coil icon shown", true, pf.shown and pf.alpha == 1)
  expect("RP icon: shows Death Coil on 1 target", "icon:47541", pf.icon.texture)
  expect("RP icon: it's a layer on the next-cast icon, not a separate frame", AssistCompanionNext, pf.parent)
  expect("RP icon: the next-cast icon underneath still shows the highlight", "icon:55090", nf.icon.texture)
  expect("RP icon: the layer covers the icon's text (keybind) but has its own GCD swipe", true,
    pf.level > nf.textLayer.level and pf.gcd ~= nil)
  -- Blightfall (listed before the runic power rule) wins: layer off
  state.overrides = { [1233448] = 1271967 }; state.next = 77575; step()
  expect("RP icon: higher-priority correction (Blightfall) -> layer hidden", true,
    nf.icon.texture == "icon:1271967" and not pf.shown)
  state.overrides = {}; state.next = 55090
  AssistCompanionDB.locked = false; step()
  expect("RP icon: unlocked -> layer hidden (only the next-cast icon to drag)", false, pf.shown)
  AssistCompanionDB.locked = true; step()
  expect("RP icon: asks for runic power", 6, state.rpAskedType)
  state.rpPct = 0.7; step()
  expect("RP icon: 70% (below 80) -> invisible", 0, pf.alpha)
  state.rpPct, state.rpScale = 85, 1; step()
  expect("RP icon: 0-100 scale, 85 -> visible", 1, pf.alpha)
  state.rpPct = 50; step()
  expect("RP icon: 0-100 scale, 50 -> invisible", 0, pf.alpha)
  state.rpPct = 0.9; state.plates = 5; step()
  expect("RP icon: 5 targets -> Epidemic", "icon:207317", pf.icon.texture)
  state.next = 77575; step()
  expect("RP icon: highlight on a cooldown (Outbreak) -> not covered (0.25.0)", false, pf.shown)
  state.next = 1247378; step()
  expect("RP icon: ...nor Putrefy", false, pf.shown)
  state.overrides = { [55090] = 433895 }; state.next = 433895; step()
  expect("RP icon: Vampiric Strike (Scourge Strike's button) -> covered", true, pf.shown and pf.alpha == 1)
  state.overrides = {}; state.next = 55090
  state.known[433901] = nil; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED"); step()
  expect("RP icon: Rider (no Vampiric Strike talent) -> off", false, pf.shown)
  state.known[433901] = true; events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED"); step()
  state.next = 47541; step()
  expect("RP icon: highlight already on Death Coil -> hidden", false, pf.shown)
  state.next = 207317; step()
  expect("RP icon: highlight already on Epidemic -> hidden", false, pf.shown)
  state.overrides = { [47541] = 1242174 }; state.next = 1242174; step()
  expect("RP icon: highlight on Death Coil's replacement (Necrotic Coil) -> hidden", false, pf.shown)
  state.next = 55090; state.plates = 1; step()
  expect("RP icon: shows the button's spell (Necrotic Coil), not plain Death Coil", "icon:1242174", pf.icon.texture)
  state.overrides = { [207317] = 383269 }; state.plates = 5; step()
  expect("RP icon: shows Graveyard when it replaces Epidemic", "icon:383269", pf.icon.texture)
  state.next = 383269; step()
  expect("RP icon: highlight already on Graveyard (Epidemic's replacement) -> hidden", false, pf.shown)
  state.overrides = {}; state.next = 207317
  state.next = 55090; state.rp = 90; step()
  expect("RP icon: readable runic power -> hidden (the rule shows on the next-cast icon)", false, pf.shown)
  expect("RP icon: ...and the rule fires", "icon:207317", nf.icon.texture)
  state.rp = "SECRET"; ns.setRuleEnabled(252, "rpcap", false); step()
  expect("RP icon: rule turned off -> hidden", false, pf.shown)
  ns.setRuleEnabled(252, "rpcap", true)
  combat(false); step()
  expect("RP icon: out of combat -> hidden", false, pf.shown)
  -- Blood: within 20 of max (100 in the mock -> 80%)
  state.spec = 250; state.known = { [49998] = true }; state.next = 206930
  events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED")
  combat(true); state.rpPct = 0.85; step()
  expect("RP icon: Blood 85% -> Death Strike", true, pf.shown and pf.alpha == 1 and pf.icon.texture == "icon:49998")
  state.rpPct = 0.75; step()
  expect("RP icon: Blood 75% -> invisible", 0, pf.alpha)
  state.next = 49998; step()
  expect("RP icon: Blood, highlight already on Death Strike -> hidden", false, pf.shown)
  -- debug line
  AssistCompanionDB.debugLog = {}; AssistCompanionDB.debug = true
  state.next = 206930; for _ = 1, 12 do step() end
  local found = false
  for _, l in ipairs(AssistCompanionDB.debugLog) do if l:find("rpicon=0", 1, true) then found = true end end
  expect("RP icon: debug status shows rpicon=", true, found)
  -- API errors are logged, icon hidden
  UnitPowerPercent = function() error("bad args") end; step()
  found = false
  for _, l in ipairs(AssistCompanionDB.debugLog) do if l:find("UnitPowerPercent failed", 1, true) then found = true end end
  expect("RP icon: API error logged and icon hidden", true, found and not pf.shown)
  -- /ac rptest: ignores the highlight and combat
  UnitPowerPercent = function(unit, ptype, predicted, curve) return curve:Evaluate(state.rpPct) end
  state.next = 49998; combat(false); state.rpPct = 0.9; step()
  expect("RP test: off -> hidden out of combat", false, pf.shown)
  SlashCmdList.ASSISTCOMPANION("rptest"); step()
  expect("RP test: on -> follows runic power out of combat, highlight ignored", true, pf.shown and pf.alpha == 1)
  expect("RP test: labelled", "RP test", pf.label.text)
  state.rpPct = 0.5; step()
  expect("RP test: low runic power -> invisible", 0, pf.alpha)
  SlashCmdList.ASSISTCOMPANION("rptest"); step()
  expect("RP test: off again -> hidden, label cleared", true, not pf.shown and pf.label.text == "")
  -- Hold runic power for Death Strike (Blood option): hold layer (Blood Boil / Heart Strike) shown
  -- below max-20 runic power, Death Strike layer on top at <= 50% health
  local hold, low = AssistCompanionHold, AssistCompanionHoldLow
  function UnitPowerPercent(unit, ptype, predicted, curve) return curve:Evaluate(state.rpPct) end
  state.spec = 250; state.pet = true; state.overrides = {}
  state.known = { [195182]=true, [49998]=true, [50842]=true, [206930]=true, [219786]=true }
  state.charges = { [50842] = { 1, 2, 0, 7.5 } }
  events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED")
  for _, k in ipairs({ "boneshield", "rpcap", "bloodboil", "vampiricblood", "raisedead" }) do ns.setRuleEnabled(250, k, false) end
  local savedUnitPower = UnitPower
  UnitPower = function(u, t) if t == 5 then return 3 end return state.rp end
  state.rp = "SECRET"; state.rpmax = 125; state.next = 49998; state.hp = 1.0; state.hpSecret = false
  combat(true); step()
  expect("Hold: option off -> no hold layers", false, hold.shown or low.shown)
  AssistCompanionDB.holdDeathStrike = true
  state.rpPct = 0.52; step()   -- 65 of 125
  expect("Hold: 65/125 runic power, full health -> Blood Boil over Death Strike", true, hold.shown and hold.alpha == 1)
  expect("Hold: ...Blood Boil icon (a charge)", "icon:50842", hold.icon.texture)
  expect("Hold: ...low-health layer invisible", 0, low.alpha)
  cast(50842); cast(50842); cast(50842); step()   -- charges are counted from your casts in combat
  expect("Hold: no Blood Boil charge -> Heart Strike", "icon:206930", hold.icon.texture)
  state.rpPct = 0.85; step()  -- 106 of 125: within 20 of max
  expect("Hold: within 20 of max -> hold layer invisible (Death Strike)", 0, hold.alpha)
  state.rpPct = 0.52; state.hp = 0.4; step()
  expect("Hold: 40% health -> Death Strike layer on top", 1, low.alpha)
  expect("Hold: ...with the Death Strike icon", "icon:49998", low.icon.texture)
  state.hp = 1.0; state.next = 206930; step()
  expect("Hold: highlight not on Death Strike -> layers off", false, hold.shown or low.shown)
  state.next = 49998; combat(false); step()
  expect("Hold: out of combat -> off", false, hold.shown)
  AssistCompanionDB.holdDeathStrike = false; UnitPower = savedUnitPower
  for _, k in ipairs({ "boneshield", "rpcap", "bloodboil", "vampiricblood", "raisedead" }) do ns.setRuleEnabled(250, k, true) end
  UnitPowerPercent = nil; AssistCompanionDB.debug = false; combat(false); state.rp = 10; state.rpmax = nil; step()
end

-- WINDWALKER -----------------------------------------------------------------
do
  local TP, BOK, SCK, RSK, FOF = 100780, 100784, 101546, 107428, 113656
  local ZEN, XUEN, CC, CCH = 1249625, 123904, 443028, 1248989
  C_Spell.GetSpellCharges, C_Spell.GetSpellCooldown = nil, nil -- hidden: everything from casts
  issecretvalue = nil; UnitPowerPercent = nil
  state.spec = 269; state.overrides = {}; state.target = nil; state.inRange = true; state.usable = {}; state.noPower = {}
  state.known = { [TP]=true, [BOK]=true, [SCK]=true, [RSK]=true, [FOF]=true, [ZEN]=true }
  state.rp = 3; state.rpmax = 5; state.plates = 1
  events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED")
  events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED"); now = now + 500
  local function rules() local t = {} for _, r in ipairs(ns.rules[269]) do t[#t + 1] = r.key end return table.concat(t, ",") end
  expect("Windwalker: rule order", "xuen,conduit,zenith,danceofchiji,sck3,sckaoe", rules())
  state.rangeAsked = {}; step()
  expect("Windwalker: enemies counted in Fists of Fury range (8 yd, Spinning Crane Kick's radius)", true, state.rangeAsked[113656] or false)
  expect("Windwalker: melee check still uses Tiger Palm", true, state.rangeAsked[100780] or false)
  expect("Windwalker: listed in the options", true, (function()
    for _, sp in ipairs(ns.specInfo) do if sp.id == 269 then return true end end return false end)())
  state.next = TP; step()
  expect("Windwalker: out of combat -> no Zenith prompt", "icon:100780", nf.icon.texture)
  combat(true); step()
  expect("Windwalker: in combat, Zenith charge ready -> Zenith", "icon:1249625", nf.icon.texture)
  cast(ZEN); now = now + 1; step()
  expect("Windwalker: Zenith running -> highlight", "icon:100780", nf.icon.texture)
  now = now + 16; step()
  expect("Windwalker: Zenith over, second charge -> Zenith again", "icon:1249625", nf.icon.texture)
  cast(ZEN); now = now + 17; step()
  expect("Windwalker: no charge left -> highlight", "icon:100780", nf.icon.texture)
  events.scripts.OnEvent(events, "SPELLS_CHANGED"); step()
  expect("Windwalker: button swap mid-fight (SPELLS_CHANGED) keeps the charge count -> no Zenith", "icon:100780", nf.icon.texture)
  now = now + 60; step()
  expect("Windwalker: first charge back after 90s -> Zenith", "icon:1249625", nf.icon.texture)
  talented(280197, true); ns.setRuleEnabled(269, "zenith", false); step()
  -- 3 targets: Spinning Crane Kick in place of Tiger Palm / Blackout Kick
  state.plates = 3; state.next = TP; step()
  expect("Windwalker: 3 targets + Tiger Palm -> Spinning Crane Kick", "icon:101546", nf.icon.texture)
  expect("Windwalker: ...as a correction (gold border)", true, nf.border.shown)
  state.next = BOK; step()
  expect("Windwalker: 3 targets + Blackout Kick -> Spinning Crane Kick", "icon:101546", nf.icon.texture)
  state.next = FOF; step()
  expect("Windwalker: 3 targets + Fists of Fury -> stays", "icon:113656", nf.icon.texture)
  state.next = TP; cast(SCK); step()
  expect("Windwalker: last ability was Spinning Crane Kick (Combo Strikes) -> Tiger Palm", "icon:100780", nf.icon.texture)
  cast(TP); state.rp = 1; step()
  expect("Windwalker: 1 chi -> can't afford it, Tiger Palm stays", "icon:100780", nf.icon.texture)
  state.rp = 3; state.plates = 2; step()
  expect("Windwalker: 2 targets -> Tiger Palm stays", "icon:100780", nf.icon.texture)
  -- 4+ targets: Spinning Crane Kick over Rising Sun Kick
  state.plates = 5; state.next = RSK; step()
  expect("Windwalker: 5 targets + Rising Sun Kick at 3 chi -> Rising Sun Kick (keep chi for Fists of Fury)", "icon:107428", nf.icon.texture)
  state.rp = 4; step()
  expect("Windwalker: 5 targets + Rising Sun Kick at 4 chi -> Spinning Crane Kick", "icon:101546", nf.icon.texture)
  state.plates = 3; step()
  expect("Windwalker: 3 targets + Rising Sun Kick -> stays (lost damage in the sims)", "icon:107428", nf.icon.texture)
  -- Dance of Chi-Ji glow, 1-2 targets
  state.plates = 1; state.next = RSK; step()
  expect("Windwalker: no glow -> Rising Sun Kick", "icon:107428", nf.icon.texture)
  events.scripts.OnEvent(events, "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", SCK); step()
  expect("Windwalker: Dance of Chi-Ji glow on 1 target -> Spinning Crane Kick", "icon:101546", nf.icon.texture)
  state.rp = 0; step()
  expect("Windwalker: ...free, so 0 chi is fine", "icon:101546", nf.icon.texture)
  state.rp = 3; state.plates = 3; step()
  expect("Windwalker: glow on 3 targets -> no Dance of Chi-Ji rule", "icon:107428", nf.icon.texture)
  state.plates = 1
  events.scripts.OnEvent(events, "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE", SCK); step()
  expect("Windwalker: glow gone -> Rising Sun Kick", "icon:107428", nf.icon.texture)
  -- secret spell ID in the glow event: ignored
  issecretvalue = function(v) return v == "SECRET" end
  events.scripts.OnEvent(events, "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", "SECRET"); step()
  expect("Windwalker: secret glow event -> ignored", "icon:107428", nf.icon.texture)
  issecretvalue = nil
  -- Xuen and Celestial Conduit (Conduit of the Celestials)
  state.known[XUEN] = true; state.known[CCH] = true; talented(XUEN, true)
  expect("Windwalker: Xuen ready -> Invoke Xuen", "icon:123904", nf.icon.texture)
  cast(XUEN); now = now + 1; step()
  expect("Windwalker: after Xuen -> Celestial Conduit", "icon:443028", nf.icon.texture)
  cast(CC); now = now + 1; step()
  expect("Windwalker: Conduit used -> highlight", "icon:107428", nf.icon.texture)
  now = now + 89; step()
  expect("Windwalker: Conduit off cooldown but no Xuen in the last 60s -> highlight", "icon:107428", nf.icon.texture)
  now = now + 30; step()
  expect("Windwalker: Xuen back after 120s -> Invoke Xuen", "icon:123904", nf.icon.texture)
  talented(392986, true); cast(XUEN); now = now + 61; cast(RSK); step()
  expect("Windwalker: Conduit window over (60s) -> highlight", "icon:107428", nf.icon.texture)
  now = now + 30; step()
  expect("Windwalker: Xuen's Bond -> Xuen back after 90s", "icon:123904", nf.icon.texture)
  ns.setRuleEnabled(269, "zenith", true); talented(280197, false)
  combat(false); state.rp = 10; state.rpmax = nil; state.plates = 1; step()
end

-- BREWMASTER -----------------------------------------------------------------
do
  local KS, BOK, TP, BOF, EK, ETC, PB, CI, BOB, NIU = 121253, 205523, 100780, 115181, 325153, 1262768, 119582, 1241059, 115399, 132578
  local BOC, FP = 196736, 389942
  C_Spell.GetSpellCharges, C_Spell.GetSpellCooldown = nil, nil -- hidden: everything from casts
  issecretvalue = nil; UnitPowerPercent = nil
  state.spec = 268; state.overrides = {}; state.target = nil; state.inRange = true; state.usable = {}; state.noPower = {}
  state.known = { [KS]=true, [BOK]=true, [TP]=true, [BOF]=true, [EK]=true, [PB]=true, [CI]=true, [BOB]=true, [NIU]=true,
                  [BOC]=true, [FP]=true }
  state.rp = 100; state.rpmax = 100; state.plates = 1
  events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED")
  events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED"); now = now + 500
  local function rules() local t = {} for _, r in ipairs(ns.rules[268]) do t[#t + 1] = r.key end return table.concat(t, ",") end
  expect("Brewmaster: rule order", "purify,celestial,niuzao,blackoxbrew,cellar,combo3,pool", rules())
  expect("Brewmaster: listed in the options", true, (function()
    for _, sp in ipairs(ns.specInfo) do if sp.id == 268 then return true end end return false end)())
  state.next = KS; step()
  expect("Brewmaster: out of combat -> highlight", "icon:121253", nf.icon.texture)
  combat(true); step()
  expect("Brewmaster: in combat, Purifying Brew charges -> Purifying Brew", "icon:119582", nf.icon.texture)
  cast(PB); step()
  expect("Brewmaster: one charge left -> still Purifying Brew", "icon:119582", nf.icon.texture)
  cast(PB); step()
  expect("Brewmaster: no charges -> Celestial Infusion", "icon:1241059", nf.icon.texture)
  cast(CI); step()
  expect("Brewmaster: -> Invoke Niuzao", "icon:132578", nf.icon.texture)
  cast(NIU); step()
  expect("Brewmaster: Celestial Infusion spent -> Black Ox Brew", "icon:115399", nf.icon.texture)
  cast(BOB); step()
  expect("Brewmaster: Black Ox Brew refills Purifying Brew", "icon:119582", nf.icon.texture)
  cast(PB); cast(PB); step()
  expect("Brewmaster: Black Ox Brew granted Celestial Infusion", "icon:1241059", nf.icon.texture)
  cast(CI); step()
  expect("Brewmaster: ...only one charge (owner's log: two with Endless Draught counted as refilled)", "icon:121253", nf.icon.texture)
  expect("Brewmaster: everything spent -> highlight", "icon:121253", nf.icon.texture)
  -- brew recharge sped up by Tiger Palm (1.5s with Face Palm) and Keg Smash (3s, 5s with Blackout Combo)
  now = now + 10; step()
  expect("Brewmaster: 10s after Purifying Brew -> not back (20s)", "icon:121253", nf.icon.texture)
  cast(KS); cast(BOK); cast(KS); step()   -- 3 + 5 = 8s off
  expect("Brewmaster: Keg Smashes took 8s off -> still 2s left", "icon:121253", nf.icon.texture)
  cast(TP); cast(TP); step()             -- 3s off
  expect("Brewmaster: Tiger Palms -> Purifying Brew back early", "icon:119582", nf.icon.texture)
  -- a brew the game refuses: count dropped, the icon moves on
  events.scripts.OnEvent(events, "UNIT_SPELLCAST_FAILED", "player", "guid", PB); step()
  expect("Brewmaster: Purifying Brew refused (not ready) -> highlight", "icon:121253", nf.icon.texture)
  ns.setRuleEnabled(268, "purify", false); ns.setRuleEnabled(268, "celestial", false)
  -- Empty the Cellar: on the Exploding Keg button
  state.overrides = { [EK] = ETC }; step()
  expect("Brewmaster: Empty the Cellar on the Exploding Keg button -> shown", "icon:1262768", nf.icon.texture)
  state.overrides = {}; step()
  -- Blackout Combo on 3+ targets
  state.plates = 3; cast(BOK); state.next = KS; step()
  expect("Brewmaster: 3 targets, Blackout Combo up, highlight Keg Smash -> Tiger Palm", "icon:100780", nf.icon.texture)
  state.plates = 2; step()
  expect("Brewmaster: 2 targets -> the highlight handles it", "icon:121253", nf.icon.texture)
  state.plates = 3; cast(TP); step()
  expect("Brewmaster: combo spent -> Keg Smash", "icon:121253", nf.icon.texture)
  -- save energy for Keg Smash
  state.plates = 1; state.next = TP; state.rp = 40; step()
  expect("Brewmaster: filler Tiger Palm at 40 energy -> keep the icon...", "icon:100780", nf.icon.texture)
  expect("Brewmaster: ...but wait (desaturated)", true, nf.icon.desat)
  state.rp = 70; step()
  expect("Brewmaster: 70 energy -> Tiger Palm, no wait", false, nf.icon.desat)
  state.rp = 40; cast(BOK); step()
  expect("Brewmaster: Tiger Palm spending Blackout Combo -> no wait", false, nf.icon.desat)
  -- stagger probe for the debug log
  local savedAuras = C_UnitAuras
  C_UnitAuras = { GetPlayerAuraBySpellID = function(id) if id == 124273 then return { applications = 1 } end end }
  UnitStagger = function() return 12345 end
  expect("Brewmaster: stagger readable -> amount and level in the debug status", "stagger=12345 level=heavy", ns.bmStaggerText())
  issecretvalue = function(v) return v == "SECRET" end; UnitStagger = function() return "SECRET" end
  C_UnitAuras = { GetPlayerAuraBySpellID = function() return "SECRET" end }
  expect("Brewmaster: stagger hidden -> 'hidden'", "stagger=hidden level=hidden", ns.bmStaggerText())
  issecretvalue = nil; UnitStagger = nil; C_UnitAuras = savedAuras
  expect("Brewmaster: no stagger API -> '?'", "stagger=? level=?", ns.bmStaggerText())
  ns.setRuleEnabled(268, "purify", true); ns.setRuleEnabled(268, "celestial", true)
  combat(false); state.rp = 10; state.rpmax = nil; state.plates = 1; step()
end

io.stdout:write(table.concat(printed, "\n"), "\n")
io.stdout:write(("\n%d passed, %d failed\n"):format(pass, fail))
os.exit(fail == 0 and 0 or 1)

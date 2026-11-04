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
  function f:SetPoint() end
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
  function f:SetParent() end
  function f:SetWidth() end
  function f:SetHeight(h) self.height = h end
  function f:SetScrollChild(c) self.child = c end
  function f:EnableMouseWheel() end
  function f:GetVerticalScrollRange() return 0 end
  function f:GetVerticalScroll() return 0 end
  function f:SetVerticalScroll() end
  function f:Click() if self.scripts.OnClick then self.scripts.OnClick(self, "LeftButton") end end
  return f
end
local frames = {}
function CreateFrame(_, name) local f = newFrame(); frames[#frames + 1] = f; if name then _G[name] = f end; return f end
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

-- load addon files with a shared namespace
local ns = {}
for _, file in ipairs({ "Rules.lua", "Core.lua", "Options.lua" }) do
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
state.spec = 252; state.known = { [207317] = true }
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
state.plates = 3; state.next = 49020; step()
expect("Frost: 3 targets + Obliterate -> Frostscythe", "icon:207230", (seen()))
state.plates = 5; step()
expect("Frost: 5 targets -> no Frostscythe nag", "nothing", (seen()))
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
local function combat(on) events.scripts.OnEvent(events, on and "PLAYER_REGEN_DISABLED" or "PLAYER_REGEN_ENABLED") end
local function openerIcons() local t = {} for i = 1, 6 do local s = ob.slots[i]; if s.shown then t[#t+1] = s.texture end end return table.concat(t, ",") end
state.spec = 251; state.inRange = true; state.target = nil
state.known = { [47568]=true, [51271]=true, [1249658]=true, [49020]=true, [279302]=true } -- no Reaper's Mark
events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED"); now = now + 300; step()
expect("Opener: Frost shows before pull with hostile target", true, ob.shown)
expect("Opener: Frost skips Reaper's Mark when not talented", "icon:47568,icon:51271,icon:1249658,icon:49020,icon:279302,icon:49020", openerIcons())
expect("Opener: label", "Opener\n1/8", ob.label.text)
expect("Opener: first icon is large", 44, ob.slots[1].size[1])
combat(true); cast(47568); step()
expect("Opener: advances after first cast", "Opener\n2/8", ob.label.text)
cast(1249658); step() -- pressed Breath before Pillar: skip ahead within 2 steps
expect("Opener: out-of-order cast skips ahead", "Opener\n4/8", ob.label.text)
cast(49020); cast(279302); cast(49020); cast(49020); cast(49020); step()
expect("Opener: finished -> hidden", false, ob.shown)
combat(false); step()
expect("Opener: resets after combat", "Opener\n1/8", ob.label.text)
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
expect("Opener: Unholy length without Raise Dead", "Opener\n1/9", ob.label.text)
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
state.spec = 252; state.known = { [207317] = true }; state.pet = true
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
state.spec = 252; state.known = { [207317] = true }; state.pet = true; state.overrides = {}
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
state.known = { [47568]=true, [51271]=true, [1249658]=true, [49020]=true, [279302]=true }
events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED")
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED")
now = now + 600; state.next = 49143; step()
-- pull: Pillar + Breath used, then combat drops (wipe)
combat(true); cast(47568); cast(51271); cast(1249658); step()
expect("Reset: mid-opener before wipe", "Opener\n4/8", ob.label.text)
combat(false); step()
expect("Reset: combat drop -> opener back to step 1", "Opener\n1/8", ob.label.text)
-- next pull right away: Breath must count as ready even though it was cast <120s ago
AssistCompanionDB.openerIcon = false
combat(true); now = now + 5; cast(51271); state.next = 49020; step()
expect("Reset: Breath treated as off cooldown after combat drop", "icon:1249658", nf.icon.texture)
combat(false); AssistCompanionDB.openerIcon = true
-- death resets mid-pull
combat(true); cast(47568); cast(51271); step()
events.scripts.OnEvent(events, "PLAYER_DEAD"); step()
expect("Reset: death -> opener back to step 1", "Opener\n1/8", ob.label.text)
combat(false)
-- encounter end resets
combat(true); cast(47568); step()
events.scripts.OnEvent(events, "ENCOUNTER_END"); combat(false); step()
expect("Reset: encounter end -> step 1", "Opener\n1/8", ob.label.text)
-- out-of-combat press: stays advanced briefly, resets after 10s idle
cast(47568); step()
expect("Reset: out-of-combat press advances", "Opener\n2/8", ob.label.text)
now = now + 5; step()
expect("Reset: still advanced after 5s", "Opener\n2/8", ob.label.text)
now = now + 6; step()
expect("Reset: reset after 10s idle out of combat", "Opener\n1/8", ob.label.text)
AssistCompanionDB.openerIcon = false

-- OPENER SURVIVES MID-COMBAT SPELLBOOK UPDATES ----------------------------
AssistCompanionDB.openerIcon = true
state.spec = 251; state.target = nil; state.overrides = {}; state.inRange = true
state.known = { [47568]=true, [51271]=true, [439843]=true, [1249658]=true, [49020]=true, [279302]=true }
events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED")
events.scripts.OnEvent(events, "PLAYER_REGEN_ENABLED"); now = now + 700; step()
combat(true)
cast(47568); cast(51271); cast(439843); cast(1249658); cast(49020); cast(279302); cast(49020); step()
expect("Opener bug: at step 8 of 9 (two Obliterates left)", "Opener\n8/9", ob.label.text)
events.scripts.OnEvent(events, "SPELLS_CHANGED"); step() -- e.g. Pillar of Frost ends
expect("Opener bug: SPELLS_CHANGED mid-combat does not reset", "Opener\n8/9", ob.label.text)
events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED"); step()
expect("Opener bug: talent event mid-combat does not reset", "Opener\n8/9", ob.label.text)
cast(49020); cast(49020); step()
expect("Opener bug: finishes normally", false, ob.shown)
combat(false); step()
expect("Opener bug: still resets on combat drop", "Opener\n1/9", ob.label.text)
-- out of combat, mid-opener: SPELLS_CHANGED keeps progress; a real talent change rebuilds
cast(47568); events.scripts.OnEvent(events, "SPELLS_CHANGED"); step()
expect("Opener bug: SPELLS_CHANGED out of combat keeps progress", "Opener\n2/9", ob.label.text)
events.scripts.OnEvent(events, "TRAIT_CONFIG_UPDATED"); step()
expect("Opener bug: talent change out of combat rebuilds", "Opener\n1/9", ob.label.text)
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
state.spec = 252; state.known = { [207317] = true }; state.pet = true; state.overrides = {}
events.scripts.OnEvent(events, "PLAYER_SPECIALIZATION_CHANGED")
state.bars = {}; state.target = nil; state.next = 55090; state.rp = 10; state.plates = 1; state.barRange = true; state.inRange = true
now = now + 800; step()
expect("Shading: usable -> normal", 1, nf.icon.color[3] == 1 and nf.icon.color[1] or 0)
state.usable[55090] = false; state.noPower[55090] = true; step()
expect("Shading: not enough runes -> blue", "0.5,0.5,1", table.concat(nf.icon.color, ","))
state.noPower[55090] = false; step()
expect("Shading: unusable for other reason -> gray", "0.4,0.4,0.4", table.concat(nf.icon.color, ","))
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
expect("CD skip: Pillar on cooldown is skipped", "icon:439843", nf.icon.texture)
expect("CD skip: opener moves on past Pillar", "Opener\n3/9", ob.label.text)
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
function UnitPower() return state.rp end
combat(false)
-- Opener
state.pet = false; events.scripts.OnEvent(events, "UNIT_PET", "player"); state.target = nil; now = now + 100; step()
expect("Blood opener: starts with Death's Caress", "icon:195292", ob.slots[1].texture)
expect("Blood opener: then Raise Dead when no ghoul", "icon:46585", ob.slots[2].texture)
state.pet = true; events.scripts.OnEvent(events, "UNIT_PET", "player"); step()
expect("Blood opener: ghoul out -> skips Raise Dead", "icon:195182", ob.slots[2].texture)
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
expect("Debug log: opener step done", true, logHas("opener: step 1/8 done (spell47568)"))
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
for i = 1, 600 do cast(49020) end
expect("Debug log: capped at 500 lines", 500, #log)
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
local size = AssistCompanionDB.iconSize
for _, w in ipairs(ns.optionsWidgets) do if w.label and w.label.text == "Icon size" then w.plus:Click() end end
expect("Options: icon size + button", size + 4, AssistCompanionDB.iconSize)
AssistCompanionDB.iconSize = size
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
expect("Aug: rule order", "ebonmight,breatheons,prescience",
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

io.stdout:write(table.concat(printed, "\n"), "\n")
io.stdout:write(("\n%d passed, %d failed\n"):format(pass, fail))
os.exit(fail == 0 and 0 or 1)

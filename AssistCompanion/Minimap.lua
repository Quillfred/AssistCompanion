-- Assist Companion: minimap button (left-click: options, right-click: lock/unlock, drag: move it
-- around the minimap) and an entry in Blizzard's addon compartment (the minimap's addon menu).

local _, ns = ...

local C            -- Core.lua's helpers, handed over in ns.initMinimap
local button
local ICON = "Interface\\Icons\\INV_Misc_Gear_01"

local function db() return C.db() end

-- Place the button on the minimap's edge at db.minimapAngle (degrees, 0 = right, counter-clockwise).
-- Square minimaps (some UI packs) get the square's edge instead of a circle.
local function place()
  if not button then return end
  local angle = math.rad(db().minimapAngle or 225)
  local x, y = math.cos(angle), math.sin(angle)
  local r = (Minimap:GetWidth() or 140) / 2 + 5
  local shape = GetMinimapShape and GetMinimapShape()
  if shape == "SQUARE" then
    local d = math.sqrt(2) -- push out to the corners, then clamp to the edge
    x = math.max(-1, math.min(1, x * d))
    y = math.max(-1, math.min(1, y * d))
  end
  button:ClearAllPoints()
  button:SetPoint("CENTER", Minimap, "CENTER", x * r, y * r)
end

-- Angle from the minimap's centre to the cursor, in degrees.
local function cursorAngle()
  local mx, my = Minimap:GetCenter()
  local px, py = GetCursorPosition()
  local scale = Minimap:GetEffectiveScale() or 1
  px, py = px / scale, py / scale
  return math.deg(math.atan2(py - my, px - mx)) % 360
end

function ns.updateMinimap()
  if not button then return end
  button:SetShown(db().minimapButton and true or false)
  place()
end

local function build()
  button = CreateFrame("Button", "AssistCompanionMinimapButton", Minimap)
  button:SetSize(31, 31)
  button:SetFrameStrata("MEDIUM")
  button:SetFrameLevel(8)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button:RegisterForDrag("LeftButton")
  button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  local bg = button:CreateTexture(nil, "BACKGROUND")
  bg:SetSize(20, 20)
  bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  bg:SetPoint("TOPLEFT", 7, -5)
  button.icon = button:CreateTexture(nil, "ARTWORK")
  button.icon:SetSize(17, 17)
  button.icon:SetTexture(ICON)
  button.icon:SetPoint("TOPLEFT", 7, -6)
  local border = button:CreateTexture(nil, "OVERLAY")
  border:SetSize(53, 53)
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetPoint("TOPLEFT")

  button:SetScript("OnClick", function(_, mouse)
    if mouse == "RightButton" then
      SlashCmdList.ASSISTCOMPANION(db().locked and "unlock" or "lock")
    else
      ns.openOptions()
    end
  end)
  button:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
      db().minimapAngle = cursorAngle()
      place()
    end)
  end)
  button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
  button:SetScript("OnEnter", function(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Assist Companion", 1, 1, 1)
    GameTooltip:AddLine("Left-click: options", nil, nil, nil, true)
    GameTooltip:AddLine("Right-click: " .. (db().locked and "unlock frames to move them" or "lock frames"), nil, nil, nil, true)
    GameTooltip:AddLine("Drag: move this button", nil, nil, nil, true)
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
end

function ns.initMinimap(core)
  C = core
  if not button and Minimap then build() end
  ns.updateMinimap()
end

-- Blizzard's addon compartment (minimap addon menu), set up in the TOC (## AddonCompartmentFunc).
function AssistCompanion_OnAddonCompartmentClick()
  if ns.openOptions then ns.openOptions() end
end

ns.minimapButton = function() return button end -- for tests

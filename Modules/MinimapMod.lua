-- Modules/MinimapMod.lua (Classic Era)
-- Features: Square Minimap with Sleek Border + Bottom Addon Icon Alignment + Drag-and-Drop Button
local addonName, ns = ...

local Minimap = Minimap
local MinimapCompassTexture = MinimapCompassTexture
local MinimapCompassTextureUnderlay = MinimapCompassTextureUnderlay
local CreateFrame = CreateFrame
local UIParent = UIParent
local GetCursorPosition = GetCursorPosition
local hooksecurefunc = hooksecurefunc
local C_Timer = C_Timer
local LibStub = LibStub
local math_rad = math.rad
local math_cos = math.cos
local math_sin = math.sin
local math_deg = math.deg
local math_atan2 = math.atan2
local math_floor = math.floor
local math_min = math.min
local pcall = pcall
local pairs = pairs
local ipairs = ipairs
local wipe = wipe
local _G = _G

local MinimapMod = {}
ns.MinimapMod = MinimapMod

local miniBtn = nil
local borderFrame = nil
local SQUARE_MASK = "Interface\\ChatFrame\\ChatFrameBackground"
local ROUND_MASK = "Interface\\Minimap\\UI-Minimap-Background"
local applyingMask = false
local originalButtonPoints = {}

-- Frames to ignore when scanning for addon minimap buttons
local IgnoredFrames = {
    ["Minimap"] = true,
    ["MinimapBackdrop"] = true,
    ["MinimapCompassTexture"] = true,
    ["MinimapCompassTextureUnderlay"] = true,
    ["MinimapCluster"] = true,
    ["MiniMapWorldMap"] = true,
    ["MiniMapTracking"] = true,
    ["MiniMapTrackingButton"] = true,
    ["MiniMapTrackingFrame"] = true,
    ["MiniMapMailFrame"] = true,
    ["MiniMapMailIcon"] = true,
    ["MinimapZoneTextButton"] = true,
    ["TimeManagerClockButton"] = true,
    ["GameTimeFrame"] = true,
    ["QueueStatusMinimapButton"] = true,
    ["QueueStatusButton"] = true,
    ["GarrisonLandingPageMinimapButton"] = true,
    ["ExpansionLandingPageMinimapButton"] = true,
    ["Wellbrock_MinimapBorder"] = true,
}

-- ---------------------------------------------------------
-- Square Minimap Border Frame
-- ---------------------------------------------------------
local function CreateMinimapBorder()
    if borderFrame then return borderFrame end

    borderFrame = CreateFrame("Frame", "Wellbrock_MinimapBorder", Minimap, "BackdropTemplate")
    borderFrame:SetFrameStrata("BACKGROUND")
    borderFrame:SetFrameLevel(Minimap:GetFrameLevel() + 5)
    borderFrame:Hide()
    return borderFrame
end

function MinimapMod:UpdateBorder()
    local border = CreateMinimapBorder()
    local isSquare = ns.db and ns.db.modules and ns.db.modules.squareMinimap
    local showBorder = ns.db and ns.db.minimap and (ns.db.minimap.showBorder ~= false)

    if isSquare and showBorder then
        local bWidth = (ns.db.minimap and ns.db.minimap.borderWidth) or 2
        border:ClearAllPoints()
        border:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -bWidth, bWidth)
        border:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", bWidth, -bWidth)
        border:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = bWidth,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        border:SetBackdropBorderColor(0.12, 0.12, 0.15, 0.95)
        border:Show()
    else
        border:Hide()
    end
end

-- ---------------------------------------------------------
-- Addon Buttons Collection & Bottom Alignment
-- ---------------------------------------------------------
local function GetAllAddonButtons()
    local buttons = {}
    local seen = {}

    -- 1. Wellbrock Minimap Button
    if miniBtn and miniBtn:IsShown() then
        table.insert(buttons, miniBtn)
        seen[miniBtn] = true
    end

    -- 2. Buttons registered via LibDBIcon-1.0
    local LibDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
    if LibDBIcon and LibDBIcon.GetButtonList then
        local list = LibDBIcon:GetButtonList()
        table.sort(list)
        for _, name in ipairs(list) do
            local btn = LibDBIcon:GetMinimapButton(name)
            if btn and not seen[btn] and btn:IsShown() then
                seen[btn] = true
                table.insert(buttons, btn)
            end
        end
    end

    -- 3. Scan Minimap & MinimapBackdrop for standalone addon buttons
    local function ScanParent(parent)
        if not parent or not parent.GetChildren then return end
        local children = { parent:GetChildren() }
        for _, child in ipairs(children) do
            if child and child.IsObjectType and child:IsObjectType("Button") and not seen[child] and child:IsShown() then
                local name = child:GetName() or ""
                if not IgnoredFrames[name]
                    and not name:find("^MinimapBackdrop")
                    and not name:find("^MinimapCompass")
                    and not name:find("^TimeManager")
                    and not name:find("^GameTime")
                    and not name:find("^MiniMapTracking")
                    and not name:find("^MiniMapMail")
                    and not name:find("^MiniMapWorldMap")
                    and not name:find("^MinimapZone")
                    and not name:find("^Wellbrock_") then
                    local w, h = child:GetSize()
                    if w and h and w >= 16 and w <= 48 and h >= 16 and h <= 48 then
                        seen[child] = true
                        table.insert(buttons, child)
                    end
                end
            end
        end
    end

    ScanParent(Minimap)
    if MinimapBackdrop then ScanParent(MinimapBackdrop) end

    return buttons
end

function MinimapMod:AlignAddonButtons()
    if not ns.db or not ns.db.modules then return end
    local isSquare = ns.db.modules.squareMinimap
    local alignBottom = ns.db.minimap and (ns.db.minimap.alignBottom ~= false)

    if not isSquare or not alignBottom then
        -- Restore original points and sizes
        for btn, pos in pairs(originalButtonPoints) do
            if btn and btn.ClearAllPoints and btn.SetPoint then
                btn:ClearAllPoints()
                btn:SetPoint(pos.point, pos.relativeTo or Minimap, pos.relativePoint or pos.point, pos.x, pos.y)
                if pos.size and btn.SetSize then
                    btn:SetSize(pos.size, pos.size)
                end
            end
        end
        wipe(originalButtonPoints)
        -- Restore Wellbrock button to its radial position
        local savedAngle = (ns.db.minimap and ns.db.minimap.angle) or 220
        if MinimapMod.UpdateButtonPosition then
            MinimapMod.UpdateButtonPosition(savedAngle)
        end
        return
    end

    local buttons = GetAllAddonButtons()
    local totalButtons = #buttons
    if totalButtons == 0 then return end

    local BUTTON_SIZE = 24
    local BUTTON_SPACING = 3
    local mapWidth = (Minimap and Minimap:GetWidth()) or 200
    local bWidth = (ns.db.minimap and ns.db.minimap.borderWidth) or 2

    local maxPerRow = math_floor((mapWidth + BUTTON_SPACING) / (BUTTON_SIZE + BUTTON_SPACING))
    if maxPerRow < 1 then maxPerRow = 1 end

    for i, btn in ipairs(buttons) do
        -- Save original position once for restoration
        if not originalButtonPoints[btn] then
            local point, relativeTo, relativePoint, xOfs, yOfs = btn:GetPoint()
            if point then
                originalButtonPoints[btn] = {
                    point = point,
                    relativeTo = relativeTo,
                    relativePoint = relativePoint,
                    x = xOfs,
                    y = yOfs,
                    size = btn:GetWidth(),
                }
            end
        end

        local idx = i - 1
        local row = math_floor(idx / maxPerRow)
        local col = idx % maxPerRow

        local buttonsInThisRow = math_min(maxPerRow, totalButtons - row * maxPerRow)
        local rowWidth = (buttonsInThisRow * BUTTON_SIZE) + ((buttonsInThisRow - 1) * BUTTON_SPACING)
        local startX = (mapWidth - rowWidth) / 2
        local xOfs = startX + (col * (BUTTON_SIZE + BUTTON_SPACING))
        -- Align just below the bottom border
        local yOfs = -bWidth - 3 - (row * (BUTTON_SIZE + BUTTON_SPACING))

        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", xOfs, yOfs)
        btn:SetSize(BUTTON_SIZE, BUTTON_SIZE)
        btn:SetFrameStrata("MEDIUM")
        btn:SetFrameLevel(Minimap:GetFrameLevel() + 10)
    end
end

-- ---------------------------------------------------------
-- Square Minimap Implementation
-- ---------------------------------------------------------
function MinimapMod:UpdateSquareMinimap()
    if not ns.db or not ns.db.modules then return end
    if not Minimap or not Minimap.SetMaskTexture then return end
    local isSquare = ns.db.modules.squareMinimap

    if isSquare then
        if MinimapCompassTexture then MinimapCompassTexture:Hide() end
        if MinimapCompassTextureUnderlay then MinimapCompassTextureUnderlay:Hide() end
        applyingMask = true
        pcall(Minimap.SetMaskTexture, Minimap, SQUARE_MASK)
        applyingMask = false
        _G.GetMinimapShape = function() return "SQUARE" end
    else
        applyingMask = true
        pcall(Minimap.SetMaskTexture, Minimap, ROUND_MASK)
        applyingMask = false
        if MinimapCompassTexture then MinimapCompassTexture:Show() end
        _G.GetMinimapShape = function() return "ROUND" end
    end
end

function MinimapMod:RefreshAll()
    MinimapMod:UpdateSquareMinimap()
    MinimapMod:UpdateBorder()
    MinimapMod:AlignAddonButtons()
end

-- ---------------------------------------------------------
-- Minimap Button Shortcut
-- ---------------------------------------------------------
function MinimapMod.UpdateButtonPosition(angle)
    if not miniBtn then return end
    -- If bottom alignment is active, button is positioned in bottom row
    if ns.db and ns.db.modules and ns.db.modules.squareMinimap and ns.db.minimap and (ns.db.minimap.alignBottom ~= false) then
        return
    end

    local rad = math_rad(angle or 220)
    local cos = math_cos(rad)
    local sin = math_sin(rad)
    -- Radial distance from center of minimap
    local radius = 80
    local x = cos * radius
    local y = sin * radius
    miniBtn:ClearAllPoints()
    miniBtn:SetPoint("CENTER", Minimap, "CENTER", x, y)
    miniBtn:SetSize(32, 32)
end

local function CreateMinimapButton()
    if miniBtn then return miniBtn end

    miniBtn = CreateFrame("Button", "WellbrockMinimapButton", Minimap)
    miniBtn:SetSize(32, 32)
    miniBtn:SetFrameStrata("MEDIUM")
    miniBtn:SetFrameLevel(8)
    miniBtn:EnableMouse(true)
    miniBtn:RegisterForDrag("LeftButton")
    miniBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    -- Addon Dragon Icon
    local icon = miniBtn:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", miniBtn, "CENTER", 0, 0)
    icon:SetTexture(ns.ICON_PATH)
    -- Mask to circle
    local mask = miniBtn:CreateMaskTexture()
    mask:SetSize(20, 20)
    mask:SetPoint("CENTER", miniBtn, "CENTER", 0, 0)
    mask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    icon:AddMaskTexture(mask)
    miniBtn.icon = icon

    -- Border overlay
    local border = miniBtn:CreateTexture(nil, "OVERLAY")
    border:SetSize(52, 52)
    border:SetPoint("TOPLEFT", miniBtn, "TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    miniBtn.border = border

    -- Highlight
    local highlight = miniBtn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetSize(20, 20)
    highlight:SetPoint("CENTER", miniBtn, "CENTER", 0, 0)
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    miniBtn.highlight = highlight

    -- Dragging around Minimap (only if not docked at bottom)
    miniBtn:SetScript("OnDragStart", function(self)
        if ns.db and ns.db.modules and ns.db.modules.squareMinimap and ns.db.minimap and (ns.db.minimap.alignBottom ~= false) then
            return -- locked in bottom row
        end

        self:SetScript("OnUpdate", function()
            if not Minimap or not Minimap.GetCenter then return end
            local mx, my = Minimap:GetCenter()
            if not mx or not my then return end

            local cx, cy = GetCursorPosition()
            local scale = UIParent and UIParent:GetEffectiveScale() or 1
            if not scale or scale == 0 then scale = 1 end

            cx, cy = cx / scale, cy / scale
            local angle = math_deg(math_atan2(cy - my, cx - mx))
            if not ns.db.minimap then ns.db.minimap = {} end
            ns.db.minimap.angle = angle
            MinimapMod.UpdateButtonPosition(angle)
        end)
    end)

    miniBtn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    miniBtn:SetScript("OnHide", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    -- Click to open settings
    miniBtn:SetScript("OnClick", function(self, button)
        if ns.ConfigUI then
            ns.ConfigUI:Toggle()
        end
    end)

    -- Tooltip
    miniBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("|cff00ccffWellbrock|r", 1, 1, 1)
        GameTooltip:AddLine("|cffffff00Clique:|r Abrir Painel de Configurações", 0.9, 0.9, 0.9)
        local isDocked = ns.db and ns.db.modules and ns.db.modules.squareMinimap and ns.db.minimap and (ns.db.minimap.alignBottom ~= false)
        if not isDocked then
            GameTooltip:AddLine("|cffffff00Arrastar:|r Mover ao redor do minimapa", 0.7, 0.7, 0.7)
        end
        GameTooltip:Show()
    end)
    miniBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local savedAngle = (ns.db and ns.db.minimap and ns.db.minimap.angle) or 220
    MinimapMod.UpdateButtonPosition(savedAngle)

    if ns.db and ns.db.minimap and ns.db.minimap.hide then
        miniBtn:Hide()
    else
        miniBtn:Show()
    end

    return miniBtn
end

function MinimapMod:ApplyButtonVisibility()
    if not miniBtn then return end
    if ns.db and ns.db.minimap and ns.db.minimap.hide then
        miniBtn:Hide()
    else
        miniBtn:Show()
    end
    MinimapMod:AlignAddonButtons()
end

function MinimapMod:Init()
    -- Initialize Minimap button
    CreateMinimapButton()

    -- Initialize Square Minimap and Border
    MinimapMod:UpdateSquareMinimap()

    if Minimap and Minimap.SetMaskTexture then
        hooksecurefunc(Minimap, "SetMaskTexture", function()
            if not applyingMask and ns.db and ns.db.modules and ns.db.modules.squareMinimap then
                MinimapMod:UpdateSquareMinimap()
            end
        end)
    end

    if MinimapCompassTexture then
        hooksecurefunc(MinimapCompassTexture, "Show", function()
            if ns.db and ns.db.modules and ns.db.modules.squareMinimap then
                MinimapCompassTexture:Hide()
            end
        end)
    end

    -- Hook LibDBIcon callback when other addons register their minimap icons
    local LibDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
    if LibDBIcon and LibDBIcon.callbacks and LibDBIcon.callbacks.RegisterCallback then
        pcall(LibDBIcon.callbacks.RegisterCallback, LibDBIcon.callbacks, addonName, "LibDBIcon_IconCreated", function()
            C_Timer.After(0.2, function()
                MinimapMod:AlignAddonButtons()
            end)
        end)
    end

    -- Delayed refreshes after login to align all late-loading addons
    ns.RegisterEvent("PLAYER_ENTERING_WORLD", function()
        MinimapMod:UpdateSquareMinimap()
        C_Timer.After(1.0, function() MinimapMod:AlignAddonButtons() end)
        C_Timer.After(3.0, function() MinimapMod:AlignAddonButtons() end)
    end)

    ns.RegisterEvent("ADDON_LOADED", function()
        MinimapMod:AlignAddonButtons()
    end)

    ns.Utils.Debug("MinimapMod module initialized (Square Minimap, Border & Bottom Icons).")
end
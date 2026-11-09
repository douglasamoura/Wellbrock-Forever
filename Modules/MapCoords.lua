-- Modules/MapCoords.lua (Classic Era)
-- Map Coordinates Display & Bookmark Manager (replaces MapPins + WaypointHUD for Classic)
local addonName, ns = ...

local CreateFrame = CreateFrame
local UIParent = UIParent
local GetPlayerMapPosition = GetPlayerMapPosition
local GetRealZoneText = GetRealZoneText
local GetSubZoneText = GetSubZoneText
local GetMinimapZoneText = GetMinimapZoneText
local IsInInstance = IsInInstance
local tinsert = table.insert
local tremove = table.remove
local ipairs = ipairs
local pairs = pairs
local string_format = string.format

local MapCoords = {}
ns.MapCoords = MapCoords

local coordsFrame = nil
local coordsText = nil
local updateTicker = nil

-- Get current player coordinates (Classic API)
function MapCoords:GetCurrentPlayerCoords()
    local x, y = GetPlayerMapPosition("player")
    if x == 0 and y == 0 then
        -- Try minimap zone if world map coords unavailable
        return nil, nil, GetMinimapZoneText()
    end
    return x * 100, y * 100, GetRealZoneText()
end

-- Create coordinates display frame
local function CreateCoordsFrame()
    if coordsFrame then return coordsFrame end

    coordsFrame = CreateFrame("Frame", "WellbrockCoordsFrame", UIParent)
    coordsFrame:SetSize(120, 20)
    coordsFrame:SetPoint("BOTTOM", Minimap, "TOP", 0, 5)
    coordsFrame:SetFrameStrata("LOW")
    coordsFrame:SetMovable(true)
    coordsFrame:EnableMouse(true)
    coordsFrame:RegisterForDrag("LeftButton")
    coordsFrame:SetClampedToScreen(true)
    coordsFrame:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() then self:StartMoving() end
    end)
    coordsFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    -- Background
    local bg = coordsFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.5)
    coordsFrame.bg = bg

    -- Coordinates text
    coordsText = coordsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    coordsText:SetPoint("CENTER", coordsFrame, "CENTER", 0, 0)
    coordsText:SetText("0.0, 0.0")
    coordsFrame.text = coordsText

    coordsFrame:Hide()
    return coordsFrame
end

function MapCoords:UpdateCoordsDisplay()
    if not ns.db or not ns.db.modules or not ns.db.modules.mapCoords then
        if coordsFrame then coordsFrame:Hide() end
        return
    end

    local frame = CreateCoordsFrame()
    local x, y, zone = MapCoords:GetCurrentPlayerCoords()

    if x and y then
        coordsText:SetText(string_format("%.1f, %.1f", x, y))
        frame:Show()
    else
        coordsText:SetText(zone or "Desconhecido")
        frame:Show()
    end
end

function MapCoords:SavePin(label)
    local x, y, zone = MapCoords:GetCurrentPlayerCoords()
    if not x or not y or not zone then
        ns.Utils.Print("Não foi possível determinar suas coordenadas atuais.")
        return
    end

    label = (label and label ~= "") and label or ("Pin " .. (#ns.db.savedPins + 1))

    local pin = {
        name = label,
        zone = zone,
        x = x,
        y = y,
        timestamp = time(),
    }

    tinsert(ns.db.savedPins, pin)
    ns.Utils.Print(string_format("Ponto salvo: |cffffff00%s|r em %s (%.1f, %.1f)", label, zone, x, y))
end

function MapCoords:ListPins()
    if #ns.db.savedPins == 0 then
        ns.Utils.Print("Nenhum ponto salvo no momento.")
        return
    end

    ns.Utils.Print("Pontos Salvos:")
    for i, pin in ipairs(ns.db.savedPins) do
        ns.Utils.Print(string_format("  [%d] |cffffff00%s|r - %s (%.1f, %.1f)", i, pin.name, pin.zone, pin.x, pin.y))
    end
end

function MapCoords:DeletePin(index)
    if ns.db.savedPins[index] then
        local removed = tremove(ns.db.savedPins, index)
        ns.Utils.Print("Ponto removido: " .. removed.name)
    else
        ns.Utils.Print("Ponto não encontrado.")
    end
end

-- Set waypoint for a saved pin (integrates with WaypointHUD)
function MapCoords:SetWaypoint(index)
    local pin = ns.db.savedPins[index]
    if not pin then
        ns.Utils.Print("Ponto número " .. tostring(index) .. " não encontrado.")
        return
    end

    -- Use global API to set waypoint in WaypointHUD
    if _G.Wellbrock_SetWaypointHUD then
        _G.Wellbrock_SetWaypointHUD(pin)
    else
        ns.Utils.Print("WaypointHUD não está ativo. Ative o módulo Waypoint HUD nas configurações.")
    end
end

function MapCoords:Init()
    if not ns.db.savedPins then
        ns.db.savedPins = {}
    end

    CreateCoordsFrame()

    -- Update coordinates at 5Hz (smooth but low CPU)
    updateTicker = C_Timer.NewTicker(0.2, function()
        MapCoords:UpdateCoordsDisplay()
    end)

    ns.Utils.Debug("MapCoords module initialized (coordinates display + bookmarks).")
end
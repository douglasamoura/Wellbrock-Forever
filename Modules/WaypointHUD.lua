-- Modules/WaypointHUD.lua (Forever / Classic Era / SoD)
-- Waypoint HUD Integration: Detects TomTom / HandyNotes / MapNotes
-- Falls back to basic coordinate display + manual waypoint setting
local addonName, ns = ...

local CreateFrame = CreateFrame
local UIParent = UIParent
local GetPlayerFacing = GetPlayerFacing
local C_Timer = C_Timer
local math_atan2 = math.atan2
local math_sqrt = math.sqrt
local string_format = string.format
local pcall = pcall

local WaypointHUD = {}
ns.WaypointHUD = WaypointHUD

local hudFrame = nil
local navTicker = nil
local activeWaypoint = nil
local detectedAddon = nil

-- Detected waypoint addon API
local waypointAPI = {}

-- Detect available waypoint addons
local function DetectWaypointAddon()
    if detectedAddon then return detectedAddon end

    -- TomTom (most popular)
    if TomTom and TomTom.AddWaypoint and TomTom.RemoveWaypoint then
        detectedAddon = "TomTom"
        waypointAPI = {
            SetWaypoint = function(mapID, x, y, title)
                return TomTom:AddWaypoint(mapID, x, y, { title = title or "Waypoint", persistent = false, minimap = true, world = true })
            end,
            RemoveWaypoint = function(uid)
                if uid then TomTom:RemoveWaypoint(uid) end
            end,
            GetDistance = function(uid)
                if uid and TomTom.GetDistanceToWaypoint then
                    return TomTom:GetDistanceToWaypoint(uid)
                end
                return nil
            end,
            SetCrazyArrow = function(uid, distance, title)
                if uid and TomTom.SetCrazyArrow then
                    TomTom:SetCrazyArrow(uid, distance or 0, title or "Waypoint")
                end
            end,
        }
        ns.Utils.Debug("WaypointHUD: Detectado TomTom")
        return detectedAddon
    end

    -- HandyNotes (limited waypoint support)
    if HandyNotes and HandyNotes.AddWaypoint then
        detectedAddon = "HandyNotes"
        waypointAPI = {
            SetWaypoint = function(mapID, x, y, title)
                return HandyNotes:AddWaypoint(mapID, x, y, title)
            end,
        }
        ns.Utils.Debug("WaypointHUD: Detectado HandyNotes")
        return detectedAddon
    end

    -- MapNotes (Classic)
    if MapNotes and MapNotes.AddNote then
        detectedAddon = "MapNotes"
        waypointAPI = {
            SetWaypoint = function(mapID, x, y, title)
                MapNotes:AddNote(mapID, x, y, title)
            end,
        }
        ns.Utils.Debug("WaypointHUD: Detectado MapNotes")
        return detectedAddon
    end

    -- Built-in Classic waypoint (SoD 1.15+ has limited support)
    if C_Map and C_Map.SetUserWaypoint then
        detectedAddon = "BuiltIn"
        waypointAPI = {
            SetWaypoint = function(mapID, x, y, title)
                local point = CreateVector2D and CreateVector2D(x, y) or { x = x, y = y }
                C_Map.SetUserWaypoint({ uiMapID = mapID, position = point })
                if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
                    C_SuperTrack.SetSuperTrackedUserWaypoint(true)
                end
            end,
            GetDistance = function()
                if C_Navigation and C_Navigation.GetDistance then
                    return C_Navigation.GetDistance()
                end
                return nil
            end,
        }
        ns.Utils.Debug("WaypointHUD: Usando waypoint nativo do jogo")
        return detectedAddon
    end

    detectedAddon = "None"
    ns.Utils.Debug("WaypointHUD: Nenhum addon de waypoint detectado")
    return detectedAddon
end

local function CreateHUDFrame()
    if hudFrame then return hudFrame end

    hudFrame = CreateFrame("Frame", addonName .. "_WaypointHUD", UIParent)
    hudFrame:SetSize(180, 48)
    hudFrame:SetPoint("TOP", UIParent, "TOP", 0, -120)
    hudFrame:SetMovable(true)
    hudFrame:EnableMouse(true)
    hudFrame:RegisterForDrag("LeftButton")
    hudFrame:SetClampedToScreen(true)

    hudFrame:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() then
            self:StartMoving()
        end
    end)
    hudFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    -- Background
    local bg = hudFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.45)
    hudFrame.bg = bg

    -- Arrow indicator
    local arrow = hudFrame:CreateTexture(nil, "ARTWORK")
    arrow:SetSize(24, 24)
    arrow:SetPoint("LEFT", hudFrame, "LEFT", 10, 0)
    arrow:SetTexture("Interface\\Navigation\\Arrow-Active")
    hudFrame.arrow = arrow

    -- Distance & Target text
    local text = hudFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
    text:SetPoint("LEFT", arrow, "RIGHT", 8, 0)
    text:SetPoint("RIGHT", hudFrame, "RIGHT", -8, 0)
    text:SetJustifyH("LEFT")
    text:SetText("Navegação")
    hudFrame.text = text

    hudFrame:Hide()
    return hudFrame
end

local function StopNavigation()
    if navTicker then
        navTicker:Cancel()
        navTicker = nil
    end
    if hudFrame and hudFrame:IsShown() then
        hudFrame:Hide()
    end
    activeWaypoint = nil
end

local function UpdateNavigation()
    if not ns.db or not ns.db.modules or not ns.db.modules.waypointHUD then
        StopNavigation()
        return
    end

    DetectWaypointAddon()

    local waypoint = activeWaypoint
    if not waypoint then
        StopNavigation()
        return
    end

    local playerMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    if not playerMapID or playerMapID ~= waypoint.mapID then
        if hudFrame and hudFrame:IsShown() then hudFrame:Hide() end
        return
    end

    local playerPos = C_Map and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(playerMapID, "player")
    if not playerPos then
        if hudFrame and hudFrame:IsShown() then hudFrame:Hide() end
        return
    end

    local px, py
    if playerPos.GetXY then
        px, py = playerPos:GetXY()
    else
        px, py = playerPos.x, playerPos.y
    end

    if not px or not py then
        if hudFrame and hudFrame:IsShown() then hudFrame:Hide() end
        return
    end

    local dx = waypoint.x - px
    local dy = waypoint.y - py

    -- Calculate player orientation relative to waypoint
    local facing = (GetPlayerFacing and GetPlayerFacing()) or 0
    local targetAngle = math_atan2(dx, -dy)
    local relAngle = targetAngle - facing

    -- Rotate arrow indicator
    if hudFrame and hudFrame.arrow then
        hudFrame.arrow:SetRotation(relAngle)
    end

    -- Distance calculation
    local distance = nil

    -- Try TomTom/waypoint addon distance
    if waypoint.uid and waypointAPI.GetDistance then
        local ok, dist = pcall(waypointAPI.GetDistance, waypoint.uid)
        if ok and dist and dist > 0 then
            distance = dist
        end
    end

    -- Try built-in navigation
    if not distance and C_Navigation and C_Navigation.GetDistance then
        local ok, dist = pcall(C_Navigation.GetDistance)
        if ok and dist and dist > 0 then
            distance = dist
        end
    end

    -- Try world position distance
    if not distance and C_Map and C_Map.GetWorldPosFromMapPos then
        local ok1, _, playerWorld = pcall(C_Map.GetWorldPosFromMapPos, playerMapID, playerPos)
        local ok2, _, waypointWorld = pcall(C_Map.GetWorldPosFromMapPos, playerMapID, { GetXY = function() return waypoint.x, waypoint.y end })
        if ok1 and ok2 and playerWorld and waypointWorld and playerWorld.GetDistanceTo then
            local okDist, calcDist = pcall(playerWorld.GetDistanceTo, playerWorld, waypointWorld)
            if okDist and calcDist and calcDist > 0 then
                distance = calcDist
            end
        end
    end

    -- No fallback - show unavailable if no real distance
    if not distance or distance == 0 then
        if hudFrame and hudFrame.text then
            hudFrame.text:SetText("|cffff8800Distância indisponível|r")
        end
        if not hudFrame:IsShown() then hudFrame:Show() end
        return
    end

    if hudFrame and hudFrame.text then
        if distance < 5 then
            hudFrame.text:SetText("|cff00ff00Chegou ao destino!|r")
        else
            hudFrame.text:SetText(string_format("|cff00ccff%.0f yd|r", distance))
        end
    end

    if not hudFrame:IsShown() then
        hudFrame:Show()
    end

    -- Update TomTom crazy arrow if available
    if waypoint.uid and waypointAPI.SetCrazyArrow then
        waypointAPI.SetCrazyArrow(waypoint.uid, distance, waypoint.name)
    end
end

local function StartNavigation()
    if navTicker then return end
    CreateHUDFrame()
    WaypointHUD:ApplySettings()
    navTicker = C_Timer.NewTicker(0.1, UpdateNavigation)
    UpdateNavigation()
end

-- Public API: Set waypoint from MapCoords pin
function WaypointHUD:SetWaypointFromPin(pin)
    if not pin or not pin.x or not pin.y or not pin.mapID then return end

    DetectWaypointAddon()

    -- Convert percentage to 0-1
    local x = pin.x / 100
    local y = pin.y / 100

    local uid = nil
    if waypointAPI.SetWaypoint then
        local ok, result = pcall(waypointAPI.SetWaypoint, pin.mapID, x, y, pin.name)
        if ok then
            uid = result
        end
    end

    activeWaypoint = {
        mapID = pin.mapID,
        x = pin.x,
        y = pin.y,
        name = pin.name,
        uid = uid,
    }

    StartNavigation()
    ns.Utils.Print("Waypoint HUD ativado para: " .. pin.name)
end

function WaypointHUD:ClearWaypoint()
    if activeWaypoint and activeWaypoint.uid and waypointAPI.RemoveWaypoint then
        waypointAPI.RemoveWaypoint(activeWaypoint.uid)
    end
    StopNavigation()
end

function WaypointHUD:CheckActiveWaypoint()
    -- Called on login/zone change - could restore from saved waypoint
    if not ns.db or not ns.db.modules or not ns.db.modules.waypointHUD then
        StopNavigation()
        return
    end
end

function WaypointHUD:ApplySettings()
    if not hudFrame then return end
    local cfg = ns.db and ns.db.waypointHUD or {}
    hudFrame:SetScale(cfg.scale or 1.0)
    hudFrame:SetAlpha(cfg.alpha or 0.9)
end

function WaypointHUD:Init()
    CreateHUDFrame()
    WaypointHUD:ApplySettings()

    DetectWaypointAddon()

    ns.RegisterEvent("PLAYER_ENTERING_WORLD", function()
        WaypointHUD:CheckActiveWaypoint()
    end)

    -- Hide HUD when entering combat
    ns.RegisterEvent("PLAYER_REGEN_DISABLED", function()
        StopNavigation()
    end)

    ns.Utils.Debug("WaypointHUD initialized (TomTom/HandyNotes/BuiltIn integration).")
end

-- Global API for MapCoords to call
function _G.Wellbrock_SetWaypointHUD(pin)
    if ns.WaypointHUD then
        ns.WaypointHUD:SetWaypointFromPin(pin)
    end
end

function _G.Wellbrock_ClearWaypointHUD()
    if ns.WaypointHUD then
        ns.WaypointHUD:ClearWaypoint()
    end
end
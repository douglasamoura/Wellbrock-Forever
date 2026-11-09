-- Init.lua (Classic Era)
local addonName, ns = ...

local CreateFrame = CreateFrame

local frame = CreateFrame("Frame", addonName .. "_EventFrame")
ns.EventFrame = frame

-- Event dispatch table
local eventHandlers = {}
ns.eventHandlers = eventHandlers

function ns.RegisterEvent(event, handler)
    if not eventHandlers[event] then
        eventHandlers[event] = {}
        frame:RegisterEvent(event)
    end
    table.insert(eventHandlers[event], handler)
end

frame:SetScript("OnEvent", function(self, event, ...)
    local handlers = eventHandlers[event]
    if handlers then
        for _, handler in ipairs(handlers) do
            local ok, err = pcall(handler, event, ...)
            if not ok then
                if ns.Utils and ns.Utils.Debug then
                    ns.Utils.Debug("Erro no evento " .. tostring(event) .. ": " .. tostring(err))
                end
                if geterrorhandler then
                    geterrorhandler()(err)
                end
            end
        end
    end
end)

local function SafeInit(name, module)
    if not module or not module.Init then return end
    local ok, err = pcall(module.Init, module)
    if not ok then
        if ns.Utils and ns.Utils.Print then
            ns.Utils.Print("|cffff3333Erro ao inicializar módulo " .. name .. ":|r " .. tostring(err))
        end
        if geterrorhandler then
            geterrorhandler()(err)
        end
    end
end

-- Handle SavedVariables initialization
ns.RegisterEvent("ADDON_LOADED", function(event, loadedAddon)
    if loadedAddon ~= addonName then return end

    if not WellbrockDB then
        WellbrockDB = {}
    end
    WellbrockDB = ns.Utils.CopyDefaults(ns.DefaultConfig, WellbrockDB)
    ns.db = WellbrockDB

    -- Lazy-load modules: only initialize if enabled in config
    local mods = ns.db.modules
    if mods.autoLoot then SafeInit("AutoLoot", ns.AutoLoot) end
    if mods.vendorAutomation then SafeInit("VendorAutomation", ns.VendorAutomation) end
    if mods.blizzMove then SafeInit("BlizzMover", ns.BlizzMover) end
    if mods.transmog then SafeInit("Transmog", ns.Transmog) end
    if mods.minimapMod or mods.squareMinimap then SafeInit("MinimapMod", ns.MinimapMod) end
    if mods.mapCoords then SafeInit("MapCoords", ns.MapCoords) end
    if mods.waypointHUD then SafeInit("WaypointHUD", ns.WaypointHUD) end
    if mods.questCinematic then SafeInit("QuestCinematic", ns.QuestCinematic) end
    SafeInit("ConfigUI", ns.ConfigUI) -- Always init config UI

    ns.Utils.Debug("SavedVariables loaded and modules initialized.")
end)

-- Player Login
ns.RegisterEvent("PLAYER_LOGIN", function(event)
    ns.Utils.Print("Inicializado! Digite |cffffff00/wb|r para abrir o painel de configurações.")
end)

-- Save frame positions on logout
ns.RegisterEvent("PLAYER_LOGOUT", function()
    if ns.BlizzMover and ns.db and ns.db.framePositions then
        -- Positions already saved on drag stop, but ensure all are saved
        for name, _ in pairs(ns.db.framePositions) do
            local frame = _G[name]
            if frame and frame.GetPoint then
                ns.BlizzMover:SavePosition(frame, name)
            end
        end
    end
end)
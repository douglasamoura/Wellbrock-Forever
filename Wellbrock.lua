-- Wellbrock.lua (Classic Era)
local addonName, ns = ...

-- Register Slash Commands
SLASH_WELLBROCK1 = "/wellbrock"
SLASH_WELLBROCK2 = "/wb"

local function ToggleModule(modKey, modName)
    if not ns.db or not ns.db.modules then return end
    ns.db.modules[modKey] = not ns.db.modules[modKey]
    local state = ns.db.modules[modKey] and "|cff00ff00Ativado|r" or "|cffff0000Desativado|r"
    ns.Utils.Print(modName .. ": " .. state)
end

SlashCmdList["WELLBROCK"] = function(msg)
    local args = {}
    for word in msg:gmatch("%S+") do
        table.insert(args, word)
    end

    local command = (args[1] or ""):lower()

    if command == "" or command == "config" or command == "menu" or command == "options" then
        if ns.ConfigUI then
            ns.ConfigUI:Toggle()
        end

    elseif command == "debug" then
        if not ns.db then return end
        ns.db.debugMode = not ns.db.debugMode
        ns.Utils.Print("Modo debug: " .. (ns.db.debugMode and "|cff00ff00Ativado|r" or "|cffff0000Desativado|r"))

    elseif command == "status" then
        local mods = (ns.db and ns.db.modules) or {}
        ns.Utils.Print("--- Status dos Módulos ---")
        ns.Utils.Print("  AutoLoot (Speedy): " .. (mods.autoLoot and "|cff00ff00Ativo|r" or "|cffff0000Inativo|r"))
        ns.Utils.Print("  VendorAutomation (Lixo/Reparo): " .. (mods.vendorAutomation and "|cff00ff00Ativo|r" or "|cffff0000Inativo|r"))
        ns.Utils.Print("  BlizzMove: " .. (mods.blizzMove and "|cff00ff00Ativo|r" or "|cffff0000Inativo|r"))
            ns.Utils.Print("  Transmog Status: " .. (mods.transmog and "|cff00ff00Ativo|r" or "|cffff0000Inativo|r"))
            ns.Utils.Print("  Waypoint HUD: " .. (mods.waypointHUD and "|cff00ff00Ativo|r" or "|cffff0000Inativo|r"))
            ns.Utils.Print("  Minimapa Quadrado: " .. (mods.squareMinimap and "|cff00ff00Ativo|r" or "|cffff0000Inativo|r"))
            ns.Utils.Print("  Coordenadas no Mapa: " .. (mods.mapCoords and "|cff00ff00Ativo|r" or "|cffff0000Inativo|r"))
            ns.Utils.Print("  QuestCinematic (Lorewalker): " .. (mods.questCinematic and "|cff00ff00Ativo|r" or "|cffff0000Inativo|r"))

        elseif command == "vendor" then
            ToggleModule("vendorAutomation", "Automação de Mercador (Lixo/Reparo)")

        elseif command == "square" then
            ToggleModule("squareMinimap", "Minimapa Quadrado")
            if ns.MinimapMod then ns.MinimapMod:RefreshAll() end

        elseif command == "loot" then
            ToggleModule("autoLoot", "Speedy AutoLoot")

        elseif command == "move" then
            ToggleModule("blizzMove", "BlizzMove")

        elseif command == "transmog" then
            ToggleModule("transmog", "Transmog Status")

        elseif command == "nav" then
            ToggleModule("waypointHUD", "Waypoint HUD Bússola")
            if ns.WaypointHUD then ns.WaypointHUD:CheckActiveWaypoint() end

        elseif command == "coords" then
            ToggleModule("mapCoords", "Coordenadas no Mapa")

        elseif command == "quest" then
            ToggleModule("questCinematic", "Cinematic Quest Dialog")

        elseif command == "pin" then
            local subCmd = (args[2] or ""):lower()
            if subCmd == "save" then
                local label = table.concat(args, " ", 3)
                ns.MapCoords:SavePin(label)
            elseif subCmd == "list" then
                ns.MapCoords:ListPins()
            elseif subCmd == "goto" then
                local idx = tonumber(args[3])
                if idx then
                    ns.MapCoords:SetWaypoint(idx)
                else
                    ns.Utils.Print("Uso: |cffffff00/wb pin goto [número]|r")
                end
            elseif subCmd == "del" then
                local idx = tonumber(args[3])
                if idx then
                    ns.MapCoords:DeletePin(idx)
                else
                    ns.Utils.Print("Uso: |cffffff00/wb pin del [número]|r")
                end
            else
                ns.Utils.Print("Comandos de Favoritos de Mapa:")
                ns.Utils.Print("  |cffffff00/wb pin save [nome]|r - Salva a coordenada atual")
                ns.Utils.Print("  |cffffff00/wb pin list|r        - Lista todos os pontos salvos")
                ns.Utils.Print("  |cffffff00/wb pin goto [id]|r   - Define waypoint para o ponto")
                ns.Utils.Print("  |cffffff00/wb pin del [id]|r    - Deleta o ponto salvo")
            end

    else
            ns.Utils.Print("Comandos do Wellbrock Forever:")
        ns.Utils.Print("  |cffffff00/wb status|r - Status de todos os módulos")
        ns.Utils.Print("  |cffffff00/wb loot|r   - Alterna Speedy AutoLoot")
        ns.Utils.Print("  |cffffff00/wb move|r   - Alterna movimentação de janelas da Blizzard")
            ns.Utils.Print("  |cffffff00/wb transmog|r - Alterna status de Transmog")
            ns.Utils.Print("  |cffffff00/wb nav|r    - Alterna Waypoint HUD Bússola")
            ns.Utils.Print("  |cffffff00/wb coords|r - Alterna exibição de coordenadas")
            ns.Utils.Print("  |cffffff00/wb quest|r  - Alterna diálogo imersivo de missões")
            ns.Utils.Print("  |cffffff00/wb pin|r    - Gerenciador de favoritos de coordenadas")
            ns.Utils.Print("  |cffffff00/wb debug|r  - Alterna mensagens de debug")
        end
    end
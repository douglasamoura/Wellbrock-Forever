-- Core/ConfigUI.lua (Classic Era)
-- Settings & Configuration Menu using InterfaceOptions (Classic compatible)
local addonName, ns = ...

local CreateFrame = CreateFrame
local UIParent = UIParent
local InterfaceOptions_AddCategory = InterfaceOptions_AddCategory
local PlaySound = PlaySound
local SOUNDKIT = SOUNDKIT
local tinsert = table.insert
local _G = _G

local ConfigUI = {}
ns.ConfigUI = ConfigUI

local mainFrame = nil
local optionsFrame = nil

-- Helper to create styled checkboxes
local function CreateCheckbox(parent, label, getFunc, setFunc, tooltip)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check.text = check.text or check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    check.text:ClearAllPoints()
    check.text:SetPoint("LEFT", check, "RIGHT", 4, 0)
    check.text:SetText(label)

    check:SetScript("OnShow", function(self)
        if getFunc then
            self:SetChecked(getFunc() or false)
        end
    end)

    check:SetScript("OnClick", function(self)
        local isChecked = self:GetChecked()
        if PlaySound and SOUNDKIT then
            local sound = isChecked and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF
            if sound then PlaySound(sound) end
        end
        if setFunc then
            setFunc(isChecked)
        end
    end)

    if tooltip then
        check:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(label, 1, 1, 1)
            GameTooltip:AddLine(tooltip, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        check:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
    end

    return check
end

-- Helper to create styled sliders
local sliderCounter = 0
local function CreateSlider(parent, label, minVal, maxVal, step, getFunc, setFunc, formatStr)
    sliderCounter = sliderCounter + 1
    local sliderName = addonName .. "_ConfigSlider_" .. sliderCounter
    local slider = CreateFrame("Slider", sliderName, parent, "OptionsSliderTemplate")
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetWidth(180)

    local lowText = _G[sliderName .. "Low"]
    if lowText then
        lowText:SetText(string.format(formatStr or "%.1f", minVal))
    end
    local highText = _G[sliderName .. "High"]
    if highText then
        highText:SetText(string.format(formatStr or "%.1f", maxVal))
    end
    local titleText = _G[sliderName .. "Text"]
    if titleText then
        titleText:SetText(label)
    end

    local valueLabel = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    valueLabel:SetPoint("TOP", slider, "BOTTOM", 0, -2)
    slider.valueLabel = valueLabel

    slider:SetScript("OnShow", function(self)
        local val = getFunc and getFunc() or minVal
        self:SetValue(val)
        self.valueLabel:SetText(string.format(formatStr or "%.1f", val))
    end)

    slider:SetScript("OnValueChanged", function(self, val)
        self.valueLabel:SetText(string.format(formatStr or "%.1f", val))
        if setFunc then
            setFunc(val)
        end
    end)

    return slider
end

-- Builds all settings widgets inside a scrollable content frame
local function PopulateSettings(parent)
    local y = -10

    -- Section: Módulos Principais
    local titleGeral = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleGeral:SetPoint("TOPLEFT", parent, "TOPLEFT", 15, y)
    titleGeral:SetText("|cff00ccff1. Módulos Principais (Ativação)|r")
    y = y - 30

    local cbAutoLoot = CreateCheckbox(parent, "Speedy AutoLoot (Saque Rápido)",
        function() return ns.db.modules.autoLoot end,
        function(v) ns.db.modules.autoLoot = v end,
        "Coleta itens instantaneamente ao saquear sem delay visual da janela da Blizzard."
    )
    cbAutoLoot:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
    y = y - 28

    local cbVendor = CreateCheckbox(parent, "Automação de Mercador (Venda de Lixo & Reparo)",
        function() return ns.db.modules.vendorAutomation end,
        function(v) ns.db.modules.vendorAutomation = v end,
        "Vende lixos cinzas e conserta equipamentos automaticamente ao interagir com comerciantes."
    )
    cbVendor:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
    y = y - 28

    local cbBlizzMove = CreateCheckbox(parent, "BlizzMove (Janelas Móveis)",
        function() return ns.db.modules.blizzMove end,
        function(v) ns.db.modules.blizzMove = v end,
        "Permite arrastar janelas padrão da Blizzard (Personagem, Feitiços, Missões, etc.)."
    )
    cbBlizzMove:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
    y = y - 28

    local cbMapCoords = CreateCheckbox(parent, "Coordenadas no Mapa & Favoritos",
        function() return ns.db.modules.mapCoords end,
        function(v) ns.db.modules.mapCoords = v end,
        "Exibe coordenadas atuais e permite salvar pontos favoritos (/wb pin save)."
    )
    cbMapCoords:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
    y = y - 28

    local cbQuest = CreateCheckbox(parent, "Lorewalker (Diálogo Imersivo de Missões)",
        function() return ns.db.modules.questCinematic end,
        function(v) ns.db.modules.questCinematic = v end,
        "Apresenta textos de missões em um painel estilizado e legível com foco na história."
    )
    cbQuest:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
    y = y - 28

    local cbSquareMinimap = CreateCheckbox(parent, "Minimapa Quadrado (Square Minimap)",
        function() return ns.db.modules.squareMinimap end,
        function(v)
            ns.db.modules.squareMinimap = v
            if ns.MinimapMod then ns.MinimapMod:RefreshAll() end
        end,
        "Altera a máscara do minimapa para formato quadrado moderno (estilo Leatrix Plus)."
    )
    cbSquareMinimap:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
        y = y - 28

        local cbTransmog = CreateCheckbox(parent, "Transmog Status (CanIMogIt/TomTom/ATT Integration)",
            function() return ns.db.modules.transmog end,
            function(v) ns.db.modules.transmog = v end,
            "Exibe no tooltip e nas bolsas se a aparência já foi aprendida. Integra com CanIMogIt, TransmogMaster, MogIt, AllTheThings."
        )
        cbTransmog:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
        y = y - 28

        local cbWaypointHUD = CreateCheckbox(parent, "Waypoint HUD Bússola (TomTom/BuiltIn)",
            function() return ns.db.modules.waypointHUD end,
            function(v)
                ns.db.modules.waypointHUD = v
                if ns.WaypointHUD then ns.WaypointHUD:CheckActiveWaypoint() end
            end,
            "Mostra uma bússola com seta indicando o rumo e distância do waypoint. Integra com TomTom, HandyNotes, waypoint nativo."
        )
        cbWaypointHUD:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
        y = y - 40

        -- Section: Opções Avançadas e Específicas
    local titleAdv = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleAdv:SetPoint("TOPLEFT", parent, "TOPLEFT", 15, y)
    titleAdv:SetText("|cff00ccff2. Ajustes Específicos|r")
    y = y - 30

    -- Vendor settings
    local cbAutoSell = CreateCheckbox(parent, "Vendedor: Vender itens cinzas (lixo) automaticamente",
        function() return ns.db.vendor.autoSell end,
        function(v) ns.db.vendor.autoSell = v end,
        "Ao abrir um comerciante, vende instantaneamente todos os itens cinzas de lixo."
    )
    cbAutoSell:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
    y = y - 28

    local cbAutoRepair = CreateCheckbox(parent, "Vendedor: Consertar todos os itens automaticamente",
        function() return ns.db.vendor.autoRepair end,
        function(v) ns.db.vendor.autoRepair = v end,
        "Ao abrir um comerciante com serviço de reparo, conserta seus equipamentos automaticamente."
    )
    cbAutoRepair:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
    y = y - 28

    local cbGuildRepair = CreateCheckbox(parent, "Vendedor: Usar fundos do Banco da Guilda para conserto (se permitido)",
        function() return ns.db.vendor.guildRepair end,
        function(v) ns.db.vendor.guildRepair = v end,
        "Tenta debitar o valor do conserto no banco da guilda antes de usar seus fundos pessoais."
    )
    cbGuildRepair:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
    y = y - 28

    local cbVendorSummary = CreateCheckbox(parent, "Vendedor: Exibir resumo de ouro no chat",
        function() return ns.db.vendor.showSummary end,
        function(v) ns.db.vendor.showSummary = v end,
        "Exibe mensagens no chat informando o total ganho com lixo ou gasto com reparos."
    )
    cbVendorSummary:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
    y = y - 28

    -- Minimap button
    local cbMiniBtn = CreateCheckbox(parent, "Minimapa: Exibir botão do Wellbrock junto ao minimapa",
        function() return not (ns.db and ns.db.minimap and ns.db.minimap.hide) end,
        function(v)
            if not ns.db.minimap then ns.db.minimap = {} end
            ns.db.minimap.hide = not v
            if ns.MinimapMod then ns.MinimapMod:ApplyButtonVisibility() end
        end,
        "Mostra ou oculta o ícone do dragão do Wellbrock junto ao minimapa."
    )
    cbMiniBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
    y = y - 28

    -- Minimap Square Border
    local cbMiniBorder = CreateCheckbox(parent, "Minimapa: Exibir borda fina no minimapa quadrado",
        function() return not ns.db.minimap or (ns.db.minimap.showBorder ~= false) end,
        function(v)
            if not ns.db.minimap then ns.db.minimap = {} end
            ns.db.minimap.showBorder = v
            if ns.MinimapMod then ns.MinimapMod:UpdateBorder() end
        end,
        "Exibe uma pequena borda escura refinada ao redor do minimapa quando o formato quadrado estiver ativo."
    )
    cbMiniBorder:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
    y = y - 28

    -- Minimap Align Addon Icons to Bottom
    local cbMiniBottom = CreateCheckbox(parent, "Minimapa: Alinhar ícones de AddOns na borda inferior",
        function() return not ns.db.minimap or (ns.db.minimap.alignBottom ~= false) end,
        function(v)
            if not ns.db.minimap then ns.db.minimap = {} end
            ns.db.minimap.alignBottom = v
            if ns.MinimapMod then ns.MinimapMod:AlignAddonButtons() end
        end,
        "Organiza todos os botões de AddOns (LibDBIcon e Wellbrock) em uma linha horizontal alinhada rente à borda inferior do minimapa."
    )
    cbMiniBottom:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
    y = y - 28

    -- AutoLoot BoP
    local cbBoP = CreateCheckbox(parent, "AutoLoot: Confirmar itens BoP automaticamente (Solo)",
        function() return ns.db.autoLoot.autoConfirmBoP end,
        function(v) ns.db.autoLoot.autoConfirmBoP = v end,
        "Ignora a caixa de confirmação de itens 'Vinculados ao Coletar' quando não estiver em grupo."
    )
    cbBoP:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
    y = y - 28

    -- BlizzMove Clamp
    local cbClamp = CreateCheckbox(parent, "BlizzMove: Manter janelas presas à tela",
        function() return ns.db.blizzMove.clampToScreen end,
        function(v) ns.db.blizzMove.clampToScreen = v end,
        "Impede que janelas sejam arrastadas para fora da área visível do monitor."
    )
    cbClamp:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
    y = y - 36

        -- Transmog Settings
        local cbTransmogBagIcons = CreateCheckbox(parent, "Transmog: Exibir ícones V (verde) e X (vermelho) nas bolsas",
            function() return ns.db.transmog.showBagIcons end,
            function(v) ns.db.transmog.showBagIcons = v end,
            "Exibe um pequeno V verde no canto do item se já tiver aprendido, ou X vermelho se não."
        )
        cbTransmogBagIcons:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
        y = y - 28

        local cbTransmogKnown = CreateCheckbox(parent, "Transmog: Exibir texto para aparências já aprendidas",
            function() return ns.db.transmog.showKnown end,
            function(v) ns.db.transmog.showKnown = v end,
            "Se desmarcado, só exibirá texto no tooltip em itens que você ainda NÃO aprendeu."
        )
        cbTransmogKnown:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
        y = y - 28

        local cbTransmogUnknown = CreateCheckbox(parent, "Transmog: Exibir texto para aparências não aprendidas",
            function() return ns.db.transmog.showUnknown end,
            function(v) ns.db.transmog.showUnknown = v end,
            "Exibe texto no tooltip para itens com aparência não aprendida."
        )
        cbTransmogUnknown:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
        y = y - 36

        -- WaypointHUD Settings
        local sliderScale = CreateSlider(parent, "Escala da Bússola HUD", 0.7, 1.6, 0.1,
            function() return ns.db.waypointHUD.scale or 1.0 end,
            function(v)
                ns.db.waypointHUD.scale = v
                if ns.WaypointHUD and ns.WaypointHUD.ApplySettings then
                    ns.WaypointHUD:ApplySettings()
                end
            end,
            "%.1fx"
        )
        sliderScale:SetPoint("TOPLEFT", parent, "TOPLEFT", 25, y - 10)

        local sliderAlpha = CreateSlider(parent, "Opacidade da Bússola HUD", 0.3, 1.0, 0.05,
            function() return ns.db.waypointHUD.alpha or 0.9 end,
            function(v)
                ns.db.waypointHUD.alpha = v
                if ns.WaypointHUD and ns.WaypointHUD.ApplySettings then
                    ns.WaypointHUD:ApplySettings()
                end
            end,
            "%.2f"
        )
        sliderAlpha:SetPoint("TOPLEFT", sliderScale, "TOPRIGHT", 40, 0)
        y = y - 65

        -- Botões de Ação
    local btnResetFrames = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btnResetFrames:SetSize(210, 26)
    btnResetFrames:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
    btnResetFrames:SetText("Resetar Posições das Janelas")
    btnResetFrames:SetScript("OnClick", function()
        if ns.db.framePositions then
            ns.db.framePositions = {}
            ns.Utils.Print("Todas as posições salvas de janelas foram resetadas.")
        end
    end)

    local btnReload = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btnReload:SetSize(180, 26)
    btnReload:SetPoint("LEFT", btnResetFrames, "RIGHT", 15, 0)
    btnReload:SetText("Recarregar Interface (/reload)")
    btnReload:SetScript("OnClick", function()
        if ReloadUI then ReloadUI() end
    end)
    y = y - 45

    -- Footer info
    local footer = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    footer:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
        footer:SetText("Wellbrock Forever v" .. ns.VERSION .. " - Digite /wb para comandos rápidos via chat.")
end

-- Builds the standalone floating window
local function CreateStandaloneConfigFrame()
    if mainFrame then return mainFrame end

    mainFrame = CreateFrame("Frame", "WellbrockConfigFrame", UIParent, "BackdropTemplate")
    mainFrame:SetSize(540, 620)
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    mainFrame:SetFrameStrata("DIALOG")
    mainFrame:EnableMouse(true)
    mainFrame:SetMovable(true)
    mainFrame:SetClampedToScreen(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)

    -- Backdrop
    mainFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    mainFrame:SetBackdropColor(0.08, 0.08, 0.12, 0.96)
    mainFrame:SetBackdropBorderColor(0, 0.8, 1, 0.8)

    -- Header Icon
    local headerIcon = mainFrame:CreateTexture(nil, "ARTWORK")
    headerIcon:SetSize(28, 28)
    headerIcon:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 16, -12)
    headerIcon:SetTexture(ns.ICON_PATH)

    -- Header Title
    local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", headerIcon, "RIGHT", 10, 0)
        title:SetText("|cff00ccffWellbrock Forever|r - Painel de Configurações")

    -- Close Button
    local closeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -6, -6)
    closeBtn:SetScript("OnClick", function()
        mainFrame:Hide()
    end)

    -- ScrollFrame container
    local scrollFrame = CreateFrame("ScrollFrame", nil, mainFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -50)
    scrollFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -32, 20)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(480, 780)
    scrollFrame:SetScrollChild(content)

    PopulateSettings(content)

    mainFrame:Hide()
    tinsert(UISpecialFrames, "WellbrockConfigFrame")
    return mainFrame
end

-- Registers inside the standard Blizzard Interface Options panel (Classic)
local function RegisterInterfaceOptions()
    optionsFrame = CreateFrame("Frame", "WellbrockOptionsFrame", UIParent)
    optionsFrame.name = "Wellbrock Forever"
    optionsFrame:Hide()

    local scrollFrame = CreateFrame("ScrollFrame", nil, optionsFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 10, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOMRIGHT", -32, 10)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(600, 800)
    scrollFrame:SetScrollChild(content)

    PopulateSettings(content)

    InterfaceOptions_AddCategory(optionsFrame)
end

function ConfigUI:Toggle()
    local frame = CreateStandaloneConfigFrame()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end

function ConfigUI:OpenInterfaceOptions()
    if InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(optionsFrame)
    else
        ConfigUI:Toggle()
    end
end

function ConfigUI:Init()
    RegisterInterfaceOptions()
    ns.Utils.Debug("ConfigUI initialized (InterfaceOptions).")
end

-- Global function called by minimap button or macros
function _G.Wellbrock_OpenSettingsUI()
    ConfigUI:Toggle()
end
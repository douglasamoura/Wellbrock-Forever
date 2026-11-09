-- Modules/QuestCinematic.lua (Classic Era)
-- Reverse-engineered & optimized from Lorewalker
-- UX & Accessibility: Spacebar/Esc hotkey to close, Auto-hide on combat start
local addonName, ns = ...

local CreateFrame = CreateFrame
local UIParent = UIParent
local GetTitleText = GetTitleText
local GetQuestText = GetQuestText
local GetProgressText = GetProgressText
local GetRewardText = GetRewardText
local InCombatLockdown = InCombatLockdown
local tinsert = table.insert

local QuestCinematic = {}
ns.QuestCinematic = QuestCinematic

local dialogFrame = nil

local function CreateCinematicDialog()
    if dialogFrame then return dialogFrame end

    dialogFrame = CreateFrame("Frame", "WellbrockQuestCinematicFrame", UIParent, "BackdropTemplate")
    dialogFrame:SetSize(620, 360)
    dialogFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -60)
    dialogFrame:SetFrameStrata("DIALOG")
    dialogFrame:EnableMouse(true)
    dialogFrame:SetMovable(true)
    dialogFrame:RegisterForDrag("LeftButton")
    dialogFrame:SetScript("OnDragStart", dialogFrame.StartMoving)
    dialogFrame:SetScript("OnDragStop", dialogFrame.StopMovingOrSizing)

    -- Backdrop styling
    dialogFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    dialogFrame:SetBackdropColor(0.05, 0.05, 0.07, 0.92)
    dialogFrame:SetBackdropBorderColor(0.2, 0.6, 0.9, 0.8)

    -- NPC / Quest Title
    local title = dialogFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", dialogFrame, "TOPLEFT", 24, -20)
    title:SetPoint("TOPRIGHT", dialogFrame, "TOPRIGHT", -24, -20)
    title:SetJustifyH("LEFT")
    title:SetTextColor(1, 0.85, 0.3)
    dialogFrame.title = title

    -- Separator Line
    local line = dialogFrame:CreateTexture(nil, "ARTWORK")
    line:SetHeight(2)
    line:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    line:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, -8)
    line:SetColorTexture(0.2, 0.6, 0.9, 0.5)

    -- Quest Description / Narrative Text
    local scrollFrame = CreateFrame("ScrollFrame", nil, dialogFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", line, "BOTTOMLEFT", 0, -12)
    scrollFrame:SetPoint("BOTTOMRIGHT", dialogFrame, "BOTTOMRIGHT", -36, 60)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(560, 200)
    scrollFrame:SetScrollChild(content)

    local body = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    body:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    body:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)
    body:SetJustifyH("LEFT")
    body:SetSpacing(4)
    dialogFrame.body = body

    -- Close / Continue Button
    local closeBtn = CreateFrame("Button", nil, dialogFrame, "UIPanelButtonTemplate")
    closeBtn:SetSize(130, 32)
    closeBtn:SetPoint("BOTTOMRIGHT", dialogFrame, "BOTTOMRIGHT", -24, 16)
    closeBtn:SetText("Continuar [Espaço]")
    closeBtn:SetScript("OnClick", function()
        dialogFrame:Hide()
    end)
    dialogFrame.closeBtn = closeBtn

    -- Enable keyboard close on Space or Escape (propagate keys properly)
    dialogFrame:EnableKeyboard(true)
    dialogFrame:SetScript("OnKeyDown", function(self, key)
        if key == "SPACE" or key == "ESCAPE" then
            self:Hide()
        end
        -- Always propagate to not block keybinds
        if self.SetPropagateKeyboardInput then
            self:SetPropagateKeyboardInput(true)
        end
    end)

    dialogFrame:Hide()
    tinsert(UISpecialFrames, "WellbrockQuestCinematicFrame")
    return dialogFrame
end

function QuestCinematic:ShowNarrative(titleText, questText)
    if not ns.db or not ns.db.modules.questCinematic then return end
    if InCombatLockdown() then return end

    local frame = CreateCinematicDialog()
    frame.title:SetText(titleText or "Missão")
    frame.body:SetText(questText or "")
    frame:Show()
end

function QuestCinematic:Init()
    ns.RegisterEvent("QUEST_DETAIL", function()
        local title = GetTitleText()
        local text = GetQuestText()
        QuestCinematic:ShowNarrative(title, text)
    end)

    ns.RegisterEvent("QUEST_PROGRESS", function()
        local title = GetTitleText()
        local text = GetProgressText()
        QuestCinematic:ShowNarrative(title, text)
    end)

    ns.RegisterEvent("QUEST_COMPLETE", function()
        local title = GetTitleText()
        local text = GetRewardText()
        QuestCinematic:ShowNarrative(title, text)
    end)

    ns.RegisterEvent("QUEST_FINISHED", function()
        if dialogFrame and dialogFrame:IsShown() then
            dialogFrame:Hide()
        end
    end)

    -- Auto-dismiss when combat begins to avoid blocking action
    ns.RegisterEvent("PLAYER_REGEN_DISABLED", function()
        if dialogFrame and dialogFrame:IsShown() then
            dialogFrame:Hide()
        end
    end)

    ns.Utils.Debug("QuestCinematic module initialized with hotkey advance and combat safety.")
end
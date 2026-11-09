-- Modules/BlizzMove.lua (Classic Era)
-- Reverse-engineered & optimized from BlizzMove
-- Anti-Taint & UX Optimization: InCombatLockdown Protection, Shift+Right-Click Individual Frame Reset
local addonName, ns = ...

local InCombatLockdown = InCombatLockdown
local IsShiftKeyDown = IsShiftKeyDown
local pairs = pairs
local ipairs = ipairs
local _G = _G

local BlizzMover = {}
ns.BlizzMover = BlizzMover

local registeredFrames = {}

-- Classic-safe frames only (no protected frames like TalentUI, LFG, Collections)
local DEFAULT_FRAMES = {
    "CharacterFrame",
    "SpellBookFrame",
    "QuestFrame",
    "GossipFrame",
    "MerchantFrame",
    "MailFrame",
    "FriendsFrame",
    "MacroFrame",
    "BankFrame",
    "ItemUpgradeFrame",    -- May not exist in all Classic versions
    "ClassTrainerFrame",
    "DressUpFrame",
    "InspectFrame",
    "TradeFrame",
    "LootFrame",
    "QuestLogFrame",
    "WorldMapFrame",
    "VideoOptionsFrame",
    "AudioOptionsFrame",
    "InterfaceOptionsFrame",
    "GameMenuFrame",
    "HelpFrame",
    "GuildFrame",
    "RaidFrame",
    "BattlefieldFrame",
    "PetStableFrame",
    "TabardFrame",
    "TaxiFrame",
}

function BlizzMover:SavePosition(frame, name)
    if InCombatLockdown and InCombatLockdown() then return end
    if not ns.db or not ns.db.modules or not ns.db.modules.blizzMove then return end
    if not ns.db.blizzMove or not ns.db.blizzMove.savePositions then return end
    if not ns.db.framePositions then ns.db.framePositions = {} end

    if not frame or not frame.GetPoint then return end
    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
    if point and xOfs and yOfs then
        ns.db.framePositions[name] = {
            point = point,
            relativePoint = relativePoint or point,
            x = xOfs,
            y = yOfs,
        }
    end
end

function BlizzMover:RestorePosition(frame, name)
    if InCombatLockdown and InCombatLockdown() then return end
    if not ns.db or not ns.db.modules or not ns.db.modules.blizzMove then return end
    if not ns.db.blizzMove or not ns.db.blizzMove.savePositions then return end
    if not ns.db.framePositions then return end

    local pos = ns.db.framePositions[name]
    if pos and pos.point and pos.x and pos.y and frame and frame.ClearAllPoints and frame.SetPoint then
        frame:ClearAllPoints()
        frame:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.x, pos.y)
    end
end

function BlizzMover:ResetFramePosition(frame, name)
    if InCombatLockdown and InCombatLockdown() then return end
    if ns.db and ns.db.framePositions then
        ns.db.framePositions[name] = nil
    end
    if frame and frame.ClearAllPoints and frame.SetPoint then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    ns.Utils.Print("Posição resetada para: |cffffff00" .. name .. "|r")
end

function BlizzMover:MakeMovable(frameName)
    local frame = _G[frameName]
    if not frame or registeredFrames[frameName] then return end
    if not frame.SetMovable or not frame.HookScript then return end

    -- Skip protected frames to avoid taint
    if frame.IsProtected and frame:IsProtected() then
        ns.Utils.Debug("BlizzMove: Pulando frame protegido: " .. frameName)
        return
    end

    registeredFrames[frameName] = true
    frame:SetMovable(true)
    if frame.SetClampedToScreen and ns.db and ns.db.blizzMove and ns.db.blizzMove.clampToScreen then
        frame:SetClampedToScreen(true)
    end
    if frame.EnableMouse then frame:EnableMouse(true) end
    if frame.RegisterForDrag then frame:RegisterForDrag("LeftButton") end

    pcall(frame.HookScript, frame, "OnDragStart", function(self)
        if InCombatLockdown and InCombatLockdown() then return end
        if not ns.db or not ns.db.modules or not ns.db.modules.blizzMove then return end
        self:StartMoving()
    end)

    pcall(frame.HookScript, frame, "OnDragStop", function(self)
        self:StopMovingOrSizing()
        BlizzMover:SavePosition(self, frameName)
        -- Mark as user-placed for native persistence
        if self.SetUserPlaced then self:SetUserPlaced(true) end
    end)

    pcall(frame.HookScript, frame, "OnShow", function(self)
        BlizzMover:RestorePosition(self, frameName)
    end)

    -- Shift + Right Click to reset this individual frame position
    pcall(frame.HookScript, frame, "OnMouseDown", function(self, button)
        if button == "RightButton" and IsShiftKeyDown and IsShiftKeyDown() then
            BlizzMover:ResetFramePosition(self, frameName)
        end
    end)
end

function BlizzMover:ScanAndHook()
    if InCombatLockdown() then return end
    for _, name in ipairs(DEFAULT_FRAMES) do
        BlizzMover:MakeMovable(name)
    end
end

function BlizzMover:Init()
    ns.RegisterEvent("PLAYER_LOGIN", function()
        BlizzMover:ScanAndHook()
    end)

    -- Check when LoD (Load on demand) addons are loaded
    ns.RegisterEvent("ADDON_LOADED", function(event, addon)
        BlizzMover:ScanAndHook()
    end)

    ns.Utils.Debug("BlizzMover initialized with anti-taint safeguards and Shift+Right-Click reset.")
end
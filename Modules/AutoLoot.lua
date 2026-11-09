-- Modules/AutoLoot.lua (Classic Era)
-- Reverse-engineered & optimized from SpeedyAutoLoot
-- Performance & UX Optimization: Safe Bag Checking, Key Modifier Override, Anti-Spam Debounce
local addonName, ns = ...

local GetNumLootItems = GetNumLootItems
local GetLootSlotType = GetLootSlotType
local LootSlot = LootSlot
local ConfirmLootSlot = ConfirmLootSlot
local GetCVarBool = GetCVarBool
local IsModifiedClick = IsModifiedClick
local IsShiftKeyDown = IsShiftKeyDown
local IsInGroup = IsInGroup
local C_Timer = C_Timer
local EnumLootSlotTypeNone = Enum.LootSlotType and Enum.LootSlotType.None or 0

local AutoLoot = {}
ns.AutoLoot = AutoLoot

local isLooting = false
local lootFrame = nil

-- Check if player has any free slots across equipped bags (Classic: bags 0-4)
local function HasFreeBagSpace()
    local totalFree = 0
    for bag = 0, 4 do  -- 0=Backpack, 1-4=Bags (no Reagent Bag in Classic)
        local free = GetContainerNumFreeSlots(bag)
        if free and free > 0 then
            totalFree = totalFree + free
        end
    end
    return totalFree > 0
end

local function LootAllSlots(numItems)
    if numItems <= 0 then return end
    
    local currentSlot = numItems
    local canConfirmBoP = ns.db and ns.db.autoLoot and ns.db.autoLoot.autoConfirmBoP

    -- Use a simple OnUpdate frame with throttling instead of high-frequency ticker
    if not lootFrame then
        lootFrame = CreateFrame("Frame")
        lootFrame:Hide()
    end
    
    local lastUpdate = 0
    local UPDATE_INTERVAL = 0.1  -- 10Hz - smooth but doesn't freeze client
    
    lootFrame:SetScript("OnUpdate", function(self, elapsed)
        lastUpdate = lastUpdate + elapsed
        if lastUpdate < UPDATE_INTERVAL then return end
        lastUpdate = 0
        
        if currentSlot >= 1 then
            if GetLootSlotType and LootSlot then
                local slotType = GetLootSlotType(currentSlot)
                if slotType ~= EnumLootSlotTypeNone then
                    LootSlot(currentSlot)
                    -- Auto confirm BOP when solo and enabled
                    if canConfirmBoP and IsInGroup and not IsInGroup() and ConfirmLootSlot then
                        ConfirmLootSlot(currentSlot)
                    end
                end
            end
            currentSlot = currentSlot - 1
        else
            self:SetScript("OnUpdate", nil)
            self:Hide()
            isLooting = false
        end
    end)
    lootFrame:Show()
end

function AutoLoot:OnLootReady(autoLoot)
    if not ns.db or not ns.db.modules or not ns.db.modules.autoLoot then return end

    -- Shift modifier: holding Shift allows manually inspecting the loot window
    if IsShiftKeyDown() or IsModifiedClick("AUTOLOOTTOGGLE") then
        return
    end

    local shouldAutoLoot = autoLoot or GetCVarBool("autoLootDefault")
    if not shouldAutoLoot then return end

    local numItems = GetNumLootItems()
    if numItems == 0 then return end

    -- If bags are completely full, avoid spamming failed requests
    if not HasFreeBagSpace() then
        return
    end

    if isLooting then
        return -- Debounce: already processing loot
    end

    isLooting = true
    LootAllSlots(numItems)
end

function AutoLoot:Init()
    ns.RegisterEvent("LOOT_READY", function(event, autoLoot)
        AutoLoot:OnLootReady(autoLoot)
    end)

    ns.RegisterEvent("LOOT_CLOSED", function(event)
        if lootFrame then
            lootFrame:SetScript("OnUpdate", nil)
            lootFrame:Hide()
        end
        isLooting = false
    end)
    
    ns.Utils.Debug("AutoLoot initialized with bag space check and Shift override.")
end
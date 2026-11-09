-- Modules/VendorAutomation.lua (Classic Era)
-- Reverse-engineered & optimized from Leatrix Plus (AutoSellJunk & AutoRepairGear)
local addonName, ns = ...

local MerchantFrame = MerchantFrame
local CanMerchantRepair = CanMerchantRepair
local GetRepairAllCost = GetRepairAllCost
local RepairAllItems = RepairAllItems
local CanGuildBankRepair = CanGuildBankRepair
local IsInGuild = IsInGuild
local IsShiftKeyDown = IsShiftKeyDown
local GetContainerNumSlots = GetContainerNumSlots
local GetContainerItemLink = GetContainerItemLink
local GetContainerItemInfo = GetContainerItemInfo
local UseContainerItem = UseContainerItem
local GetItemInfo = GetItemInfo

local VendorAutomation = {}
ns.VendorAutomation = VendorAutomation

-- Automatically sell grey/junk items
function VendorAutomation:SellJunk()
    if not ns.db or not ns.db.modules or not ns.db.modules.vendorAutomation or not ns.db.vendor or not ns.db.vendor.autoSell then
        return
    end
    if IsShiftKeyDown() then return end -- Shift cancels auto-selling
    if not MerchantFrame or not MerchantFrame:IsShown() then return end

    local totalEarned = 0
    local soldCount = 0

    for bag = 0, 4 do  -- Classic: bags 0-4 (no Reagent Bag)
        local numSlots = GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local _, _, quality, _, _, _, _, _, _, _, sellPrice = GetItemInfo(link)
                -- Check if item is grey (Poor quality == 0) and has value
                if quality == 0 and sellPrice and sellPrice > 0 then
                    local _, itemCount = GetContainerItemInfo(bag, slot)
                    UseContainerItem(bag, slot)
                    totalEarned = totalEarned + (sellPrice * (itemCount or 1))
                    soldCount = soldCount + 1
                end
            end
        end
    end

    if soldCount > 0 and ns.db.vendor.showSummary and totalEarned > 0 then
        local coinStr = ns.Utils.FormatMoney(totalEarned)
        ns.Utils.Print(string.format("Lixo vendido: %d itens por %s.", soldCount, coinStr))
    end
end

-- Automatically repair equipped and inventory gear
function VendorAutomation:RepairGear()
    if not ns.db or not ns.db.modules or not ns.db.modules.vendorAutomation or not ns.db.vendor or not ns.db.vendor.autoRepair then
        return
    end
    if IsShiftKeyDown() then return end -- Shift cancels auto-repair
    if not MerchantFrame or not MerchantFrame:IsShown() then return end

    if not CanMerchantRepair or not CanMerchantRepair() then return end
    if not GetRepairAllCost or not RepairAllItems then return end

    local cost, canRepair = GetRepairAllCost()
    if not canRepair or not cost or cost <= 0 then return end

    local usedGuild = false

    -- Attempt guild bank repair if enabled and permitted
    if ns.db.vendor.guildRepair and IsInGuild and IsInGuild() and CanGuildBankRepair and CanGuildBankRepair() then
        RepairAllItems(1) -- 1 = use guild bank
        usedGuild = true
        -- Check if anything is still damaged (guild daily limit reached)
        local remainingCost = GetRepairAllCost()
        if remainingCost and remainingCost > 0 then
            RepairAllItems() -- Use personal funds
            usedGuild = false
        end
    else
        RepairAllItems() -- Use personal funds
    end

    if ns.db.vendor.showSummary then
        local coinStr = ns.Utils.FormatMoney(cost)
        local source = usedGuild and " (Fundos da Guilda)" or " (Fundos Pessoais)"
        ns.Utils.Print("Equipamentos consertados por " .. coinStr .. source .. ".")
    end
end

function VendorAutomation:Init()
    ns.RegisterEvent("MERCHANT_SHOW", function()
        VendorAutomation:SellJunk()
        VendorAutomation:RepairGear()
    end)

    ns.Utils.Debug("VendorAutomation module initialized (Auto-Sell Junk & Auto-Repair).")
end
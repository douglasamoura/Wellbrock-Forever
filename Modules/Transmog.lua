-- Modules/Transmog.lua (Forever / Classic Era / SoD)
-- Transmog Integration: Detects CanIMogIt / TransmogMaster / MogIt / ATT
-- Falls back to basic tooltip scanning if no addon found
local addonName, ns = ...

local C_Item = C_Item
local GetItemInfo = GetItemInfo
local GetItemInfoInstant = GetItemInfoInstant
local GameTooltip = GameTooltip
local hooksecurefunc = hooksecurefunc
local wipe = wipe
local select = select

local Transmog = {}
ns.Transmog = Transmog

-- Detected transmog addon
local detectedAddon = nil
local addonAPI = {}

-- Cache: [itemLink] = { known = true/false, source = "addon"/"fallback" }
local transmogCache = {}

function Transmog:ClearCache()
    wipe(transmogCache)
    ns.Utils.Debug("Transmog cache wiped.")
end

-- Detect available transmog addons
local function DetectTransmogAddon()
    if detectedAddon then return detectedAddon end

    -- CanIMogIt
    if CanIMogIt and CanIMogIt.PlayerKnowsTransmog then
        detectedAddon = "CanIMogIt"
        addonAPI = {
            PlayerKnowsTransmog = function(itemLink) return CanIMogIt.PlayerKnowsTransmog(itemLink) end,
            GetReason = function(itemLink) return CanIMogIt.GetReason and CanIMogIt.GetReason(itemLink) end,
        }
        ns.Utils.Debug("Transmog: Detectado CanIMogIt")
        return detectedAddon
    end

    -- TransmogMaster
    if TransmogMaster and TransmogMaster.IsKnown then
        detectedAddon = "TransmogMaster"
        addonAPI = {
            PlayerKnowsTransmog = function(itemLink) return TransmogMaster.IsKnown(itemLink) end,
        }
        ns.Utils.Debug("Transmog: Detectado TransmogMaster")
        return detectedAddon
    end

    -- MogIt
    if MogIt and MogIt.IsKnown then
        detectedAddon = "MogIt"
        addonAPI = {
            PlayerKnowsTransmog = function(itemLink) return MogIt.IsKnown(itemLink) end,
        }
        ns.Utils.Debug("Transmog: Detectado MogIt")
        return detectedAddon
    end

    -- All The Things (ATT)
    if ATT and ATT.IsKnown then
        detectedAddon = "AllTheThings"
        addonAPI = {
            PlayerKnowsTransmog = function(itemLink) return ATT.IsKnown(itemLink) end,
        }
        ns.Utils.Debug("Transmog: Detectado All The Things")
        return detectedAddon
    end

    -- Fallback: tooltip scanning
    detectedAddon = "Fallback"
    ns.Utils.Debug("Transmog: Nenhum addon detectado, usando fallback (tooltip scan)")
    return detectedAddon
end

-- Fallback: Check tooltip for "Already Known" or similar text
local function FallbackCheckTooltip(itemLink)
    if not itemLink then return nil end

    local tooltipData = {
        lines = {},
        known = false,
    }

    -- Create temporary tooltip
    local tip = CreateFrame("GameTooltip", "WellbrockTransmogScanTip", nil, "GameTooltipTemplate")
    tip:SetOwner(UIParent, "ANCHOR_NONE")
    tip:SetHyperlink(itemLink)

    for i = 1, tip:NumLines() do
        local left = _G["WellbrockTransmogScanTipTextLeft" .. i]
        local right = _G["WellbrockTransmogScanTipTextRight" .. i]
        local text = (left and left:GetText() or "") .. " " .. (right and right:GetText() or "")
        text = text:lower()

        -- Classic/SoD known indicators
        if text:find("já conhecido") or text:find("already known") or text:find("conhecido") then
            tooltipData.known = true
            break
        end
        -- Unknown indicators
        if text:find("não conhecido") or text:find("not known") or text:find("desconhecido") then
            tooltipData.known = false
            break
        end
    end

    tip:Hide()
    return tooltipData.known
end

-- Main API: Returns true/false/nil (known/unknown/undetermined)
function Transmog:PlayerKnowsTransmog(itemLink)
    if not itemLink then return nil end

    local cached = transmogCache[itemLink]
    if cached ~= nil then
        return cached.known
    end

    DetectTransmogAddon()

    local known = nil

    if addonAPI.PlayerKnowsTransmog then
        local ok, result = pcall(addonAPI.PlayerKnowsTransmog, itemLink)
        if ok and result ~= nil then
            known = result
        end
    end

    -- Fallback to tooltip scan if addon didn't give definitive answer
    if known == nil and detectedAddon == "Fallback" then
        known = FallbackCheckTooltip(itemLink)
    end

    transmogCache[itemLink] = { known = known, source = detectedAddon }
    return known
end

-- Get display text for tooltip
function Transmog:GetTransmogStatusText(itemLink)
    if not itemLink then return nil end

    local known = Transmog:PlayerKnowsTransmog(itemLink)
    if known == nil then return nil end

    if known then
        return "|cff00ff00[Transmog: Conhecido]|r"
    else
        return "|cffff3333[Transmog: Não Aprendido]|r"
    end
end

-- Bag overlay icons (Green V / Red X)
function Transmog:UpdateItemOverlay(button)
    if not button then return end

    if not ns.db or not ns.db.modules.transmog or not ns.db.transmog.showBagIcons then
        if button.wellbrockOverlay then
            button.wellbrockOverlay:Hide()
        end
        return
    end

    local itemLink = nil

    -- Try GetItemLink from button (works in Classic container frames)
    if button.GetBagID and button.GetID then
        local bag = button:GetBagID()
        local slot = button:GetID()
        if bag and slot and GetContainerItemLink then
            itemLink = GetContainerItemLink(bag, slot)
        end
    end

    if not itemLink then
        if button.wellbrockOverlay then
            button.wellbrockOverlay:Hide()
        end
        return
    end

    local known = Transmog:PlayerKnowsTransmog(itemLink)
    if known == nil then
        if button.wellbrockOverlay then
            button.wellbrockOverlay:Hide()
        end
        return
    end

    -- Create overlay texture if not present
    if not button.wellbrockOverlay then
        local overlay = button:CreateTexture(nil, "OVERLAY", nil, 7)
        overlay:SetSize(14, 14)
        overlay:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
        button.wellbrockOverlay = overlay
    end

    if known then
        -- Green checkmark / V
        button.wellbrockOverlay:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        button.wellbrockOverlay:Show()
    else
        -- Red cross / X
        button.wellbrockOverlay:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
        button.wellbrockOverlay:Show()
    end
end

-- Tooltip integration
function Transmog:OnTooltipSetItem(tooltip)
    if not ns.db or not ns.db.modules.transmog then return end
    if not tooltip or not tooltip.AddLine then return end

    local itemLink = select(2, tooltip:GetItem())
    if not itemLink then return end

    local status = Transmog:GetTransmogStatusText(itemLink)
    if status then
        tooltip:AddLine(status)
    end
end

function Transmog:Init()
    -- Tooltip hook (Classic style)
    GameTooltip:HookScript("OnTooltipSetItem", function(self)
        Transmog:OnTooltipSetItem(self)
    end)

    -- Container frame hook for bag overlays
    -- Hook ContainerFrameItemButton_OnUpdate (Classic)
    if ContainerFrameItemButton_OnUpdate then
        hooksecurefunc("ContainerFrameItemButton_OnUpdate", function(button)
            Transmog:UpdateItemOverlay(button)
        end)
    end

    -- Also hook for combined bags if they exist (SoD/newer Classic)
    if ContainerFrameCombinedBags then
        hooksecurefunc(ContainerFrameCombinedBags, "Update", function()
            if ContainerFrameCombinedBags.GetChildren then
                for _, child in ipairs({ContainerFrameCombinedBags:GetChildren()}) do
                    if child and child.IsObjectType and child:IsObjectType("Button") then
                        Transmog:UpdateItemOverlay(child)
                    end
                end
            end
        end)
    end

    -- Invalidate cache on transmog-related events (if any addon fires them)
    ns.RegisterEvent("TRANSMOG_COLLECTION_UPDATED", function()
        Transmog:ClearCache()
    end)

    -- Also listen for addon messages from known transmog addons
    ns.RegisterEvent("ADDON_LOADED", function(event, addon)
        if addon == "CanIMogIt" or addon == "TransmogMaster" or addon == "MogIt" or addon == "AllTheThings" then
            detectedAddon = nil -- Force re-detection
            Transmog:ClearCache()
            ns.Utils.Debug("Transmog: Addon " .. addon .. " carregado, cache invalidado")
        end
    end)

    ns.Utils.Debug("Transmog module initialized (Community addon integration + Fallback).")
end
-- Constants.lua (Forever / Classic Era / SoD)
local addonName, ns = ...

ns.NAME = addonName
ns.VERSION = "1.3.0-forever"
ns.COLOR_HEX = "00ccff"
ns.PREFIX = "|cff" .. ns.COLOR_HEX .. "[" .. addonName .. "]|r "
ns.ICON_PATH = "Interface\\AddOns\\" .. addonName .. "\\Media\\icon.png"

-- Default configuration database schema (Forever compatible)
ns.DefaultConfig = {
    enabled = true,
    debugMode = false,
    modules = {
        autoLoot = true,         -- Speedy AutoLoot engine
        blizzMove = true,        -- BlizzMove frame mover
        transmog = true,         -- Transmog status (CanIMogIt/TomTom integration)
        mapCoords = true,        -- Map Coordinates & Bookmarks
        waypointHUD = true,      -- Waypoint HUD compass (TomTom/BuiltIn)
        questCinematic = true,   -- Lorewalker immersive quest reader
        vendorAutomation = true, -- Auto Sell Junk & Auto Repair
        squareMinimap = false,   -- Square Minimap (Leatrix style)
    },
    vendor = {
        autoSell = true,         -- Automatically sell grey junk at merchants
        autoRepair = true,       -- Automatically repair gear at repair merchants
        guildRepair = true,      -- Use guild bank funds for repair if available
        showSummary = true,      -- Print copper/gold summary in chat
    },
    autoLoot = {
        autoConfirmBoP = true,
        fishingSound = true,
    },
    blizzMove = {
        clampToScreen = true,
        savePositions = true,
    },
    transmog = {
        showKnown = true,
        showUnknown = true,
        showBagIcons = true,     -- Green checkmark (V) / Red cross (X) overlay in bags
    },
    minimap = {
        hide = false,
        angle = 220,
        showBorder = true,
        borderWidth = 2,
        alignBottom = true,
    },
    mapCoords = {
        showCoords = true,
    },
    waypointHUD = {
        showDistance = true,
        scale = 1.0,
        locked = true,
        alpha = 0.9,
    },
    questCinematic = {
        hideUI = true,
        dimBackground = true,
        autoAccept = false,    -- Auto-accept quests (Shift to override)
        autoComplete = false,  -- Auto-complete quests (Shift to override)
    },
    framePositions = {},
    savedPins = {},
}
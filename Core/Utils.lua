-- Utils.lua (Classic Era)
local addonName, ns = ...

-- Local cached functions for performance
local print = print
local type = type
local pairs = pairs

ns.Utils = {}

function ns.Utils.Print(...)
    print(ns.PREFIX, ...)
end

function ns.Utils.Debug(...)
    if ns.db and ns.db.debugMode then
        print(ns.PREFIX .. "|cffffaa00[DEBUG]|r", ...)
    end
end

-- Deep copy / table merge for SavedVariables defaults
function ns.Utils.CopyDefaults(src, dst)
    if type(src) ~= "table" then return src end
    if type(dst) ~= "table" then dst = {} end
    for k, v in pairs(src) do
        if type(v) == "table" then
            dst[k] = ns.Utils.CopyDefaults(v, dst[k])
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end

-- Classic-compatible money formatting
function ns.Utils.FormatMoney(copper)
    if not copper or copper <= 0 then return "0|cffffd700c|r" end
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local c = copper % 100
    local parts = {}
    if gold > 0 then table.insert(parts, "|cffffd700" .. gold .. "g|r") end
    if silver > 0 then table.insert(parts, "|cffc7c7cf" .. silver .. "s|r") end
    if c > 0 or #parts == 0 then table.insert(parts, "|cffeda55f" .. c .. "c|r") end
    return table.concat(parts, " ")
end
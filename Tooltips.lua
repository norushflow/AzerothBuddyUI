local _, UI = ...
local Style = UI.Style
local Color = Style.Color
local skins = setmetatable({}, {__mode="k"})
local tooltipNames = {"GameTooltip", "ItemRefTooltip", "ShoppingTooltip1", "ShoppingTooltip2", "ItemRefShoppingTooltip1", "ItemRefShoppingTooltip2"}

function UI.SkinTooltip(tooltip)
    -- Retain the existing native backdrop skin without touching shared fonts or text.
    UI.Foreign(tooltip, function(native)
        local skin = skins[native]
        if not skin then
            skin = UI.Panel(native, 1, 1)
            skin:SetAllPoints(native)
            skin:SetBackdropColor(unpack(Color.inset))
            skin:SetBackdropBorderColor(unpack(Color.bronze))
            skin:EnableMouse(false)
            skins[native] = skin
            native:HookScript("OnShow", UI.SkinTooltip)
        end
        local level = native:GetFrameLevel()
        if UI.Public(level) and type(level) == "number" then
            skin:SetFrameLevel(math.max(0, level - 1))
        end
        UI.Foreign(native.NineSlice, function(slice) slice:SetAlpha(0) end)
    end)
end

function UI.InstallTooltips()
    for _, name in ipairs(tooltipNames) do UI.SkinTooltip(_G[name]) end
    if not UI.tooltipStyleHooked and type(SharedTooltip_SetBackdropStyle)=="function" then
        UI.tooltipStyleHooked = true
        hooksecurefunc("SharedTooltip_SetBackdropStyle", function(tooltip)
            if UI.Public(tooltip) and skins[tooltip] then UI.SkinTooltip(tooltip) end
        end)
    end
end

local function setContent(tooltip, unit, index, filter)
    if index then return tooltip:SetUnitAura(unit, index, filter) end
    return tooltip:SetUnit(unit)
end

local function showTooltip(owner, anchor, unit, index, filter)
    if not InCombatLockdown() then
        local ok, result = pcall(function()
            local tooltip = Style.Tooltip(owner, anchor)
            if not tooltip or tooltip:IsForbidden() then return false end
            return setContent(tooltip, unit, index, filter)
        end)
        if ok and UI.Public(result) and result ~= false then return end
        pcall(Style.HideTooltip, owner)
    end
    -- Use the established native path in combat and when the private frame
    -- cannot display the Blizzard tooltip data.
    UI.Foreign(GameTooltip, function(native)
        if anchor == "ANCHOR_NONE" then
            GameTooltip_SetDefaultAnchor(native, owner)
        else
            native:SetOwner(owner, anchor)
        end
        setContent(native, unit, index, filter)
    end)
end

function UI.ShowUnitTooltip(frame, defaultAnchor)
    showTooltip(frame, defaultAnchor and "ANCHOR_NONE" or "ANCHOR_RIGHT", frame.unit)
end

function UI.ShowAuraTooltip(frame, unit, index, filter)
    showTooltip(frame, "ANCHOR_RIGHT", unit, index, filter)
end

function UI.HideUnitTooltip(owner)
    pcall(Style.HideTooltip, owner)
    UI.Foreign(GameTooltip, function(native)
        local owned = native:IsOwned(owner)
        if UI.Public(owned) and owned then native:Hide() end
    end)
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function()
    if UI.started then UI.InstallTooltips() end
end)

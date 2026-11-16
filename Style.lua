local addonName, ns = ...

-- Central styling for AzerothBuddyUI; never change shared Blizzard font objects.
local Style = {}
ns.Style = Style

local Color = {
    background = {.075, .075, .075, .94},
    inset = {.045, .045, .045, .93},
    header = {.12, .12, .12, .96},
    border = {.32, .32, .32, .85},
    bronze = {.32, .32, .32, .85},
    gold = {.94, .94, .94, 1},
    text = {.90, .90, .90, 1},
    muted = {.65, .65, .65, 1},
    disabled = {.45, .45, .45, 1},
    button = {.16, .16, .16, .96},
    pushed = {.09, .09, .09, .96},
    cooldown = {0, 0, 0, .8},
    highlight = {1, 1, 1, .12},
    selected = {.75, .75, .75, .9},
    strip = {.075, .075, .075, .65},
    success = {.51, .84, .44, 1},
    danger = {1, .45, .36, 1},
    info = {.55, .80, .94, 1},
    transparent = {0, 0, 0, 0},
}
Style.Color = Color
Style.Spacing = {small = 4, gap = 8, inset = 12, panel = 16}
Style.WHITE = "Interface\\Buttons\\WHITE8X8"
local sizes = {title = 20, heading = 15, body = 13, small = 11, button = 13, hud = 12, tooltip = 13}
local expressway = "Interface\\AddOns\\" .. addonName .. "\\Media\\Expressway.ttf"
local fontPath

function Style.Hex(color)
    local r, g, b = unpack(color)
    return ("|cff%02x%02x%02x"):format(math.floor(r * 255 + .5), math.floor(g * 255 + .5), math.floor(b * 255 + .5))
end

function Style.Font(region, role, flags, color)
    if not region then return end
    local size = type(role) == "number" and role or sizes[role] or sizes.body
    flags = flags or ""
    if not fontPath then
        local locale = GetLocale and GetLocale()
        if locale ~= "koKR" and locale ~= "zhCN" and locale ~= "zhTW" then
            -- Probe the optional font once. Some clients raise for missing assets.
            local ok, loaded = pcall(region.SetFont, region, expressway, size, flags)
            if ok and loaded then fontPath = expressway end
        end
        if not fontPath then
            fontPath = (GameFontNormal and GameFontNormal:GetFont()) or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
            region:SetFont(fontPath, size, flags)
        end
    else
        region:SetFont(fontPath, size, flags)
    end
    if color then region:SetTextColor(unpack(color)) end
    return region
end

function Style.Text(parent, role, color, flags)
    local text = parent:CreateFontString(nil, "OVERLAY")
    local heading = role == "title" or role == "heading"
    Style.Font(text, role, flags, color or (heading and Color.gold or Color.text))
    text:SetShadowColor(0, 0, 0, .9)
    text:SetShadowOffset(1, -1)
    return text
end

local function fill(frame, layer, subLevel, color)
    local texture = frame:CreateTexture(nil, layer, nil, subLevel)
    texture:SetAllPoints(frame)
    texture:SetColorTexture(unpack(color))
    return texture
end

function Style.Divider(frame, color)
    local edge = frame:CreateTexture(nil, "BORDER")
    edge:SetHeight(1)
    edge:SetColorTexture(unpack(color or Color.border))
    return edge
end

function Style.Border(frame, color, layer, subLevel)
    local borders = {}
    for _, side in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
        local edge = frame:CreateTexture(nil, layer or "BORDER", nil, subLevel)
        if side == "TOP" or side == "BOTTOM" then
            edge:SetPoint(side .. "LEFT", frame, side .. "LEFT")
            edge:SetPoint(side .. "RIGHT", frame, side .. "RIGHT")
            edge:SetHeight(1)
        else
            edge:SetPoint("TOP" .. side, frame, "TOP" .. side, 0, -1)
            edge:SetPoint("BOTTOM" .. side, frame, "BOTTOM" .. side, 0, 1)
            edge:SetWidth(1)
        end
        edge:SetColorTexture(unpack(color or Color.border))
        borders[#borders + 1] = edge
    end
    return borders
end

local function setPanelColor(frame, r, g, b, a)
    frame.background:SetColorTexture(r, g, b, a)
end

local function setBorderColor(frame, r, g, b, a)
    for _, edge in ipairs(frame.borders) do edge:SetColorTexture(r, g, b, a) end
end

function Style.Panel(frame)
    -- Fixed edge anchors also work on HUD frames whose dimensions can be secret.
    frame.background = fill(frame, "BACKGROUND", -5, Color.background)
    frame.borders = Style.Border(frame)
    frame.SetBackdropColor = setPanelColor
    frame.SetBackdropBorderColor = setBorderColor
    return frame
end

function Style.Window(frame, headerHeight, opacity)
    if frame.SetBackdrop then frame:SetBackdrop(nil) end
    headerHeight = headerHeight or 38
    Style.Panel(frame)
    if opacity then
        frame:SetBackdropColor(Color.background[1], Color.background[2], Color.background[3], opacity)
    end
    local left, top, right = 1, 1, -1
    local header = frame:CreateTexture(nil, "BACKGROUND", nil, -4)
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", left, -top)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", right, -top)
    header:SetHeight(headerHeight - top)
    header:SetColorTexture(unpack(Color.header))
    local divider = Style.Divider(frame)
    divider:SetPoint("TOPLEFT", frame, "TOPLEFT", Style.Spacing.inset, -headerHeight)
    divider:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -Style.Spacing.inset, -headerHeight)
    return frame
end

function Style.Inset(frame)
    if frame.SetBackdrop then frame:SetBackdrop(nil) end
    Style.Panel(frame)
    frame:SetBackdropColor(unpack(Color.inset))
    return frame
end

local buttonFonts
local function buttonTexture(button, state, color)
    button["Set" .. state .. "Texture"](button, Style.WHITE)
    local texture = button["Get" .. state .. "Texture"](button)
    texture:SetVertexColor(unpack(color))
    texture:SetTexCoord(0, 1, 0, 1)
    texture:ClearAllPoints()
    texture:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
    texture:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
end

function Style.Button(button)
    button.styleSelection = false
    if CreateFont and button.SetNormalFontObject then
        if not buttonFonts then
            buttonFonts = {}
            for _, state in ipairs({"Normal", "Highlight", "Disabled"}) do
                local font = CreateFont(addonName .. "ButtonFont" .. state)
                local color = state == "Disabled" and Color.disabled or (state == "Highlight" and Color.gold or Color.text)
                Style.Font(font, "button", "OUTLINE", color)
                buttonFonts[state] = font
            end
        end
        button:SetNormalFontObject(buttonFonts.Normal)
        button:SetHighlightFontObject(buttonFonts.Highlight)
        button:SetDisabledFontObject(buttonFonts.Disabled)
    elseif button.GetFontString then
        Style.Font(button:GetFontString(), "button", "OUTLINE", Color.text)
    end
    for _, key in ipairs({"Left", "Middle", "Right"}) do
        local piece = button[key]
        if piece and type(piece) ~= "function" then piece:Hide() end
    end
    buttonTexture(button, "Normal", Color.button)
    buttonTexture(button, "Pushed", Color.pushed)
    buttonTexture(button, "Disabled", Color.inset)
    buttonTexture(button, "Highlight", Color.highlight)
    Style.Border(button)
    return button
end

function Style.Close(button)
    Style.Button(button)
    local glyph = Style.Text(button, 18, Color.text)
    glyph:SetPoint("CENTER", button, "CENTER", 0, 1)
    glyph:SetText("×")
    return button
end

function Style.Select(button, selected)
    if not button.styleSelection and selected then
        local marker = Style.Divider(button, Color.selected)
        marker:SetDrawLayer("OVERLAY", 2)
        marker:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 5, 1)
        marker:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -5, 1)
        button.styleSelection = marker
    end
    if button.styleSelection then button.styleSelection:SetShown(selected and true or false) end
end

function Style.Icon(button)
    button.styleSelection = false
    local background = button:CreateTexture(nil, "BACKGROUND", nil, -5)
    background:SetAllPoints(button)
    background:SetColorTexture(unpack(Color.button))
    Style.Border(button, Color.bronze, "OVERLAY", 2)
    if not button:GetHighlightTexture() then
        button:SetHighlightTexture(Style.WHITE, "ADD")
        local highlight = button:GetHighlightTexture()
        if highlight then highlight:SetVertexColor(unpack(Color.highlight)) end
    end
    return button
end

function Style.Check(button)
    Style.Button(button)
    local checked = button:GetCheckedTexture()
    if checked then
        checked:SetDesaturated(true)
        checked:SetVertexColor(unpack(Color.selected))
    end
    local label = button.Text or button.text
    if label and type(label) ~= "function" then Style.Font(label, "body", nil, Color.text) end
    return button
end

local tooltip
local tooltipName = addonName .. "DesignTooltip"

local function styleTooltipLine(frame)
    local count = frame:NumLines()
    if (issecretvalue and issecretvalue(count)) or type(count) ~= "number" or count < 1 then return end
    local role = count == 1 and "heading" or "tooltip"
    Style.Font(_G[tooltipName .. "TextLeft" .. count], role)
    Style.Font(_G[tooltipName .. "TextRight" .. count], role)
end

local function refreshTooltip(frame, event)
    if event == "TOOLTIP_DATA_UPDATE" and frame.shouldRefreshData and frame:IsShown()
        and not InCombatLockdown() then
        pcall(frame.RefreshData, frame)
    end
end

function Style.Tooltip(owner, anchor)
    if not tooltip then
        tooltip = CreateFrame("GameTooltip", tooltipName, UIParent, "GameTooltipTemplate")
        if hooksecurefunc and tooltip.NumLines then
            -- Native item, unit and aura rendering also uses these methods to lay out its lines.
            hooksecurefunc(tooltip, "AddLine", styleTooltipLine)
            hooksecurefunc(tooltip, "AddDoubleLine", styleTooltipLine)
            hooksecurefunc(tooltip, "SetText", styleTooltipLine)
        end
        if tooltip.RefreshData then
            -- The native template flags refreshes. Consume them when notified.
            tooltip:HookScript("OnEvent", refreshTooltip)
        end
    end
    if anchor == "ANCHOR_NONE" and GameTooltip_SetDefaultAnchor then
        GameTooltip_SetDefaultAnchor(tooltip, owner)
    else
        tooltip:SetOwner(owner, anchor or "ANCHOR_RIGHT")
    end
    tooltip:ClearLines()
    if tooltip.ClearHandlerInfo then tooltip:ClearHandlerInfo() end
    tooltip.shouldRefreshData = false
    local slice = tooltip.NineSlice
    if slice and type(slice) ~= "function" then
        slice:SetCenterColor(unpack(Color.inset))
        slice:SetBorderColor(unpack(Color.bronze))
    end
    return tooltip
end

function Style.HideTooltip(owner)
    if tooltip and (not owner or tooltip:GetOwner() == owner) then tooltip:Hide() end
end

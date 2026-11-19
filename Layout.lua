local _, UI = ...
local Style = UI.Style
local Color = Style.Color

local function shadeStrip(panel)
    panel:SetBackdropColor(unpack(Color.strip))
    panel:SetBackdropBorderColor(unpack(Color.transparent))
end

function UI.ClickFooterClock(_, mouse)
    if mouse ~= "LeftButton" and mouse ~= "RightButton" then return end
    pcall(function()
        if mouse == "LeftButton" then
            local native = GameTimeFrame
            if not UI.Public(native) then return end
            if native then
                local forbidden = native:IsForbidden()
                if not UI.Public(forbidden) or forbidden then return end
                local click = native:GetScript("OnClick")
                if type(click)=="function" then click(native, "LeftButton"); return end
            end
            if type(ToggleCalendar)=="function" then ToggleCalendar() end
            return
        end
        -- Direkt das Menü öffnen: der native Uhrklick quittiert ggf. nur einen Alarm.
        if not TimeManager_Toggle and C_AddOns and C_AddOns.LoadAddOn and not InCombatLockdown() then
            C_AddOns.LoadAddOn("Blizzard_TimeManager")
        end
        if type(TimeManager_Toggle)=="function" then TimeManager_Toggle() end
    end)
end
local function layoutClockAndCalendar()
    local function usable(frame)
        if not frame then return false end
        local forbidden, protected = frame:IsForbidden(), frame:IsProtected()
        return UI.Public(forbidden) and not forbidden and UI.Public(protected) and not protected
    end
    pcall(function()
        if usable(TimeManagerClockButton) then
            TimeManagerClockButton:SetAlpha(0)
            TimeManagerClockButton:EnableMouse(false)
        end
    end)
    pcall(function()
        if usable(GameTimeFrame) and Minimap and not Minimap:IsForbidden() then
            GameTimeFrame:SetScale(1.4)
            GameTimeFrame:ClearAllPoints()
            GameTimeFrame:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -3, -3)
        end
    end)
end
-- Blizzards EditMode-SetPoint merkt sich den relativen Rahmen als "Snap".
-- Unsere Anordnung ist kein EditMode-Snap: beim Ausblenden der Ziel-Leiste
-- bricht Blizzard sonst die Verankerung der geschützten Leiste (auch im Kampf),
-- sie bleibt ohne Punkt zurück und UpdateSystemAnchorInfo rechnet mit nil.
local function place(frame, point, relative, relativePoint, x, y)
    frame:ClearAllPoints()
    frame:SetPoint(point, relative, relativePoint, x, y)
    if type(frame.ClearFrameSnap) == "function" then frame:ClearFrameSnap() end
end
local function darkenActionArt(texture)
    UI.Foreign(texture, function(region)
        if region.SetVertexColor then region:SetVertexColor(.16, .16, .16) end
    end)
end

local function skinActionButtons(prefix, count)
    for i=1,count do
        UI.Foreign(_G[prefix..i], function(button)
            darkenActionArt(button.SlotArt)
            darkenActionArt(button.SlotBackground)
            darkenActionArt(button.NormalTexture)
            if button.GetNormalTexture then darkenActionArt(button:GetNormalTexture()) end
        end)
    end
end

local function skinActionBars()
    for _, name in ipairs({"MainActionBar", "MultiBarBottomLeft", "MultiBarBottomRight",
        "MultiBarRight", "MultiBarLeft", "MultiBar5", "MultiBar6", "MultiBar7"}) do
        UI.Foreign(_G[name], function(bar)
            darkenActionArt(bar.Background)
            darkenActionArt(bar.BorderArt)
            darkenActionArt(bar.EndCaps)
        end)
        skinActionButtons(name == "MainActionBar" and "ActionButton" or name.."Button", 12)
    end
    skinActionButtons("StanceButton", NUM_STANCE_SLOTS or 10)
    skinActionButtons("PetActionButton", NUM_PET_ACTION_SLOTS or 10)
end

local function hideNative(frame, vehicle, raid)
    if InCombatLockdown() then return end
    UI.Foreign(frame, function(native)
        local host = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
        host:SetAllPoints(UIParent)
        native:SetParent(host)
        RegisterStateDriver(host, "visibility", vehicle and "[vehicleui] show; hide" or raid and "[group:raid] show; hide" or "hide")
    end)
end

local function positionPlayerCast()
    local anchor, width, offset = UI.combatAnchor, 264, -10
    UI.Foreign(MainActionBar, function(main)
        local scale, parentScale = main:GetEffectiveScale(), UIParent:GetEffectiveScale()
        local barWidth, center, bottom = main:GetWidth(), main:GetCenter(), main:GetBottom()
        local function numeric(value)
            return UI.Public(value) and type(value) == "number"
        end
        if not (numeric(scale) and numeric(parentScale) and numeric(barWidth)
            and numeric(center) and numeric(bottom)) or scale <= 0 or parentScale <= 0 or barWidth <= 10 then return end
        local centerX = center * scale
        anchor, width, offset = main, barWidth * scale / parentScale, -12
        local lowest = bottom * scale
        for _, name in ipairs({"MultiBarBottomLeft", "MultiBarBottomRight"}) do
            UI.Foreign(_G[name], function(bar)
                local shown = bar:IsVisible()
                if not UI.Public(shown) or not shown then return end
                local x, y, barScale = bar:GetCenter(), bar:GetBottom(), bar:GetEffectiveScale()
                if numeric(x) and numeric(y) and numeric(barScale) and barScale > 0
                    and math.abs(x * barScale - centerX) <= barWidth * scale / 4 and y * barScale < lowest then
                    anchor, lowest = bar, y * barScale
                end
            end)
        end
    end)
    place(UI.playerCastAnchor, "TOP", anchor, "BOTTOM", 0, offset)
    place(UI.playerCast, "TOP", UI.playerCastAnchor, "TOP", 0, 0)
    UI.playerCast:SetWidth(width)
    UI.playerCast.label:SetWidth(width - 10)
end
-- Observe Blizzard's public exit event without writing to the manager or
-- running our frame mutations inside its OnHide/reset call stack.
function UI.WatchEditMode()
    if UI.editModeWatcher or not EventRegistry then return end
    EventRegistry:RegisterCallback("EditMode.Exit", function()
        C_Timer.After(0, function()
            if UI.started and not InCombatLockdown() then UI.ApplyLayout() end
        end)
    end, UI)
    UI.editModeWatcher = true
end

function UI.CreateLayout()
    UI.InstallTooltips()
    UI.footer = UI.Panel(UIParent,1,38)
    UI.footer:SetPoint("BOTTOMLEFT")
    UI.footer:SetPoint("BOTTOMRIGHT")
    UI.footer:SetFrameStrata("BACKGROUND")
    shadeStrip(UI.footer)
    UI.clockButton = CreateFrame("Button", nil, UI.footer)
    UI.clockButton:SetSize(100, 38)
    UI.clockButton:SetPoint("CENTER", UI.footer, "CENTER", 0, 0)
    UI.clockButton:SetFrameStrata("MEDIUM")
    UI.clockButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    UI.clockButton:SetScript("OnClick", UI.ClickFooterClock)
    UI.clockButton:SetHighlightTexture(Style.WHITE, "ADD")
    UI.clockButton:GetHighlightTexture():SetVertexColor(unpack(Color.highlight))
    UI.clock = UI.Text(UI.clockButton, 26, "CENTER", nil, 0, 0, Color.gold)
    local zoneWidth = 186
    UI.header = CreateFrame("Frame", nil, UIParent)
    UI.header:SetSize(zoneWidth, 20)
    -- Minimap ist ein fremdes Blizzard-Fenster: nur gesichert umhängen.
    pcall(function()
        local parent = Minimap
        if not parent or parent:IsForbidden() then parent = UIParent end
        UI.header:SetParent(parent)
        UI.header:SetPoint("TOP", parent, "TOP", 0, -5)
    end)
    pcall(function()
        if not Minimap or Minimap:IsForbidden() then return end
        UI.header:SetFrameLevel(Minimap:GetFrameLevel()+5)
    end)
    UI.info = UI.Text(UI.header, "hud", "CENTER", nil, 0, 0, Color.gold)
    UI.info:SetWidth(zoneWidth - 2 * Style.Spacing.small)
    UI.info:SetWordWrap(false)
    local lastMinute
    local function showInfo(hour, minute)
        lastMinute = minute
        UI.info:SetText(GetZoneText())
        UI.clock:SetFormattedText("%02d:%02d", hour, minute)
    end
    local function refreshInfo()
        showInfo(GetGameTime())
    end
    -- The minute is the smallest unit shown: check once per second but only
    -- rewrite the text when it actually changes, so the clock never lags.
    local function tickClock()
        local hour, minute = GetGameTime()
        if minute ~= lastMinute then showInfo(hour, minute) end
    end
    UI.header:RegisterEvent("ZONE_CHANGED_INDOORS")
    UI.header:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    UI.header:RegisterEvent("ZONE_CHANGED")
    UI.header:SetScript("OnEvent", refreshInfo)
    UI.timer = C_Timer.NewTicker(1, tickClock)
    refreshInfo()
    UI.mapAnchor = CreateFrame("Frame", nil, UIParent)
    UI.mapAnchor:SetSize(240, 240)
    pcall(function()
        if not Minimap or Minimap:IsForbidden() then return end
        Minimap:SetMaskTexture(Style.WHITE)
        UI.mapBorder = CreateFrame("Frame", nil, Minimap)
        UI.mapBorder:EnableMouse(false)
        UI.mapBorder:SetFrameLevel(math.max(0, Minimap:GetFrameLevel()-1))
        UI.mapBorder:SetAllPoints(Minimap)
        UI.mapBorder.borders = Style.Border(UI.mapBorder)
    end)
    -- Class resources are drawn by our own widgets; native hierarchy stays intact.
    UI.targetCast = UI.CreateCastBar(UI.target, "target", 260)
    UI.playerCast = UI.CreateCastBar(UIParent, "player", 264)
    UI.focusCast = UI.CreateCastBar(UI.focus, "focus", 220)
    for _, boss in ipairs(UI.bosses) do boss.cast = UI.CreateCastBar(boss, boss.unit, 220) end
    UI.CreateHolyPower()
    UI.CreateSoulShards()
    UI.CreateClassPower()
    local stanceEvents = CreateFrame("Frame")
    stanceEvents:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
    stanceEvents:SetScript("OnEvent", function()
        if not InCombatLockdown() then skinActionBars() end
    end)
    hideNative(PaladinPowerBarFrame)
    hideNative(PlayerFrame, true)
    hideNative(TargetFrameToT)
    hideNative(TargetFrame)
    hideNative(FocusFrame)
    hideNative(PlayerCastingBarFrame)
    hideNative(OverlayPlayerCastingBarFrame)
    for i=1,#UI.bosses do hideNative(_G["Boss"..i.."TargetFrame"]) end
    hideNative(PetFrame)
    hideNative(PartyFrame)
    -- Own group and raid grids replace the native ones. Keep the native
    -- hierarchy and secure show/hide callbacks untouched; suppress only
    -- rendering and mouse input, outside combat.
    UI.MaskNativeGroupFrames()
    UI.WatchEditMode()
end
function UI.ApplyLayout()
    if InCombatLockdown() then return end
    UI.WatchEditMode()
    UI.MaskNativeGroupFrames()
    UI.PositionUnits()
    skinActionBars()
    UI.Anchor(UI.mapAnchor, "minimap", "TOPRIGHT", -4, -10)
    if MinimapCluster then
        pcall(function()
            if MinimapCluster:IsForbidden() then return end
            MinimapCluster:SetScale(1)
            place(MinimapCluster, "TOPRIGHT", UI.mapAnchor, "TOPRIGHT", 0, 0)
        end)
    end
    pcall(function()
        if not Minimap or Minimap:IsForbidden() then return end
        place(Minimap, "TOPRIGHT", UI.mapAnchor, "TOPRIGHT", 0, 0)
        Minimap:SetSize(240, 240)
        Minimap:SetMaskTexture(Style.WHITE)
        -- Originales Blizzard-Tracking an der Minimap positionieren.
        if not (InCombatLockdown and InCombatLockdown()) then
            UI.Foreign(MinimapCluster, function(cluster)
                UI.Foreign(GameTimeFrame, function(calendar)
                    UI.Foreign(cluster.Tracking, function(tracking)
                        local w, h = calendar:GetWidth(), calendar:GetHeight()
                        local cs = calendar:GetEffectiveScale()
                        local parent = tracking:GetParent()
                        local ps = parent and parent:GetEffectiveScale()

                        local function valid(v)
                            return not (issecretvalue and issecretvalue(v))
                                and type(v) == "number" and v > 0
                        end

                        if not (valid(w) and valid(h) and valid(cs) and valid(ps)) then return end

                        tracking:ClearAllPoints()
                        tracking:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 3, -3)
                        tracking:SetSize(w, h)
                        tracking:SetScale(cs / ps)

                        local button = tracking.Button
                        if button and not button:IsForbidden() then
                            button:ClearAllPoints()
                            button:SetAllPoints(tracking)
                        end

                        local level = Minimap:GetFrameLevel()
                        if valid(level) then
                            tracking:SetFrameLevel(level + 5)
                            if button and not button:IsForbidden() then
                                button:SetFrameLevel(level + 6)
                            end
                        end
                    end)
                end)
            end)
        end
        if MinimapCompassTexture and not MinimapCompassTexture:IsForbidden() then MinimapCompassTexture:SetAlpha(0) end
    end)
    UI.Foreign(Minimap, function(map)
        UI.Foreign(BuffFrame, function(frame) place(frame, "TOPRIGHT", map, "TOPLEFT", -12, 0) end)
    end)
    layoutClockAndCalendar()
    UI.PositionProgress()
    positionPlayerCast()
    place(UI.targetCast, "BOTTOM", UI.target, "TOP", 0, 5)
    place(UI.focusCast, "TOP", UI.focus, "BOTTOM", 0, -24)
    for _, boss in ipairs(UI.bosses) do place(boss.cast, "TOP", boss, "BOTTOM", 0, -22) end
end

function UI.MaskNativeGroupFrames()
    if InCombatLockdown() then return end
    local function mask(frame)
        -- Selection highlights and ready-check icons ignore parent alpha in
        -- Blizzard's template. Restore inheritance for every region and child.
        pcall(function()
            if frame:IsForbidden() then return end
            frame:SetIgnoreParentAlpha(false)
            frame:EnableMouse(false)
            for _, region in ipairs({frame:GetRegions()}) do
                pcall(function()
                    if not region:IsForbidden() then region:SetIgnoreParentAlpha(false) end
                end)
            end
            for _, child in ipairs({frame:GetChildren()}) do mask(child) end
        end)
    end
    for _, name in ipairs({"CompactPartyFrame", "CompactRaidFrameContainer", "CompactRaidFrameManager"}) do
        local frame = _G[name]
        if frame then
            pcall(function()
                if frame:IsForbidden() then return end
                frame:SetAlpha(0)
                mask(frame)
            end)
        end
    end
end

-- Roster changes can create native children even when raid membership stays
-- unchanged. Coalesce the pass and run after Blizzard's event handlers.
function UI.QueueNativeGroupMask()
    if UI.nativeMaskPending then return end
    UI.nativeMaskPending = true
    C_Timer.After(0, function()
        UI.nativeMaskPending = nil
        if UI.started then UI.MaskNativeGroupFrames() end
    end)
end

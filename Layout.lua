local _, UI = ...
local Style = UI.Style
local Color = Style.Color

local function shadeStrip(panel)
    panel:SetBackdropColor(0, 0, 0, .5)
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
local bars = {
    {name="MainActionBar", prefix="ActionButton", key="actions1", y=43},
    {name="MultiBarBottomLeft", prefix="MultiBarBottomLeftButton", key="actions2", y=5},
    {name="MultiBarBottomRight", prefix="MultiBarBottomRightButton", key="actions3", y=81},
}
-- Blizzards EditMode-SetPoint merkt sich den relativen Rahmen als "Snap".
-- Unsere Anordnung ist kein EditMode-Snap: beim Ausblenden der Ziel-Leiste
-- bricht Blizzard sonst die Verankerung der geschützten Leiste (auch im Kampf),
-- sie bleibt ohne Punkt zurück und UpdateSystemAnchorInfo rechnet mit nil.
local function place(frame, point, relative, relativePoint, x, y)
    frame:ClearAllPoints()
    frame:SetPoint(point, relative, relativePoint, x, y)
    if type(frame.ClearFrameSnap) == "function" then frame:ClearFrameSnap() end
end
-- Nur Darstellung nativer Aktionsknöpfe; keine Aktionen, Attribute oder Skripte ersetzen.
function UI.SkinActionButton(button)
    if not button or InCombatLockdown() then return end
    pcall(function()
        if button:IsForbidden() or button.abuiQuestSkin then return end
        local bg = button:CreateTexture(nil, "BACKGROUND", nil, -8)
        bg:SetAllPoints(button)
        bg:SetColorTexture(unpack(Color.inset))
        local edges = Style.Border(button, Color.border, "OVERLAY", 1)
        local icon=button.icon or button.Icon
        if icon and not icon:IsForbidden() then
            if button.IconMask and not button.IconMask:IsForbidden() then icon:RemoveMaskTexture(button.IconMask) end
            icon:ClearAllPoints();icon:SetPoint("TOPLEFT",button,"TOPLEFT",1,-1)
            icon:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",-1,1)
            icon:SetTexCoord(.07,.93,.07,.93)
        end
        for _,key in ipairs({"SlotArt","SlotBackground","NormalTexture"}) do
            local region=button[key]
            if region and not region:IsForbidden() then region:SetAlpha(0) end
        end
        local normal=button:GetNormalTexture()
        if normal and not normal:IsForbidden() then normal:SetAlpha(0) end
        button:SetHighlightTexture(Style.WHITE, "ADD")
        button:SetPushedTexture(Style.WHITE)
        if button.SetCheckedTexture then
            button:SetCheckedTexture("Interface\\AddOns\\AzerothBuddyUI\\Media\\Selection")
            local checked=button:GetCheckedTexture()
            if checked and not checked:IsForbidden() then
                checked:SetAllPoints(button)
                checked:SetVertexColor(unpack(Color.selected))
            end
        end
        local hover,pressed=button:GetHighlightTexture(),button:GetPushedTexture()
        if hover and not hover:IsForbidden() then
            hover:SetAllPoints(button)
            hover:SetVertexColor(unpack(Color.highlight))
        end
        if pressed and not pressed:IsForbidden() then
            pressed:SetAllPoints(button)
            pressed:SetVertexColor(Color.inset[1], Color.inset[2], Color.inset[3], .4)
        end
        -- Cooldown, Ladungen, Tastenkürzel, Reichweite und Proc-Effekte bleiben nativ.
        button.abuiQuestSkin={background=bg,edges=edges}
    end)
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
    local plaqueWidth = 186
    UI.header = UI.Panel(UIParent, plaqueWidth, 20)
    shadeStrip(UI.header)
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
    UI.info:SetWidth(plaqueWidth - 2 * Style.Spacing.small)
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
    for _, spec in ipairs(bars) do
        spec.anchor = CreateFrame("Frame", nil, UIParent)
        spec.anchor:SetSize(264, 36)
    end
    -- Keep the game's action buttons, bindings, paging, cooldowns and flyouts.
    -- Only arrange visible native bars; never force-show a bar hidden by a secure driver.
    UI.chatAnchor = CreateFrame("Frame", nil, UIParent)
    UI.chatAnchor:SetSize(365, 145)
    UI.mapAnchor = CreateFrame("Frame", nil, UIParent)
    UI.mapAnchor:SetSize(240, 240)
    pcall(function()
        if not Minimap or Minimap:IsForbidden() then return end
        Minimap:SetMaskTexture(Style.WHITE)
        UI.mapBorder = CreateFrame("Frame", nil, Minimap)
        UI.mapBorder:EnableMouse(false)
        UI.mapBorder:SetFrameLevel(math.max(0, Minimap:GetFrameLevel()-1))
        if NineSliceUtil and NineSliceUtil.ApplyLayoutByName then
            -- The native top piece extends downward. Leave room for it above the map.
            UI.mapBorder:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 4)
            UI.mapBorder:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 0, 0)
            NineSliceUtil.ApplyLayoutByName(UI.mapBorder, "SimplePanelTemplate")
        else
            UI.mapBorder:SetAllPoints(Minimap)
            Style.Border(UI.mapBorder)
        end
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
    stanceEvents:SetScript("OnEvent", function() UI.PositionStances() end)
    hideNative(PaladinPowerBarFrame)
    hideNative(PlayerFrame, true)
    hideNative(TargetFrameToT)
    hideNative(TargetFrame)
    hideNative(FocusFrame)
    hideNative(PlayerCastingBarFrame)
    for i=1,#UI.bosses do hideNative(_G["Boss"..i.."TargetFrame"]) end
    hideNative(PetFrame)
    hideNative(PartyFrame)
    -- Own group and raid grids replace the native ones. Keep the native
    -- hierarchy and secure show/hide callbacks untouched; suppress only
    -- rendering and mouse input, outside combat.
    UI.MaskNativeGroupFrames()
    UI.WatchEditMode()
end
function UI.ArrangeBar(spec)
    if InCombatLockdown() or spec.arranging then return end
    spec.arranging = true
    UI.Anchor(spec.anchor, spec.key, "BOTTOM", 0, spec.y, UI.combatAnchor, "BOTTOM")
    local native = _G[spec.name]
    UI.Foreign(native, function()
        -- Fremde Blizzard-Leisten nur gesichert anfassen.
        pcall(function()
            if native:IsForbidden() then return end
            native:SetScale(1)
            native:SetSize(264, 36)
            place(native, "BOTTOMLEFT", spec.anchor, "BOTTOMLEFT", 0, 0)
        end)
        -- Bewusst sieben sichtbare Plätze; die Plätze 8–12 bleiben ausgeblendet.
        -- Wer das ändert, muss UI.SkinActionButton und ArrangeBar gemeinsam anpassen.
        for i=1,12 do
            local button = _G[spec.prefix..i]
            if button and i > 7 then
                -- A hidden secure parent survives Blizzard's button Show updates.
                if not button.suiOverflowHidden then
                    local ok = pcall(function()
                        if button:IsForbidden() then error("forbidden") end
                        local container = button.container
                        hideNative(container and container ~= native and container or button)
                    end)
                    if ok then button.suiOverflowHidden = true end
                end
            elseif button then
                -- Retail scales and positions a container around each button.
                -- Keep that hierarchy (paging/visibility), normalize both levels.
                pcall(function()
                    if button:IsForbidden() then return end
                    local container = button.container or button:GetParent()
                    if container and container ~= native then
                        local forbidden = container:IsForbidden()
                        if not UI.Public(forbidden) or forbidden then return end
                        container:SetScale(1)
                        container:SetSize(36, 36)
                        place(container, "BOTTOMLEFT", native, "BOTTOMLEFT", (i-1)*38, 0)
                    end
                    button:SetScale(1)
                    button:SetSize(36, 36)
                    place(button, "BOTTOMLEFT", native, "BOTTOMLEFT", (i-1)*38, 0)
                end)
                UI.SkinActionButton(button)
            end

        end
        for _, key in ipairs({"EndCaps", "BorderArt", "Background"}) do
            local region = native[key]
            if region ~= nil then
                pcall(function()
                    if region:IsForbidden() then return end
                    region:SetAlpha(0)
                end)
            end
        end
        if not spec.hooked and type(native.UpdateGridLayout) == "function" then
            hooksecurefunc(native, "UpdateGridLayout", function() UI.ArrangeBar(spec) end)
            spec.hooked = true
        end
    end)
    if spec.key == "actions1" then UI.HideActionPager() end
    spec.arranging = nil
end
function UI.HideActionPager()
    if InCombatLockdown() then return end
    pcall(function()
        if not MainActionBar or MainActionBar:IsForbidden() then return end
        local pager = MainActionBar.ActionBarPageNumber
        if not pager or pager:IsForbidden() then return end
        -- Keep native paging and bindings intact; only hide its mouse controls.
        pager:SetAlpha(0)
        pager:EnableMouse(false)
        for _, key in ipairs({"UpButton", "DownButton"}) do
            local button = pager[key]
            if button then
                pcall(function()
                    if button:IsForbidden() then return end
                    button:SetAlpha(0)
                    button:EnableMouse(false)
                end)
            end
        end
    end)
end
function UI.ApplyLayout()
    if InCombatLockdown() then return end
    UI.WatchEditMode()
    UI.MaskNativeGroupFrames()
    UI.HideActionPager()
    UI.PositionUnits()
    for _, spec in ipairs(bars) do UI.ArrangeBar(spec) end
    -- Weitere Leisten behalten ihre Sichtbarkeit und vollständige native Anordnung.
    for _,prefix in ipairs({"MultiBarRightButton","MultiBarLeftButton","MultiBar5Button","MultiBar6Button","MultiBar7Button"}) do
        for i=1,12 do UI.SkinActionButton(_G[prefix..i]) end
    end
    UI.Anchor(UI.chatAnchor, "chat", "BOTTOMLEFT", 22, 52)
    if ChatFrame1 then
        pcall(function()
            if ChatFrame1:IsForbidden() then return end
            place(ChatFrame1, "BOTTOMLEFT", UI.chatAnchor, "BOTTOMLEFT", 0, 0)
            ChatFrame1:SetSize(365, 145)
            local font, _, flags = ChatFrame1:GetFont()
            ChatFrame1:SetFont(font, 16, flags)
        end)
    end
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
    place(UI.playerCastAnchor, "TOP", bars[2].anchor, "BOTTOM", 0, -15)
    place(UI.playerCast, "TOP", UI.playerCastAnchor, "TOP", 0, 0)
    place(UI.targetCast, "BOTTOM", UI.target, "TOP", 0, 5)
    place(UI.focusCast, "TOP", UI.focus, "BOTTOM", 0, -24)
    for _, boss in ipairs(UI.bosses) do place(boss.cast, "TOP", boss, "BOTTOM", 0, -22) end
    UI.PositionStances()
    UI.PositionPetBar()
    if not UI.barFourSizeHooked then
        UI.Foreign(MultiBarRight,function(bar)
            if type(bar.UpdateGridLayout)=="function" then
                hooksecurefunc(bar,"UpdateGridLayout",UI.PositionStances)
                UI.barFourSizeHooked=true
            end
        end)
    end
end

-- Button-Abmessungen in lokalen Punkten der Ziel-Leiste, inklusive
-- nativer/EditMode-Skalierung von Leiste 4.
local function barFourButtonSize(target)
    local width,height
    UI.Foreign(_G.MultiBarRightButton1,function(button)
        local w,h=button:GetWidth(),button:GetHeight()
        local sourceScale,targetScale=button:GetEffectiveScale(),target:GetEffectiveScale()
        for _,value in ipairs({w,h,sourceScale,targetScale}) do
            if not UI.Public(value) or type(value)~="number" or value<=0 then return end
        end
        if not w or not h or not sourceScale or not targetScale then return end
        width,height=w*sourceScale/targetScale,h*sourceScale/targetScale
    end)
    return width,height
end

function UI.PositionStances()
    if InCombatLockdown() or not StanceBar or not MultiBarRight or UI.stanceBusy then return end
    UI.stanceBusy = true
    UI.Foreign(StanceBar, function()
        UI.Foreign(MultiBarRight, function()
            -- GetNumShapeshiftForms kann geheim sein: vor jeder Rechnung prüfen.
            local count = GetNumShapeshiftForms and GetNumShapeshiftForms() or 0
            if not UI.Public(count) or type(count) ~= "number" then count = 0 end
            StanceBar:SetScale(1)
            local w,h=barFourButtonSize(StanceBar)
            if not w then return end
            local step=w+2
            StanceBar:SetSize(math.max(1,count*step-2),h)
            place(StanceBar, "RIGHT", MultiBarRight, "LEFT", -8, 0)
            for i=1,count do
                local button = _G["StanceButton"..i]
                UI.Foreign(button, function()
                    local container = button.container
                    UI.Foreign(container, function()
                        container:SetScale(1)
                        container:SetSize(w, h)
                        place(container, "BOTTOMRIGHT", StanceBar, "BOTTOMRIGHT", -(i-1)*step, 0)
                    end)
                    button:SetScale(1)
                    button:SetSize(w, h)
                    place(button, "BOTTOMRIGHT", StanceBar, "BOTTOMRIGHT", -(i-1)*step, 0)
                    UI.SkinActionButton(button)
                end)
            end
            if not UI.stanceHooked and type(StanceBar.UpdateGridLayout) == "function" then
                hooksecurefunc(StanceBar, "UpdateGridLayout", UI.PositionStances)
                UI.stanceHooked = true
            end
        end)
    end)
    UI.stanceBusy = nil
    UI.PositionPetBar()
end

function UI.PositionPetBar()
    if InCombatLockdown() or not PetActionBar or not MultiBarRight or UI.petBarBusy then return end
    UI.petBarBusy = true
    UI.Foreign(PetActionBar, function()
        UI.Foreign(MultiBarRight, function()
            local forms = GetNumShapeshiftForms and GetNumShapeshiftForms() or 0
            if not UI.Public(forms) or type(forms) ~= "number" then forms = 0 end
            local hasStances = forms > 0 and UI.Foreign(StanceBar, function() end)
            PetActionBar:SetScale(1)
            local w,h=barFourButtonSize(PetActionBar)
            if not w then return end
            local step=w+2
            PetActionBar:SetSize(10*step-2,h)
            place(PetActionBar, "RIGHT", hasStances and StanceBar or MultiBarRight, "LEFT", -8, 0)
            for i=1,10 do
                local button = _G["PetActionButton"..i]
                UI.Foreign(button, function()
                    UI.Foreign(button.container, function()
                        button.container:SetScale(1)
                        button.container:SetSize(w, h)
                        place(button.container, "BOTTOMLEFT", PetActionBar, "BOTTOMLEFT", (i-1)*step, 0)
                    end)
                    button:SetScale(1)
                    button:SetSize(w, h)
                    place(button, "BOTTOMLEFT", PetActionBar, "BOTTOMLEFT", (i-1)*step, 0)
                    UI.SkinActionButton(button)
                end)
            end
            if not UI.petBarHooked and type(PetActionBar.UpdateGridLayout) == "function" then
                hooksecurefunc(PetActionBar, "UpdateGridLayout", UI.PositionPetBar)
                UI.petBarHooked = true
            end
        end)
    end)
    UI.petBarBusy = nil
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

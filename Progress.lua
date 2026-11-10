local _, UI = ...
local Style = UI.Style
local Color = Style.Color
local HEIGHT, GAP = 14, 4
-- Retain Blizzard's XP, renown, friendship/paragon, visibility and tooltip logic.
-- Only the two native display containers and their artwork are arranged here.
function UI.PositionProgress()
    local manager = StatusTrackingBarManager
    if not manager or not manager.barContainers or not Minimap or UI.progressBusy or InCombatLockdown() then return end
    UI.progressBusy = true
    pcall(function()
    if manager:IsForbidden() or Minimap:IsForbidden() then return end
    -- Geometrie erst prüfen, dann rechnen: kein Indexieren/Teilen auf geheimen
    -- oder fehlenden Widgetwerten, keine Division durch null.
    local minimapScale, managerScale = Minimap:GetEffectiveScale(), manager:GetEffectiveScale()
    local width = Minimap:GetWidth()
    if not UI.Public(minimapScale) or not UI.Public(managerScale) or not UI.Public(width)
        or type(minimapScale) ~= "number" or type(managerScale) ~= "number" or type(width) ~= "number"
        or managerScale <= 0 or minimapScale <= 0 or width <= 0 then return end
    local scale = minimapScale / managerScale
    for index, container in ipairs(manager.barContainers) do
        if container:IsForbidden() then return end
        container:SetScale(scale)
        container:ClearAllPoints()
        container:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", 0, -5-(index-1)*(HEIGHT+GAP))
        container:SetSize(width, HEIGHT)
        if container.BarFrameTexture then container.BarFrameTexture:SetAlpha(0) end
        for _, bar in pairs(container.bars or {}) do
            if bar:IsForbidden() or (bar.StatusBar and bar.StatusBar:IsForbidden()) then return end
            bar:ClearAllPoints()
            bar:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
            bar:SetSize(width, HEIGHT)
            local status = bar.StatusBar
            if status then
                status:ClearAllPoints()
                status:SetAllPoints(bar)
                status:SetSize(width, HEIGHT)
            end
            if not bar.suiProgressHooked and type(bar.Update) == "function" then
                bar.suiProgressHooked = true
                hooksecurefunc(bar, "Update", UI.PositionProgress)
            end
            if bar.isExpBar then
                if type(bar.UpdateStatusBarTextures) == "function" then
                    bar:UpdateStatusBarTextures(GetRestState() == 1)
                end
                UI.StyleRestedXP(bar)
                if not bar.abuiRestedHooked and bar.ExhaustionTick then
                    bar.abuiRestedHooked = true
                    hooksecurefunc(bar.ExhaustionTick, "UpdateTickPosition", function() UI.StyleRestedXP(bar) end)
                end
            end
            if status then
                status:SetStatusBarTexture(Style.WHITE)
                if bar.isExpBar then
                    if GetRestState()==1 then status:SetStatusBarColor(.25,.48,.72,.85)
                    else status:SetStatusBarColor(.55,.35,.70,.85) end
                else status:SetStatusBarColor(unpack(Color.bronze)) end
                if status.Background then
                    status.Background:SetTexture(Style.WHITE)
                    status.Background:SetVertexColor(unpack(Color.inset))
                end
                if not bar.abuiProgressBorder then
                    local border=UI.Panel(bar,1,1)
                    border:SetAllPoints(bar);border:SetBackdropColor(unpack(Color.transparent))
                    border:EnableMouse(false);bar.abuiProgressBorder=border
                end
            end
            if bar.OverlayFrame and bar.OverlayFrame.Text then
                Style.Font(bar.OverlayFrame.Text, "small", "OUTLINE")
            end
        end
        if not container.suiProgressHooked then
            container.suiProgressHooked = true
            hooksecurefunc(container, "SetPoint", UI.PositionProgress)
            hooksecurefunc(container, "SetSize", UI.PositionProgress)
            hooksecurefunc(container, "SetScale", UI.PositionProgress)
        end
    end
    if not UI.progressHooked and type(manager.UpdateBarVisuals) == "function" then
        UI.progressHooked = true
        hooksecurefunc(manager, "UpdateBarVisuals", UI.PositionProgress)
    end
    end)
    UI.progressBusy = nil
end

function UI.CreateHolyPower()
    local _, class = UnitClass("player")
    if not UI.Public(class) or class ~= "PALADIN" then return end
    local powerType = Enum.PowerType.HolyPower
    local holder = CreateFrame("Frame", "AzerothBuddyUIHolyPower", UI.player)
    holder:SetSize(148, 10)
    holder:SetPoint("BOTTOMLEFT", UI.player, "TOPLEFT", 0, 5)
    holder.segments = {}
    for i=1,5 do
        local segment = CreateFrame("StatusBar", nil, holder)
        segment:SetSize(28, 8)
        segment:SetPoint("LEFT", holder, "LEFT", (i-1)*30, 0)
        UI.StyleStatusBar(segment)
        segment:SetStatusBarColor(1, .78, .18)
        segment:SetMinMaxValues(i-1, i)
        holder.segments[i] = segment
    end
    local function refresh()
        -- No Lua arithmetic/comparisons on resource values, including in combat.
        local power = UnitPower("player", powerType)
        for _, segment in ipairs(holder.segments) do segment:SetValue(power) end
    end
    holder:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
    holder:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    holder:RegisterEvent("PLAYER_ENTERING_WORLD")
    holder:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    holder:SetScript("OnEvent", refresh)
    UI.holyPower = holder
    refresh()
end

-- Keep the rested extension aligned with the native XP tick in the compact bar.
function UI.StyleRestedXP(bar)
    if InCombatLockdown() then return end
    pcall(function()
    if bar:IsForbidden() then return end
    local tick, fill = bar.ExhaustionTick, bar.ExhaustionLevelFillBar
    if not tick or not fill or tick:IsForbidden() or fill:IsForbidden() then return end
    local current, maximum = UnitXP("player"), UnitXPMax("player")
    local rested = GetXPExhaustion()
    if not UI.Public(current) or not UI.Public(maximum) or not UI.Public(rested)
        or type(current) ~= "number" or type(maximum) ~= "number"
        or (rested ~= nil and type(rested) ~= "number") then return end
    -- IsCapped kann einen geschützten Boolean liefern: niemals direkt verzweigen.
    local capped = false
    if bar.IsCapped then
        local value = bar:IsCapped()
        if UI.Public(value) and value == true then capped = true end
    end
    local barWidth = bar:GetWidth()
    if not UI.Public(barWidth) or type(barWidth) ~= "number" or barWidth <= 0 then
        tick:Hide()
        fill:Hide()
        return
    end
    tick:SetAlpha(1)
    fill:SetTexture(Style.WHITE)
    fill:SetVertexColor(.25,.48,.72,.35)
    fill:SetAlpha(1)
    fill:ClearAllPoints()
    fill:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
    if not rested or rested <= 0 or maximum <= 0 or capped then
        tick:Hide()
        fill:Hide()
        return
    end
    local fraction = math.min(1, math.max(0, (current + rested)/maximum))
    fill:SetSize(barWidth*fraction, HEIGHT)
    fill:SetTexCoord(0, fraction, 0, 1)
    fill:Show()
    tick:ClearAllPoints()
    tick:SetPoint("CENTER", bar, "LEFT", barWidth*fraction, 0)
    tick:SetSize(4, HEIGHT+2)
    tick:Show()
    end)
end

function UI.CreateSoulShards()
    local _, class = UnitClass("player")
    if not UI.Public(class) or class ~= "WARLOCK" then return end
    local powerType = Enum.PowerType.SoulShards
    local holder = CreateFrame("Frame", "AzerothBuddyUISoulShards", UI.player)
    holder:SetSize(148, 10)
    holder:SetPoint("BOTTOMLEFT", UI.player, "TOPLEFT", 0, 5)
    holder.segments = {}
    for i=1,5 do
        local segment = CreateFrame("StatusBar", nil, holder)
        segment:SetSize(28, 8)
        segment:SetPoint("LEFT", holder, "LEFT", (i-1)*30, 0)
        UI.StyleStatusBar(segment)
        segment:SetStatusBarColor(.67, .42, .91)
        holder.segments[i] = segment
    end
    local function refresh()
        local spec = C_SpecializationInfo.GetSpecialization()
        local partial = UI.Public(spec) and spec == (SPEC_WARLOCK_DESTRUCTION or 3)
        local step = 1
        if partial then
            local modifier = UnitPowerDisplayMod(powerType)
            if UI.Public(modifier) and modifier and modifier > 0 then step = modifier
            else partial = false end
        end
        -- Scale the public segment bounds, never calculate with secret power.
        local power = UnitPower("player", powerType, partial)
        for i, segment in ipairs(holder.segments) do
            segment:SetMinMaxValues((i-1)*step, i*step)
            segment:SetValue(power)
        end
    end
    holder:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
    holder:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
    holder:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    holder:RegisterEvent("PLAYER_ENTERING_WORLD")
    holder:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    holder:SetScript("OnEvent", refresh)
    UI.soulShards = holder
    refresh()
end

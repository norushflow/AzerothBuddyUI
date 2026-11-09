local _, UI = ...
local L = UI.L
UI.VERSION = "1.0.6"
-- Setup acknowledgement belongs to this character, not the account layout.
function UI.GetCharacterSettings()
    AzerothBuddyUICharDB = AzerothBuddyUICharDB or {}
    return AzerothBuddyUICharDB
end
UI.WHITE = "Interface\\Buttons\\WHITE8X8"
UI.FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
function UI.Public(value)
    return not (issecretvalue and issecretvalue(value))
end
-- Auch Methoden-/Feldauflösung fremder Frames gehört in den Schutzblock.
function UI.Foreign(frame, action)
    if not UI.Public(frame) or not frame then return false end
    return pcall(function()
        local forbidden = frame:IsForbidden()
        if not UI.Public(forbidden) or forbidden then error("forbidden") end
        return action(frame)
    end)
end
function UI.Text(parent, size, point, relative, x, y)
    local text = parent:CreateFontString(nil, "OVERLAY")
    text:SetFont(UI.FONT, size, "")
    text:SetShadowColor(0, 0, 0, .85)
    text:SetShadowOffset(1, -1)
    text:SetPoint(point, relative or parent, point, x or 0, y or 0)
    text:SetTextColor(.92, .95, 1)
    return text
end
function UI.Panel(parent, width, height)
    -- Anchored panels can inherit secret dimensions (especially tooltips).
    -- Solid textures need no size reads or Backdrop OnSizeChanged arithmetic.
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetSize(width, height)
    panel.background = panel:CreateTexture(nil, "BACKGROUND")
    panel.background:SetAllPoints(panel)
    panel.borders = {}
    for _, side in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
        local edge = panel:CreateTexture(nil, "BORDER")
        if side=="TOP" or side=="BOTTOM" then
            edge:SetPoint(side.."LEFT", panel, side.."LEFT", 0, 0)
            edge:SetPoint(side.."RIGHT", panel, side.."RIGHT", 0, 0)
            edge:SetHeight(1)
        else
            edge:SetPoint("TOP"..side, panel, "TOP"..side, 0, -1)
            edge:SetPoint("BOTTOM"..side, panel, "BOTTOM"..side, 0, 1)
            edge:SetWidth(1)
        end
        panel.borders[#panel.borders+1] = edge
    end
    function panel:SetBackdropColor(r,g,b,a)
        self.background:SetColorTexture(r,g,b,a)
    end
    function panel:SetBackdropBorderColor(r,g,b,a)
        for _, edge in ipairs(self.borders) do edge:SetColorTexture(r,g,b,a) end
    end
    panel:SetBackdropColor(.015, .02, .028, .9)
    panel:SetBackdropBorderColor(.10, .12, .15, .72)
    return panel
end
function UI.Message(text)
    print("|cff35bbdfAzerothBuddyUI:|r " .. text)
end
function UI.Anchor(frame, key, point, x, y, relative, relativePoint)
    frame:ClearAllPoints()
    local position = AzerothBuddyUI.positions[key]
    if position then
        frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", position.x, position.y)
    else
        frame:SetPoint(point, relative or UIParent, relativePoint or point, x, y)
    end
end
local events = CreateFrame("Frame")
for _, event in ipairs({
    "PLAYER_LOGIN", "PLAYER_REGEN_ENABLED",
    "DISPLAY_SIZE_CHANGED", "UI_SCALE_CHANGED", "PLAYER_ENTERING_WORLD",
    "GROUP_ROSTER_UPDATE", "ADDON_LOADED",
}) do
    events:RegisterEvent(event)
end

-- Blizzard can apply its own Edit-Mode/bar layout after our handler has already
-- run, which leaves the bars misplaced until the next layout pass (previously
-- the end of the first fight). Reapply shortly after zone, scale and roster
-- changes, but only outside combat.
local REAPPLY = {
    PLAYER_ENTERING_WORLD = true,
    GROUP_ROSTER_UPDATE = true,
    UI_SCALE_CHANGED = true,
    DISPLAY_SIZE_CHANGED = true,
}
function UI.ReapplySoon()
    for _, delay in ipairs({0.6, 2}) do
        C_Timer.After(delay, function()
            if UI.started and not InCombatLockdown() then UI.ApplyLayout() end
        end)
    end
end

local raidState
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        -- The old SavedVariables file is executed before PLAYER_LOGIN. Only
        -- the new name is written on logout; never replace an existing new DB.
        if type(AzerothBuddyUI) ~= "table" then
            AzerothBuddyUI = type(ScreenshotUIDB) == "table" and ScreenshotUIDB or {}
        end
        ScreenshotUIDB = nil
        AzerothBuddyUI.positions = AzerothBuddyUI.positions or {}
        UI.ReportEditLayoutResult()
        if AzerothBuddyUI.enabled == false then return end
        if InCombatLockdown() then UI.pendingStart = true; return end
        UI.Start()
    elseif event == "PLAYER_REGEN_ENABLED" and UI.pendingStart then
        UI.pendingStart = nil
        UI.Start()
    elseif event == "ADDON_LOADED" then
        -- Nachgeladenes Blizzard_EditMode: Schließen-Hook einmalig nachziehen.
        if UI.started then UI.WatchEditMode() end
    elseif UI.started and not InCombatLockdown() then
        if event == "GROUP_ROSTER_UPDATE" then
            UI.QueueNativeGroupMask()
            UI.PositionRaid()
            local raid = (IsInRaid and IsInRaid()) and true or false
            if raid == raidState then return end
            raidState = raid
        end
        UI.ApplyLayout()
        if REAPPLY[event] then UI.ReapplySoon() end
    end
end)
function UI.Start()
    if UI.started then return end
    if not AzerothBuddyUI.rightEdge046 then
        AzerothBuddyUI.positions.minimap=nil
        AzerothBuddyUI.rightEdge046=true
    end
    if not AzerothBuddyUI.bossFocusLayout018 then
        local bossPosition = AzerothBuddyUI.positions.bosses
        if bossPosition then bossPosition.x = bossPosition.x - 360 end
        AzerothBuddyUI.positions.focus = nil
        AzerothBuddyUI.bossFocusLayout018 = true
    end
    if not AzerothBuddyUI.bossFocusLayout019 then
        for _, key in ipairs({"bosses", "focus"}) do
            local position = AzerothBuddyUI.positions[key]
            if position then position.y = position.y - 100 end
        end
        AzerothBuddyUI.bossFocusLayout019 = true
    end
    if not AzerothBuddyUI.combatLayout024 then
        -- Retain the previous group row's height as the centre layout origin.
        local group = AzerothBuddyUI.positions.group
        if group then
            AzerothBuddyUI.positions.combatOrigin = {x=group.x, y=group.y-7}
        end
        for _, key in ipairs({"player", "target", "group", "actions1", "actions2", "actions3"}) do
            AzerothBuddyUI.positions[key] = nil
        end
        AzerothBuddyUI.combatLayout024 = true
    end
    if not AzerothBuddyUI.upperUnits026 then
        AzerothBuddyUI.positions.player = nil
        AzerothBuddyUI.positions.target = nil
        AzerothBuddyUI.upperUnits026 = true
    end
    if not AzerothBuddyUI.combatOffset028 then
        -- Stored positions are absolute; relative attachments follow the block
        -- automatically and must not receive the offset a second time.
        for _, key in ipairs({"combatOrigin", "player", "target", "group", "actions1", "actions2", "actions3"}) do
            local position = AzerothBuddyUI.positions[key]
            if position then position.y = position.y + 10 end
        end
        AzerothBuddyUI.combatOffset028 = true
    end
    if not AzerothBuddyUI.actionTop047 then
        for _,key in ipairs({"actions1","actions2","actions3"}) do
            local position=AzerothBuddyUI.positions[key]
            if position then position.y=position.y+5 end
        end
        AzerothBuddyUI.actionTop047=true
    end
    UI.CreateUnits()
    UI.CreateLayout()
    UI.ApplyLayout()
    UI.started = true
    UI.InstallEquipment()
    raidState = (IsInRaid and IsInRaid()) and true or false
    UI.Message(L["Version 1.0.6 geladen. /abui für Leisten 1–4."])
end
-- Nur auf ausdrücklichen Slash-Aufruf Einstellungen ändern, nie beim Start.
function UI.ConfigureActionBars()
    if InCombatLockdown() then return false end
    local ok = pcall(function()
        assert(Settings and Settings.GetValue and Settings.SetValue, "Settings unavailable")
        assert(C_CVar and C_CVar.GetCVar and C_CVar.SetCVar, "CVar unavailable")
        -- Erst alle Werte prüfen, bevor Einstellungen geschrieben werden.
        local current = {}
        for bar=2,8 do
            local key = "PROXY_SHOW_ACTIONBAR_"..bar
            local value = Settings.GetValue(key)
            assert(UI.Public(value) and type(value)=="boolean", "action bar setting unavailable")
            current[bar] = value
        end
        local cooldown = C_CVar.GetCVar("cooldownViewerEnabled")
        assert(UI.Public(cooldown) and type(cooldown)=="string", "cooldown setting unavailable")
        for bar=2,8 do
            local enabled = bar<=4
            if current[bar]~=enabled then Settings.SetValue("PROXY_SHOW_ACTIONBAR_"..bar,enabled) end
        end
        if cooldown~="0" then C_CVar.SetCVar("cooldownViewerEnabled","0") end
        for bar=2,8 do
            local value = Settings.GetValue("PROXY_SHOW_ACTIONBAR_"..bar)
            assert(UI.Public(value) and value==(bar<=4), "action bar setting rejected")
        end
        local value = C_CVar.GetCVar("cooldownViewerEnabled")
        assert(UI.Public(value) and value=="0", "cooldown setting rejected")
    end)
    if not ok then
        UI.Message(L["Einstellungen konnten nicht vollständig übernommen werden. Bitte Aktionsleisten und Abklingzeitmanager in den WoW-Optionen prüfen."])
        return false
    end
    UI.ApplyLayout()
    UI.ReapplySoon()
    UI.Message(L["Aktionsleisten 1–4 aktiv, 5–8 aus. Abklingzeitmanager deaktiviert. /abui hilfe zeigt die Befehle."])
    return true
end
-- Called only by the explicit setup button after displaying the overwrite warning.
function UI.RunSetup()
    if InCombatLockdown() then UI.Message(L["Bitte nach dem Kampf erneut versuchen."]); return end
    if not UI.EnableEditLayout() then return end
    UI.CompleteEditLayoutSetup(function()
        UI.GetCharacterSettings().welcomeVersion = UI.VERSION
        AzerothBuddyUI.enabled = true
        UI.ShowSetupComplete()
    end)
end

SLASH_AZEROTHBUDDYUI1 = "/abui"
SlashCmdList.AZEROTHBUDDYUI = function(message)
    local command = (message or ""):lower():match("^%s*(.-)%s*$")
    if InCombatLockdown() then UI.Message(L["Bitte nach dem Kampf erneut versuchen."]); return end
    if command == "layoutstatus" then
        UI.PrintEditLayoutStatus()
    elseif command == "blizzard" then
        UI.editLayoutPending = nil
        AzerothBuddyUI.enabled = false
        UI.Message(L["Neustart ohne UI-Eingriffe. Danach Blizzard-Bearbeitungsmodus normal öffnen; zurück mit /abui on."])
        ReloadUI()
    elseif command == "on" then
        UI.ShowWelcome(true)
    elseif command == "off" then
        UI.editLayoutPending = nil
        AzerothBuddyUI.enabled = false
        ReloadUI()
    elseif not UI.started then
        UI.Message(L["Deaktiviert. Mit /abui on einschalten."])
    elseif command == "" then
        UI.ConfigureActionBars()
    elseif command == "raidtest" or command:match("^raidtest%s") then
        UI.RaidTest(command:match("^raidtest%s*(.*)$"))
    elseif command == "reset" then
        AzerothBuddyUI.positions = {}
        UI.ApplyLayout()
    else
        UI.Message(L["/abui reset · raidtest 20 · raidtest off · blizzard · off · on · layoutstatus. /abui setzt Leisten 1–4 und deaktiviert den Abklingzeitmanager."])
    end
end

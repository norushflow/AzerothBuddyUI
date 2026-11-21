local _, UI = ...
local L = UI.L
local Style = UI.Style

-- Selected interface CVars from the reference character for this client.
local preset = {
    alwaysCompareItems = "0",
    autoLootDefault = "1",
    colorChatNamesByClass = "1",
    combinedBags = "1",
    countdownForCooldowns = "1",
    displaySpellActivationOverlays = "0",
    expandBagBar = "0",
    minimapTrackingShowAll = "1",
    nameplateShowAll = "1",
    nameplateShowFriendlyPlayers = "0",
    nameplateShowOnlyNameForFriendlyPlayerUnits = "1",
    nameplateSize = "3",
    nameplateUseClassColorForFriendlyPlayerUnitNames = "1",
    raidFramesDisplayClassColor = "1",
    raidFramesDisplayPowerBars = "1",
    showTargetOfTarget = "1",
    timeMgrUseLocalTime = "1",
    softTargetEnemy = "3",
    tooltipShowAuraSpellIDs = "1",
}

local function skipPreset()
    local character = UI.GetCharacterSettings()
    if character.norushflowPreset == nil then
        character.norushflowPreset = false
    end
end

local function applyPreset()
    if InCombatLockdown() then
        UI.Message(L["Bitte nach dem Kampf erneut versuchen."])
        return
    end

    local get = C_CVar and C_CVar.GetCVar or GetCVar
    local set = C_CVar and C_CVar.SetCVar or SetCVar
    local applied, total = 0, 0
    for name, wanted in pairs(preset) do
        total = total + 1
        local ok, matches = pcall(function()
            local current = get(name)
            if not UI.Public(current) or type(current) ~= "string" then return false end
            if current == wanted then return true end
            set(name, wanted)
            current = get(name)
            return UI.Public(current) and current == wanted
        end)
        if ok and matches then applied = applied + 1 end
    end

    UI.GetCharacterSettings().norushflowPreset = applied > 0
    if applied == total then
        UI.welcome.presetButton:Hide()
        UI.Message(L["Norushflow-Preset übernommen."])
    else
        UI.Message(L["Norushflow-Preset: %d von %d Optionen übernommen. Erneut über das Setup versuchen."]:format(applied, total))
    end
end

local function confirmPreset()
    if InCombatLockdown() then
        UI.Message(L["Bitte nach dem Kampf erneut versuchen."])
        return
    end
    StaticPopupDialogs["AZEROTHBUDDYUI_NORUSHFLOW_PRESET"] = {
        text = L["Das Norushflow-Preset überschreibt ausgewählte WoW-Interface-Optionen, darunter die Zielerfassung für Aktionen, Namensplaketten und Taschen. Manche Änderungen können auch andere Charaktere betreffen. Möchtest du es übernehmen?"],
        button1 = L["Übernehmen"],
        button2 = L["Ohne Preset"],
        OnAccept = applyPreset,
        OnCancel = function()
            skipPreset()
            UI.welcome.presetButton:Hide()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
    StaticPopup_Show("AZEROTHBUDDYUI_NORUSHFLOW_PRESET")
end

function UI.ShowWelcome(force)
    local db = AzerothBuddyUI
    if not db then return end
    local character = UI.GetCharacterSettings()
    if not force and (character.welcomeVersion == UI.VERSION or db.enabled == false) then return end
    if InCombatLockdown() then return end
    if not UI.welcome then
        local panel = CreateFrame("Frame", nil, UIParent)
        panel:SetSize(480, 424)
        Style.Window(panel, 56)
        panel:SetPoint("CENTER", UIParent, "CENTER", 0, 70)
        panel:SetFrameStrata("DIALOG")
        panel:EnableMouse(true)
        panel:SetClampedToScreen(true)
        local title = UI.Text(panel, "title", "TOP", panel, 0, -25, Style.Color.gold)
        title:SetText(L["AzerothBuddyUI einrichten"])
        local warning = UI.Text(panel, "heading", "TOP", panel, 0, -72, Style.Color.danger)
        warning:SetText(L["Vorsicht: Layout wird überschrieben!"])
        local description = UI.Text(panel, "body", "TOP", panel, 0, -104)
        description:SetWidth(480 - 2 * Style.Spacing.panel)
        description:SetWordWrap(true)
        local footer = Style.Divider(panel)
        footer:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", Style.Spacing.panel, 132)
        footer:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -Style.Spacing.panel, 132)
        local setup = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        setup:SetSize(220, 32)
        setup:SetPoint("BOTTOM", panel, "BOTTOM", 0, 42)
        Style.Button(setup)
        local presetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        presetButton:SetSize(252, 30)
        presetButton:SetPoint("BOTTOM", panel, "BOTTOM", 0, 90)
        presetButton:SetText(L["Norushflow-Preset übernehmen"])
        Style.Button(presetButton)
        presetButton:SetScript("OnClick", confirmPreset)
        panel.presetButton = presetButton
        local close = Style.Close(CreateFrame("Button", nil, panel, "UIPanelCloseButton"))
        close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -3, -3)
        close:SetScript("OnClick", function()
            skipPreset()
            panel:Hide()
        end)
        local hint = UI.Text(panel, "small", "BOTTOM", panel, 0, 18, Style.Color.muted)
        hint:SetText(L["Erneut öffnen: /abui on"])
        panel.description = description
        panel.setupButton = setup
        panel.closeButton = close
        UI.welcome = panel
    end
    UI.welcome.description:SetText("Version " .. UI.VERSION .. L["\nLayoutvorlagen für 3440 × 1440, 2560 × 1440 und 1920 × 1080 Pixel.\n\nDas Layout AzerothBuddyUI wird durch die passende Vorlage ersetzt. Eigene Änderungen an diesem Layout gehen verloren. Andere Layouts bleiben erhalten.\n\nBitte vorher den Bearbeitungsmodus schließen."])
    local setup = UI.welcome.setupButton
    setup:SetText(L["One Button Setup"])
    setup:SetScript("OnClick", function()
        skipPreset()
        UI.RunSetup()
    end)
    setup:Show()
    if force or character.norushflowPreset == nil then
        UI.welcome.presetButton:Show()
    else
        UI.welcome.presetButton:Hide()
    end
    UI.welcome:Show()
    character.welcomeVersion = UI.VERSION
end

function UI.ShowSetupComplete()
    UI.Message(L["Layout eingerichtet. Zum Abschließen die UI neu laden oder /reload eingeben."])
    if UI.welcome then
        UI.welcome.presetButton:Hide()
        UI.welcome.description:SetText(L["Layout eingerichtet. Zum Abschließen die UI neu laden oder /reload eingeben."])
        local button = UI.welcome.setupButton
        button:SetText(L["UI neu laden"])
        button:SetScript("OnClick", function()
            if InCombatLockdown() then
                UI.Message(L["Bitte nach dem Kampf erneut versuchen."])
                return
            end
            ReloadUI()
        end)
        button:Show()
        UI.welcome:Show()
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(0, function() UI.ShowWelcome() end)
    else
        UI.ShowWelcome()
    end
end)

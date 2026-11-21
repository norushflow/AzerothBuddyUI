local _, UI = ...
local L = UI.L
local layoutName = "AzerothBuddyUI"
local layoutString = [=[2 52 0 0 0 4 4 UIParent 0.0 -243.7 -1 ##$$%*&''%)$+#,$ 0 1 0 0 6 MainActionBar 0.0 -4.0 -1 ##$$%*&''%(#,$ 0 2 0 8 2 MainActionBar 0.0 4.0 -1 ##$$%*&''%(#,$ 0 3 0 7 7 UIParent 1195.0 2.0 -1 ##$$%/&%'%(#,$ 0 4 1 5 5 UIParent -5.0 -77.0 -1 #$$$%/&('%(#,$ 0 5 1 1 4 UIParent 0.0 0.0 -1 ##$$%/&('%(#,$ 0 6 1 1 4 UIParent 0.0 -50.0 -1 ##$$%/&('%(#,$ 0 7 1 1 4 UIParent 0.0 -100.0 -1 ##$$%/&('%(#,$ 0 10 0 0 0 UIParent 1369.3 -742.1 -1 ##$$&('% 0 11 0 8 6 MultiBarRight -4.0 0.0 -1 ##$$&('%,# 0 12 0 5 3 MinimapCluster -4.0 -44.5 -1 #$$$&('% 1 -1 1 4 4 UIParent 0.0 0.0 -1 ##$#%# 2 -1 1 2 2 UIParent 0.0 0.0 -1 ##$#%(&( 3 0 1 8 7 UIParent -300.0 250.0 -1 $#3# 3 1 1 6 7 UIParent 300.0 250.0 -1 %#3# 3 2 1 6 7 UIParent 520.0 265.0 -1 %#&#3# 3 3 0 0 0 UIParent 1851.0 -940.0 -1 '$(#)#-=.+/#1$3#5#6(7-7$8(9( 3 4 0 0 0 UIParent 1943.0 -928.5 -1 ,%-=.+/#0#1#2(3#5#6(7-7$8(9( 3 5 0 2 2 UIParent -270.0 -293.0 -1 &#*$3# 3 6 1 5 5 UIParent 0.0 0.0 -1 -=.+/#4$5#6(7-7$8(9( 3 7 1 4 4 UIParent 0.0 0.0 -1 3# 4 -1 0 4 4 UIParent 0.0 398.3 -1 # 5 -1 0 4 4 UIParent 473.0 -500.0 -1 # 6 0 1 2 2 UIParent -255.0 -10.0 -1 ##$#%#&.(()( 6 1 0 4 4 UIParent -297.5 -87.5 -1 ##$#%#'+(()(-$ 6 2 1 1 1 UIParent 0.0 -25.0 -1 ##$#%$&.(()(+#,-,$ 7 -1 0 4 4 UIParent 0.0 485.8 -1 # 8 -1 1 6 6 UIParent 35.0 50.0 -1 #'$A%$&i 9 -1 0 5 3 MinimapCluster -4.0 -98.8 -1 # 10 -1 1 0 0 UIParent 16.0 -116.0 -1 # 11 -1 0 5 5 UIParent -2.0 -275.0 -1 # 12 -1 0 3 3 UIParent 32.0 145.6 -1 #K$#%% 13 -1 0 0 0 UIParent 2.0 -0.0 -1 ##$#%/&- 14 -1 0 5 5 UIParent -1.5 -580.8 -1 ##$#%# 15 0 0 5 5 UIParent -39.0 179.7 -1 &- 15 1 0 0 6 Minimap 0.0 -23.0 -1 &- 16 -1 0 2 8 SecondaryStatusTrackingBarContainer 0.0 -4.0 -1 #( 17 -1 1 1 1 UIParent 0.0 -100.0 -1 ## 18 -1 0 2 8 SecondaryStatusTrackingBarContainer 0.0 -4.0 -1 #- 19 -1 1 7 7 UIParent 0.0 0.0 -1 ## 20 0 1 7 7 UIParent 0.0 310.0 -1 ##$/%$&('%(-($)#+$,$-$ 20 1 1 7 7 UIParent 0.0 240.0 -1 ##$*%$&('%(-($)#+$,$-$ 20 2 1 7 7 UIParent 0.0 370.0 -1 ##$$%$&('((-($)#+$,$-$ 20 3 1 7 7 UIParent 420.0 430.0 -1 #$$$%#&('((-($)#*#+$,$-$.-.$ 21 -1 1 7 7 UIParent -410.0 380.0 -1 #$%$&$'((()#*-*$+#,&-$.#/(0#1# 22 0 1 8 7 UIParent -457.0 336.0 -1 #$$$%#&('((#)U*$+%,$-#.#/U0% 22 1 1 1 1 UIParent 0.0 -40.0 -1 &('()U*#+% 22 2 1 1 1 UIParent 0.0 -90.0 -1 &('()U*#+% 22 3 1 1 1 UIParent 0.0 -130.0 -1 &('()U*#+% 23 -1 0 5 5 UIParent -2.0 -480.8 -1 ##$#%$&7&%'7(%)U+$,$-$.(/U 24 -1 1 1 1 UIParent 0.0 -182.0 -1 # 26 -1 1 4 4 UIParent 0.0 0.0 -1 #(]=]
-- Supported 16:9 screens use the supplied common Blizzard Edit Mode export.
local layoutString16x9 = [=[2 52 0 0 0 4 4 UIParent 0.0 -243.7 -1 ##$$%*&''%)$+#,$ 0 1 0 0 6 MainActionBar 0.0 -4.0 -1 ##$$%*&''%(#,$ 0 2 0 8 2 MainActionBar 0.0 4.0 -1 ##$$%*&''%(#,$ 0 3 0 7 7 UIParent 1195.0 2.0 -1 ##$$%/&%'%(#,$ 0 4 1 5 5 UIParent -5.0 -77.0 -1 #$$$%/&('%(#,$ 0 5 1 1 4 UIParent 0.0 0.0 -1 ##$$%/&('%(#,$ 0 6 1 1 4 UIParent 0.0 -50.0 -1 ##$$%/&('%(#,$ 0 7 1 1 4 UIParent 0.0 -100.0 -1 ##$$%/&('%(#,$ 0 10 0 4 4 UIParent 0.0 -158.8 -1 ##$$&('% 0 11 0 8 6 MultiBarRight -4.0 0.0 -1 ##$$&('%,# 0 12 0 5 3 MinimapCluster -4.0 -44.5 -1 #$$$&('% 1 -1 1 4 4 UIParent 0.0 0.0 -1 ##$#%# 2 -1 1 2 2 UIParent 0.0 0.0 -1 ##$#%(&( 3 0 1 8 7 UIParent -300.0 250.0 -1 $#3# 3 1 1 6 7 UIParent 300.0 250.0 -1 %#3# 3 2 1 6 7 UIParent 520.0 265.0 -1 %#&#3# 3 3 0 0 0 UIParent 1851.0 -940.0 -1 '$(#)#-=.+/#1$3#5#6(7-7$8(9( 3 4 0 0 0 UIParent 1349.3 -928.5 -1 ,%-=.+/#0#1#2(3#5#6(7-7$8(9( 3 5 0 2 2 UIParent -270.0 -293.0 -1 &#*$3# 3 6 1 5 5 UIParent 0.0 0.0 -1 -=.+/#4$5#6(7-7$8(9( 3 7 1 4 4 UIParent 0.0 0.0 -1 3# 4 -1 0 4 4 UIParent 0.0 398.3 -1 # 5 -1 0 4 4 UIParent 473.0 -500.0 -1 # 6 0 1 2 2 UIParent -255.0 -10.0 -1 ##$#%#&.(()( 6 1 0 4 4 UIParent -297.5 -87.5 -1 ##$#%#'+(()(-$ 6 2 1 1 1 UIParent 0.0 -25.0 -1 ##$#%$&.(()(+#,-,$ 7 -1 0 4 4 UIParent 0.0 485.8 -1 # 8 -1 1 6 6 UIParent 35.0 50.0 -1 #'$A%$&i 9 -1 0 5 3 MinimapCluster -4.0 -98.8 -1 # 10 -1 1 0 0 UIParent 16.0 -116.0 -1 # 11 -1 0 5 5 UIParent -2.0 -275.0 -1 # 12 -1 0 3 3 UIParent 32.0 145.6 -1 #K$#%% 13 -1 0 0 0 UIParent 2.0 -0.0 -1 ##$#%/&- 14 -1 0 5 5 UIParent -1.5 -580.8 -1 ##$#%# 15 0 0 5 5 UIParent -39.0 179.7 -1 &- 15 1 0 0 6 Minimap 0.0 -23.0 -1 &- 16 -1 0 2 8 SecondaryStatusTrackingBarContainer 0.0 -4.0 -1 #( 17 -1 1 1 1 UIParent 0.0 -100.0 -1 ## 18 -1 0 2 8 SecondaryStatusTrackingBarContainer 0.0 -4.0 -1 #- 19 -1 1 7 7 UIParent 0.0 0.0 -1 ## 20 0 1 7 7 UIParent 0.0 310.0 -1 ##$/%$&('%(-($)#+$,$-$ 20 1 1 7 7 UIParent 0.0 240.0 -1 ##$*%$&('%(-($)#+$,$-$ 20 2 1 7 7 UIParent 0.0 370.0 -1 ##$$%$&('((-($)#+$,$-$ 20 3 1 7 7 UIParent 420.0 430.0 -1 #$$$%#&('((-($)#*#+$,$-$.-.$ 21 -1 1 7 7 UIParent -410.0 380.0 -1 #$%$&$'((()#*-*$+#,&-$.#/(0#1# 22 0 1 8 7 UIParent -457.0 336.0 -1 #$$$%#&('((#)U*$+%,$-#.#/U0% 22 1 1 1 1 UIParent 0.0 -40.0 -1 &('()U*#+% 22 2 1 1 1 UIParent 0.0 -90.0 -1 &('()U*#+% 22 3 1 1 1 UIParent 0.0 -130.0 -1 &('()U*#+% 23 -1 0 5 5 UIParent -2.0 -480.8 -1 ##$#%$&7&%'7(%)U+$,$-$.(/U 24 -1 1 1 1 UIParent 0.0 -182.0 -1 # 26 -1 1 4 4 UIParent 0.0 0.0 -1 #(]=]

function UI.GetEditLayoutTemplate()
    if type(GetPhysicalScreenSize) ~= "function" then return nil end
    local width, height = GetPhysicalScreenSize()
    if issecretvalue and (issecretvalue(width) or issecretvalue(height)) then return nil end
    if width == 3440 and height == 1440 then return layoutString end
    if (width == 2560 and height == 1440) or (width == 1920 and height == 1080) then
        return layoutString16x9
    end
    return nil -- Unknown screen resolutions never silently overwrite a layout.
end


-- Explicit /abui on only; never change the selected layout during login.
function UI.EnableEditLayout()
    if InCombatLockdown() or UI.editLayoutFinalizing then return false end
    local action = L["bereits vorhanden"]
    local ok, failure = pcall(function()
        local api = C_EditMode
        assert(api and type(api.GetLayouts) == "function" and type(api.SetActiveLayout) == "function")
        if C_AddOns and C_AddOns.LoadAddOn then C_AddOns.LoadAddOn("Blizzard_EditMode") end
        local manager = EditModeManagerFrame
        assert(manager and not manager:IsForbidden(), L["Bearbeitungsmodus nicht verfügbar"])
        assert(not manager:IsShown(), L["Bitte Bearbeitungsmodus schließen"])
        local function findLayout()
            -- Use the same indexed list as Blizzard's dropdown (including presets).
            local info = manager.layoutInfo
            assert(type(info) == "table" and type(info.layouts) == "table")
            for index, layout in pairs(info.layouts) do
                if layout.layoutName == layoutName then return index, info.activeLayout end
            end

        end
        local index, active = findLayout()
        local template = UI.GetEditLayoutTemplate()
        assert(template, L["Bildschirmauflösung nicht unterstützt"])
        local replacement = api.ConvertStringToLayoutInfo(template)
        assert(type(replacement) == "table" and type(replacement.systems) == "table" and #replacement.systems > 0, L["Vorlage ungültig"])
        local function copy(value)
            if type(value) ~= "table" then return value end
            local result = {}
            for k, v in pairs(value) do result[k] = copy(v) end
            return result
        end
        -- Keep the active native chat settings when applying the layout template.
        local chatSystem = Enum.EditModeSystem.ChatFrame
        local current = manager.layoutInfo.layouts[api.GetLayouts().activeLayout]
        assert(current and type(current.systems) == "table", L["Layoutdaten nicht verfügbar"])
        for slot = #replacement.systems, 1, -1 do
            if replacement.systems[slot].system == chatSystem then
                table.remove(replacement.systems, slot)
            end
        end
        local hasChat
        for _, system in ipairs(current.systems) do
            if system.system == chatSystem then
                replacement.systems[#replacement.systems + 1] = copy(system)
                hasChat = true
            end
        end
        assert(hasChat, L["Layoutdaten nicht verfügbar"])
        if index then
            assert(type(api.SaveLayouts) == "function", L["Layouts können nicht gespeichert werden"])
            -- Work on the API snapshot, never mutate the manager's cached layout table.
            local saved = api.GetLayouts()
            saved = copy(saved)
            local replaced = false
            for slot, existing in pairs(saved.layouts or {}) do
                if existing.layoutName == layoutName then
                    assert(existing.layoutType ~= Enum.EditModeLayoutType.Preset, L["Blizzard-Vorlagen bleiben unverändert"])
                    replacement.layoutName = layoutName
                    replacement.layoutType = existing.layoutType or Enum.EditModeLayoutType.Account
                    saved.layouts[slot] = replacement
                    replaced = true
                    break
                end
            end
            assert(replaced, L["Layoutdaten nicht verfügbar"])
            api.SaveLayouts(saved)
            action = L["überschrieben"]
        else
            assert(type(manager.ImportLayout) == "function", L["Layoutimport nicht verfügbar"])
            manager:ImportLayout(replacement, Enum.EditModeLayoutType.Account, layoutName)
            action = L["neu importiert"]
            index, active = findLayout()
            assert(index, L["Layout import failed"])
        end
        -- The manager may already show the imported layout before it is active.
        active = api.GetLayouts().activeLayout
        if index ~= active then
            api.SetActiveLayout(index)
            action = action .. L[", ausgewählt"]
        else
            action = action .. L[", bereits aktiv"]
        end
        UI.editLayoutPending = {index=index, action=action}
    end)
    if not ok then
        UI.Message(L["Layout konnte nicht aktiviert werden: "] .. tostring(failure))
    end
    return ok
end

-- Let import notifications settle before committing the explicit setup/reload.
function UI.CompleteEditLayoutSetup(onReady)
    local pending = UI.editLayoutPending
    if not pending or UI.editLayoutFinalizing then return end
    UI.editLayoutFinalizing = true
    local attempts = 0
    local function finish()
        if UI.editLayoutPending ~= pending then UI.editLayoutFinalizing = nil; return end
        local ok, selected = pcall(function()
            assert(not InCombatLockdown(), L["Bitte nach dem Kampf erneut versuchen"])
            local manager = EditModeManagerFrame
            assert(manager and not manager:IsForbidden() and not manager:IsShown(), L["Bitte Bearbeitungsmodus schließen"])
            local layout = manager.layoutInfo.layouts[pending.index]
            assert(layout and layout.layoutName == layoutName, L["Layoutliste hat sich geändert"])
            local active = C_EditMode.GetLayouts().activeLayout
            if attempts == 0 and active ~= pending.index then
                C_EditMode.SetActiveLayout(pending.index)
                return false -- Confirm on the next tick, never reload in a write callback.
            end
            return active == pending.index
        end)
        attempts = attempts + 1
        if ok and not selected and attempts < 5 then
            C_Timer.After(0.1, finish)
            return
        end
        UI.editLayoutFinalizing = nil
        UI.editLayoutPending = nil
        if not ok or not selected then
            UI.Message(L["Layoutauswahl nicht bestätigt. Bitte Einrichtung erneut starten."])
            return
        end
        AzerothBuddyUI.editLayoutResult = pending.action
        onReady()
    end
    C_Timer.After(0, finish)
end

-- One-shot confirmation for the explicit command, surviving its ReloadUI.
function UI.ReportEditLayoutResult()
    local result = AzerothBuddyUI and AzerothBuddyUI.editLayoutResult
    if not result then return end
    AzerothBuddyUI.editLayoutResult = nil
    local ok, activeName = pcall(function()
        local info = EditModeManagerFrame and EditModeManagerFrame.layoutInfo or C_EditMode.GetLayouts()
        local layout = info.layouts[info.activeLayout]
        return layout and layout.layoutName
    end)
    if ok and activeName == layoutName then
        UI.Message(L["Layout-Import: "] .. result .. L[". Nach Reload aktiv: "] .. activeName .. ".")
    else
        UI.Message(L["Layout-Import: "] .. result .. L[". Nach Reload nicht bestätigt; aktives Layout: "] .. (ok and tostring(activeName) or L["nicht lesbar"]) .. ".")
    end
end

-- Read-only diagnosis without a reload, including when the addon is disabled.
function UI.PrintEditLayoutStatus()
    UI.Message(L["Layoutstatus: Import-Erweiterung geladen (Diagnose 2)."])
    local ok, failure = pcall(function()
        assert(C_EditMode and type(C_EditMode.GetLayouts) == "function", L["Layout-API fehlt"])
        local info = EditModeManagerFrame and EditModeManagerFrame.layoutInfo or C_EditMode.GetLayouts()
        assert(type(info) == "table" and type(info.layouts) == "table", L["Layoutliste nicht verfügbar"])
        UI.Message(L["Aktiver Layoutindex: "] .. tostring(info.activeLayout))
        local found = false
        for index, layout in pairs(info.layouts) do
            if type(layout) == "table" then
                UI.Message("Layout " .. tostring(index) .. ": " .. tostring(layout.layoutName)
                    .. (index == info.activeLayout and L[" [aktiv]"] or ""))
                if layout.layoutName == layoutName then found = true end
            end
        end
        UI.Message(L["AzerothBuddyUI-Layout: "] .. (found and L["vorhanden"] or L["fehlt"]))
    end)
    if not ok then UI.Message(L["Layoutstatus: "] .. tostring(failure)) end
end

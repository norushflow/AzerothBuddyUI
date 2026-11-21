local loadfile = dofile("tests/load_locales.lua")
local UI = {}
local frames, timers = {}, {}
local combat, reloads, imports, bars = false, 0, 0, 0
local allowImport, allowBars = true, true
local methods = {}
for _, method in ipairs({"SetSize", "SetWidth", "SetHeight", "SetWordWrap", "SetTextColor",
    "SetFrameStrata", "EnableMouse", "SetClampedToScreen", "RegisterEvent", "SetAllPoints", "SetTexture",
    "SetColorTexture", "SetShadowColor", "SetShadowOffset", "ClearAllPoints", "SetDrawLayer", "SetTexCoord"}) do
    methods[method] = function() end
end
function methods:SetPoint(...) self.point={...} end
function methods:SetColorTexture(...) self.color={...} end
function methods:SetSize(w,h) self.width,self.height=w,h end
function methods:SetVertexColor(...) self.tint={...} end
function methods:SetText(text) self.text=text end
function methods:SetFont(path, size) self.fontPath, self.fontSize = path, size; return true end
function methods:SetScript(event, callback) self[event] = callback end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function CreateFrame()
    local frame = setmetatable({}, {__index=methods})
    frames[#frames+1] = frame
    return frame
end
methods.CreateTexture = CreateFrame
methods.CreateFontString = CreateFrame
for _, state in ipairs({"Normal", "Pushed", "Disabled", "Highlight"}) do
    methods["Set"..state.."Texture"] = function(self, path)
        self[state] = CreateFrame()
        self[state].path = path
    end
    methods["Get"..state.."Texture"] = function(self) return self[state] end
end
function methods:GetFontString()
    self.label = self.label or CreateFrame()
    return self.label
end
UIParent = {}
SlashCmdList = {}
function InCombatLockdown() return combat end
function ReloadUI() reloads = reloads + 1 end
C_Timer = {After=function(_, callback) timers[#timers+1] = callback end}
assert(loadfile("Core.lua"))("AzerothBuddyUI", UI)
local toc=assert(io.open("AzerothBuddyUI.toc","r")):read("*a")
assert(toc:match("## Version: ([^\r\n]+)")==UI.VERSION, "setup version must match TOC")
UI.Message = function() end
local barsEnabled, barWrites = false, 0
function GetActionBarToggles()
    return barsEnabled, barsEnabled, barsEnabled, false, true, false, true
end
function SetActionBarToggles(bar2, bar3, bar4, bar5, bar6, bar7, bar8)
    assert(bar2 and bar3 and bar4 and not combat)
    assert(bar5 == false and bar6 == true and bar7 == false and bar8 == true)
    barWrites = barWrites + 1
end
local viewer, viewerWrites = "1", 0
C_CVar = {
    GetCVar = function(key)
        assert(key == "cooldownViewerEnabled")
        return viewer
    end,
    SetCVar = function(key, value)
        assert(key == "cooldownViewerEnabled" and value == "0" and not combat)
        viewer = value
        viewerWrites = viewerWrites + 1
    end,
}
UI.CompleteEditLayoutSetup = function(callback) callback() end
UI.EnableEditLayout = function() imports = imports + 1; return allowImport end
UI.EnableActionBars = function() bars = bars + 1; return allowBars end
assert(loadfile("Welcome.lua"))("AzerothBuddyUI", UI)
local events = frames[#frames]
AzerothBuddyUI = {positions={}}
events.OnEvent(events, "PLAYER_LOGIN")
assert(not UI.welcome and #timers == 1, "login must defer and not install")
combat = true
timers[1]()
assert(not UI.welcome and (not AzerothBuddyUICharDB or not AzerothBuddyUICharDB.welcomeVersion), "combat login waits")
combat = false
events.OnEvent(events, "PLAYER_REGEN_ENABLED")
assert(UI.welcome.shown and AzerothBuddyUICharDB.welcomeVersion, "welcome shown once after combat")
assert(UI.welcome.setupButton.label.fontPath == "Interface\\AddOns\\AzerothBuddyUI\\Media\\Expressway.ttf")
assert(UI.welcome.description.fontPath == UI.welcome.setupButton.label.fontPath and UI.welcome.description.fontSize == 13)
local fill = UI.welcome.setupButton.Normal
assert(fill.path == UI.Style.WHITE and fill.tint[1] == UI.Style.Color.button[1])
assert(UI.welcome.width==480 and UI.welcome.height==424 and UI.welcome.point[5]==70,
    "dark styling must preserve setup window placement")
assert(UI.welcome.background.color[1]==UI.welcome.background.color[2]
    and UI.welcome.background.color[2]==UI.welcome.background.color[3]
    and UI.welcome.background.color[4]<1 and #UI.welcome.borders==4)
assert(UI.welcome.closeButton.Normal.path==UI.Style.WHITE
    and UI.welcome.closeButton.Normal.tint[1]==fill.tint[1], "close and setup share the dark fill")
for _,frame in ipairs(frames) do
    if frame.text == UI.L["AzerothBuddyUI einrichten"] then assert(frame.point[5] == -25) end
end
assert(imports == 0 and bars == 0 and reloads == 0, "showing must not configure")
local warning=false
for _,frame in ipairs(frames) do if frame.text=="Vorsicht: Layout wird überschrieben!" then warning=true end end
assert(warning and UI.welcome.description.text:find("gehen verloren",1,true), "overwrite warning must be visible before setup")
combat = true
UI.welcome.setupButton.OnClick()
assert(imports == 0 and reloads == 0, "setup must respect combat guard")
combat = false
allowImport = false
UI.welcome.setupButton.OnClick()
assert(reloads == 0 and UI.welcome.shown and barWrites == 0 and viewerWrites == 0, "failed layout setup must not change Blizzard options")
allowImport = true
UI.welcome.setupButton.OnClick()
assert(barWrites == 1 and viewerWrites == 0 and UI.welcome.setupButton.text ~= UI.L["UI neu laden"],
    "setup waits for the server to confirm all requested action bars")
barsEnabled = true
table.remove(timers)()
assert(reloads == 0 and AzerothBuddyUI.enabled and AzerothBuddyUICharDB.welcomeVersion, "setup must not reload from completion callback")
assert(UI.welcome.description.text:find("/reload",1,true) and UI.welcome.setupButton.shown, "completion shows the reload button")
assert(UI.welcome.setupButton.text == UI.L["UI neu laden"])
assert(barsEnabled and barWrites == 1, "confirmed setup enables action bars 2 to 4 in one write")
assert(viewer == "0" and viewerWrites == 1, "confirmed layout setup disables only the Cooldown Manager CVar")
combat = true
UI.welcome.setupButton.OnClick()
assert(reloads == 0, "reload button must respect combat guard")
combat = false
UI.welcome.setupButton.OnClick()
assert(reloads == 1, "only the button click triggers UI reload")
UI.welcome.closeButton.OnClick()
events.OnEvent(events, "PLAYER_REGEN_ENABLED")
assert(not UI.welcome.shown, "dismissed welcome must not reopen")
AzerothBuddyUICharDB = {}
AzerothBuddyUI = {enabled=false}
UI.ShowWelcome()
assert(not UI.welcome.shown and not AzerothBuddyUICharDB.welcomeVersion, "disabled addon stays quiet")
AzerothBuddyUI = {positions={}}
local before=imports
SlashCmdList.AZEROTHBUDDYUI("on")
assert(UI.welcome.shown and imports==before, "on opens warning without overwriting")
UI.welcome.closeButton.OnClick()
UI.ShowWelcome()
assert(not UI.welcome.shown, "same version stays dismissed")
UI.VERSION="99.0.0"
UI.ShowWelcome()
assert(UI.welcome.shown and AzerothBuddyUICharDB.welcomeVersion=="99.0.0", "version update reopens setup")
UI.welcome.closeButton.OnClick()
AzerothBuddyUICharDB={}
AzerothBuddyUI={positions={},welcomeSeen=true}
UI.ShowWelcome()
assert(UI.welcome.shown, "old boolean does not suppress version setup")

print("PASS: first-login setup, combat deferral, no automatic configuration, retry, dismissal and manual setup")

assert(toc:find("## SavedVariablesPerCharacter: AzerothBuddyUICharDB",1,true))
UI.welcome.closeButton.OnClick()
local firstCharacter=AzerothBuddyUICharDB
AzerothBuddyUI.welcomeVersion=UI.VERSION
AzerothBuddyUICharDB=nil
UI.ShowWelcome()
assert(UI.welcome.shown and AzerothBuddyUICharDB~=firstCharacter, "new character must show setup despite account acknowledgement")
local secondCharacter=AzerothBuddyUICharDB
UI.welcome.closeButton.OnClick()
AzerothBuddyUICharDB=firstCharacter
UI.ShowWelcome()
assert(not UI.welcome.shown, "returning character keeps its own acknowledgement")
UI.VERSION="100.0.0"
UI.ShowWelcome()
assert(UI.welcome.shown and firstCharacter.welcomeVersion==UI.VERSION)
UI.welcome.closeButton.OnClick()
AzerothBuddyUICharDB=secondCharacter
UI.ShowWelcome()
assert(UI.welcome.shown and secondCharacter.welcomeVersion==UI.VERSION, "update must show independently on each character")
UI.welcome.closeButton.OnClick()
UI.ShowWelcome()
assert(not UI.welcome.shown, "reload on same character/version must stay quiet")
print("PASS: per-character persistence, new character, account migration, returning character and version update on both characters")

for _, mode in ipairs({"missing", "error", "koKR", "zhCN", "zhTW"}) do
    local previousLocale = GetLocale
    GetLocale = function() return mode end
    local namespace = {}
    assert(loadfile("Style.lua"))("AzerothBuddyUI", namespace)
    local probes = 0
    local region = {SetFont=function(self, path)
        if path:find("Expressway", 1, true) then
            probes = probes + 1
            if mode == "error" then error("missing font") end
            return false
        end
        self.path = path
        return true
    end}
    namespace.Style.Font(region, "body")
    namespace.Style.Font(region, "small")
    assert(region.path=="Fonts\\FRIZQT__.TTF" and probes==((mode=="missing" or mode=="error") and 1 or 0),
        "font fallback must be cached and retain locale support")
    GetLocale = previousLocale
end
print("PASS: dark window/control styling, preserved geometry and optional font fallback")

-- Preset consent is independent of layout setup and addon version.
StaticPopupDialogs = {}
local dialog
function StaticPopup_Show(key) dialog = assert(StaticPopupDialogs[key]) end
local values, writes = {nameplateShowFriendlyPlayers = "1"}, 0
C_CVar = {
    GetCVar = function(key) return values[key] or "0" end,
    SetCVar = function(key, value)
        writes = writes + 1
        values[key] = value
    end,
}
AzerothBuddyUICharDB = {}
local beforePreset = imports
UI.ShowWelcome()
assert(UI.welcome.presetButton.shown and AzerothBuddyUICharDB.norushflowPreset == nil and writes == 0)
UI.welcome.presetButton.OnClick()
assert(dialog.text and writes == 0, "opening the confirmation must not write CVars")
dialog.OnCancel()
assert(AzerothBuddyUICharDB.norushflowPreset == false and writes == 0)
UI.welcome.closeButton.OnClick()
UI.VERSION = "101.0.0"
UI.ShowWelcome()
assert(not UI.welcome.presetButton.shown, "declined preset is not offered again on a patch")
UI.ShowWelcome(true)
assert(UI.welcome.presetButton.shown, "manual setup lets the user reconsider")
UI.welcome.presetButton.OnClick()
combat = true
dialog.OnAccept()
assert(writes == 0, "confirmation in combat must not write CVars")
combat = false
UI.welcome.presetButton.OnClick()
dialog.OnAccept()
assert(values.autoLootDefault == "1" and values.showTargetOfTarget == "1" and AzerothBuddyUICharDB.norushflowPreset == true)
assert(values.softTargetEnemy == "3", "confirmed preset enables Action Targeting")
assert(values.nameplateShowFriendlyPlayers == "0", "confirmed preset disables friendly player nameplates")
assert(imports == beforePreset and not UI.welcome.presetButton.shown, "preset does not touch Edit Mode")
local appliedWrites = writes
UI.VERSION = "102.0.0"
UI.ShowWelcome()
assert(not UI.welcome.presetButton.shown and writes == appliedWrites, "patch cannot reapply consent")
print("PASS: preset opt-in, confirmation, combat guard, and persistent patch-independent decision")

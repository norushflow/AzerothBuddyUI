local loadfile = dofile("tests/load_locales.lua")
local UI = {}
local frames, timers = {}, {}
local combat, reloads, imports, bars = false, 0, 0, 0
local allowImport, allowBars = true, true
local methods = {}
for _, method in ipairs({"SetSize", "SetWidth", "SetHeight", "SetWordWrap", "SetTextColor",
    "SetFrameStrata", "EnableMouse", "SetClampedToScreen", "RegisterEvent", "SetAllPoints", "SetTexture",
    "SetColorTexture", "SetShadowColor", "SetShadowOffset", "ClearAllPoints", "SetDrawLayer"}) do
    methods[method] = function() end
end
function methods:SetPoint(...) self.point={...} end
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
for _, state in ipairs({"Normal", "Pushed", "Disabled"}) do
    methods["Set"..state.."Atlas"] = function(self, atlas)
        self[state] = CreateFrame()
        self[state].atlas = atlas
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
assert(fill.atlas == "UI-HUD-CoolDownManager-Bar" and fill.tint[1] == UI.Style.Color.button[1])
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
assert(reloads == 0 and UI.welcome.shown, "failed setup stays retryable")
allowImport = true
UI.welcome.setupButton.OnClick()
assert(reloads == 0 and AzerothBuddyUI.enabled and AzerothBuddyUICharDB.welcomeVersion, "setup must not reload from completion callback")
assert(UI.welcome.description.text:find("/reload",1,true) and not UI.welcome.setupButton.shown, "completion asks for manual reload")
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

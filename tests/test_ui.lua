-- Run from the workspace root: luajit AzerothBuddyUI/tests/test_ui.lua
local combat = false
local objects = {}
local methods = {}
local function object(name, parent, kind)
    local obj = setmetatable({name=name, parent=parent, kind=kind, scripts={}, events={}, shown=true, width=100, height=30, scale=1}, {__index=methods})
    objects[#objects+1]=obj
    if name then _G[name]=obj end
    return obj
end
local function protected(self)
    assert(not (combat and self.secure), "protected mutation in combat")
end
for _, name in ipairs({"SetGradient", "SetShadowColor", "SetShadowOffset", "SetBackdrop", "SetBackdropColor", "SetBackdropBorderColor", "SetFont", "SetWidth", "SetWordWrap", "SetJustifyH", "SetColorTexture", "SetStatusBarTexture", "RegisterForDrag", "RegisterForClicks", "SetMovable", "SetClampedToScreen", "SetFrameStrata", "SetMaskTexture", "SetOwner", "SetUnit", "SetTexture", "SetVertexColor", "SetUnitAura", "RemoveMaskTexture"}) do
    methods[name]=function() end
end
function methods:SetTexCoord(...) self.texcoord={...} end
function methods:SetTexture(value) self.tex=value end
function methods:GetTexture() return self.tex end
function methods:SetStatusBarColor(r,g,b) self.statusColor={r,g,b} end
function methods:SetAlpha(v) self.alpha=v end
function methods:SetTextColor(r,g,b,a) self.textColor={r,g,b,a} end
function methods:EnableMouse(v) self.mouse=v end
function methods:SetPoint(...)
    protected(self); self.point={...}
    -- Blizzard's EditModeSystemMixin:SetPointOverride exists only on EditMode
    -- system frames and registers the relative system as a snap.
    local relative=select(2,...)
    if self.AddSnappedFrame and type(relative)=="table" and relative.AddSnappedFrame then
        relative:AddSnappedFrame(self); self.snappedToFrame=relative
    end
end
function methods:ClearAllPoints()
    protected(self); self.point=nil
    -- Blizzard's ClearAllPointsOverride also drops the EditMode snap.
    if type(self.ClearFrameSnap)=="function" then self:ClearFrameSnap() end
end
-- Blizzard's EditModeSystemMixin snap contract for native system frames.
local function editModeSystem(frame)
    frame.snappedFrames={}
    function frame:AddSnappedFrame(other) self.snappedFrames[other]=true end
    function frame:RemoveSnappedFrame(other) self.snappedFrames[other]=nil end
    function frame:ClearFrameSnap()
        if self.snappedToFrame then
            self.snappedToFrame:RemoveSnappedFrame(self); self.snappedToFrame=nil
        end
    end
end
function methods:SetSize(w,h) protected(self); self.width=w;self.height=h end
function methods:SetHeight(h) self.height=h end
function methods:SetColorTexture(...) self.color={...} end
function methods:SetBackdrop(info) self.backdropInfo=info end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetAllPoints(f) self.all=f end
function methods:GetCenter() return 500, 200 end
function methods:GetEffectiveScale() return self.scale end
function methods:SetScale(s) protected(self);self.scale=s end
function methods:GetChildren()
    local children={}
    for _,obj in ipairs(objects) do if obj.parent==self and obj.kind~="texture" and obj.kind~="font" then children[#children+1]=obj end end
    return unpack(children)
end
function methods:IsForbidden() return self.forbidden or false end
function methods:IsProtected() return self.secure or false end
function methods:IsObjectType(kind) return self.kind==kind end
function methods:GetName() return self.name end
function methods:GetScript(script) return self.scripts[script] end
function methods:SetIgnoreParentAlpha(value) self.ignoreParentAlpha=value end
function methods:GetRegions()
    local regions={}
    for _,obj in ipairs(objects) do
        if obj.parent==self and (obj.kind=="texture" or obj.kind=="font") then regions[#regions+1]=obj end
    end
    return unpack(regions)
end
function methods:GetParent() return self.parent end
function methods:GetFont() return "test",12,"" end
function methods:SetFont(font,size,flags) self.fontSize=size end
function methods:SetCheckedTexture(path) self.checkedTexture=object(nil,self); self.checkedTexture.path=path end
function methods:SetHighlightTexture(path) self.highlightTexture=object(nil,self); self.highlightTexture.path=path end
function methods:SetPushedTexture(path) self.pushedTexture=object(nil,self); self.pushedTexture.path=path end
function methods:GetCheckedTexture() return self.checkedTexture end
function methods:GetHighlightTexture() return self.highlightTexture end
function methods:GetPushedTexture() return self.pushedTexture end
function methods:SetTimerDuration(duration, interpolation, direction) self.duration=duration;self.direction=direction end
function methods:GetNormalTexture() return nil end
function methods:GetFrameLevel() return self.level or 1 end
function methods:SetFrameLevel(v) self.level=v end
function methods:SetFrameStrata(v) self.strata=v end
function methods:SetParent(p) protected(self);self.parent=p end
function methods:CreateFontString() return object(nil,self,"font") end
function methods:CreateTexture() return object(nil,self,"texture") end
function methods:SetText(v) self.text=v end
function methods:SetFormattedText(fmt, ...) self.format=fmt;self.values={...} end
function methods:SetMinMaxValues(a,b) self.min=a;self.max=b end
function methods:SetValue(v) self.value=v end
function methods:SetStatusBarTexture(v) self.texture=v end
function methods:SetAttribute(k,v) protected(self);self[k]=v end
function methods:SetScript(k,v) self.scripts[k]=v end
function methods:HookScript(k,v)
    local previous=self.scripts[k]
    self.scripts[k]=function(...) if previous then previous(...) end;v(...) end
end
function methods:RegisterEvent(e) self.events[e]=true end
function methods:RegisterUnitEvent(e,u) self.events[e]=u end
-- Model the relevant protection propagation: secure frames also protect their
-- parent/anchor dependencies. A visual cast bar must never be such an anchor.
local function dependsOn(frame, target, seen)
    if frame==target then return true end
    if not frame or frame==UIParent or seen[frame] then return false end
    seen[frame]=true
    return dependsOn(frame.parent,target,seen)
        or (frame.point and type(frame.point[2])=="table" and dependsOn(frame.point[2],target,seen))
        or (type(frame.all)=="table" and dependsOn(frame.all,target,seen))
end
local function protectVisibility(frame)
    if not combat then return end
    for _,candidate in ipairs(objects) do
        assert(not (candidate.secure and dependsOn(candidate,frame,{})),
            "protected visibility change through a secure parent/anchor dependency")
    end
end
function methods:Hide() protectVisibility(self); self.shown=false end
function methods:Show() protectVisibility(self); self.shown=true end
function methods:IsShown() return self.shown end
function methods:StartMoving() protected(self); self.moving=true end
function methods:StopMovingOrSizing() protected(self);self.moving=false end
function CreateFrame(kind,name,parent,template)
    local f=object(name,parent,kind)
    f.secure=template and template:find("Secure")
    f.template=template
    if template and template:find("BackdropTemplate",1,true) then
        -- Relevant native contract: the template does arithmetic on resize,
        -- outside the pcall that originally created/anchored the panel.
        f.scripts.OnSizeChanged=function(self)
            if self.backdropInfo then
                local repeatX=self:GetWidth()/self.backdropInfo.edgeSize
                local repeatY=self:GetHeight()/self.backdropInfo.edgeSize
                self.backdropUV={repeatX,repeatY}
            end
        end
    end
    assert(template~="TargetSpellBarTemplate", "addon-owned Blizzard cast mixin reintroduced")
    return f
end
UIParent=object("UIParent");UIParent.width=1920;UIParent.height=1080
function InCombatLockdown() return combat end
function RegisterStateDriver(frame, state, condition) assert(not combat); frame[state.."Driver"]=condition end
local secret=setmetatable({}, {__tostring=function() error("secret stringify") end, __div=function() error("secret arithmetic") end})
function issecretvalue(v) return v==secret end
function UnitHealth() return secret end
function UnitHealthMax() return secret end
function UnitPower() return secret end
function UnitPowerMax() return secret end
function UnitHealthPercent() return secret end
function UnitName() return secret end
function UnitClass(unit) if unit=="player" then return "Paladin", "PALADIN" end return nil, secret end
Enum={PowerType={HolyPower=9}, LuaCurveType={Linear=0, Step=1}, StatusBarInterpolation={Immediate=0}, StatusBarTimerDirection={ElapsedTime=0,RemainingTime=1}}
C_CurveUtil={CreateCurve=function()
    local curve={points={}}
    function curve:SetType(kind) self.curveType=kind end
    function curve:AddPoint(x,y) self.points[#self.points+1]={x,y} end
    return curve
end}
local castMode = "none"
function UnitCastingInfo()
    if castMode=="cast" then return secret,nil,secret,secret,secret,false,secret,secret,secret,42 end
end
function UnitChannelInfo()
    if castMode=="channel" or castMode=="empower" then return secret,nil,secret,secret,secret,false,secret,secret,castMode=="empower",3,43 end
end
function UnitCastingDuration() return secret end
function UnitChannelDuration() return secret end
function GetNumShapeshiftForms() return 3 end
function UnitPowerType() return 0, secret end
function UnitGroupRolesAssigned() return secret end
local inRaid=false
local raidCount=0
function GetNumGroupMembers() return raidCount end
function IsInRaid() return inRaid end
RAID_CLASS_COLORS={PALADIN={r=.96,g=.55,b=.73},MAGE={r=.25,g=.78,b=.92}};PowerBarColor={};CurveConstants={ScaleTo100={}}
local deferred={}
local tickers={}
C_Timer={After=function(_,callback) deferred[#deferred+1]=callback end, NewTicker=function(interval,callback)
    -- Model the documented ticker contract: Cancel stops further runs.
    local ticker={interval=interval, callback=callback, active=true}
    function ticker:Cancel() self.active=false; self.cancelled=true end
    tickers[#tickers+1]=ticker
    return ticker
end}
function CreateColor(...) return {...} end
function GetGameTime() return 16,35 end
local restedXP, xpCurrent, xpMaximum, restState = 400, 200, 1000, 1
function GetRestState() return restState end
function GetXPExhaustion() return restedXP end
function UnitXP() return xpCurrent end
function UnitXPMax() return xpMaximum end
function GetMoney() return 123456 end
function GetZoneText() return "Testzone" end
function BreakUpLargeNumbers(v) return tostring(v) end
local aurasRestricted = false
local auraReads = 0
C_Secrets={ShouldAurasBeSecret=function() return aurasRestricted end}
C_UnitAuras={GetAuraDataByIndex=function(_,index)
    assert(not combat and not aurasRestricted, "restricted aura API called")
    auraReads=auraReads+1
    if index==1 then return {icon=secret} end
end}
Enum.RaidAuraOrganizationType={Legacy=0}
Enum.RaidDispelDisplayType={Disabled=0,DisplayAll=1,DispellableByMe=2}
Enum.RaidDispelOverlayType={UseDebuffColor=0}
CompactRaidGroupTypeEnum={Party=4,Raid=5}
local nativeAuraAnchors={}
C_UnitAuras.AddPrivateAuraAnchor=function(args)
    assert(not combat, "native aura container created during combat")
    assert(type(args.unitToken)=="string" and args.isContainer==true and args.auraIndex==1)
    assert(args.showCooldownFrame and args.showCountdownNumbers and args.showDispelIcon)
    assert(args.parent.parent.unit==args.unitToken and args.iconInfo.iconAnchor.relativeTo==args.parent)
    for _,key in ipairs({"max-buffs","max-debuffs","max-dispel-debuffs","aura-organization-type",
        "debuff-size","buff-size","debuff-border-scale","buff-border-scale","power-bar-used-height",
        "group-type","dispel-indicator-option","dispel-indicator-overlay-type"}) do
        assert(type(args.parent[key])=="number", "missing native container setting: "..key)
    end
    assert(args.parent["max-debuffs"]==3 and args.parent["max-buffs"]==0)
    nativeAuraAnchors[#nativeAuraAnchors+1]=args
    return #nativeAuraAnchors
end
function methods:SetUnitAura()
    assert(not combat and not aurasRestricted, "restricted aura tooltip called")
end
GameTooltip=object("GameTooltip");GameMenuFrame=object("GameMenuFrame")
function methods:SetOwner(owner,anchor) self.owner=owner;self.ownerAnchor=anchor end
function methods:SetUnit(unit) self.tooltipUnit=unit end
function methods:SetBackdropColor(...) self.backdropColor={...} end
function methods:SetBackdropBorderColor(...) self.borderColor={...} end
local originalTooltipShow=0
GameTooltip.scripts.OnShow=function() originalTooltipShow=originalTooltipShow+1 end
for _,name in ipairs({"GameTooltip","ItemRefTooltip","ShoppingTooltip1","ShoppingTooltip2","ItemRefShoppingTooltip1","ItemRefShoppingTooltip2"}) do
    local tooltip=_G[name] or object(name,UIParent)
    tooltip.NineSlice=object(nil,tooltip)
end
function GameTooltip_SetDefaultAnchor(tooltip,owner)
    tooltip:SetOwner(owner,"ANCHOR_NONE")
    tooltip.defaultOwner=owner
end
function SharedTooltip_SetBackdropStyle(tooltip) tooltip.NineSlice:SetAlpha(1) end

SlashCmdList={}
local reloads=0
function ReloadUI() reloads=reloads+1 end
function HideUIPanel(f) f:Hide() end
function ShowUIPanel(f) f:Show() end
for _,name in ipairs({"FocusFrame","Boss1TargetFrame","Boss2TargetFrame","Boss3TargetFrame","Boss4TargetFrame","Boss5TargetFrame","TargetFrameToT","WarlockPowerFrame","MultiBarRight","MainActionBar","MultiBarBottomLeft","MultiBarBottomRight","ChatFrame1","Minimap","MinimapCluster","BuffFrame","MicroMenuContainer","PlayerFrame","TargetFrame","PartyFrame","CompactPartyFrame","CompactRaidFrameContainer","CompactRaidFrameManager","PetFrame","PlayerCastingBarFrame","PetActionBar","StanceBar","EditModeManagerFrame"}) do object(name,UIParent) end
for _,frame in ipairs({MainActionBar,MultiBarRight,MultiBarBottomLeft,MultiBarBottomRight,PetActionBar,StanceBar,ChatFrame1,Minimap,MinimapCluster,BuffFrame}) do editModeSystem(frame) end
Minimap:SetSize(198,198) -- native retail geometry
local nativeClockClicks=0
TimeManagerClockButton=object("TimeManagerClockButton",MinimapCluster,"Button")
TimeManagerClockButton.scripts.OnClick=function(self,mouse)
    assert(self==TimeManagerClockButton and mouse=="LeftButton")
    nativeClockClicks=nativeClockClicks+1
end
GameTimeFrame=object("GameTimeFrame",MinimapCluster,"Button")
local minimapIcon=object("LibDBIcon10_TestAddon",Minimap,"Button")
minimapIcon.width=32;minimapIcon.height=32
local iconClicks=0
minimapIcon.scripts.OnClick=function() iconClicks=iconClicks+1 end
local buddyIcon=object("AzerothBuddyMinimapButton",Minimap,"Button")
buddyIcon.width=32;buddyIcon.height=32
local zygorIcon=object("ZygorGuidesViewerMapIcon",UIParent,"Button")
zygorIcon.width=32;zygorIcon.height=32
local buddyClicks,zygorClicks=0,0
buddyIcon.scripts.OnClick=function() buddyClicks=buddyClicks+1 end
zygorIcon.scripts.OnClick=function() zygorClicks=zygorClicks+1 end

local secureIcon=object("LibDBIcon10_SecureAddon",Minimap,"Button")
secureIcon.width=32;secureIcon.height=32;secureIcon.secure=true
local forbiddenIcon=object("LibDBIcon10_ForbiddenAddon",Minimap,"Button")
forbiddenIcon.forbidden=true
local specialIcons={}
for _,name in ipairs({"BugSack","RXPGuides"}) do
    local button=object("LibDBIcon10_"..name,Minimap,"Button")
    button.width=32;button.height=32
    button.icon=button:CreateTexture()
    button.icon:SetTexture("initial-"..name)
    button.scripts.OnClick=function(self,mouse)
        assert(self==button and (mouse=="RightButton" or mouse=="LeftButton"))
        self.originalClick=true
        self.lastMouse=mouse
    end
    button.scripts.OnEnter=function(self) self.originalEnter=true end
    button.scripts.OnLeave=function(self) self.originalLeave=true end
    specialIcons[#specialIcons+1]=button
end
MainActionBar.ActionBarPageNumber=object(nil,MainActionBar)
MainActionBar.ActionBarPageNumber.UpButton=object(nil,MainActionBar.ActionBarPageNumber)
MainActionBar.ActionBarPageNumber.DownButton=object(nil,MainActionBar.ActionBarPageNumber)
for _,prefix in ipairs({"ActionButton","MultiBarBottomLeftButton","MultiBarBottomRightButton","MultiBarRightButton"}) do
    local native = prefix=="ActionButton" and MainActionBar or prefix=="MultiBarBottomLeftButton" and MultiBarBottomLeft or prefix=="MultiBarRightButton" and MultiBarRight or MultiBarBottomRight
    for i=1,12 do
        local container=object(nil,native); container.scale=1.5
        local f=object(prefix..i,container);f.secure=true;f.container=container;f.scale=1.4
    end
end
for i=1,3 do object("StanceButton"..i,StanceBar) end
for i=1,10 do object("PetActionButton"..i,PetActionBar) end
-- Extra action / zone ability buttons: built by Blizzard, not by our bars.
local extraBar=object("ExtraActionBarFrame",UIParent)
local extraButton=object("ExtraActionButton1",extraBar)
extraButton.secure=false
extraBar.button=extraButton
extraButton.icon=object(nil,extraButton,"texture")
extraButton.IconMask=object(nil,extraButton,"texture")
extraButton.Flash=object(nil,extraButton,"texture")
extraButton.style=object(nil,extraButton,"texture")
extraButton.cooldown=object(nil,extraButton)
extraButton.lossOfControlCooldown=object(nil,extraButton)
extraButton.chargeCooldown=object(nil,extraButton)
extraButton.HotKey=object(nil,extraButton,"font")
extraButton.Count=object(nil,extraButton,"font")
local zoneFrame=object("ZoneAbilityFrame",UIParent)
zoneFrame.Style=object(nil,zoneFrame,"texture")
local zoneContainer=object(nil,zoneFrame)
zoneFrame.SpellButtonContainer=zoneContainer
local function zoneButton()
    local b=object(nil,zoneContainer)
    b.Icon=object(nil,b,"texture")
    b.Cooldown=object(nil,b)
    b.ChargeCooldown=object(nil,b)
    b.Count=object(nil,b,"font")
    b.NormalTexture=object(nil,b,"texture")
    return b
end
local zoneButtons={zoneButton(),zoneButton()}
function hooksecurefunc(obj, method, callback)
    if type(obj)=="string" then obj,method,callback=_G,obj,method end
    local original=obj[method]
    obj[method]=function(...) original(...);callback(...) end
end
function MainActionBar:UpdateGridLayout() ActionButton2.container:SetScale(1.5) end
MinimapCluster.Tracking=object(nil,MinimapCluster)
StatusTrackingBarManager=object("StatusTrackingBarManager",UIParent)
StatusTrackingBarManager.barContainers={}
for i=1,2 do
    local container=object(nil,StatusTrackingBarManager)
    container.BarFrameTexture=object(nil,container)
    local bar=object(nil,container)
    bar.StatusBar=object(nil,bar)
    bar.StatusBar.Background=object(nil,bar.StatusBar)
    bar.StatusBar:SetMinMaxValues(100,200)
    bar.StatusBar:SetValue(150)
    function bar:Update() self.StatusBar:SetStatusBarTexture("native-art") end
    container:Hide()
    if i==1 then
        bar.isExpBar=true
        bar.ExhaustionTick=object(nil,bar)
        bar.ExhaustionLevelFillBar=object(nil,bar)
        function bar.ExhaustionTick:UpdateTickPosition() end
        function bar:UpdateStatusBarTextures(rested)
            self.StatusBar:SetStatusBarTexture(rested and "native-rested-blue" or "native-normal-purple")
        end
    end
    container.bars={bar}
    StatusTrackingBarManager.barContainers[i]=container
end
-- Match the failing Blizzard ClassPowerBar:GetUnit contract, not a permissive mock.
function WarlockPowerFrame:GetUnit()
    local unit = self.unit or self:GetParent():GetParent().unit
    return unit or "player"
end
local UI={}
for _,file in ipairs({"Core.lua","Tooltips.lua","Equipment.lua","GroupDebuffs.lua","Units.lua","Progress.lua","Castbars.lua","ClassPower.lua","Layout.lua","RaidTest.lua"}) do assert(loadfile(""..file))("AzerothBuddyUI",UI) end
local dispatcher
for _,o in ipairs(objects) do if o.events.PLAYER_LOGIN then dispatcher=o end end
assert(dispatcher)
local function event(e) dispatcher.scripts.OnEvent(dispatcher,e) end
ScreenshotUIDB={enabled=false,positions={group={x=960,y=330},player={x=200,y=100},target={x=1400,y=100},actions1={x=900,y=84}}}
event("PLAYER_LOGIN")
assert(not UI.started,"disabled addon changed layout")
ScreenshotUIDB.enabled=true
combat=true;event("PLAYER_LOGIN")
assert(UI.pendingStart and not UI.started,"combat startup not deferred")
combat=false
if arg and arg[1]=="startup-failure" then
    UI.CreateLayout=function() error("simulated layout failure") end
    local ok=pcall(event,"PLAYER_REGEN_ENABLED")
    assert(not ok and not UI.started, "partial startup reported as success")
    print("PASS: interrupted startup does not report success")
    return
end
event("PLAYER_REGEN_ENABLED")
assert(UI.started and UI.chatAnchor and UI.mapAnchor and not UI.Mover,
    "layout started without manual movers")
assert(TimeManagerClockButton.alpha==0 and TimeManagerClockButton.mouse==false, "native clock hidden; footer remains clickable")
local calendarClicks, managerToggles=0,0
GameTimeFrame.scripts.OnClick=function(self,mouse)
    assert(self==GameTimeFrame and mouse=="LeftButton")
    calendarClicks=calendarClicks+1
end
TimeManager_Toggle=function() managerToggles=managerToggles+1 end
UI.clockButton.scripts.OnClick(UI.clockButton,"LeftButton")
assert(calendarClicks==1 and managerToggles==0 and nativeClockClicks==0)
UI.clockButton.scripts.OnClick(UI.clockButton,"RightButton")
assert(managerToggles==1 and calendarClicks==1 and UI.clock.parent==UI.clockButton)
UI.clockButton.scripts.OnClick(UI.clockButton,"MiddleButton")
assert(managerToggles==1 and calendarClicks==1)
local savedForbidden=GameTimeFrame.IsForbidden
GameTimeFrame.IsForbidden=function() return true end
UI.ClickFooterClock(nil,"LeftButton")
assert(calendarClicks==1,'forbidden calendar must not be accessed')
GameTimeFrame.IsForbidden=function() return secret end
UI.ClickFooterClock(nil,"LeftButton")
assert(calendarClicks==1,'secret forbidden result must not be branched on')
GameTimeFrame.IsForbidden=function() error('inaccessible calendar') end
assert(pcall(UI.ClickFooterClock,nil,"LeftButton"))
GameTimeFrame.IsForbidden=savedForbidden
local savedCalendar=GameTimeFrame
GameTimeFrame=nil
ToggleCalendar=function() calendarClicks=calendarClicks+1 end
UI.ClickFooterClock(nil,"LeftButton")
assert(calendarClicks==2,'missing calendar button uses native toggle')
ToggleCalendar=nil;GameTimeFrame=savedCalendar
local savedAddOns=C_AddOns
local loads=0
TimeManager_Toggle=nil
C_AddOns={LoadAddOn=function(name)
    assert(name=="Blizzard_TimeManager");loads=loads+1
    TimeManager_Toggle=function() managerToggles=managerToggles+1 end
end}
UI.ClickFooterClock(nil,"RightButton")
assert(loads==1 and managerToggles==2,'lazy load timer menu on click')
TimeManager_Toggle=nil
local savedCombat=InCombatLockdown
InCombatLockdown=function() return true end
UI.ClickFooterClock(nil,"RightButton")
assert(loads==1,'do not load Blizzard modules during combat')
InCombatLockdown=savedCombat
C_AddOns=savedAddOns
assert(GameTimeFrame.scale==1.4 and GameTimeFrame.point[2]==Minimap, "calendar inside square minimap")
assert(not UI.minimapButtonBar and not UI.minimapButtonTrigger and not UI.RefreshMinimapWidgets)
for _,icon in ipairs({minimapIcon,buddyIcon,secureIcon,forbiddenIcon,unpack(specialIcons)}) do
    assert(icon.parent==Minimap and icon.alpha==nil and icon.mouse==nil,
        "removed minimap module still modifies addon buttons")
end
assert(zygorIcon.parent==UIParent)
assert(not Minimap.scripts.OnEnter and not Minimap.scripts.OnLeave)
minimapIcon:SetPoint("TOP",Minimap,"TOP",13,17)
UI.ApplyLayout()
assert(minimapIcon.point[4]==13 and minimapIcon.point[5]==17, "layout still repositions addon icon")
minimapIcon.scripts.OnClick(minimapIcon)
buddyIcon.scripts.OnClick(buddyIcon)
zygorIcon.scripts.OnClick(zygorIcon)
assert(iconClicks==1 and buddyClicks==1 and zygorClicks==1)
for _,original in ipairs(specialIcons) do
    original.scripts.OnClick(original,"RightButton")
    assert(original.originalClick and original.lastMouse=="RightButton")
end
for _,step in ipairs(deferred) do step() end
deferred={}

local pager=MainActionBar.ActionBarPageNumber
assert(pager.alpha==0 and pager.mouse==false)
assert(pager.UpButton.mouse==false and pager.DownButton.mouse==false)
local function tooltipSkin(tooltip)
    for _,obj in ipairs(objects) do if obj.parent==tooltip and obj.all==tooltip then return obj end end
end
local resizingPanel=UI.Panel(UIParent,10,10)
resizingPanel.width=secret;resizingPanel.height=secret
local resizeOK=pcall(function()
    if resizingPanel.scripts.OnSizeChanged then resizingPanel.scripts.OnSizeChanged(resizingPanel) end
end)
assert(resizeOK,"panel resize performs arithmetic on secret dimensions")
for _,name in ipairs({"GameTooltip","ItemRefTooltip","ShoppingTooltip1","ShoppingTooltip2","ItemRefShoppingTooltip1","ItemRefShoppingTooltip2"}) do
    local tooltip=_G[name]
    local skin=tooltipSkin(tooltip)
    assert(skin and skin.background.color[4]==.85 and skin.borders[1].color[1]==.75 and tooltip.NineSlice.alpha==0, "questwatcher tooltip style")
end
resizingPanel:SetBackdropColor(.03,.35,.45,.8)
resizingPanel:SetBackdropBorderColor(.1,.2,.3,.4)
assert(resizingPanel.background.color[4]==.8 and resizingPanel.borders[4].color[4]==.4)
GameTooltip.scripts.OnShow(GameTooltip)
assert(originalTooltipShow==1, "tooltip skin replaced Blizzard OnShow")
SharedTooltip_SetBackdropStyle(GameTooltip)
assert(GameTooltip.NineSlice.alpha==0, "questwatcher tooltip style survives native refresh")
local forbiddenTooltip=object(nil,UIParent)
forbiddenTooltip.forbidden=true
UI.SkinTooltip(forbiddenTooltip)
assert(not tooltipSkin(forbiddenTooltip), "forbidden tooltip was modified")
local party=AzerothBuddyUI_party1Group
for _,frame in ipairs({party,UI.raid[1]}) do
    combat=true
    frame.scripts.OnEnter(frame)
    assert(GameTooltip.ownerAnchor=="ANCHOR_NONE" and GameTooltip.defaultOwner==frame
        and GameTooltip.tooltipUnit==frame.unit, "group tooltip must use Blizzard default anchor")
    frame.scripts.OnLeave(frame)
    combat=false
end
UI.player.scripts.OnEnter(UI.player)
assert(GameTooltip.ownerAnchor=="ANCHOR_RIGHT")
GameTooltip.forbidden=true
GameTooltip.tooltipUnit="unchanged"
party.scripts.OnEnter(party)
assert(GameTooltip.tooltipUnit=="unchanged")
GameTooltip.forbidden=false
combat=true
pager.alpha=1
UI.HideActionPager()
assert(pager.alpha==1, "pager mutation must wait until combat ends")
combat=false
UI.HideActionPager()
assert(pager.alpha==0)

assert(#nativeAuraAnchors==45, "all five party and forty raid buttons need native debuffs")
for _,args in ipairs(nativeAuraAnchors) do
    local frame=args.parent.parent
    assert(frame.debuffContainer==args.parent and args.parent.all==frame)
    assert(not args.parent.scripts.OnUpdate and not args.parent.events.UNIT_AURA,
        "native containers must not have addon aura polling")
    assert(frame.percent.point[5]==17 and frame.name.point[5]==6)
    local expectedGroup=frame.unit:match("^raid") and CompactRaidGroupTypeEnum.Raid or CompactRaidGroupTypeEnum.Party
    assert(args.parent["group-type"]==expectedGroup)
end
local beforeAnchors=#nativeAuraAnchors
assert(UI.CreateGroupDebuffs(UI.raid[1]) and #nativeAuraAnchors==beforeAnchors,
    "repeated setup must not leak aura anchors")
combat=true
assert(not UI.CreateGroupDebuffs({unit="raid1"}) and #nativeAuraAnchors==beforeAnchors)
combat=false
local savedAdd=C_UnitAuras.AddPrivateAuraAnchor
C_UnitAuras.AddPrivateAuraAnchor=nil
assert(not UI.CreateGroupDebuffs({unit="raid1"}))
C_UnitAuras.AddPrivateAuraAnchor=function() return nil end
assert(not UI.CreateGroupDebuffs({unit="raid1"}))
C_UnitAuras.AddPrivateAuraAnchor=function() error("simulated API failure") end
assert(not UI.CreateGroupDebuffs({unit="raid1"}))
C_UnitAuras.AddPrivateAuraAnchor=savedAdd

assert(ScreenshotUIDB.combatLayout024, "layout migration missing")
assert(UI.player.point[1]=="RIGHT" and UI.player.point[2]==UI.combatAnchor
    and UI.player.point[3]=="LEFT" and UI.player.point[4]==-20 and UI.player.point[5]==38)
assert(UI.target.point[1]=="LEFT" and UI.target.point[2]==UI.combatAnchor
    and UI.target.point[3]=="RIGHT" and UI.target.point[4]==20 and UI.target.point[5]==38)
assert(UI.combatAnchor.point[1]=="CENTER" and UI.combatAnchor.point[4]==960
    and UI.combatAnchor.point[5]==333, "saved group height lost during migration")
assert(not ScreenshotUIDB.positions.player and not ScreenshotUIDB.positions.target
    and not ScreenshotUIDB.positions.actions1 and not ScreenshotUIDB.positions.group,
    "old positions must not override the new layout")
assert(UI.group.point[1]=="TOP" and UI.group.point[2]==UI.playerCastAnchor
    and UI.group.point[3]=="BOTTOM" and UI.group.point[5]==-20)


-- Own raid grid: 40 secure slots, visible only inside a raid.
assert(#UI.raid==40)
assert(UI.group.width==441 and UI.group.height==90)
assert(AzerothBuddyUI_party1Group.scale==1.5 and AzerothBuddyUI_playerGroup.scale==1.5,
    "party frames including text/auras must be 50 percent larger")
assert(UI.raidAnchor.width==438 and UI.raidAnchor.height==270)
for _,frame in ipairs(UI.raid) do
    assert(frame.scale==1.5 and frame.width*frame.scale==84 and frame.height*frame.scale==87)
end

assert(UI.raid[1].unit=="raid1" and UI.raid[40].unit=="raid40")
assert(UI.raid[1].type1=="target" and UI.raid[40].type2=="togglemenu")
assert(UI.raid[7].visibilityDriver:find("[group:raid,@raid7,exists] show; hide",1,true))
assert(UI.raidAnchor.point[1]=="TOP" and UI.raidAnchor.point[2]==UI.group
    and UI.raidAnchor.point[3]=="TOP" and UI.raidAnchor.point[4]==0
    and UI.raidAnchor.point[5]==0, "raid grid must sit on the group position")
assert(UI.raid[1].point[2]==UI.raidAnchor and UI.raid[1].point[4]==0 and UI.raid[1].point[5]==0)
assert(UI.raid[2].point[4]==59 and UI.raid[2].point[5]==0)
assert(UI.raid[6].point[4]==5*59 and UI.raid[6].point[5]==0,
    "spare slots must continue to the right of a full row")
assert(UI.raid[40].point[4]==16*59 and UI.raid[40].point[5]==-60,
    "spare slots must fill three-high spare columns")
assert(CompactRaidFrameContainer.alpha==0 and CompactRaidFrameContainer.mouse==false,
    "native raid frames not masked")
assert(CompactRaidFrameManager.alpha==0, "native raid manager not masked")
local nativeMember=object(nil,CompactRaidFrameContainer)
local nativeSelection=object(nil,nativeMember,"texture")
nativeSelection.ignoreParentAlpha=true
local nativeReady=object(nil,nativeMember)
nativeReady.ignoreParentAlpha=true
local nativeIcon=object(nil,nativeReady,"texture")
nativeIcon.ignoreParentAlpha=true
local forbiddenMember=object(nil,CompactRaidFrameContainer)
forbiddenMember.forbidden=true
forbiddenMember.mouse=true
UI.MaskNativeGroupFrames()
assert(nativeSelection.ignoreParentAlpha==false and nativeReady.ignoreParentAlpha==false
    and nativeIcon.ignoreParentAlpha==false, "native highlights must inherit hidden parent alpha")
assert(nativeMember.mouse==false and nativeReady.mouse==false)
assert(forbiddenMember.mouse==true, "forbidden frames must stay untouched")
combat=true
nativeSelection.ignoreParentAlpha=true
UI.MaskNativeGroupFrames()
assert(nativeSelection.ignoreParentAlpha==true, "mask must defer during combat")
combat=false
UI.MaskNativeGroupFrames()


-- Native extra/zone button artwork and scripts must survive without a skin hook.
assert(not extraButton.suiExtraSkinned and not extraButton.icon.all)
assert(extraButton.Flash.alpha==nil and extraButton.style.alpha==nil)
assert(extraButton.parent==extraBar)
assert(zoneFrame.Style.alpha==nil)
for _,button in ipairs(zoneButtons) do
    assert(not button.suiExtraSkinned and not button.Icon.all and button.NormalTexture.alpha==nil)
end
local laterButton=zoneButton()
UI.ApplyLayout()
assert(not laterButton.suiExtraSkinned and not laterButton.Icon.all)

-- Class colour must reach player units, including target-of-target.
local savedUnitClass=UnitClass
UnitClass=function(u)
    if u=="targettarget" then return "Mage","MAGE" end
    return savedUnitClass(u)
end
UI.targettarget.scripts.OnEvent(UI.targettarget,"UNIT_HEALTH","targettarget")
assert(UI.targettarget.health.statusColor[2]==.78, "target-of-target lost its class colour")
UnitClass=savedUnitClass

-- Blizzard can apply its own layout after ours. Without the deferred passes the
-- bars only settle at the end of the first fight.
assert(#deferred==0, "startup must not queue extra layout passes")
local applied=0
local realApply=UI.ApplyLayout
UI.ApplyLayout=function() applied=applied+1 end

-- Zone change outside combat: one direct pass plus the two delayed passes.
event("PLAYER_ENTERING_WORLD")
assert(applied==1 and #deferred==2, "zone change does not queue a reapply")
for _,step in ipairs(deferred) do step() end
deferred={}
assert(applied==3, "deferred reapply did not run")

-- Queued passes must do nothing when combat starts before they fire.
event("PLAYER_ENTERING_WORLD")
combat=true
event("PLAYER_ENTERING_WORLD") -- swallowed by the combat guard
for _,step in ipairs(deferred) do step() end
deferred={}
assert(applied==4, "deferred layout ran in combat")
combat=false

-- Roster updates only reapply when the raid state actually changed.
event("GROUP_ROSTER_UPDATE")
assert(applied==4 and #deferred==1, "unchanged roster must queue only masking")
event("GROUP_ROSTER_UPDATE")
assert(#deferred==1, "mask passes must coalesce")
local lateMember=object(nil,CompactRaidFrameContainer)
local lateSelection=object(nil,lateMember,"texture")
lateSelection.ignoreParentAlpha=true
for _,step in ipairs(deferred) do step() end
deferred={}
assert(lateMember.mouse==false and lateSelection.ignoreParentAlpha==false,
    "new native raid members must be masked after roster updates")
inRaid=true
event("GROUP_ROSTER_UPDATE")
assert(applied==5 and #deferred==3, "entering a raid was not picked up")
for _,step in ipairs(deferred) do step() end
deferred={}
event("GROUP_ROSTER_UPDATE")
assert(applied==7 and #deferred==1, "unchanged raid roster must queue only masking")
for _,step in ipairs(deferred) do step() end
deferred={}
inRaid=false
event("GROUP_ROSTER_UPDATE")
assert(applied==8 and #deferred==3, "leaving the raid was not picked up")
deferred={}
UI.ApplyLayout=realApply

-- Every raid size fits the available height; party size and top anchor stay fixed.
local previousScale=1.5
inRaid=true
for count=1,40 do
    raidCount=count
    event("GROUP_ROSTER_UPDATE")
    local scale,rows,_,columns,vertical=UI.RaidLayout(count)
    assert(scale<=previousScale and rows*60*scale<=270+1e-8)
    assert(rows<=3, "raid must never need a fourth row")
    if count<=10 then assert(scale==1.5)
    else assert(scale==1.5*math.sqrt(10/15), "all raids above ten must use the confirmed 15-player size") end
    local capacity=columns*rows
    for i,frame in ipairs(UI.raid) do
        assert(frame.scale==scale)
        local column,row
        if i<=capacity then
            column=count>=20 and math.floor((i-1)/3) or (i-1)%columns
            row=count>=20 and (i-1)%3 or math.floor((i-1)/columns)
        else
            local spare=i-capacity-1
            column=columns+math.floor(spare/3); row=spare%3
        end
        assert(frame.point[4]==column*59 and frame.point[5]==-row*60)
        assert(frame.point[5]>=-2*60, "no secure slot may sit below the third row")
    end
    assert(UI.raidAnchor.width==(columns*59-3)*scale, "grid must grow equally around its centre")
    assert(UI.group.width==441 and AzerothBuddyUI_party1Group.scale==1.5)
    assert(UI.raidAnchor.point[2]==UI.group and UI.raidAnchor.point[5]==0)
    previousScale=scale
    for _,step in ipairs(deferred) do step() end
    deferred={}
end
raidCount=19;event("GROUP_ROSTER_UPDATE")
assert(UI.raid[2].point[4]==59 and UI.raid[2].point[5]==0)
combat=true;raidCount=20;event("GROUP_ROSTER_UPDATE")
assert(UI.raid[2].point[4]==59, "orientation changed during combat")
combat=false;event("PLAYER_REGEN_ENABLED")
assert(UI.raid[2].point[4]==0 and UI.raid[2].point[5]==-60,
    "vertical orientation was not applied after combat")
raidCount=40;event("GROUP_ROSTER_UPDATE")
-- A member joining during combat must appear beside the grid, never in a
-- fourth row; the normal row-major layout follows after combat.
inRaid=true;combat=false;raidCount=15;event("GROUP_ROSTER_UPDATE")
assert(UI.raid[16].point[4]==5*59 and UI.raid[16].point[5]==0,
    "spare slot must already sit to the right of the 15-player grid")
combat=true;raidCount=16;event("GROUP_ROSTER_UPDATE")
assert(UI.raid[1].point[4]==0 and UI.raid[1].point[5]==0, "grid moved during combat")
assert(UI.raid[16].point[4]==5*59 and UI.raid[16].point[5]==0,
    "joining member must appear beside the grid, not below it")
combat=false;event("PLAYER_REGEN_ENABLED")
assert(UI.raid[16].point[4]==3*59 and UI.raid[16].point[5]==-120,
    "row-major six-column layout was not applied after combat")
local scaleBefore=UI.raid[1].scale
combat=true
raidCount=10
event("GROUP_ROSTER_UPDATE")
assert(UI.raid[1].scale==scaleBefore, "raid resized during combat")
combat=false
event("PLAYER_REGEN_ENABLED")
assert(UI.raid[1].scale==1.5, "raid did not resize after combat")
raidCount=secret
UI.PositionRaid()
assert(UI.raid[1].scale==1.5, "secret group count must not be calculated")
raidCount=0;inRaid=false
UI.ApplyLayout()

local auraHosts={}
for _,o in ipairs(objects) do if o.events.UNIT_AURA then auraHosts[#auraHosts+1]=o end end
assert(#auraHosts>0 and auraReads>0)
for _,host in ipairs(auraHosts) do
    -- F-10: kein dauerhaftes OnUpdate mehr, der Abruf hängt an Ereignissen.
    assert(not host.scripts.OnUpdate and type(host.RefreshAuras)=="function",
        "aura hosts must refresh on events, not every frame")
end
local readsBefore=auraReads
for _,state in ipairs({"restricted","combat","missing-api"}) do
    aurasRestricted=state=="restricted"
    combat=state=="combat"
    local saved=C_Secrets
    if state=="missing-api" then C_Secrets=nil end
    for _,host in ipairs(auraHosts) do
        host.scripts.OnEvent(host,"PLAYER_TARGET_CHANGED")
        -- Ersatz für das frühere 0,5-s-OnUpdate: der Abruf ist ein Vertrag.
        host.RefreshAuras(host)
        for _,icon in ipairs(objects) do
            if icon.parent==host then
                assert(not icon:IsShown(), "stale aura left visible")
                icon.scripts.OnEnter(icon)
            end
        end
    end
    C_Secrets=saved
    assert(auraReads==readsBefore,"aura queried while access denied")
end
combat=false;aurasRestricted=false
for _,host in ipairs(auraHosts) do host.scripts.OnEvent(host,"PLAYER_REGEN_ENABLED") end
assert(auraReads>readsBefore,"auras did not resume")
assert(#nativeAuraAnchors==45, "combat/roster updates must not recreate native containers")
for _,args in ipairs(nativeAuraAnchors) do
    assert(args.parent:IsShown(), "native aura host must remain available during aura restrictions")
end

assert(WarlockPowerFrame.parent==UIParent)
assert(not UI.soulShards, "paladin must not get shards")
assert(ChatFrame1.fontSize==16)
assert(UI.info and UI.header, "native minimap zone header retained")
assert(UI.targettarget.unit=="targettarget" and UI.targettarget.events.UNIT_TARGET=="target")
assert(UI.targettarget.point[2]==UI.target and UI.targettarget.point[3]=="TOPRIGHT")
assert(TargetFrameToT.parent.visibilityDriver=="hide")
-- F-09: der 0,2-s-Abruf läuft als Ticker nur bei sichtbarer Anzeige.
assert(not UI.targettarget.scripts.OnUpdate, "target-of-target must not poll every frame")
assert(type(UI.targettarget.Poll)=="function" and type(UI.targettarget.SyncPoll)=="function")
local tickersBefore=#tickers
UI.targettarget.scripts.OnShow(UI.targettarget)
assert(#tickers==tickersBefore+1 and tickers[#tickers].active,
    "showing the target-of-target must start exactly one ticker")
UI.targettarget.SyncPoll()
assert(#tickers==tickersBefore+1, "synchronising twice must not stack tickers")
tickers[#tickers].callback()
assert(UI.targettarget.health.value==secret, "ticker run refreshes the unit")
UI.targettarget.scripts.OnHide(UI.targettarget)
assert(tickers[#tickers].cancelled, "hiding the target-of-target must cancel the ticker")
UI.targettarget:Show()
UI.targettarget.scripts.OnEvent(UI.targettarget, "UNIT_TARGET", "target")
UI.targettarget.Poll()
assert(UI.targettarget.health.value==secret)
for _,prefix in ipairs({"ActionButton","MultiBarBottomLeftButton","MultiBarBottomRightButton"}) do
    for i=1,12 do
        local button=_G[prefix..i]
        if i>7 then assert(button.container.parent.visibilityDriver=="hide")
        else assert(not button.suiOverflowHidden) end
    end
end
assert(MainActionBar.width==264 and MainActionBar.point[2].width==264)
for i=1,12 do
    local button=_G["MultiBarRightButton"..i]
    assert(button.abuiQuestSkin and not button.suiOverflowHidden)
    assert(button.parent.parent==MultiBarRight and button.shown)
end
assert(UI.focus.unit=="focus" and UI.focus.events.PLAYER_FOCUS_CHANGED)
assert(#UI.bosses==5 and UI.bosses[5].events.INSTANCE_ENCOUNTER_ENGAGE_UNIT)
assert(FocusFrame.parent.visibilityDriver=="hide" and Boss5TargetFrame.parent.visibilityDriver=="hide")
assert(PlayerCastingBarFrame.parent.visibilityDriver=="hide")
assert(UI.playerCastAnchor.point[1]=="TOP" and UI.playerCastAnchor.point[2]==MultiBarBottomLeft.point[2]
    and UI.playerCastAnchor.point[3]=="BOTTOM" and UI.playerCastAnchor.point[5]==-15)
assert(UI.playerCast.point[2]==UI.playerCastAnchor and UI.playerCast.point[3]=="TOP"
    and UI.playerCast.point[5]==0)
assert(StanceBar.point[2]==MultiBarRight and StanceBar.point[3]=="LEFT")
for _,candidate in ipairs(objects) do
    if candidate.secure then
        assert(not dependsOn(candidate,UI.playerCast,{}), "secure unit anchored to visible cast bar")
    end
end
assert(StanceBar.width==3*(MultiBarRightButton1.width*MultiBarRightButton1.scale+2)-2 and StanceButton3.abuiQuestSkin)
assert(ActionButton1.abuiQuestSkin and ActionButton1.checkedTexture, "questwatcher action skin")
assert(#ActionButton1.abuiQuestSkin.edges==4 and ActionButton1.abuiQuestSkin.edges[1].color[1]==.75)
local skinCount=#objects
UI.SkinActionButton(ActionButton1)
assert(#objects==skinCount,"skin duplicated textures")
local forbiddenAction=object(nil,UIParent,"Button");forbiddenAction.forbidden=true
UI.SkinActionButton(forbiddenAction);assert(not forbiddenAction.abuiQuestSkin)
local deferredAction=object(nil,UIParent,"Button")
combat=true;UI.SkinActionButton(deferredAction);assert(not deferredAction.abuiQuestSkin)
combat=false;UI.SkinActionButton(deferredAction);assert(deferredAction.abuiQuestSkin)
assert(not UI.targetCast:IsShown())
for _,mode in ipairs({"cast","channel","empower","none"}) do
    castMode=mode
    combat=true
    UI.targetCast:Refresh()
    UI.playerCast:Refresh()
    UI.focusCast:Refresh()
    UI.bosses[1].cast:Refresh()
    assert(UI.group.point[2]==UI.playerCastAnchor and UI.raidAnchor.point[2]==UI.group)
    if mode=="none" then
        assert(not UI.targetCast:IsShown() and not UI.playerCast:IsShown())
        assert(UI.playerCastAnchor:IsShown(), "static layout anchor must not follow cast visibility")
    else
        assert(UI.targetCast:IsShown() and UI.targetCast.fill.duration==secret and UI.targetCast.label.text==secret)
        assert(UI.targetCast.fill.direction==(mode=="channel" and 1 or 0))
    end
    combat=false
end
assert(UI.holyPower and #UI.holyPower.segments==5)
local savedClass, savedPower = UnitClass, UnitPower
local warlockSpec, rawQuery = 3, nil
Enum.PowerType.SoulShards=7
C_SpecializationInfo={GetSpecialization=function() return warlockSpec end}
function UnitPowerDisplayMod(kind) assert(kind==7); return 10 end
UnitClass=function() return "Hexenmeister", "WARLOCK" end
UnitPower=function(unit,kind,raw) assert(unit=="player" and kind==7); rawQuery=raw; return secret end
UI.CreateSoulShards()
assert(UI.soulShards and #UI.soulShards.segments==5 and rawQuery==true)
assert(UI.soulShards.parent==UI.player and UI.soulShards.point[3]=="TOPLEFT")
for i,segment in ipairs(UI.soulShards.segments) do
    assert(segment.min==(i-1)*10 and segment.max==i*10 and segment.value==secret)
end
combat=true
UI.soulShards.scripts.OnEvent()
combat=false
for _,spec in ipairs({1,2}) do
    warlockSpec=spec
    UI.soulShards.scripts.OnEvent()
    assert(rawQuery==false)
    for i,segment in ipairs(UI.soulShards.segments) do assert(segment.min==i-1 and segment.max==i and segment.value==secret) end
end
UnitClass, UnitPower = savedClass, savedPower
local oldMax, oldType = UnitPowerMax, UnitPowerType
-- Forever: optional specialization API must not abort resource creation.
local savedSpecAPI = C_SpecializationInfo
for _, api in ipairs({false, {}, {GetSpecialization=function() error("unavailable") end}, {GetSpecialization=function() return secret end}, {GetSpecialization=function() return "1" end}}) do
    C_SpecializationInfo = api or nil
    assert(UI.GetSpecialization()==nil, "invalid specialization must be ignored")
    UI.CreateClassPower()
end
C_SpecializationInfo = savedSpecAPI
local oldSpec = C_SpecializationInfo.GetSpecialization
local testClass, testSpec, mainKind, maximum = "WARRIOR", 1, 1, 6
for key,value in pairs({ComboPoints=4,Chi=12,ArcaneCharges=16,Essence=19,Energy=3}) do Enum.PowerType[key]=value end
UnitClass=function() return testClass,testClass end
C_SpecializationInfo.GetSpecialization=function() return testSpec end
UnitPowerType=function() return mainKind,"MANA" end
UnitPowerMax=function(_,kind) if kind then return maximum end return secret end
UnitPower=function() return secret end
function UnitStagger() return secret end
function UnitPartialPower() return 500 end
function GetTime() return 105 end
function GetRuneCooldown(index) return 100,10,index==6 end
local cases={
 {"DEATHKNIGHT",1,"runes",6},{"DEATHKNIGHT",2,"runes",6},{"DEATHKNIGHT",3,"runes",6},
 {"ROGUE",1,"points",6},{"DRUID",2,"points",6,3},{"DRUID",3,"hidden",nil,1},
 {"MONK",3,"points",6},{"MONK",1,"stagger",1},{"MONK",2,"hidden",nil},
 {"MAGE",1,"points",6},{"MAGE",2,"hidden",nil},{"EVOKER",1,"points",6},
 {"WARRIOR",1,"hidden",nil},{"HUNTER",1,"hidden",nil},{"PRIEST",3,"hidden",nil},
 {"SHAMAN",1,"hidden",nil},{"DEMONHUNTER",1,"hidden",nil},
}
for _,case in ipairs(cases) do
    testClass,testSpec,mainKind=case[1],case[2],case[5] or 0
    UI.CreateClassPower()
    local resource=UI.classPower
    assert(resource.mode==case[3] and resource.count==case[4],testClass)
    assert(resource:IsShown()==(case[3]~="hidden"), "extra primary bar: "..testClass)
    -- F-08: OnUpdate entfällt; nur bei Runen oder Evoker läuft ein Ticker.
    assert(not resource.scripts.OnUpdate, "class power must not poll every frame")
    assert(type(resource.Poll)=="function" and type(resource.SyncPoll)=="function")
    if case[3]=="runes" or testClass=="EVOKER" then
        resource:Show()
        resource.SyncPoll()
        local active=false
        for i=1,#tickers do
            if tickers[i].active then active=true; tickers[i].callback(); break end
        end
        assert(active,"ticker started for timed resource")
    elseif case[3]=="hidden" then
        resource.SyncPoll()
    end
    combat=true;resource.scripts.OnEvent();resource.Poll();combat=false
    if case[3]=="hidden" then
        assert(resource.segments[1].value==nil, "hidden primary bar must not read resource values")
    elseif case[3]=="runes" then
        assert(resource.segments[1].value==.5 and resource.segments[6].value==1)
    else assert(resource.segments[1].value==secret) end
end
-- Talent maximum changes and form/spec switches update the existing widgets.
testClass,testSpec,mainKind,maximum="ROGUE",1,3,7
UI.CreateClassPower();assert(UI.classPower.count==7)
maximum=secret;UI.classPower.scripts.OnEvent();assert(UI.classPower.count==7)
testClass,testSpec,mainKind,maximum="DRUID",2,3,5
UI.CreateClassPower();assert(UI.classPower.mode=="points")
mainKind=1;UI.classPower.scripts.OnEvent();assert(UI.classPower.mode=="hidden" and not UI.classPower:IsShown())
mainKind=3;UI.classPower.scripts.OnEvent();assert(UI.classPower.mode=="points" and UI.classPower:IsShown())
testClass,testSpec="MAGE",1
UI.CreateClassPower();assert(UI.classPower:IsShown())
testSpec=2;UI.classPower.scripts.OnEvent();assert(not UI.classPower:IsShown())
testSpec=1;UI.classPower.scripts.OnEvent();assert(UI.classPower:IsShown())
testClass,testSpec,maximum="EVOKER",1,6
UnitPower=function() return 2 end
UI.CreateClassPower();assert(UI.classPower.segments[3].value==2.5)
UnitClass,UnitPower,UnitPowerMax,UnitPowerType=savedClass,savedPower,oldMax,oldType
C_SpecializationInfo.GetSpecialization=oldSpec
for i,segment in ipairs(UI.holyPower.segments) do
    assert(segment.min==i-1 and segment.max==i and segment.value==secret)
end
for i,container in ipairs(StatusTrackingBarManager.barContainers) do
    assert(container.point[2]==Minimap and container.point[3]=="BOTTOMLEFT")
    assert(container.point[5]==-5-(i-1)*18 and container.width==240 and container.height==14)
    assert(not container:IsShown(), "preserve native availability")
    assert(container.BarFrameTexture.alpha==0 and container.bars[1].StatusBar.Background.tex==UI.WHITE, "questwatcher progress decoration")
    local status=container.bars[1].StatusBar
    assert(status.value==150 and status.min==100 and status.max==200)
    container.bars[1]:Update()
    assert(status.texture==UI.WHITE, "correct texture survives native updates")
    container:SetPoint("BOTTOM",UIParent,"BOTTOM",0,0)
    assert(container.point[2]==Minimap, "native reposition restored")
end
local xpBar=StatusTrackingBarManager.barContainers[1].bars[1]
assert(xpBar.ExhaustionLevelFillBar.width==144 and xpBar.ExhaustionTick.point[4]==144)
restedXP=1500
xpBar.ExhaustionTick:UpdateTickPosition()
assert(xpBar.ExhaustionLevelFillBar.width==240, "rested extension must clamp at bar edge")
restedXP=nil;restState=2
UI.PositionProgress()
assert(not xpBar.ExhaustionLevelFillBar:IsShown() and not xpBar.ExhaustionTick:IsShown())
assert(xpBar.StatusBar.texture==UI.WHITE and xpBar.StatusBar.statusColor[1]==.55)
restedXP=400;restState=1
combat=true
xpBar.ExhaustionTick:UpdateTickPosition()
assert(not xpBar.ExhaustionLevelFillBar:IsShown(), "rested layout deferred in combat")
combat=false;UI.PositionProgress()
assert(xpBar.ExhaustionLevelFillBar:IsShown() and xpBar.ExhaustionLevelFillBar.width==144)
-- Geschützte IsCapped-Antwort darf nicht als Verzweigung dienen.
xpBar.IsCapped=function() return secret end
xpBar.ExhaustionTick:UpdateTickPosition()
assert(xpBar.ExhaustionLevelFillBar:IsShown() and xpBar.ExhaustionLevelFillBar.width==144,
    "secret IsCapped must not be branched on")
-- Eine öffentliche Kappung blendet die Erholungsanzeige weiterhin aus.
xpBar.IsCapped=function() return true end
xpBar.ExhaustionTick:UpdateTickPosition()
assert(not xpBar.ExhaustionLevelFillBar:IsShown(), "public cap hides rested extension")
xpBar.IsCapped=nil
xpBar.ExhaustionTick:UpdateTickPosition()
assert(xpBar.ExhaustionLevelFillBar:IsShown(), "rested extension restored once cap clears")
-- Ungültige Breite: keine Arithmetik auf dem Widgetwert, Anzeige bleibt verborgen.
local nativeBarWidth=xpBar.width
xpBar.width=secret
xpBar.ExhaustionTick:UpdateTickPosition()
assert(not xpBar.ExhaustionLevelFillBar:IsShown(), "secret bar width must not be used in arithmetic")
xpBar.width=nativeBarWidth
xpBar.ExhaustionTick:UpdateTickPosition()
assert(xpBar.ExhaustionLevelFillBar:IsShown() and xpBar.ExhaustionLevelFillBar.width==144)
-- Ungültige Skalierung: Layout wird übersprungen statt zu teilen.
local progressContainer=StatusTrackingBarManager.barContainers[1]
local nativePoint, nativeContainerScale=progressContainer.point, progressContainer.scale
local nativeMinimapScale=Minimap.scale
Minimap.scale=0
UI.PositionProgress()
assert(progressContainer.point==nativePoint and progressContainer.scale==nativeContainerScale,
    "zero minimap scale must skip progress layout")
Minimap.scale=nativeMinimapScale
UI.PositionProgress()
assert(progressContainer.scale==1 and progressContainer.width==240)
combat=false
for count=1,40 do
    SlashCmdList.AZEROTHBUDDYUI("raidtest "..count)
    for i,cell in ipairs(UI.raidPreview.cells) do
        assert(cell:IsShown()==(i<=count))
        assert(#cell.debuffIcons==3 and not cell.debuffContainer,
            "preview must use static sample debuffs without live aura anchors")
        if i<=count then
            local scale,rows,_,columns=UI.RaidLayout(count)
            local column=count>=20 and math.floor((i-1)/3) or (i-1)%columns
            local row=count>=20 and (i-1)%3 or math.floor((i-1)/columns)
            assert(cell.scale==scale and cell.point[4]==column*59 and cell.point[5]==-row*60)
            assert(UI.raidPreview.width==(columns*59-3)*scale)
            assert(UI.raidPreview.height==(rows*60-2)*scale)
        end
    end
end
SlashCmdList.AZEROTHBUDDYUI("raidtest off")
assert(not UI.raidPreview:IsShown())
for _,invalid in ipairs({"0","41","2.5","foo"}) do
    SlashCmdList.AZEROTHBUDDYUI("raidtest "..invalid)
    assert(not UI.raidPreview:IsShown())
end
SlashCmdList.AZEROTHBUDDYUI("raidtest")
assert(UI.raidPreview.point[1]=="TOP" and UI.raidPreview.point[2]==UI.raidAnchor
    and UI.raidPreview.point[3]=="TOP" and UI.raidPreview.point[5]==0)
assert(not UI.raidPreview.title and not UI.raidPreview.scripts.OnDragStart
    and UI.raidPreview.kind=="Frame", "preview must contain only cells, no movable window")
assert(UI.raidPreview.cells[20]:IsShown() and not UI.raidPreview.cells[21]:IsShown())
UI.raidPreview.scripts.OnEvent(UI.raidPreview,"PLAYER_REGEN_DISABLED")
assert(not UI.raidPreview:IsShown())
combat=true
SlashCmdList.AZEROTHBUDDYUI("raidtest 40")
assert(not UI.raidPreview:IsShown())
combat=false
assert(PetActionBar.point[2]==StanceBar and PetActionBar.point[3]=="LEFT")
-- Regression: our SetPoint must not leave an EditMode snap behind. Otherwise
-- StanceBar:HideOverride -> BreakSnappedFrames -> PetActionBar:BreakFrameSnap
-- clears the protected bar's point (in combat) and UpdateSystemAnchorInfo
-- crashes on nil offsetY.
assert(not PetActionBar.snappedToFrame and not next(PetActionBar.snappedFrames),
    "pet bar must not stay snapped to another EditMode system")
assert(not StanceBar.snappedToFrame and not next(StanceBar.snappedFrames),
    "stance bar must not stay snapped to another EditMode system")
do
    -- The harness must really model the snap contract, otherwise the checks above prove nothing.
    local probe=object(nil,UIParent); editModeSystem(probe)
    probe:SetPoint("LEFT",StanceBar,"RIGHT",0,0)
    assert(probe.snappedToFrame==StanceBar and StanceBar.snappedFrames[probe], "snap contract not simulated")
    probe:ClearAllPoints()
    assert(not StanceBar.snappedFrames[probe] and not probe.snappedToFrame, "ClearAllPoints must drop the snap")
end
assert(PetActionButton10.width==MultiBarRightButton1.width*MultiBarRightButton1.scale and PetActionButton10.abuiQuestSkin)
assert(EditModeManagerFrame.scripts.OnHide, "edit mode hook must be installed")
assert(Minimap.width==240 and MinimapCluster.scale==1, "native map dimensions preserved")
assert(BuffFrame.point[2]==Minimap and BuffFrame.point[3]=="TOPLEFT")
assert(MinimapCluster.Tracking.parent==MinimapCluster and MinimapCluster.Tracking.shown,
    "native tracking must stay native")
assert(MicroMenuContainer.parent==UIParent)
assert(not UI.menuButton and not UI.menuPanel)
assert(Minimap.GetMaskTexture==nil, "do not invent unsupported minimap methods")
assert(PlayerFrame.parent.visibilityDriver=="[vehicleui] show; hide")
assert(TargetFrame.parent.visibilityDriver=="hide")
assert(PartyFrame.parent.visibilityDriver=="hide")
assert(CompactPartyFrame.parent==UIParent)
assert(PetFrame.parent.visibilityDriver=="hide")
assert(CompactRaidFrameContainer.parent==UIParent)
assert(CompactRaidFrameManager.parent==UIParent)
assert(UI.pet.visibilityDriver:find("@pet,exists",1,true))
assert(ActionButton1:GetWidth()==36 and ActionButton1.container.scale==1 and ActionButton1.scale==1)
assert(ActionButton2.point[4]-ActionButton1.point[4]==38)
assert(MultiBarBottomLeft.point[2].point[5]==5)
assert(MainActionBar.point[2].point[5]==43)
assert(MultiBarBottomRight.point[2].point[5]==81)
MainActionBar:UpdateGridLayout()
assert(ActionButton2.container.scale==1, "restore layout after native grid updates")
assert(UI.player.health.value==secret and UI.player.health.max==secret)
assert(UI.target.name.text==secret and UI.target.percent.values[1]==secret,
    "protected percent value must reach the widget")
-- Colour thresholds run natively: the addon only forwards the secret curve
-- results as alpha values and never compares the percentage itself.
assert(UI.target.percentWarn and UI.target.percentLow)
assert(UI.target.percentWarn.values[1]==secret and UI.target.percentLow.values[1]==secret)
assert(UI.target.percent.alpha==secret and UI.target.percentWarn.alpha==secret
    and UI.target.percentLow.alpha==secret, "percent colour must use the native curve result")
assert(UI.target.percent.textColor[1]<.3 and UI.target.percent.textColor[2]==1)
assert(UI.target.percentWarn.textColor[1]==1 and UI.target.percentWarn.textColor[2]>.8)
assert(UI.target.percentLow.textColor[1]>.9 and UI.target.percentLow.textColor[2]<.2)
assert(UI.targettarget.percentLow.fontSize==11 and UI.focus.percentWarn.fontSize==14
    and UI.bosses[1].percentLow.fontSize==14, "colour labels must share the percent font")
assert(UI.raid[40].percentWarn and UI.raid[40].percentLow.alpha==secret)
assert(UI.player.type1=="target" and UI.player.type2=="togglemenu")
assert(UI.target.visibilityDriver:find("@target,exists",1,true))
assert(AzerothBuddyUI_party1Group.visibilityDriver:find("group:raid",1,true))
assert(SLASH_AZEROTHBUDDYUI1=="/abui" and SLASH_AZEROTHBUDDYUI2==nil,
    "only /abui remains registered")
-- Manual mover commands were removed; they must fall through to help text.
SlashCmdList.AZEROTHBUDDYUI("unlock")
SlashCmdList.AZEROTHBUDDYUI("lock")
assert(UI.unlocked==nil and UI.frames==nil and UI.Mover==nil and UI.Lock==nil)
combat=true;event("PLAYER_REGEN_DISABLED")
UI.ApplyLayout() -- must do nothing protected in combat
UI.holyPower.scripts.OnEvent()
assert(WarlockPowerFrame.parent==UIParent)
combat=true;UI.targettarget.Poll()
assert(UI.holyPower.segments[5].value==secret)
SlashCmdList.AZEROTHBUDDYUI("off")
assert(reloads==0)
combat=false
ScreenshotUIDB.positions.player={x=500,y=300}
SlashCmdList.AZEROTHBUDDYUI("reset")
assert(next(ScreenshotUIDB.positions)==nil)
assert(UI.combatAnchor.point[5]==1080*.278-23, "reset must restore the default group height")
ScreenshotUIDB.positions.player={x=500,y=300}
UI.ApplyLayout()
assert(UI.player.point[1]=="CENTER" and UI.player.point[4]==500 and UI.player.point[5]==300,
    "saved positions after migration must remain supported")
local settingsValues,settingsWrites={},0
for bar=2,8 do settingsValues["PROXY_SHOW_ACTIONBAR_"..bar]=bar>=5 end
Settings={
    GetValue=function(key) return settingsValues[key] end,
    SetValue=function(key,value) assert(not combat);settingsWrites=settingsWrites+1;settingsValues[key]=value end,
}
local cooldownValue,cvarWrites="1",0
C_CVar={
    GetCVar=function(key) assert(key=="cooldownViewerEnabled");return cooldownValue end,
    SetCVar=function(key,value) assert(not combat and key=="cooldownViewerEnabled");cvarWrites=cvarWrites+1;cooldownValue=value end,
}
combat=true;SlashCmdList.AZEROTHBUDDYUI("")
assert(settingsWrites==0 and cvarWrites==0,"settings changed in combat")
combat=false;SlashCmdList.AZEROTHBUDDYUI("hilfe")
assert(settingsWrites==0 and cvarWrites==0,"help changed settings")
SlashCmdList.AZEROTHBUDDYUI("")
assert(settingsWrites==7 and cvarWrites==1 and cooldownValue=="0")
for bar=2,8 do assert(settingsValues["PROXY_SHOW_ACTIONBAR_"..bar]==(bar<=4)) end
SlashCmdList.AZEROTHBUDDYUI("")
assert(settingsWrites==7 and cvarWrites==1,"redundant settings writes")
settingsValues.PROXY_SHOW_ACTIONBAR_8=secret
assert(not UI.ConfigureActionBars() and settingsWrites==7,"secret settings must abort before writes")
settingsValues.PROXY_SHOW_ACTIONBAR_8=false
local savedSettings=Settings;Settings=nil
assert(not UI.ConfigureActionBars(),"missing Settings API reported success")
Settings=savedSettings
local savedSetter=C_CVar.SetCVar
cooldownValue="1";C_CVar.SetCVar=function() end
assert(not UI.ConfigureActionBars(),"rejected CVar reported success")
C_CVar.SetCVar=savedSetter
-- F-18: GetNumShapeshiftForms kann geheim sein; Layout muss dabei nicht rechnen.
local savedForms = GetNumShapeshiftForms
GetNumShapeshiftForms = function() return secret end
UI.PositionStances()
UI.PositionPetBar()
assert(StanceBar.point[2]==MultiBarRight, "secret form count falls back to stances off")
GetNumShapeshiftForms = savedForms
SlashCmdList.AZEROTHBUDDYUI("off")
assert(not ScreenshotUIDB.enabled and reloads==1)
print("PASS: disabled/combat startup, secure layout guards, raw secret forwarding, unit actions, visibility, positions, reset, off")

assert(UI.mapAnchor.point[4]==-4, "map border must align two points from right edge")

assert(MultiBarBottomRight.point[2].point[5]+36==112/2+38+46/2,"action top aligned with unit top")

-- Audit 1.0: Ereignisschübe erhalten genau einen Nachlauf pro Auren-Host.
combat=false;aurasRestricted=false
local auditHost=auraHosts[1]
local flush=deferred;deferred={}
for _,callback in ipairs(flush) do callback() end
local beforeTimers=#deferred
for i=1,100 do auditHost.scripts.OnEvent(auditHost,"UNIT_AURA") end
assert(#deferred-beforeTimers==1,"100 aura events must coalesce into one follow-up")
local follow=table.remove(deferred);follow()
auditHost.scripts.OnEvent(auditHost,"UNIT_AURA")
assert(#deferred==beforeTimers+1,"next aura burst must be able to schedule again")
-- Ein unzugängliches Objekt darf weder beschrieben werden noch Busy festhalten.
for _,case in ipairs({{StanceBar,UI.PositionStances,"stanceBusy"},{PetActionBar,UI.PositionPetBar,"petBarBusy"}}) do
    local frame,position,key=unpack(case)
    local original=frame.SetScale
    local calls=0
    frame.SetScale=function(...) calls=calls+1;return original(...) end
    frame.forbidden=true
    assert(pcall(position) and calls==0 and not UI[key],"forbidden bar must be skipped")
    frame.forbidden=false
    frame.SetScale=function() error("simulated native failure") end
    assert(pcall(position) and not UI[key],"layout failure must release busy")
    frame.SetScale=function(...) calls=calls+1;return original(...) end
    position()
    assert(calls>0 and not UI[key],"layout must recover without reload")
    frame.SetScale=original
end
local tooltipOwner=GameTooltip.SetOwner
GameTooltip.forbidden=true
GameTooltip.SetOwner=function() error("forbidden tooltip was touched") end
for _,obj in ipairs(objects) do
    if obj.parent==auditHost and obj.scripts.OnEnter then
        assert(pcall(obj.scripts.OnEnter,obj));assert(pcall(obj.scripts.OnLeave,obj))
    end
end
GameTooltip.forbidden=false;GameTooltip.SetOwner=tooltipOwner
print("PASS: aura burst coalescing, native bar isolation/recovery and aura tooltip guard")

-- Native Größe und Skalierung von Leiste 4 sind die gemeinsame Referenz.
combat=false
MultiBarRightButton1:SetSize(40,40);MultiBarRightButton1:SetScale(1.25)
UI.PositionStances();UI.PositionPetBar()
assert(StanceButton1.width==50 and StanceButton1.height==50)
assert(PetActionButton10.width==50 and PetActionButton10.height==50)
assert(PetActionBar.width==518 and PetActionBar.height==50)
print('PASS: stance/forms and pet buttons match scaled bar four')

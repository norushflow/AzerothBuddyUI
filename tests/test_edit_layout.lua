local loadfile = dofile("tests/load_locales.lua")
local screenWidth, screenHeight = 3440, 1440
function GetPhysicalScreenSize() return screenWidth, screenHeight end
local combat, shown, forbidden = false, false, false
function InCombatLockdown() return combat end
local UI={Message=function() end}
assert(loadfile("EditLayout.lua"))("AzerothBuddyUI",UI)
AzerothBuddyUI={}
Enum={EditModeLayoutType={Preset=0,Account=1},EditModeSystem={ChatFrame=8,ActionBar=0}}
local raw, cache, active, imports, saves, writes, completed, queue
local reject, delayed, invalid
local nativeChat
local function checkChat(data)
    local chat, count
    count = 0
    for _, system in ipairs(data.systems) do
        if system.system==Enum.EditModeSystem.ChatFrame then chat=system;count=count+1 end
    end
    assert(count==1 and chat~=nativeChat and chat.anchorInfo~=nativeChat.anchorInfo,
        "copy chat without sharing or duplicating native data")
    assert(chat.anchorInfo.offsetX==nativeChat.anchorInfo.offsetX
        and chat.anchorInfo.offsetY==nativeChat.anchorInfo.offsetY
        and chat.anchorInfo.relativeTo==nativeChat.anchorInfo.relativeTo
        and chat.settings[1].value==nativeChat.settings[1].value,
        "setup must retain native chat position and settings")
end
local function reset(existing)
    nativeChat={system=8,systemIndex=1,anchorInfo={offsetX=137,offsetY=92,relativeTo="UIParent"},settings={{setting=0,value=17}}}
    raw={{layoutName="Other",layoutType=1,systems={{keep=true},nativeChat}}}
    cache={[3]=raw[1]}
    if existing then
        raw[2]={layoutName="AzerothBuddyUI",layoutType=1,systems={{custom=true},{system=8,anchorInfo={offsetX=999}}}}
        cache[4]=raw[2]
    end
    active=3;imports=0;saves=0;writes=0;completed=0;queue={}
    reject=false;delayed=false;invalid=false
    UI.editLayoutPending=nil;UI.editLayoutFinalizing=nil
    C_Timer={After=function(_,callback) queue[#queue+1]=callback end}
    C_EditMode={
        GetLayouts=function() return {activeLayout=active,layouts=raw} end,
        ConvertStringToLayoutInfo=function(value)
            assert(#value>1000)
            local tokens = {}
            for token in value:gmatch("%S+") do tokens[#tokens+1]=token end
            assert(#tokens==2+10*tonumber(tokens[2]), "layout serialization count must match")
            local exportedChat, exportedBars = nil, {}
            for slot=3,#tokens,10 do
                if tokens[slot]=="0" then
                    exportedBars[tokens[slot+1]] = {
                        system=0, systemIndex=tonumber(tokens[slot+1]),
                        anchorInfo={relativeTo=tokens[slot+5], offsetX=tonumber(tokens[slot+6]),
                            offsetY=tonumber(tokens[slot+7])},
                    }
                end
                if tokens[slot]=="8" then
                    exportedChat={system=8,anchorInfo={offsetX=tonumber(tokens[slot+6]),offsetY=tonumber(tokens[slot+7])}}
                end
            end
            assert(exportedChat, "full user export must be retained as supplied")
            assert(exportedBars["0"].anchorInfo.offsetX==0 and exportedBars["0"].anchorInfo.offsetY==-243.7)
            if screenWidth == 3440 then
                assert(value:find("0 1 0 6 0 MainActionBar 0.0 4.0", 1, true))
                assert(value:find("0 2 0 2 8 MainActionBar 0.0 -4.0", 1, true))
                assert(value:find("0 10 0 4 4 UIParent 0.0 -160.0", 1, true))
                assert(value:find("3 4 0 0 0 UIParent 1943.0 -928.5", 1, true))
            else
                assert(value:find("0 1 0 0 6 MainActionBar 0.0 -4.0", 1, true))
                assert(value:find("0 2 0 8 2 MainActionBar 0.0 4.0", 1, true))
                assert(exportedBars["10"].anchorInfo.offsetX==0 and exportedBars["10"].anchorInfo.offsetY==-158.8)
                assert(value:find("3 4 0 0 0 UIParent 1349.3 -928.5", 1, true))
            end
            if invalid then return nil end
            return {systems={{template=true},exportedChat}}
        end,
        SetActiveLayout=function(index)
            writes=writes+1
            if not reject and not delayed then active=index end
        end,
        SaveLayouts=function(data)
            checkChat(data.layouts[2])
            saves=saves+1
            assert(data.layouts~=raw and data.layouts[1]~=raw[1], "never mutate original API or manager tables")
            assert(data.layouts[1].systems[1].keep)
            assert(data.layouts[2].systems[1].template and not data.layouts[2].systems[1].custom)
            assert(cache[4].systems[1].custom, "manager cache must stay untouched")
            raw=data.layouts
        end,
    }
    EditModeManagerFrame={layoutInfo={activeLayout=3,layouts=cache},
        IsForbidden=function() return forbidden end, IsShown=function() return shown end,
        CreateLayoutTbls=function(self) self.highestLayoutIndexByType = {} end,
        ImportLayout=function(self,data,kind,title)
            assert(self.highestLayoutIndexByType, "first import requires Blizzard's layout index")
            checkChat(data)
            imports=imports+1;data.layoutName=title;data.layoutType=kind
            raw[#raw+1]=data;cache[#raw+2]=data
        end,
    }
end
local function complete()
    UI.CompleteEditLayoutSetup(function() completed=completed+1 end)
end
local function drain()
    local count=0
    while #queue>0 do count=count+1;assert(count<=5);table.remove(queue,1)() end
end
reset(false)
assert(UI.EnableEditLayout() and imports==1 and saves==0 and active==4)
complete();assert(completed==0);drain();assert(completed==1)
assert(AzerothBuddyUI.editLayoutResult)
UI.ReportEditLayoutResult();assert(not AzerothBuddyUI.editLayoutResult)
assert(pcall(UI.PrintEditLayoutStatus))
reset(true)
assert(UI.EnableEditLayout() and saves==1 and imports==0 and active==4)
assert(raw[2].layoutName=="AzerothBuddyUI" and raw[1].systems[1].keep)
complete();drain();assert(completed==1)
reset(true)
EditModeManagerFrame.layoutInfo.activeLayout=4
assert(UI.EnableEditLayout() and writes==1, "stale manager selection must not skip actual activation")
active=3;complete();table.remove(queue,1)()
assert(completed==0 and writes==2);drain();assert(completed==1)
reset(true);delayed=true
assert(UI.EnableEditLayout());complete();table.remove(queue,1)()
assert(completed==0);active=4;drain();assert(completed==1)
reset(true);reject=true
assert(UI.EnableEditLayout());complete();drain();assert(completed==0 and not UI.editLayoutFinalizing)
reset(true);combat=true
assert(not UI.EnableEditLayout() and saves==0);combat=false
shown=true;assert(not UI.EnableEditLayout() and saves==0);shown=false
forbidden=true;assert(not UI.EnableEditLayout() and saves==0);forbidden=false
invalid=true;assert(not UI.EnableEditLayout() and saves==0 and raw[2].systems[1].custom)
reset(true);assert(UI.EnableEditLayout());complete();combat=true;drain();combat=false;assert(completed==0)
reset(true);assert(UI.EnableEditLayout());complete();UI.editLayoutPending=nil;drain();assert(completed==0)
reset(true);C_EditMode.SaveLayouts=nil;assert(not UI.EnableEditLayout() and raw[2].systems[1].custom)
reset(true);C_EditMode=nil;assert(not UI.EnableEditLayout())
print("PASS: import, overwrite exact name, preserve other layouts, snapshot isolation, actual selection, timeout and guards")

-- Already-active addon layout, presets and multiple independent chat systems.
reset(true)
active=4
nativeChat=cache[4].systems[2]
nativeChat.anchorInfo={offsetX=99,offsetY=71,relativeTo="UIParent"}
nativeChat.settings={{setting=0,value=23}}
assert(UI.EnableEditLayout() and saves==1 and writes==0)
reset(false)
cache[1]={layoutName="Preset",layoutType=0,systems={nativeChat}}
active=1
assert(UI.EnableEditLayout() and imports==1)
reset(false)
table.insert(cache[3].systems, {system=8,systemIndex=2,anchorInfo={offsetX=60},settings={}})
EditModeManagerFrame.ImportLayout=function(_, data)
    assert(#data.systems==3 and data.systems[3].systemIndex==2 and data.systems[3].anchorInfo.offsetX==60)
    assert(data.systems[3]~=cache[3].systems[3], "each chat system must be copied")
    cache[4]={layoutName="AzerothBuddyUI",systems=data.systems}
end
assert(UI.EnableEditLayout())
reset(false)
cache[3].systems={{keep=true}}
assert(not UI.EnableEditLayout() and imports==0 and saves==0 and writes==0,
    "missing chat data must abort before changing layouts")
print("PASS: setup preserves current chat on import, overwrite, active layout and preset; unavailable data prevents writes")

reset(false)
local nativeBar = {system=0,systemIndex=1,anchorInfo={offsetX=87},settings={{setting=2,value=6}}}
table.insert(cache[3].systems, nativeBar)
local convert = C_EditMode.ConvertStringToLayoutInfo
C_EditMode.ConvertStringToLayoutInfo = function(value)
    local layout = convert(value)
    table.insert(layout.systems, {system=0,systemIndex=1,anchorInfo={relativeTo="MainActionBar", offsetY=-4}})
    return layout
end
local import = EditModeManagerFrame.ImportLayout
EditModeManagerFrame.ImportLayout = function(self, layout, ...)
    local count = 0
    for _, system in ipairs(layout.systems) do
        if system.system == 0 then
            count = count + 1
            assert(system ~= nativeBar and system.anchorInfo.relativeTo == "MainActionBar" and system.anchorInfo.offsetY == -4)
        end
    end
    assert(count == 1, "setup must use the supplied action bar layout")
    return import(self, layout, ...)
end
assert(UI.EnableEditLayout())

for _, size in ipairs({{2560,1440},{1920,1080}}) do
    screenWidth, screenHeight = size[1], size[2]
    reset(true)
    assert(UI.EnableEditLayout() and saves==1 and imports==0)
    complete();drain();assert(completed==1)
end
screenWidth,screenHeight=1600,900
reset(true)
assert(not UI.EnableEditLayout() and saves==0 and imports==0 and writes==0)
screenWidth,screenHeight=3440,1440
print("PASS: 16:9 2560x1440 and 1920x1080 profiles and unsupported-resolution protection")

reset(false)
local reported
EventRegistry = {TriggerEvent = function(_, event, source, reason)
    assert(event == "BuddyReport.HandledError" and source == "AzerothBuddyUI")
    reported = reason
end}
EditModeManagerFrame.ImportLayout = function() error("Blizzard import failed") end
assert(not UI.EnableEditLayout() and reported:find("Blizzard import failed", 1, true))

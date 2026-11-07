local combat = false
function InCombatLockdown() return combat end
local UI = {Message=function() end}
assert(loadfile('EditLayout.lua'))('AzerothBuddyUI', UI)
local info = {activeLayout=1, layouts={{layoutName='Other'}}}
local imports, selections = 0, 0
Enum = {EditModeLayoutType={Account=1}}
C_EditMode = {
    GetLayouts=function() return info end,
    SetActiveLayout=function(index) selections=selections+1; info.activeLayout=index end,
    ConvertStringToLayoutInfo=function(value)
        assert(value:match('^2 52 ') and value:find('26 -1 1 4 4 UIParent 0.0 0.0 -1 #(', 1, true))
        return {systems={{}}}
    end,
}
EditModeManagerFrame = {
    layoutInfo=info,
    IsForbidden=function() return false end,
    IsShown=function() return false end,
    ImportLayout=function(_, layout, kind, name)
        imports=imports+1
        assert(kind==1)
        layout.layoutName=name
        table.insert(info.layouts,layout)
    end,
}
assert(UI.EnableEditLayout() and imports==1 and selections==1)
info.layouts[2].custom=true
info.activeLayout=1
assert(UI.EnableEditLayout() and imports==1 and selections==2 and info.layouts[2].custom)
assert(UI.EnableEditLayout() and selections==2)
combat=true
assert(not UI.EnableEditLayout() and selections==2)
combat=false
info.layouts[2]=nil
C_EditMode.ConvertStringToLayoutInfo=function() return nil end
assert(not UI.EnableEditLayout() and imports==1)
C_EditMode=nil
assert(not UI.EnableEditLayout())
print('PASS: layout import, selection, preserved edits, combat and unavailable API')

ScreenshotUIDB={editLayoutResult="bereits vorhanden"}
local messages={}
UI.Message=function(message) messages[#messages+1]=message end
C_EditMode={GetLayouts=function() return {activeLayout=1,layouts={{layoutName="AzerothBuddyUI"}}} end}
EditModeManagerFrame.layoutInfo=C_EditMode.GetLayouts()
UI.ReportEditLayoutResult()
assert(#messages==1 and messages[1]:find("Nach Reload aktiv",1,true))
UI.ReportEditLayoutResult()
assert(#messages==1 and ScreenshotUIDB.editLayoutResult==nil)
ScreenshotUIDB.editLayoutResult="neu importiert"
C_EditMode=nil
EditModeManagerFrame.layoutInfo=nil
UI.ReportEditLayoutResult()
assert(#messages==2 and messages[2]:find("nicht lesbar",1,true))
print("PASS: reload result reported once; missing API handled")

C_EditMode={GetLayouts=function() return {activeLayout=3,layouts={[3]={layoutName="AzerothBuddyUI"}}} end}
messages={}
EditModeManagerFrame.layoutInfo=C_EditMode.GetLayouts()
UI.PrintEditLayoutStatus()
assert(messages[1]:find("Diagnose 2",1,true))
assert(messages[3]:find("AzerothBuddyUI [aktiv]",1,true))
assert(messages[4]:find("vorhanden",1,true))
C_EditMode=nil
assert(pcall(UI.PrintEditLayoutStatus))
print("PASS: read-only layout status with sparse indices and unavailable API")

-- The dropdown includes preset indices; raw API arrays need not match them.
local dropdown={activeLayout=2,layouts={[3]={layoutName="OtherLayout"},[4]={layoutName="AzerothBuddyUI"}}}
EditModeManagerFrame.layoutInfo=dropdown
C_EditMode={
    GetLayouts=function() return {activeLayout=dropdown.activeLayout,layouts={{layoutName="OtherLayout"},{layoutName="AzerothBuddyUI"}}} end,
    SetActiveLayout=function(index) assert(index==4); dropdown.activeLayout=index end,
}
assert(UI.EnableEditLayout() and dropdown.activeLayout==4 and imports==1)
print("PASS: selection uses Blizzard dropdown indices instead of raw layout array indices")

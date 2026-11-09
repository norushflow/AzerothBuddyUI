local loadfile = dofile("tests/load_locales.lua")
local frames={}
function CreateFrame()
    local f={RegisterEvent=function() end,SetScript=function(self,_,fn) self.event=fn end}
    frames[#frames+1]=f;return f
end
SlashCmdList={}
local UI={}
assert(loadfile('Core.lua'))('AzerothBuddyUI',UI)
UI.ReportEditLayoutResult=function() end
local legacy={enabled=false,positions={player={x=123,y=456}},welcomeVersion='old'}
ScreenshotUIDB=legacy;AzerothBuddyUI=nil
frames[1].event(nil,'PLAYER_LOGIN')
assert(AzerothBuddyUI==legacy and AzerothBuddyUI.positions.player.x==123)
assert(ScreenshotUIDB==nil,'legacy global retired after migration')
local current={enabled=false,positions={target={x=12,y=34}}}
AzerothBuddyUI=current;ScreenshotUIDB=legacy
frames[1].event(nil,'PLAYER_LOGIN')
assert(AzerothBuddyUI==current and not AzerothBuddyUI.positions.player,'new DB always wins')
ScreenshotUIDB='invalid';AzerothBuddyUI=nil
UI.Start=function() end
function InCombatLockdown() return false end
frames[1].event(nil,'PLAYER_LOGIN')
assert(type(AzerothBuddyUI.positions)=='table','invalid old data handled')
local toc=assert(io.open('AzerothBuddyUI.toc')):read('*a')
assert(toc:find('## SavedVariables: AzerothBuddyUI\n',1,true))
assert(not toc:find('ScreenshotUIDB',1,true),'only new variable is written')
print('PASS: legacy migration, new DB precedence, invalid legacy and TOC declaration')

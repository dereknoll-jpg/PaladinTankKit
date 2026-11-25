local p,n=TEST_NS,0
local function check(v,message)assert(v,message);n=n+1 end
local function mob(id)
    return {guid="Creature-0-1-36-1-"..id.."-abc",name="Test Elite",hostile=true,classification="elite",dead=false,combat=false}
end
local function step(dt)NOW=NOW+(dt or .5);p:AutoMarkTick();p:Render()end
INSTANCE_KIND,INSTANCE_ID,GROUP,RAID,LEADER,ASSISTANT,COMBAT="party",36,true,false,false,false,false
PLAYER_ROLE="TANK";p.db.effects=false
UNITS={target=mob(90100)};MARKS={};PLATES={};p:ResetMarking()
step()
check(p.markStatus.text=="LEAD" and #MARKS==0,"Assigned tank without leader/assist sees LEAD, never AUTO")
check(select(2,p:MarkingStatus()):find("Tank role alone"),"Permission text distinguishes tank role from marker leadership")
local messages=#MESSAGES;p:Command("markstatus")
check(#MESSAGES==messages+2 and MESSAGES[#MESSAGES]:find("leader/assist=false") and MESSAGES[#MESSAGES]:find("tank=true"),"Reporter can provide permission/role diagnostics without exposing a GUID")
LEADER=true
local normalRead=GetRaidTargetIndex
GetRaidTargetIndex=function(unit)return UNITS[unit].mark or 0 end
step()
check(p.markStatus.text=="ARM" and #MARKS==0,"Armed queue is not reported as a successful auto mark")
step()
check(UNITS.target.mark==8 and p.markStatus.text=="SET","Zero unmarked result accepts Skull and waits for confirmation")
step(1)
check(p.markStatus.text=="AUTO" and p.marking.owned[UNITS.target.guid].confirmed,"AUTO requires a confirmed applied marker")
local visibleTarget=UNITS.target;UNITS.target=nil;p:Render()
check(p.markStatus.text=="HOLD","An unseen old mark cannot leave a misleading AUTO badge")
UNITS.target=visibleTarget
local markCount=#MARKS;step(1)
check(#MARKS==markCount,"Normalizing zero does not cause repeated marker toggling")

GetRaidTargetIndex=normalRead
p:ResetMarking();UNITS={target=mob(90200)};MARKS={}
step(.1)
check(p.marking.armed==UNITS.target.guid,"Initial selection arms normally")
UNITS.target=mob(90201);step(.1);step(.5)
check(UNITS.target.mark==8,"Retargeting before the first mark does not strand the queue on an unseen first selection")

p:ResetMarking();UNITS={target=mob(90300)};UNITS.target.guid=SECRET;step()
check(p.markStatus.text=="HOLD" and select(2,p:MarkingStatus()):find("identity"),"Hidden target identity has an explicit hold reason")
p:ResetMarking();UNITS={target=mob(90301)};UNITS.target.classification="normal";step()
check(p.markStatus.text=="WAIT" and UNITS.target.mark==nil,"Normal mobs stay unmarked with a selection hint")
p:ResetMarking();UNITS={target=mob(90302)};UNITS.target.mark=SECRET;p:Render()
check(p.markStatus.text=="HOLD" and select(2,p:MarkingStatus()):find("marker"),"Hidden existing marker is visible as a hold")

p:ResetMarking();UNITS={target=mob(90400)};MARKS={};SILENT_MARK_FAILURE=true
step();step()
check(p.markStatus.text=="SET","A silent refused write never immediately claims AUTO")
step(1)
check(p.markStatus.text=="PAUSE" and p.marking.paused:find("refused"),"Silent refusal becomes an explicit paused state")
SILENT_MARK_FAILURE=false

p:ResetMarking();UNITS={target=mob(90500)};MARKS={}
local setter=SetRaidTarget
local attempts=0
SetRaidTarget=function()
    attempts=attempts+1
    p.events.scripts.OnEvent(p.events,"ADDON_ACTION_FORBIDDEN","PaladinTankKit","SetRaidTarget()")
    -- Forbidden native functions can dispatch an event without raising a Lua error.
end
step();step()
check(attempts==1 and p.markStatus.text=="BLOCK","Synchronous protected-action event is detected even when pcall succeeds")
check(not next(p.marking.owned) and not next(p.marking.slots),"A blocked native call never creates imaginary owned markers")
step(2);p:Command("resume");step(2)
check(attempts==1 and p.markStatus.text=="BLOCK","Blocked marking does not retry or claim it can be resumed past a client restriction")
p:Mark(8)
check(attempts==1,"Manual addon path also avoids repeating a known forbidden call")
SetRaidTarget=setter;p.markingBlocked=nil;p:ResetMarking()
p.events.scripts.OnEvent(p.events,"ADDON_ACTION_FORBIDDEN","AnotherAddon","SetRaidTarget()")
check(not p.markingBlocked,"Another addon's blocked action cannot disable TankKit marking")
p.events.scripts.OnEvent(p.events,"ADDON_ACTION_FORBIDDEN","PaladinTankKit","UnrelatedFunction()")
check(not p.markingBlocked,"Unrelated blocked functions cannot be mistaken for marking failures")
p.markAttempt=true;p:MarkActionBlocked("PaladinTankKit","UNKNOWN()");p.markAttempt=nil
check(p.markingBlocked~=nil,"UNKNOWN action name is matched only during an actual marking attempt")
p.markingBlocked=nil;p:ResetMarking()
RAID=true;p:Render();check(p.markStatus.text=="MAN","Raid automation remains manual")
RAID=false;INSTANCE_KIND="none";p:Render();check(p.markStatus.text=="MAN","Outdoor automation remains manual")
check(p.events.events.ADDON_ACTION_BLOCKED and p.events.events.ADDON_ACTION_FORBIDDEN,"Both client refusal events are registered")
print("PASS: "..n.." marking permissions, zero markers, pre-pull retarget and protected-action status checks.")

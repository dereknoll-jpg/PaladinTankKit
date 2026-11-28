local p,n=TEST_NS,0
local function check(v,message) assert(v,message);n=n+1 end
local function event(name,...) p.events.scripts.OnEvent(p.events,name,...) end
local function mob(id,classification,cast)
    return {guid="Creature-0-1-36-1-"..id.."-abc",name="Test Elite",hostile=true,
        classification=classification or "elite",dead=false,cast=cast}
end
INSTANCE_KIND,INSTANCE_ID,GROUP,LEADER,RAID="party",36,true,true,false
check(p.assistedMarking and p:MarkingStatus()=="ASSIST","Assisted mode is the production default")
check(p.skull.template=="SecureActionButtonTemplate" and p.cross.template=="SecureActionButtonTemplate","Both anchored controls use Blizzard secure actions")
check(p.skull.parent==p.frame and p.cross.parent==p.frame,"Both controls stay anchored to the HUD")
check(not p.skull.scripts.OnClick and not p.cross.scripts.OnClick,"No insecure OnClick overrides the secure template")
for _,b in ipairs({p.skull,p.cross}) do
    check(b:GetAttribute("unit")=="target" and b:GetAttribute("*type1")=="raidtarget","Secure actions always address the selected target")
    check(b:GetAttribute("*action1")=="set" and b:GetAttribute("ctrl-action1")=="clear","Repeated marks set instead of toggling; clear is explicit")
    check(b:GetAttribute("useOnKeyDown")==false,"Keybindings use one release action")
    check(b:GetAttribute("*type-Mark")=="raidtarget" and b:GetAttribute("*action-Mark")=="set"
        and not b:GetAttribute("shift-marker-Mark") and not b:GetAttribute("ctrl-action-Mark"),"Modified key chords keep a fixed action independent of mouse gestures")
end
check(p.skull:GetAttribute("*marker1")==8 and p.skull:GetAttribute("shift-marker1")==7 and p.cross:GetAttribute("*marker1")==7,"Skull, Shift-Skull and X have fixed marker assignments")
local oldSetter=SetRaidTarget
SetRaidTarget=function() error("An addon must never call the ordinary marker setter in assisted mode") end
UNITS={target=mob(99001,"elite","Fireball")}
event("PLAYER_TARGET_CHANGED");p:Render()
check(p.markAdvice=="Priority caster" and p.markGlow.alpha>0,"Selected readable caster gets a subtle glow")
local glow=p.markGlow.alpha
NOW=NOW+.3;p:Render()
check(p.markGlow.alpha~=glow,"Normal effects gently breathe")
p.db.reducedMotion=true;p:Render();glow=p.markGlow.alpha
NOW=NOW+.3;p:Render();check(p.markGlow.alpha==glow and glow>0,"Reduced motion keeps a steady glow")
p.db.effects=false;p:Render();check(p.markGlow.alpha==0,"Effects-off suppresses priority glow")
p.db.effects=true;p.db.autoMark=false;event("PLAYER_TARGET_CHANGED");p:Render()
check(not p.markAdvice and p.markGlow.alpha==0,"Priority advice can be disabled independently of buttons")
p.db.autoMark=true
UNITS.target.mark=1;event("RAID_TARGET_UPDATE");check(not p.markAdvice,"Existing CC marks suppress advice")
UNITS.target.mark=8;event("RAID_TARGET_UPDATE");check(not p.markAdvice,"Existing Skull suppresses advice")
UNITS.target=mob(99001,"normal","Fireball");event("PLAYER_TARGET_CHANGED")
check(not p.markAdvice,"Non-elites never receive priority advice")
UNITS={mouseover=mob(99001,"elite","Fireball")};event("UPDATE_MOUSEOVER_UNIT")
check(not p.markAdvice,"Mouseover scouting alone never requests a mark")
UNITS.target=UNITS.mouseover;UNITS.target.cast=nil;event("PLAYER_TARGET_CHANGED")
check(p.markAdvice=="Priority caster","Scouted caster advice waits until selected")
RAID=true;event("PLAYER_TARGET_CHANGED");check(not p.markAdvice,"Raids remain manual without priority glow")
RAID=false;INSTANCE_KIND="none";event("PLAYER_TARGET_CHANGED");check(not p.markAdvice,"Outdoors remains manual")
INSTANCE_KIND="party";UNITS.target=mob(99001,"worldboss","Fireball");event("PLAYER_TARGET_CHANGED")
check(not p.markAdvice,"World bosses remain manual")
UNITS.target=mob(99001,"elite","Fireball")
local oldGUID=UnitGUID
UnitGUID=function()return SECRET end
event("PLAYER_TARGET_CHANGED");check(not p.markAdvice,"Secret target identity suppresses advice safely")
UnitGUID=oldGUID
COMBAT=true;event("PLAYER_REGEN_DISABLED")
local beforeScale,beforePoint=p.frame.scale,p.frame.point
p:SetScale(1.1);p:Position();p:Render()
check(p.pendingPosition and p.frame.scale==beforeScale and p.frame.point==beforePoint,"Combat scale and positioning wait until combat ends")
for i=1,10 do NOW=NOW+.4;p.events.scripts.OnUpdate(p.events,.4);p:AutoMarkTick() end
p:Mark(8);p:SmartMarkPull();p:Command("pull");event("UNIT_DIED",UNITS.target.guid)
check(#MARKS==0 and not p:AutoMarkAllowed(),"Targets, timers, slash commands and deaths never write marks")
event("ADDON_ACTION_FORBIDDEN","PaladinTankKit","SetRaidTarget()")
p:Render()
check(p.markStatus.text=="ASSIST" and not p.warning.text:find("blocked"),"Blocked actions keep the quiet ASSIST label without a HUD warning")
check(p.secureMarkBlocked and not p.markingBlocked,"Native-binding fallback is available in the tooltip without disabling buttons")
check(p.skull:GetAttribute("*marker1")==8 and p.cross:GetAttribute("*marker1")==7,"Combat observations never rewrite secure actions")
COMBAT=false;event("PLAYER_REGEN_ENABLED")
check(not p.pendingPosition and p.frame.scale==1.1,"Deferred layout applies after combat")
LEADER=false;event("GROUP_ROSTER_UPDATE");p:Render()
check(p.markStatus.text=="ASSIST","Permission guidance lives in help rather than a persistent warning")
SetRaidTarget=oldSetter
print("PASS: "..n.." assisted marking checks (secure configuration and combat safeguards; live clicks require client testing).")

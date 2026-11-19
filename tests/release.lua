local p,n=TEST_NS,0
local function check(value,message) assert(value,message);n=n+1 end
local function event(name,...)p.events.scripts.OnEvent(p.events,name,...)end
local function mob(id,combat,cast)
    return {guid="Creature-0-1-36-1-"..id.."-abc",name="Test",classification="elite",hostile=true,combat=combat,cast=cast,threat={player=1}}
end
local function tick() NOW=NOW+.5;p:AutoMarkTick() end
GROUP,LEADER,COMBAT,INSTANCE_KIND,INSTANCE_ID=true,true,false,"party",36
p.db.effects=false; UNITS={};PLATES={};p:ResetMarking();MARKS={}
UNITS.mouseover=mob(99901,false,"Fireball")
tick();tick()
check(#MARKS==0 and not p.marking.armed,"Mouseover cannot arm pre-pull marking")
UNITS.mouseover.combat=true
tick();tick()
check(#MARKS==0 and not p.marking.armed,"Engaged mouseover cannot start marking")
UNITS.nameplate1=UNITS.mouseover;PLATES={{namePlateUnitToken="nameplate1"}}
tick();tick()
check(#MARKS==0,"Party engagement/nameplates cannot start marking without a selected target")
UNITS.target=mob(99902,false);UNITS.mouseover.combat=false
tick();tick()
check(UNITS.target.mark==8 and UNITS.mouseover.mark==nil,"Only selected elite gets pre-pull Skull")
check(p.marking.armed==UNITS.target.guid,"Selection arms queue")
UNITS.nameplate1.combat=true;UNITS.nameplate1.cast=nil;tick()
check(UNITS.nameplate1.mark==8 and UNITS.target.mark==7,"Scouted caster can take opening kill priority once engagement is confirmed")
p:ResetMarking();UNITS.target=nil;tick()
check(not p.marking.armed,"Reset queue needs new target to arm")
local r=p:ObserveMarkUnit("nameplate1",true)
local before=#MARKS
check(not p:AssignAutoMark(r,8) and #MARKS==before,"Low-level auto setter also requires target arming")
KNOWN[1311015]=true; event("SPELLS_CHANGED");COOLDOWNS[1311015]=nil
p:ClearUsedTimers();event("UNIT_SPELLCAST_SUCCEEDED","player","cast",1311015)
NOW=NOW+.4;p:RefreshUsedCooldowns()
check(not p.used.bulwark.done and p:UsedTimerView("bulwark",NOW)==nil,"Zero after cast does not finish cooldown")
local _,state=p:UsedTimerView("bulwark",NOW)
check(state=="unknown" and p.readyUntil.bulwark==nil,"Pending update shows unknown, never false Ready")
COOLDOWNS[1311015]={startTime=NOW-.4,duration=240,isEnabled=true}
NOW=NOW+.4;event("SPELL_UPDATE_COOLDOWN")
check(p.cooldownTimers.bulwark and p.used.bulwark.confirmed,"Delayed positive cooldown is adopted")
p:ClearUsedTimers();event("PLAYER_ENTERING_WORLD")
check(p.cooldownTimers.bulwark and p.used.bulwark.confirmed,"Zoning/reload recovers ongoing cooldown")
event("PLAYER_DEAD")
check(p.cooldownTimers.bulwark~=nil,"Death retains readable cooldown tracking")
COOLDOWNS[1311015]={startTime=SECRET,duration=SECRET,isEnabled=true}
event("PLAYER_ENTERING_WORLD")
check(p.used.bulwark==nil,"Recovery never invents hidden cooldown")
COOLDOWNS[1311015]={startTime=NOW,duration=120,isEnabled=true};event("SPELL_UPDATE_COOLDOWN")
check(p.cooldownTimers.bulwark~=nil,"Later readable update recovers cooldown after a hidden load")
GROUP,LEADER,COMBAT=true,true,false
p:ToggleSettings()
check(p.settings.width==660 and p.settingsPages.timers~=nil,"New settings shell loads all pages")
p:SelectSettingsPage("timers")
check(p.settingsPages.timers:IsShown() and not p.settingsPages.general:IsShown(),"Settings tabs show one page")
p.preview=true;p.previewStart=NOW;p:Render()
check(p.holyTile:IsShown(),"Preview shows Holy Shield")
p.checks.trackHoly.scripts.OnClick()
check(not p.holyTile:IsShown() and not p.db.trackHoly,"Ability toggle hides timer immediately")
p.checks.trackHoly.scripts.OnClick()
check(p.holyTile:IsShown(),"Ability toggle restores timer")
local sent=#SENT_CHAT;p:ShareBossNote()
check(#SENT_CHAT==sent,"Preview notes can never send party chat")
p.checks.warnAura.scripts.OnClick()
check(not p.db.warnAura,"Aura reminder can be disabled independently")
p.checks.warnShield.scripts.OnClick()
check(not p.db.warnShield and p.db.warnFury,"Shield reminder can be disabled independently")
print("PASS: "..n.." target arming, cooldown recovery, settings and preview privacy checks.")

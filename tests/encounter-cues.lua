local p,n=TEST_NS,0
local function check(v,message) assert(v,message);n=n+1 end
local function mob(id,name,fields)
    local m={guid="Creature-0-1-36-1-"..id.."-a",name=name,hostile=true,combat=true,health=100,healthMax=100}
    for k,v in pairs(fields or {})do m[k]=v end
    return m
end
local function tick()NOW=NOW+.25;p:UpdateEncounterCue();p:Render()end
GROUP,LEADER,COMBAT,INSTANCE_KIND,INSTANCE_ID=true,false,true,"party",36
p.db.effects=false
UNITS={target=mob(645,"Cookie",{cast="Cookie's Cooking"})};PLATES={}
tick()
check(p.encounterCue and p.encounterCue.text:find("heal"),"Observed Cookie heal creates a relevant cue")
check(p.notesCard:IsShown() and not p.notesOpen,"A private cue can use the collapsed ribbon")
check(p.noteBody.text:find("Cookie's Cooking"),"Ribbon names the observed ability")
check(#SENT_CHAT==0,"Automatic cues never send group chat")
p.noteCloseButton.scripts.OnClick();tick()
check(not p.notesCard:IsShown(),"Closing dismisses an ongoing cue")
UNITS.target.cast=nil;tick();check(p.encounterCue==nil,"Ended cast clears its cue")
UNITS.target.cast="Cookie's Cooking";tick()
check(p.notesCard:IsShown(),"A later cast can show a new cue after dismissal")
p.db.encounterCues=false;tick()
check(p.encounterCue==nil and not p.notesCard:IsShown(),"Encounter cue switch disables automatic ribbon prompts")
check(p:CurrentBossNote()~=nil,"Disabling cues retains the ordinary boss plan")
p.db.encounterCues=true;p.db.bossNotes=false;tick()
check(p.encounterCue==nil and not p.notesButton:IsShown(),"Boss notes master switch disables plans and cues")
p.db.bossNotes=true
UNITS.target=mob(639,"Edwin VanCleef");tick()
check(p.encounterCue==nil and not p.notesCard:IsShown(),"Selecting a boss alone does not open the ribbon")
UNITS.nameplate1=mob(636,"Defias Blackguard");PLATES={{namePlateUnitToken="nameplate1"}};tick()
check(p.encounterCue and p.encounterCue.text:find("Blackguards"),"Observed engaged guards trigger the add cue")
UNITS.nameplate1.dead=true;tick()
check(p.encounterCue==nil,"Dead guards stop the priority cue")
UNITS.nameplate1.dead=false;UNITS.nameplate1.combat=false;tick()
check(p.encounterCue==nil,"Unengaged nearby adds cannot produce a cue")
UNITS.target.health=54;tick()
check(p.encounterCue and p.encounterCue.text:find("Half health"),"Observed crossing produces the preparation cue")
NOW=NOW+6;tick();check(p.encounterCue==nil,"Phase preparation cue expires without repeating")
UNITS.target.health=60;tick();UNITS.target.health=53;tick()
check(p.encounterCue==nil,"Healing across a threshold does not repeat a phase cue")
UNITS.target.health=SECRET;tick()
check(p.encounterCue==nil,"Secret boss health never produces a guessed phase")
UNITS.nameplate2=UNITS.target;PLATES={{namePlateUnitToken="nameplate2"}}
UNITS.target=mob(999,"Unrelated add");UNITS.nameplate1.combat=true
PLATES[#PLATES+1]={namePlateUnitToken="nameplate1"};tick()
check(p.encounterCue and p:CurrentBossNote().name=="Edwin VanCleef","Readable boss nameplate preserves context across target changes")
UNITS.nameplate2.dead=true;tick()
check(p.encounterCue==nil and p.encounterState==nil,"Boss death clears encounter context")
INSTANCE_ID=2999;UNITS={target=mob(250657,"Rath'mael",{channel="Flamestrike"})};PLATES={};tick()
check(p.encounterCue and p.encounterCue.text:find("move"),"Forever Rath'mael channel prompts movement")
INSTANCE_ID=3065;UNITS={target=mob(900,"Magmatus"),nameplate1=mob(901,"Dark Iron Summoner")}
PLATES={{namePlateUnitToken="nameplate1"}};tick()
check(p.encounterCue and p.encounterCue.text:find("Summoner"),"Forever Magmatus adds have a sourced cue")
UNITS.target.cast="Fire Nova";tick()
check(p.encounterCue.text:find("Fire Nova"),"Current dangerous cast takes priority over add guidance")
INSTANCE_KIND="raid";tick();check(p.encounterCue==nil and p:CurrentBossNote()==nil,"No automatic notes or cues in raids")
INSTANCE_KIND="none";tick();check(p.encounterCue==nil,"No outdoor encounter cues")
INSTANCE_KIND="party";INSTANCE_ID=36;UNITS={target=mob(645,"Cookie",{cast="Cookie's Cooking"})};PLATES={}
for _,version in ipairs({"1.60.2","1.15.8","12.0.0"})do
    BUILD_VERSION=version;tick()
    check(p.encounterCue==nil and p:CurrentBossNote()==nil,"Encounter data is not enabled for another client: "..version)
end
BUILD_VERSION="1.60.1";UNITS.target.combat=false;tick()
check(p.encounterCue==nil,"Idle boss casts cannot arm live cues")
UNITS.target.combat=true;DEAD=true;tick();check(p.encounterCue==nil,"Dead player gets no live cue")
DEAD=false;MOUNTED=true;tick();check(p.encounterCue==nil,"Mounted player gets no live cue")
MOUNTED=false;p.preview=true;p.previewStart=NOW;tick()
check(p.encounterCue==nil and #SENT_CHAT==0,"Preview cannot produce real encounter cues or chat")
p.preview=false
local count=0
for _,guides in pairs(p.foreverGuides)do for _,e in pairs(guides)do
    check(e.gameVersion=="1.60.1" and e.source:match("^https://www%.wowhead%.com/forever/"),"Every new plan is Forever version/source scoped")
    check(#p:BossNoteMessage(e)<=255,"Every new static plan fits explicit party sharing")
    count=count+1
end end
check(count==12,"New researched coverage has twelve plans across four dungeons")
check(#MARKS==0 and #SENT_CHAT==0,"Encounter cues neither mark enemies nor auto-share")
print("PASS: "..n.." Forever encounter-source, private cue and version-scope checks.")

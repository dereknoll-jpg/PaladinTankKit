local p,n=TEST_NS,0
local function check(v,message)assert(v,message);n=n+1 end
local function refresh()p:RefreshAuras();p:Render();return p:Warnings()end
local function step(dt)NOW=NOW+dt;return refresh()end
HELPFUL={{spellId=25780,name="Righteous Fury",expirationTime=0,duration=0}}
check(refresh()=="","Own Devotion plus Righteous Fury needs no reminder")
PALADIN_FORMS={{active=false,spellID=465},{active=true,spellID=7294}}
check(refresh()=="Missing: Devotion Aura","Retribution does not substitute for defensive Devotion Aura")
PLAYER_ROLE="HEALER"
check(refresh()=="","Healer does not get tank buff reminders")
PLAYER_ROLE="DAMAGER"
check(refresh()=="","Damage role does not get tank buff reminders")
MAIN_TANK=true
check(refresh()=="Missing: Devotion Aura","Legacy main-tank assignment enables reminders")
PLAYER_ROLE,MAIN_TANK="TANK",false
GROUP=false
check(refresh()=="","Solo player has no tank buff alert")
GROUP=true;KNOWN[643]=true
UNITS.party1={guid="Player-other",class="PALADIN"}
HELPFUL[2]={spellId=643,name="Devotion Aura",sourceUnit="party1",expirationTime=0}
check(refresh()=="" and p.devotionState.rank==3,"Another group Paladin's equal-rank aura on player prevents overlap")
HELPFUL[2].spellId=10293
check(refresh()=="","Higher-rank group Devotion also prevents overlap")
HELPFUL[2].spellId=10290
check(refresh()=="Missing: Devotion Aura","Lower-rank coverage still requests the tank's better rank")
HELPFUL[2].spellId=643;UNITS.party1.class="PRIEST"
check(refresh()=="Missing: Devotion Aura","Wrong class cannot be verified as Paladin coverage")
UNITS.party1.class=nil
check(refresh()=="" and p.devotionState.status=="unknown","Uncached group class is uncertainty, not a false missing-aura alert")
UNITS.party1.class="PALADIN";UnitInParty=function()return false end;UnitInRaid=function()return nil end
check(refresh()=="Missing: Devotion Aura","Explicit non-membership cannot be overridden by a party-looking token")
UnitInParty=nil;UnitInRaid=nil
UNITS.party1.class="PALADIN";HELPFUL[2].sourceUnit="target"
UNITS.target={class="PALADIN",guid="Player-stranger"}
check(refresh()=="Missing: Devotion Aura","Ungrouped Paladin source cannot qualify")
HELPFUL[2].sourceUnit="party1";HELPFUL[2].expirationTime=NOW-1
check(refresh()=="Missing: Devotion Aura","Expired received aura does not suppress warning")
HELPFUL[2]=nil
check(refresh()=="Missing: Devotion Aura","Group Paladin outside aura range provides no coverage")
HELPFUL[2]={spellId=643,name="Devotion Aura",sourceUnit=SECRET,expirationTime=0}
check(refresh()=="" and p.devotionState.status=="unknown","Hidden caster cannot create a false missing-aura warning")
HELPFUL[2]={spellId=SECRET,name="Devotion Aura",sourceUnit="party1",expirationTime=0}
check(refresh()=="" and p.devotionState.status=="unknown","Hidden rank is not guessed")
HELPFUL[2]=nil;RESTRICTED=true
check(refresh()=="" and p.devotionState.status=="unknown","Hidden coverage absence is not treated as missing")
C_Secrets.ShouldSpellAuraBeSecret=function()return false end
check(refresh()=="Missing: Devotion Aura","Per-spell readable absence can verify missing Devotion in combat")
C_Secrets.ShouldSpellAuraBeSecret=nil;RESTRICTED=false
PALADIN_FORMS[2].active=false;PALADIN_FORMS[1].active=true
check(refresh()=="","Own active Devotion clears reminder without another Paladin")
PALADIN_FORMS[1].active=SECRET
check(refresh()=="","Unknown stance selection does not create a false alert")
PALADIN_FORMS[1].active=false;FORM_ERROR=true
check(refresh()=="","Refused stance API stays quiet")
FORM_ERROR=false;FORM_COUNT_OVERRIDE=SECRET
check(refresh()=="","Hidden stance count stays quiet")
FORM_COUNT_OVERRIDE=nil;PALADIN_FORMS={};KNOWN[465]=false;KNOWN[643]=false
check(refresh()=="","No learned aura gives no missing-aura reminder")
PALADIN_FORMS={{active=true,spellID=465}};KNOWN[465]=true
HELPFUL={}
check(refresh()=="Missing: Righteous Fury","Missing Righteous Fury warns the assigned tank")
local outside=#SOUNDS
step(1)
check(#SOUNDS==outside and p.warningUrgent,"Outdoor grouped warning stands out without sound")
INSTANCE_KIND="party";INSTANCE_ID=36;LEADER=true
step(.5)
check(#SOUNDS==outside+1 and SOUNDS[#SOUNDS].channel=="Master","Dungeon missing buff plays one alert sound")
step(10)
check(#SOUNDS==outside+1,"Persistent missing buff never spams sound")
local alpha=p.warning.alpha;NOW=NOW+.3;p:Render()
check(p.warning.alpha~=alpha and p.warningGlow.alpha>0,"Missing tank buff blinks with a warm warning glow")
p.db.reducedMotion=true;NOW=NOW+.2;p:Render();local quiet=p.warning.alpha
NOW=NOW+.4;p:Render()
check(p.warning.alpha==quiet and p.warningGlow.alpha>0,"Reduced Motion retains a strong static warning")
p.db.reducedMotion=false
HELPFUL={{spellId=25780,name="Righteous Fury",expirationTime=0,duration=0}};refresh()
check(not p.warningUrgent and p.warningGlow.alpha==0,"Restored Fury clears blink and resets the loss episode")
HELPFUL={};step(.1)
check(#SOUNDS==outside+1,"Brief removal is debounced")
HELPFUL={{spellId=25780,name="Righteous Fury",expirationTime=0,duration=0}};step(.1)
check(#SOUNDS==outside+1,"Transient missing snapshot produces no sound")
HELPFUL={};step(2);step(.5)
check(#SOUNDS==outside+2,"A new confirmed Fury loss gets a new sound")
HELPFUL={{spellId=25780,name="Righteous Fury",expirationTime=0,duration=0}};refresh()
PALADIN_FORMS[1].active=false;step(2);step(.5)
check(#SOUNDS==outside+3 and p.warning.text=="Missing: Devotion Aura","Losing Devotion gets the same warning and dungeon sound")
HELPFUL[2]={spellId=465,name="Devotion Aura",sourceUnit="party1",expirationTime=0};refresh()
check(not p.warningUrgent,"Restored external coverage clears the alert")
HELPFUL[2]=nil;p.db.warningSounds=false;step(2);step(1)
check(p.warningUrgent and #SOUNDS==outside+3,"Sound switch mutes audio while visual warning remains")
p.db.warnAura=false;refresh()
check(not p.warningUrgent,"Aura toggle disables its alert")
p.db.warnAura=true;p.db.warningSounds=true;p.db.warnings=false;refresh()
check(p.warning.text=="" and not p.warningUrgent,"Master switch disables the alerts")
p.db.warnings=true;MOUNTED=true;refresh()
check(p.warning.text=="" and not p.warningUrgent,"Mounted tank is suppressed")
MOUNTED=false;DEAD=true;refresh()
check(p.warning.text=="" and not p.warningUrgent,"Dead tank is suppressed")
DEAD=false;p.preview=true;p.previewStart=NOW;refresh()
check(not p.warningUrgent and p.warning.text:find("PREVIEW"),"Preview cannot flash or play missing-buff warnings")
p.preview=false;PLAYER_ROLE="NONE";MAIN_TANK=false;step(1)
check(p.warning.text=="" and #SOUNDS==outside+3,"Unassigned role produces no tank buff reminders or sounds")
PLAYER_ROLE="TANK";p.db.warnAura=false
HELPFUL={{spellId=25780,name="Righteous Fury",expirationTime=0}};refresh()
HELPFUL={};step(3);step(.5);local beforeUnknown=#SOUNDS
RESTRICTED=true;step(3)
check(not p.warningUrgent and #SOUNDS==beforeUnknown,"Unknown Fury state cannot sound or flash a false loss")
RESTRICTED=false;step(3)
check(#SOUNDS==beforeUnknown,"An unreadable interval does not rearm an already sounded loss")
p.db.warnFury=false;refresh()
check(not p.warningUrgent and p:Warnings()=="","Fury reminder switch disables its alert independently")
p.db.warnFury=true;p.db.warnAura=true
PLAYER_ROLE=SECRET;refresh()
check(not p.warningUrgent,"Unreadable role cannot be treated as assigned tank")
PLAYER_ROLE="TANK";RAID=true;INSTANCE_KIND="raid"
UNITS.raid1={guid="Raid-paladin",class="PALADIN"}
HELPFUL={{spellId=25780,name="Righteous Fury",expirationTime=0},
    {spellId=10293,name="Devotion Aura",sourceUnit="raid1",expirationTime=0}}
check(refresh()=="","Equal or higher received raid-group Paladin aura also avoids overlap")
HELPFUL={};step(3);step(1)
check(p.warningUrgent and #SOUNDS==beforeUnknown,"Raid warnings stay visual; dungeon-only sound is not extended to raids")
RAID=false;INSTANCE_KIND="party";PALADIN_FORMS[1].active=true
HELPFUL={{spellId=25780,name="Righteous Fury",expirationTime=0}};refresh()
HELPFUL={};local soundBeforeCast=#SOUNDS
p.events.scripts.OnEvent(p.events,"UNIT_SPELLCAST_SUCCEEDED","player","fury-cast",25780)
step(1)
check(not p.warningUrgent and #SOUNDS==soundBeforeCast,"Successful Fury cast gets a short aura-delivery grace instead of a false loss alert")
HELPFUL={{spellId=25780,name="Righteous Fury",expirationTime=0}};step(.1)
check(not p.warningUrgent and #SOUNDS==soundBeforeCast,"Arriving Fury buff clears its handoff without audio")
print("PASS: "..n.." assigned-tank, rank-aware Devotion coverage and blink/sound checks.")

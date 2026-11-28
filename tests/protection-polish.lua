local p,n=TEST_NS,0
local function check(v,message) assert(v,message);n=n+1 end
local function effect(id,expiry,amount)
    return {spellId=id,name=C_Spell.GetSpellInfo(id).name,expirationTime=expiry,duration=8,points={amount}}
end
local function refresh()p:RefreshAuras();p:Render()end
local function event(name,...)p.events.scripts.OnEvent(p.events,name,...)end
GROUP,LEADER,COMBAT,INSTANCE_KIND,INSTANCE_ID=true,true,true,"party",36
KNOWN[1311015]=true;KNOWN[4987]=true;p:DiscoverSpells()
HELPFUL={effect(1311033,NOW+6),effect(1328551,NOW+6),effect(1311015,NOW+8,1000)}
refresh()
local iron,block,absorb=p.statusTiles.iron,p.statusTiles.block,p.statusTiles.absorb
check(not iron.expiring and not block.expiring,"Fresh protection does not show an expiration cue")
NOW=NOW+4.1;p:Render()
check(iron.expiring and block.expiring,"Both protection badges gain a final-two-second cue")
p.db.reducedMotion=true;p:Render();local alpha=iron.rim.alpha
NOW=NOW+.1;p:Render();check(iron.rim.alpha==alpha and iron.scale==1,"Reduced motion keeps expiration emphasis steady")
p.db.protectionExpiryCue=false;p:Render();check(not iron.expiring and not block.expiring,"Expiration cues have their own switch")
p.db.protectionExpiryCue=true;p.db.effects=false;p:Render();check(not iron.expiring,"Effects-off suppresses expiration decoration")
p.db.effects=true
RESTRICTED=true;AURA_ERROR=true;refresh()
check(not iron.expiring and not block.expiring,"Remembered deadlines do not claim a confirmed protection expiration")
check(not absorb.absorbFill:IsShown(),"Hidden absorb data removes the fill immediately")
RESTRICTED=false;AURA_ERROR=false;HELPFUL[3].points={500};refresh()
check(p.protection.absorb.capacity==1000 and absorb.absorbFraction==.5,"Absorb fill retains the observed peak across hidden reads")
check(absorb.absorbFill:IsShown() and absorb.absorbFill.height==8,"Half of the observed absorb fills half the icon")
check(absorb.icon.desaturated==false and absorb.icon.alpha==1,"Absorb fill preserves full-colour spell artwork")
p.db.bulwarkFill=false;p:Render();check(not absorb.absorbFill:IsShown() and absorb:IsShown(),"Fill can be disabled without hiding the protection timer")
p.db.bulwarkFill=true;HELPFUL[3].points={SECRET};refresh()
check(not absorb.absorbFill:IsShown(),"Secret absorb values never produce a guessed fill")
HELPFUL[3]=effect(1311015,NOW+8,600);refresh()
check(p.protection.absorb.capacity==600 and absorb.absorbFraction==1,"A new application starts a new observed baseline")
HELPFUL[3].points={300};p.db.reducedMotion=false;refresh()
check(absorb.absorbFraction>.5,"Normal absorb consumption eases instead of jumping")
for i=1,40 do NOW=NOW+1/60;p:Render()end
check(math.abs(absorb.absorbFraction-.5)<.001,"Absorb consumption settles to the observed value")
p.db.reducedMotion=true;HELPFUL[3].points={150};refresh()
check(absorb.absorbFraction==.25,"Reduced motion updates absorb fill immediately")
p.statusTiles.absorb.scripts.OnClick(nil,"MiddleButton")
check(not absorb:IsShown(),"Middle-click still hides the entire Bulwark status")
p.db.showBulwarkActive=true
HELPFUL[3]=nil;refresh();check(not absorb.absorbFill:IsShown(),"Readable early removal clears the fill")

-- Equipment checks respond immediately to inventory events, not aura polling.
HELPFUL={};GROUP=true;PLAYER_ROLE="TANK";EQUIPPED_OFFHAND=nil
event("PLAYER_EQUIPMENT_CHANGED",17)
check(p:Warnings():find("Equip shield") and p.warningUrgent,"Assigned tank gets an urgent missing-shield reminder")
MOUNTED=true;p:Render();check(not p:MissingShield(),"Mounted players do not get the missing-shield reminder")
MOUNTED=false;DEAD=true;check(not p:MissingShield(),"Dead players do not get the missing-shield reminder")
DEAD=false;PLAYER_ROLE="HEALER";check(not p:MissingShield(),"Other group roles do not get the missing-shield reminder")
PLAYER_ROLE="TANK";GROUP=false;check(not p:MissingShield(),"Solo players do not get the missing-shield reminder")
GROUP=true;p.db.warnMissingShield=false;check(not p:MissingShield(),"Missing-shield reminder has an independent switch")
p.db.warnMissingShield=true;p.db.warnings=false;check(not p:MissingShield(),"Master reminders switch suppresses missing-shield alerts")
p.db.warnings=true;EQUIPPED_OFFHAND=90000;ITEM_EQUIP_LOC="INVTYPE_WEAPONOFFHAND"
event("PLAYER_EQUIPMENT_CHANGED",17);check(p:MissingShield(),"An offhand weapon does not count as a shield")
ITEM_EQUIP_LOC="INVTYPE_SHIELD";event("PLAYER_EQUIPMENT_CHANGED",17)
check(not p:MissingShield() and not p:Warnings():find("Equip shield"),"Equipping a shield clears the reminder immediately")
ITEM_ERROR=true;event("PLAYER_EQUIPMENT_CHANGED",17);check(p.shieldEquipped==nil and not p:MissingShield(),"Uncached equipment data never guesses a missing shield")
ITEM_ERROR=false;EQUIPPED_OFFHAND=SECRET;event("PLAYER_EQUIPMENT_CHANGED",17)
check(p.shieldEquipped==nil and not p:MissingShield(),"Secret equipment identity never produces an alert")
EQUIPPED_OFFHAND=90000

local reads={}
local original=C_UnitAuras.GetAuraDataByIndex
C_UnitAuras.GetAuraDataByIndex=function(unit,index,filter)
    reads[filter]=(reads[filter] or 0)+1;return original(unit,index,filter)
end
HELPFUL={effect(1311033,NOW+6),effect(1328551,NOW+6),effect(1311015,NOW+8,500)}
refresh()
check(reads.HELPFUL==4,"Timer, Devotion and protection readers share one indexed helpful scan")
check(not p.auraScanCache,"Aura snapshots are discarded after each refresh")
HELPFUL[1].expirationTime=NOW+5.5;local expiry=HELPFUL[1].expirationTime
event("UNIT_AURA","player")
check(p.protection.iron.expires==expiry and reads.HELPFUL==8,"An aura event takes a fresh immediate snapshot")
reads={};event("UNIT_AURA","party1");check(not next(reads),"Another unit's aura event does not rescan player buffs")
HELPFUL[3].points={250};event("UNIT_ABSORB_AMOUNT_CHANGED","player")
check(p.protection.absorb.amount==250,"Absorb-change events refresh the fill without waiting for fallback polling")
C_UnitAuras.GetAuraDataByIndex=original
COMBAT=false;p.sealPending=nil;p.lastHolyCast=nil
check(p:AuraPollInterval()==1,"Idle fallback scans run at one-second intervals")
COMBAT=true;check(p:AuraPollInterval()==.5,"Combat retains a half-second fallback")
p.sealPending={untilTime=NOW+3};check(p:AuraPollInterval()==.2,"Seal handoffs retain fast reconciliation")
p.sealPending=nil;p.lastHolyCast=NOW;check(p:AuraPollInterval()==.2,"Holy Shield handoffs retain fast reconciliation")

local scans,renders=0,0
local originalRefresh,originalRender=p.RefreshAuras,p.Render
p.RefreshAuras=function(self,...)scans=scans+1;return originalRefresh(self,...)end
p.Render=function(self,...)renders=renders+1;return originalRender(self,...)end
COMBAT=false;p.lastHolyCast=nil;p.lastAuraRefresh=NOW
for i=1,126 do NOW=NOW+1/60;p.events.scripts.OnUpdate(p.events,1/60)end
check(scans==2 and renders>=120,"Idle fallback does two scans over two seconds while animation keeps its frame cadence")
scans=0;COMBAT=true;p.lastAuraRefresh=NOW
for i=1,126 do NOW=NOW+1/60;p.events.scripts.OnUpdate(p.events,1/60)end
check(scans==4,"Combat fallback keeps half-second checks instead of five full scans per second")
p.RefreshAuras,p.Render=originalRefresh,originalRender

INSTANCE_ID=2999;UNITS={target={guid="Creature-0-1-2999-1-250657-a",name="Witherfang",hostile=true,dead=false,combat=true}}
PLATES={};p.personalCleanse={name="Leech Poison",kind="Poison"};p:UpdateEncounterCue()
check(p.encounterCue and p.encounterCue.text:find("Purify/Cleanse"),"Verified personal poison adds a Paladin-specific encounter cue")
p.personalCleanse=nil;p:UpdateEncounterCue();check(not p.encounterCue,"Personal poison cue clears when the removable debuff clears")
UNITS.target.name="The Baron";UNITS.target.cast="Knockout";p:UpdateEncounterCue()
check(p.encounterCue and p.encounterCue.text:find("Hammer of Justice"),"Reviewed Baron cast cue names the Paladin control tool")
check(#MARKS==0,"Protection visuals and encounter tips never mark or cast")
print("PASS: "..n.." protection polish, equipment, shared scans and Paladin encounter checks.")

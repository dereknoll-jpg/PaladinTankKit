local p,n=TEST_NS,0
local function check(v,message)assert(v,message);n=n+1 end
local function event(name,...)p.events.scripts.OnEvent(p.events,name,...)end
local function hiddenCast(id,slot)
    ACTION_DESCRIPTIONS[slot or 1]={"spell",id}
    UseAction(slot or 1)
    event("UNIT_SPELLCAST_SENT","player",SECRET,SECRET,SECRET)
    event("UNIT_SPELLCAST_SUCCEEDED","player",SECRET,SECRET)
end
local spellInfo,cooldownInfo=C_Spell.GetSpellInfo,C_Spell.GetSpellCooldown
UNITS.player={name="Test Paladin",guid="Player-1-test"}
function UnitFullName()return "Test Paladin","TestRealm" end
KNOWN[1311015]=true;KNOWN[1311034]=true;KNOWN[1328544]=true
p:DiscoverSpells();p.db.effects=false
HELPFUL={{spellId=25780,name="Righteous Fury",expirationTime=0,duration=0}};p:RefreshAuras()
COMBAT,RESTRICTED,AURA_ERROR=true,true,true
C_Spell.GetSpellInfo=function()return SECRET end
C_Spell.GetSpellCooldown=function()return {startTime=SECRET,duration=SECRET,isEnabled=SECRET,modRate=SECRET}end
hiddenCast(1311015)
check(p.statusTiles.absorb:IsShown() and p.statusTiles.absorb.count.text=="~8","A first Bulwark cast in fully hidden combat immediately starts its active upper-row timer")
check(p.forbearanceTile:IsShown() and p:ForbearanceActive(),"The same first combat cast starts the separate Forbearance badge")
check(p.protection.absorb.estimated and not p.statusTiles.absorb.absorbFill:IsShown(),"Cast timing is labeled estimated and never invents absorb strength")
local absorbEnd,fbEnd=p.protection.absorb.expires,p.auras.forbearance.expires
hiddenCast(678,2)
check(p.statusTiles.iron:IsShown() and p.statusTiles.block:IsShown(),"A first Holy Strike in combat starts both learned protection effects")
check(p.statusTiles.iron.count.text=="~6" and p.statusTiles.block.count.text=="~6","Both six-second estimates are labeled")
check(p.protection.absorb.expires==absorbEnd and p.auras.forbearance.expires==fbEnd,"Holy Strike cannot restart Bulwark or Forbearance")
local ironEnd=p.protection.iron.expires
for i=1,5 do NOW=NOW+.2;event("UNIT_AURA","player")end
check(p.protection.iron.expires==ironEnd and p.protection.absorb.expires==absorbEnd,"Aura polling never restarts cast deadlines")
UNITS.target={name="Other target",guid="Creature-0-1-36-1-999-a",hostile=true}
event("PLAYER_TARGET_CHANGED");check(p.protection.iron.expires==ironEnd,"Changing targets cannot alter the upper timers")
hiddenCast(20271,3);check(p.auras.forbearance.expires==fbEnd,"Judgement cannot restart protection or Forbearance")

-- A readable buff replaces estimates immediately; readable removal still wins.
AURA_ERROR,RESTRICTED=false,false
HELPFUL={{spellId=1311015,name="Templar's Bulwark",expirationTime=NOW+4,duration=8,points={400}},
    {spellId=1311033,name="Iron Creed",expirationTime=NOW+3,duration=6},
    {spellId=1328551,name="Shieldsworn",expirationTime=NOW+2,duration=6}}
HARMFUL={{spellId=25771,name="Forbearance",expirationTime=NOW+40,duration=50}}
event("UNIT_AURA","player")
check(not p.protection.absorb.estimated and p.protection.absorb.expires==NOW+4,"Live Bulwark timing immediately replaces its estimate")
check(not p.auras.forbearance.estimated and p.auras.forbearance.expires==NOW+40,"Live Forbearance timing immediately replaces its estimate")
check(p.statusTiles.absorb.absorbFill:IsShown(),"Real absorb data enables the fill; cast estimates never do")
HELPFUL={};HARMFUL={};event("UNIT_AURA","player")
check(not p.protection.absorb and not p.protection.iron and not p.protection.block and not p:ForbearanceActive(),"Readable early removal clears all four upper effects")

-- Initial readable identities with secret timestamps must also use cast fallback.
RESTRICTED,AURA_ERROR=true,false
HELPFUL={{spellId=1311015,name="Templar's Bulwark",expirationTime=SECRET,duration=SECRET,points={SECRET}}}
HARMFUL={{spellId=25771,name="Forbearance",expirationTime=SECRET,duration=SECRET}}
hiddenCast(1311015)
check(p.statusTiles.absorb:IsShown() and p.forbearanceTile:IsShown(),"Known aura identities with hidden timing also start on the first confirmed combat cast")
check(not p.statusTiles.absorb.absorbFill:IsShown(),"Secret absorb points cannot leak into the fill")
NOW=NOW+8.1;event("UNIT_AURA","player")
check(not p.protection.absorb and p:ForbearanceActive(),"Bulwark expires independently while Forbearance continues")
NOW=NOW+60;event("UNIT_AURA","player")
check(not p:ForbearanceActive(),"Hidden Forbearance never extends beyond its bounded deadline")

-- Rejected requests and proc notifications are never successful player casts.
AURA_ERROR=true;p:ClearUsedTimers()
ACTION_DESCRIPTIONS[1]={"spell",1311015};UseAction(1)
event("UNIT_SPELLCAST_SENT","player",SECRET,SECRET,SECRET)
check(not next(p.protectionCasts),"A spell request alone cannot show protection")
event("UNIT_SPELLCAST_FAILED","player",SECRET)
event("UNIT_SPELLCAST_SUCCEEDED","player",SECRET,SECRET)
check(not next(p.protectionCasts) and not p.effectTimers.forbearance,"A failed request cannot seed estimates through a late hidden notification")
event("UNIT_SPELLCAST_SUCCEEDED","player","proc",1311015)
check(not next(p.protectionCasts),"An uncorrelated success/proc cannot seed protection")
event("UNIT_SPELLCAST_SENT","party1","Test Paladin","foreign",1311015)
event("UNIT_SPELLCAST_SUCCEEDED","party1","foreign",1311015)
check(not next(p.protectionCasts),"Another player's casts cannot seed your protection")

-- Cache talent, Fury and shield gates before/through combat restrictions.
for _,id in ipairs({678,679,680,1866,2495,5569,10332,10333})do
    p.protectionCasts={};p.protection={};p.lastKnownFury=true
    hiddenCast(id,2)
    check(p.protection.iron and p.protection.block,"Every verified Holy Strike rank is recognized: "..id)
end
p.protectionCasts={};p.protection={};p.lastKnownFury=false
hiddenCast(678,2)
check(not p.protection.iron and p.protection.block,"Iron Creed requires last-confirmed Fury; spell block remains independent")
p.protectionCasts={};p.protection={};EQUIPPED_OFFHAND=nil;p:RefreshShieldState();p.lastKnownFury=true
hiddenCast(678,2)
check(p.protection.iron and not p.protection.block,"Missing shield suppresses only spell-block estimates")
EQUIPPED_OFFHAND=90000;p:RefreshShieldState();EQUIPPED_OFFHAND=SECRET;p:RefreshShieldState()
p.protectionCasts={};p.protection={};hiddenCast(678,2)
check(p.protection.block and p.shieldEquipped==nil,"Previously confirmed equipped shield survives unreadable equipment for cast estimates only")
KNOWN[1311034],KNOWN[1328544]=false,false;p:DiscoverSpells()
p.protectionCasts={};p.protection={};hiddenCast(678,2)
check(not p.protection.iron and not p.protection.block,"Untalented Holy Strike never invents protection buffs")

-- Self-only immunities and explicitly self-targeted Blessing use separate FB timing.
p:ClearUsedTimers();p.db.observedDurations.forbearance=nil;p.talentRanks={['sacred duty']=2}
hiddenCast(642,3)
check(p.auras.forbearance.estimated and p.auras.forbearance.duration==50,"First hidden self-immunity cast uses cached Sacred Duty ranks")
p:ClearUsedTimers()
event("UNIT_SPELLCAST_SENT","player","Other Paladin","ally",1022)
event("UNIT_SPELLCAST_SUCCEEDED","player","ally",1022)
check(not p.effectTimers.forbearance,"Blessing of Protection on somebody else cannot lock out the player")
event("UNIT_SPELLCAST_SENT","player",SECRET,"unknown",1022)
event("UNIT_SPELLCAST_SUCCEEDED","player","unknown",1022)
check(not p.effectTimers.forbearance,"A hidden Blessing target is never assumed to be yourself")
event("UNIT_SPELLCAST_SENT","player","Test Paladin","self",1022)
event("UNIT_SPELLCAST_START","player","self",1022)
event("UNIT_SPELLCAST_SUCCEEDED","player","self",1022)
check(p:ForbearanceActive(),"A proven self-targeted Blessing starts Forbearance, preserving SENT target across START")
p:ClearUsedTimers()
event("UNIT_SPELLCAST_SENT","player","Test Paladin-TestRealm","self-realm",1022)
event("UNIT_SPELLCAST_SUCCEEDED","player","self-realm",1022)
check(p:ForbearanceActive(),"Realm-qualified self targets are recognized without inspecting the current target")
p:ClearUsedTimers()
event("UNIT_SPELLCAST_SENT","player","Test Paladin-OtherRealm","same-name-ally",1022)
event("UNIT_SPELLCAST_SUCCEEDED","player","same-name-ally",1022)
check(not p:ForbearanceActive(),"A same-name character on another realm cannot trigger your lockout estimate")

-- A refresh cannot be undone by one old aura snapshot during the handoff.
KNOWN[1311034],KNOWN[1328544]=true,true;p:DiscoverSpells()
RESTRICTED,AURA_ERROR=false,false;EQUIPPED_OFFHAND=90000;p:RefreshShieldState()
HELPFUL={{spellId=25780,name="Righteous Fury",expirationTime=0,duration=0},
    {spellId=1311033,name="Iron Creed",expirationTime=NOW+1,duration=6}}
HARMFUL={};event("UNIT_AURA","player")
local prior=NOW+1
hiddenCast(678,2)
check(p.protection.iron.estimated and p.protection.iron.expires>prior,"A freshly confirmed Holy Strike survives an older aura snapshot")
HELPFUL[2].expirationTime=NOW+5.8;event("UNIT_AURA","player")
check(not p.protection.iron.estimated and p.protection.iron.expires==NOW+5.8,"The fresh real snapshot replaces the refresh estimate immediately")

-- Known empty snapshots get a short handoff, not a false full-duration buff.
p:ClearUsedTimers();AURA_ERROR,RESTRICTED=false,false;HELPFUL={};HARMFUL={}
hiddenCast(1311015)
check(p.protection.absorb and p:ForbearanceActive(),"Successful casts survive the brief aura-application handoff")
NOW=NOW+1;event("UNIT_AURA","player")
check(not p.protection.absorb and not p:ForbearanceActive(),"Readable absence after the handoff cancels unconfirmed effects")
hiddenCast(1311015);HELPFUL={{spellId=1311015,name="Templar's Bulwark",expirationTime=NOW+8,duration=8,points={0}}}
event("UNIT_AURA","player")
check(not p.protection.absorb,"Readable depletion overrides even a just-started Bulwark estimate")

p:ClearUsedTimers();HELPFUL={};HARMFUL={};RESTRICTED,AURA_ERROR=true,true
C_Spell.GetSpellCooldown=cooldownInfo
COOLDOWNS[1311015]={startTime=NOW-20,duration=300,isEnabled=true,modRate=1}
p:RecoverCooldowns();p:RefreshAuras();p:Render()
check(p.cooldownTimers.bulwark and not p.protection.absorb and not p:ForbearanceActive(),"Recovering an old cooldown cannot fabricate an active shield or fresh Forbearance")
hiddenCast(1311015);p.statusTiles.absorb.scripts.OnClick(nil,"MiddleButton")
check(not p.statusTiles.absorb:IsShown() and p.protection.absorb,"Middle-click hiding still preserves the combat tracker")
p:RestoreTimers();check(p.statusTiles.absorb:IsShown(),"Restoring a hidden combat status reuses its original deadline")
DEAD=true;event("PLAYER_DEAD")
check(not next(p.protectionCasts) and not next(p.protection) and not p:ForbearanceActive(),"Death clears pending protection and Forbearance estimates")
print("PASS: "..n.." combat protection checks.")

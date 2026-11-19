local p,n=TEST_NS,0
local function check(v,message) assert(v,message);n=n+1 end
local function event(name,...) p.events.scripts.OnEvent(p.events,name,...) end
local function step(seconds) NOW=NOW+seconds;p:RefreshAuras();p:RefreshUsedCooldowns();p:Render() end
p.db.effects=false;COMBAT=true;GROUP=true
HELPFUL={{spellId=20375,name="Seal of Command",expirationTime=NOW+120,duration=120}}
p:RefreshAuras();local sealEnd=p.auras.seal.expires
RESTRICTED=true;HELPFUL={}
event("UNIT_SPELLCAST_SUCCEEDED","player","seal-proc",20375)
check(p.auras.seal.expires==sealEnd,"A Seal proc cannot clear remembered buff timing")
step(.5);event("UNIT_SPELLCAST_SUCCEEDED","player","another-proc",20375)
check(p.auras.seal.expires==sealEnd,"Repeated procs cannot restart the Seal")

RESTRICTED=false
local indexed=C_UnitAuras.GetAuraDataByIndex
C_UnitAuras.GetAuraDataByIndex=function() error("index unavailable") end
C_UnitAuras.GetAuraDataBySpellName=function(unit,name,filter)
    assert(unit=="player","Direct lookups must never read target buffs")
    for _,a in ipairs(filter=="HARMFUL" and HARMFUL or HELPFUL) do if a.name==name then return a end end
end
HELPFUL={{spellId=20375,name="Seal of Command",expirationTime=sealEnd,duration=120},
    {spellId=20925,name="Holy Shield",expirationTime=NOW+10,duration=10}}
p:RefreshAuras()
check(p.auras.seal.expires==sealEnd and not p.auras.seal.estimated,"Direct name lookup restores authoritative Seal timing")
check(p.auras.holy.expires==NOW+10,"Direct name lookup tracks Holy Shield independently")
HELPFUL={};p:RefreshAuras()
check(not p.auras.seal.active and not p.auras.holy.active,"Readable direct absence clears removed buffs even with failed index API")
C_UnitAuras.GetAuraDataBySpellName=nil
C_UnitAuras.GetPlayerAuraBySpellID=function(id)
    for _,a in ipairs(HELPFUL) do if a.spellId==id then return a end end
end
HELPFUL={{spellId=20165,name="Seal of Light",expirationTime=NOW+90,duration=120}}
p:RefreshAuras()
check(p.activeSeal.name=="Seal of Light" and p.auras.seal.expires==NOW+90,"Direct ID lookup finds active Seal without cast events")
C_UnitAuras.GetAuraDataByIndex=indexed
C_UnitAuras.GetPlayerAuraBySpellID=nil
local lightEnd=p.auras.seal.expires
HELPFUL[1].expirationTime=0;p:RefreshAuras()
check(p.auras.seal.expires==lightEnd and p.auras.seal.estimated,"Transient zero buff timing preserves verified expiration")

p:ClearUsedTimers();p.ground=nil;HELPFUL={};COOLDOWNS={}
COOLDOWNS[26573]={startTime=NOW,duration=8,isEnabled=true}
event("SPELL_UPDATE_COOLDOWN")
local groundEnd=NOW+8
check(p.ground and p.ground.expires==groundEnd,"Missed Consecration cast recovers from cooldown start")
event("UNIT_SPELLCAST_SENT","player","target","seal-request",20154)
HELPFUL={{spellId=20154,name="Seal of Righteousness",expirationTime=NOW+120,duration=120}}
event("UNIT_SPELLCAST_SUCCEEDED","player","seal-request",20154)
local righteousEnd=p.auras.seal.expires
COOLDOWNS[26573]={startTime=NOW,duration=1.5,isEnabled=true}
step(1);event("UNIT_SPELLCAST_SUCCEEDED","player","judgement",20271)
event("PLAYER_TARGET_CHANGED")
check(p.ground.expires==groundEnd and p.groundTile:IsShown(),"Seal, Judgement, target changes and GCD cannot remove Consecration")
check(p.auras.seal.expires==righteousEnd,"Judgement and target changes preserve the real Seal deadline")
HELPFUL={};event("PLAYER_TARGET_CHANGED")
check(p.auras.seal.expires==righteousEnd,"Changing enemies does not rescan or invalidate player buff timing")
RESTRICTED=true;HELPFUL={};step(2)
event("UNIT_SPELLCAST_SUCCEEDED","player","righteous-proc",20154)
check(p.auras.seal.expires==righteousEnd,"Proc during hidden aura reads preserves the last real timer")
check(p.ground.expires==groundEnd,"Unrelated proc cannot restart Consecration")
step(4.9);check(p.groundTile:IsShown(),"Consecration remains through its full eight-second window")
step(.2);check(p.ground==nil,"Consecration expires at its own deadline")

RESTRICTED=false;COOLDOWNS={};p:ClearUsedTimers();p.ground=nil
event("UNIT_SPELLCAST_SENT","player","target","ground-request",26573)
check(p.ground==nil,"Requesting a spell is not a successful cast")
event("UNIT_SPELLCAST_SUCCEEDED","player","different-cast",SECRET)
check(p.ground==nil,"Unmatched hidden success cannot consume a pending request")
event("UNIT_SPELLCAST_SUCCEEDED","player","ground-request",SECRET)
check(p.ground and p.ground.expires==NOW+8,"Exact readable cast GUID recovers its successful request")
local confirmedEnd=p.ground.expires
step(1);event("UNIT_SPELLCAST_SUCCEEDED","player","ground-tick",26573)
check(p.ground.expires==confirmedEnd,"Duplicate ground effect events cannot restart the timer")
GetTotemInfo=function(slot) if slot==1 then return true,"Consecration",NOW-2,8 end return false end
p:RefreshAuras()
check(p.ground.expires==NOW+6 and not p.ground.estimated,"Player ground-effect slot supplies authoritative timing")
GetTotemInfo=nil
HELPFUL={{spellId=26573,name="Consecration",expirationTime=NOW+5,duration=8}}
p:RefreshAuras()
check(p.ground.expires==NOW+5 and p.ground.source=="aura","Readable Consecration buff takes precedence")

local modern=C_Spell.GetSpellCooldown
C_Spell.GetSpellCooldown=function()return NOW-2,8,1,1 end
check(p:Cooldown("ground")==6,"Legacy tuple cooldown results are supported")
C_Spell.GetSpellCooldown=modern
KNOWN[20116]=true;p:DiscoverSpells()
COOLDOWNS[20116]=nil;COOLDOWNS[26573]={startTime=NOW-2,duration=8,isEnabled=true}
check(p:Cooldown("ground")==6,"Cooldown family can recover through another learned rank")

p.db.effects=true
for _,state in ipairs({"active","cooldown","unknown","ready"}) do
    p:PresentTimer("ground",state,{active=true,expires=NOW+5},NOW,"5")
    check(p.groundTile.icon.desaturated==false and p.groundTile.icon.alpha==1,"Full-colour artwork for state "..state)
end
check(p.events.events.UNIT_SPELLCAST_SENT and p.events.events.UNIT_SPELLCAST_START,"Cast correlation events are registered")
print("PASS: "..n.." overlapping timers, player aura fallback, cast correlation and full-colour icon regressions.")

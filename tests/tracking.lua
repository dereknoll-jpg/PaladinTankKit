local p, n = TEST_NS, 0
local function check(v, message) assert(v, message); n=n+1 end
local function event(unit,id) p.events.scripts.OnEvent(p.events,"UNIT_SPELLCAST_SUCCEEDED",unit,"cast",id) end
local function advance(seconds) NOW=NOW+seconds; p:RefreshUsedCooldowns(); p:Render() end
p.db.effects=false
COMBAT=true
p:RefreshAuras(); p:Render()
for _,key in ipairs({"seal","ground","justice"}) do check(not p[key.."Tile"]:IsShown(), "Unused ability stays hidden: "..key) end
for index,entry in ipairs({{1311656,"Seal of Fury"},{20154,"Seal of Righteousness"},{21082,"Seal of the Crusader"},
    {20164,"Seal of Justice"},{20165,"Seal of Light"},{20166,"Seal of Wisdom"},{20375,"Seal of Command"},{20920,"Seal of Command"}}) do
    HELPFUL={{spellId=entry[1],name=entry[2],expirationTime=NOW+120+index,duration=120+index}}
    event("player",entry[1])
    check(p.activeSeal.name==entry[2], "Last Seal name: "..entry[2])
    check(p.sealTile.icon.texture==entry[1], "Last Seal icon: "..entry[2])
    check(p.auras.seal.expires==NOW+120+index and not p.auras.seal.estimated and p.sealTile:IsShown(), "Seal uses live duration, not a 30-second assumption")
    NOW=NOW+1
end
local sealExpiry=p.auras.seal.expires
event("player",20271)
check(p.sealTile:IsShown() and p.auras.seal.expires==sealExpiry,"Judgement cannot clear or restart Seal")
advance(5); p:RefreshAuras(); p:Render()
check(p.auras.seal.expires==sealExpiry,"Subsequent aura scans cannot restart Seal")
p.events.scripts.OnEvent(p.events,"SPELL_UPDATE_COOLDOWN")
check(p.auras.seal.expires==sealExpiry,"Ability cooldown updates cannot restart Seal")
HELPFUL[1].expirationTime=NOW+200; HELPFUL[1].duration=200
p.events.scripts.OnEvent(p.events,"UNIT_AURA","player",{})
check(p.auras.seal.expires==NOW+200 and p.memory.seal.expires==NOW+200,"Blizzard buff changes update expiration immediately")
HELPFUL[1].expirationTime=NOW+12; HELPFUL[1].duration=200
p.events.scripts.OnEvent(p.events,"UNIT_AURA","player",{})
check(p.sealTile.count.text=="12","Blizzard shortened expiration updates countdown immediately")
HELPFUL={}; p.events.scripts.OnEvent(p.events,"UNIT_AURA","player",{})
check(not p.sealTile:IsShown() and p.memory.seal==nil,"Readable buff removal clears Seal even in combat")
COMBAT=false
HELPFUL={{spellId=1311656,name="Seal of Fury",expirationTime=NOW+20,duration=30}}
p:RefreshAuras()
event("player",20154)
check(p.activeSeal.name=="Seal of Righteousness" and p.auras.seal.uncertain and p.memory.seal==nil,"Late old aura cannot undo swap or donate its duration")
HELPFUL={}; event("player",20166)
check(p.auras.seal.uncertain and p.memory.seal==nil and p.sealTile.count.text=="?","Cast without aura waits for Blizzard duration")
advance(1); p:RefreshAuras(); p:Render()
check(not p.sealTile:IsShown(),"Readable absence clears expired cast grace")
HELPFUL={{spellId=20375,name="Seal of Command",expirationTime=NOW+96,duration=120}}
p.events.scripts.OnEvent(p.events,"PLAYER_ENTERING_WORLD")
check(p.activeSeal.name=="Seal of Command" and p.sealTile.count.text=="1:36","Loading restores actual Seal remainder without a new cast")
advance(1)
check(p.sealTile.count.text=="1:35","Long Seal countdown updates every second beyond rail horizon")
RESTRICTED=true; HELPFUL={}; p:RefreshAuras(); p:Render()
check(p.auras.seal.expires==NOW+95 and p.auras.seal.estimated,"Hidden aura remembers only Blizzard's last verified expiration")
event("player",20271)
check(p.auras.seal.expires==NOW+95,"Judgement cannot clear remembered Blizzard expiration")
HELPFUL={{spellId=20165,name="Seal of Light",expirationTime=SECRET,duration=SECRET}}
p:RefreshAuras(); p:Render()
check(p.activeSeal.name=="Seal of Light" and p.auras.seal.uncertain and p.auras.seal.expires==nil,"New aura cannot inherit old Seal's timing")
RESTRICTED=false; HELPFUL={}; p:RefreshAuras(); p:Render()
COMBAT=true
COOLDOWNS[10308]={startTime=NOW,duration=45,isEnabled=true}
event("party1",10308); event(SECRET,SECRET)
check(not p.justiceTile:IsShown(),"Other players and hidden casts cannot start Hammer")
event("player",10308)
check(p.justiceTile:IsShown() and p.justiceTile.count.text=="45","Hammer uses actual cast rank and modified cooldown")
check(p.justiceTile.motion.state=="cooldown","Hammer renders as cooldown, separate from active effects")
COOLDOWNS[10308]={startTime=SECRET,duration=SECRET,isEnabled=true}
advance(5)
check(p.justiceTile.count.text=="~40","Hidden cooldown continues last readable expiry as estimate")
advance(41)
check(not p.justiceTile:IsShown() and p.readyUntil.justice==nil,"Hidden expiration cannot claim ready")
COOLDOWNS[10308]={startTime=NOW,duration=60,isEnabled=true}
event("player",10308); advance(60)
check(p.justiceTile.motion.state=="ready","Confirmed cooldown completion gets ready effect")
advance(1)
check(not p.justiceTile:IsShown(),"Ready Hammer clears without an idle placeholder")
COOLDOWNS[10308]={startTime=SECRET,duration=SECRET,isEnabled=true}
event("player",10308)
check(p.justiceTile.count.text=="?","Used Hammer with unavailable cooldown shows honest unknown")
p:ClearUsedTimers(); p:Render()
check(not p.justiceTile:IsShown(),"Lifecycle reset removes used cooldown history")
COOLDOWNS[26573]=nil
event("player",26573)
check(p.groundTile.count.text=="~8","Used Consecration displays ground lifetime")
advance(8)
check(p.groundTile.motion.state=="ready","Ground completion allows short confirmed-ready state")
advance(1)
check(not p.groundTile:IsShown(),"Completed Consecration clears")
local views={}
for _,key in ipairs({"seal","ground","justice"}) do views[key]={state="active",aura={active=true,expires=NOW+30}} end
p:BuildTimerLayout(views,NOW)
local positions={p.timerPositions.seal,p.timerPositions.ground,p.timerPositions.justice}
table.sort(positions)
check(positions[2]-positions[1]>=28 and positions[3]-positions[2]>=28,"Three coincident timers fit without overlap")
check(positions[1]>=76 and positions[3]<=438,"Three timers stay inside single rail")
print("PASS: "..n.." last-Seal, Hammer of Justice and used-only tracking checks.")

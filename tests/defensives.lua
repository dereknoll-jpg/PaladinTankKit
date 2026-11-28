local p,n=TEST_NS,0
local function check(value,message) assert(value,message); n=n+1 end
local function event(name,...) p.events.scripts.OnEvent(p.events,name,...) end
local function cast(id,unit) event("UNIT_SPELLCAST_SUCCEEDED",unit or "player","cast",id) end
local function advance(dt) NOW=NOW+dt; p:RefreshUsedCooldowns(); p:Render() end
p.db.effects=false; COMBAT=true
check(not p.holyTile:IsShown() and not p.bulwarkTile:IsShown(),"Unused defensives have no placeholder")
COOLDOWNS[1311015]={startTime=NOW,duration=300,isEnabled=true}
cast(1311015)
check(p.used.bulwark==nil and not p.bulwarkTile:IsShown(),"Untalented Bulwark cannot start tracking")
COOLDOWNS[1311015]=nil; KNOWN[1311015]=true; event("SPELLS_CHANGED")
check(not p.bulwarkTile:IsShown(),"Learning Bulwark alone does not show icon")
cast(1311015,"party1")
check(p.used.bulwark==nil,"Other player's Bulwark cannot start cooldown")
COOLDOWNS[1311015]={startTime=NOW,duration=240,isEnabled=true}; cast(1311015)
check(p.bulwarkTile.count.text=="4:00" and p.bulwarkTile.motion.state=="cooldown","Bulwark uses live talent-adjusted cooldown")
advance(2); COOLDOWNS[1311015].duration=180; event("SPELL_UPDATE_COOLDOWN")
check(p.bulwarkTile.count.text=="2:58","Bulwark updates when Blizzard changes cooldown")
COOLDOWNS[1311015]={startTime=SECRET,duration=SECRET,isEnabled=true}; advance(2)
check(p.bulwarkTile.count.text=="~2:56","Bulwark only remembers a previously readable cooldown")
advance(177)
check(not p.bulwarkTile:IsShown() and p.readyUntil.bulwark==nil,"Hidden expiry cannot claim Bulwark ready")
COOLDOWNS[1311015]={startTime=NOW,duration=240,isEnabled=true}; cast(1311015); advance(240)
check(p.bulwarkTile.motion.state=="ready","Readable Bulwark completion gives short ready state")
advance(1)
check(not p.bulwarkTile:IsShown(),"Bulwark disappears after ready animation")
COOLDOWNS[1311015]={startTime=NOW,duration=300,isEnabled=true}; cast(1311015)
KNOWN[1311015]=false; COMBAT=false; event("PLAYER_TALENT_UPDATE");COMBAT=true
check(not p.bulwarkTile:IsShown() and p.used.bulwark==nil,"Removing talent clears Bulwark tracking")
KNOWN[1311015]=SECRET; cast(1311015)
check(p.used.bulwark==nil,"Unreadable talent state never starts Bulwark")
KNOWN[1311015]=false
cast(20928)
check(p.holyTile.count.text=="~10" and p.memory.holy==nil,"Successful Holy Shield has a bounded independent estimate until buff timing arrives")
HELPFUL={{spellId=20928,name="Holy Shield",expirationTime=NOW+7,duration=10}}
event("UNIT_AURA","player",{})
check(p.holyTile.count.text=="7" and not p.auras.holy.estimated,"Holy Shield tracks Blizzard remaining duration")
advance(1); cast(20271)
check(p.holyTile.count.text=="6","Judgement cannot reset Holy Shield")
HELPFUL[1].expirationTime=NOW+3; event("UNIT_AURA","player",{})
check(p.holyTile.count.text=="3","Holy Shield follows shortened buff expiry")
RESTRICTED=true; HELPFUL={}; advance(0.5); p:RefreshAuras(); p:Render()
check(p.auras.holy.estimated and p.holyTile.count.text=="~3","Hidden Holy Shield keeps verified expiry as estimate")
RESTRICTED=false; event("UNIT_AURA","player",{})
check(not p.holyTile:IsShown(),"Early buff removal clears Holy Shield when charges run out")
HELPFUL={{spellId=1239570,name="Holy Shield",expirationTime=NOW+5,duration=10}}
event("PLAYER_ENTERING_WORLD")
check(p.holyTile.count.text=="5","Readable active Holy Shield restores after loading")
local views={}; for _,key in ipairs(p.timerKeys) do views[key]={state="active",aura={active=true,expires=NOW+30}} end
p:BuildTimerLayout(views,NOW)
local positions={};for _,key in ipairs(p.timerKeys) do positions[#positions+1]=p.timerPositions[key] end
table.sort(positions)
for i=2,#positions do check(positions[i]-positions[i-1]>=28,"Five coincident timers remain separated") end
check(positions[1]>=76 and positions[5]<=438,"Five timers fit within unchanged rail")
HELPFUL={{spellId=25780,name="Righteous Fury",expirationTime=0,duration=0}}
COMBAT=false; GROUP=false
EQUIPPED_OFFHAND=nil; ITEM_DURABILITY={1,100}; event("PLAYER_EQUIPMENT_CHANGED",17)
check(p:Warnings()=="","No shield equipped means no shield warning")
EQUIPPED_OFFHAND=1001; ITEM_EQUIP_LOC="INVTYPE_WEAPONOFFHAND"; event("PLAYER_EQUIPMENT_CHANGED",17)
check(p:Warnings()=="","Offhand weapon cannot trigger shield warning")
ITEM_EQUIP_LOC="INVTYPE_HOLDABLE"; event("PLAYER_EQUIPMENT_CHANGED",17)
check(p:Warnings()=="","Held offhand cannot trigger shield warning")
ITEM_EQUIP_LOC="INVTYPE_SHIELD"; ITEM_DURABILITY={21,100}; event("UPDATE_INVENTORY_DURABILITY")
check(p:Warnings()=="","Shield above threshold stays quiet")
ITEM_DURABILITY={20,100}; event("UPDATE_INVENTORY_DURABILITY")
check(p:Warnings()=="Shield durability: 20%","Equipped shield at twenty percent warns even solo")
ITEM_DURABILITY={0,100}; event("UPDATE_INVENTORY_DURABILITY")
check(p:Warnings()=="Shield broken","Broken equipped shield gets clear warning")
GROUP=true; LEADER=false; INSTANCE_KIND="party"; INSTANCE_ID=36; p:Render()
check(p.warning.text:find("Shield broken") and not p.warning.text:find("request party leader") and p.markStatus.text=="ASSIST","Shield warning remains prominent while marking stays a quiet ASSIST status")
ITEM_DURABILITY={100,100}; event("UPDATE_INVENTORY_DURABILITY")
check(p.shieldWarning==nil,"Repair clears shield warning immediately")
ITEM_DURABILITY={5,100}; EQUIPPED_OFFHAND=nil; event("PLAYER_EQUIPMENT_CHANGED",17)
check(p.shieldWarning==nil,"Unequipping worn shield clears warning")
EQUIPPED_OFFHAND=1001; ITEM_DURABILITY={SECRET,100}; event("UPDATE_INVENTORY_DURABILITY")
check(p.shieldWarning==nil,"Secret durability cannot create false warning")
ITEM_DURABILITY={1,0}; event("UPDATE_INVENTORY_DURABILITY")
check(p.shieldWarning==nil,"Zero maximum durability handled safely")
ITEM_DURABILITY={1,100}; ITEM_EQUIP_LOC=SECRET; event("PLAYER_EQUIPMENT_CHANGED",17)
check(p.shieldWarning==nil,"Secret item type cannot be treated as shield")
ITEM_EQUIP_LOC="INVTYPE_SHIELD"; DURABILITY_ERROR=true; event("UPDATE_INVENTORY_DURABILITY")
check(p.shieldWarning==nil,"Refused durability query stays quiet")
print("PASS: "..n.." Holy Shield, talented Bulwark, durability and five-timer checks.")

local p,n=TEST_NS,0
local function check(v,message) assert(v,message);n=n+1 end
local function event(name,...)p.events.scripts.OnEvent(p.events,name,...)end
local function sync(dt)
    NOW=NOW+(dt or .2);p:RefreshAuras();p:RefreshUsedCooldowns();p:Render()
end
local function hiddenCast(id,slot)
    ACTION_DESCRIPTIONS[slot or 1]={"spell",id}
    UseAction(slot or 1)
    event("UNIT_SPELLCAST_SENT","player","target",SECRET,SECRET)
    event("UNIT_SPELLCAST_SUCCEEDED","player",SECRET,SECRET)
end
p.db.effects=false
check(CAST_HOOKS.UseAction and CAST_HOOKS.CastSpellByID and CAST_HOOKS.CastSpellByName,"Readable action, spell and macro intents are observed")
HELPFUL={{spellId=20154,name="Seal of Righteousness",duration=120,expirationTime=NOW+70},
    {spellId=20375,name="Seal of Command",duration=90,expirationTime=NOW+60}}
p:RefreshAuras()
-- Learn a second Seal independently, not just the family duration.
HELPFUL={HELPFUL[2]};p:RefreshAuras()
check(p.db.observedDurations["Seal of Righteousness"]==120 and p.db.observedDurations["Seal of Command"]==90,"Actual duration knowledge is stored separately for each Seal")
KNOWN[1311015]=true;p:DiscoverSpells()
COMBAT,RESTRICTED,AURA_ERROR=true,true,true
C_Spell.GetSpellInfo=function()return SECRET end
C_Spell.GetSpellCooldown=function()return {startTime=SECRET,duration=SECRET,isEnabled=SECRET,modRate=SECRET}end
HELPFUL={}
hiddenCast(20154)
check(p.activeSeal.name=="Seal of Righteousness" and p.auras.seal.estimated and p.auras.seal.expires==NOW+120,"Fully hidden success uses the requested Seal and learned duration during combat")
local sealEnd=p.auras.seal.expires
hiddenCast(26573,2);local groundEnd=p.ground.expires
hiddenCast(10308,3);local justiceEnd=p.cooldownTimers.justice.expires
hiddenCast(20925,4);local holyEnd=p.auras.holy.expires
KNOWN[1311015]=SECRET
hiddenCast(1311015,5);local bulwarkEnd=p.cooldownTimers.bulwark.expires
check(groundEnd==NOW+8 and holyEnd==NOW+10,"Ground and Holy Shield get independent bounded cast timers")
check(justiceEnd==NOW+60 and bulwarkEnd==NOW+300,"Used cooldowns continue even when every live cooldown field is hidden")
check(p.sealTile.icon.texture==20154,"Precombat spell identity and artwork stay available when combat spell-info queries are hidden")
for _,key in ipairs(p.timerKeys) do
    check(p[key.."Tile"]:IsShown() and p[key.."Tile"].count.text~="?","No question-mark placeholder for active timer "..key)
    check(p[key.."Tile"].icon.desaturated==false and p[key.."Tile"].icon.alpha==1,"Full-colour artwork in hidden combat for "..key)
end
for i=1,15 do
    sync(.2)
    event("PLAYER_TARGET_CHANGED")
    event("UNIT_SPELLCAST_SUCCEEDED","player","proc-"..i,20154)
end
check(p.auras.seal.expires==sealEnd and p.ground.expires==groundEnd,"Procs, target changes and repeated hidden resyncs never move deadlines")
check(p.cooldownTimers.justice.expires==justiceEnd and p.cooldownTimers.bulwark.expires==bulwarkEnd and p.auras.holy.expires==holyEnd,"Simultaneous independent cooldowns remain stable")
hiddenCast(20271,6)
check(p.auras.seal.expires==sealEnd,"A hidden Judgement request cannot consume or restart a Seal")
hiddenCast(20375,7)
check(p.activeSeal.name=="Seal of Command" and p.auras.seal.expires==NOW+90,"Seal swaps update immediately in combat without borrowing the old Seal duration")
check(p.ground.expires==groundEnd and p.cooldownTimers.justice.expires==justiceEnd,"Seal swap cannot reset ground or stun timers")
event("UNIT_SPELLCAST_SUCCEEDED","player","late-old-seal-proc",20154)
check(p.activeSeal.name=="Seal of Command" and p.auras.seal.expires==NOW+90,"A delayed proc from the previous Seal cannot undo a swap")
local commandEnd=p.auras.seal.expires
sync(.5)
-- A proc-driven spellbook event must not unlearn every spell while APIs are hidden.
KNOWN[1311015]=SECRET;event("SPELLS_CHANGED")
check(p.spells.bulwark.known and p.cooldownTimers.bulwark.expires==bulwarkEnd,"Combat spellbook changes cannot erase a learned defensive cooldown")
UseAction(2);event("UNIT_SPELLCAST_SENT","player","target",SECRET,SECRET)
event("UNIT_SPELLCAST_FAILED","player",SECRET,SECRET)
event("UNIT_SPELLCAST_SUCCEEDED","player",SECRET,SECRET)
check(p.ground.expires==groundEnd,"Failed spell plus uncorrelated hidden success cannot start a new ground timer")
-- Same-Spell proc successes with hidden GUIDs cannot consume an unrelated request.
ACTION_DESCRIPTIONS[8]={"spell",20271};UseAction(8)
event("UNIT_SPELLCAST_SENT","player","target","judgement-request",SECRET)
event("UNIT_SPELLCAST_SUCCEEDED","player","unrelated-proc",SECRET)
check(p.pendingCast and p.pendingCast.guid=="judgement-request","Readable GUID mismatch leaves the right request intact")
event("UNIT_SPELLCAST_SUCCEEDED","player","judgement-request",SECRET)
check(p.auras.seal.expires==commandEnd,"An unrelated hidden success cannot reset the selected Seal")
-- SENT can arrive inside UseAction, before its post-hook executes.
event("UNIT_SPELLCAST_SENT","player","target",SECRET,SECRET)
CastSpellByID(20154)
event("UNIT_SPELLCAST_SUCCEEDED","player",SECRET,SECRET)
check(p.activeSeal.name=="Seal of Righteousness" and p.auras.seal.expires==NOW+120,"SENT-before-post-hook event order is supported")
-- Real timers reconcile while still in combat, not only on REGEN_ENABLED.
AURA_ERROR=false
C_UnitAuras.GetAuraDataByIndex=function()error("index hidden")end
C_UnitAuras.GetPlayerAuraBySpellID=function(id)
    if id==20154 then return {spellId=SECRET,name=SECRET,duration=120,expirationTime=NOW+115} end
end
sync(.2)
check(p.auras.seal.expires==NOW+115 and not p.auras.seal.estimated,"Direct lookup identity works when returned name/ID are hidden but real timing is readable")
check(COMBAT,"Authoritative reconciliation occurs without ending combat")
local directEnd=p.auras.seal.expires
C_UnitAuras.GetPlayerAuraBySpellID=nil
CastSpellByID(20154);event("UNIT_SPELLCAST_SENT","player","target",SECRET,SECRET)
event("UNIT_SPELLCAST_SUCCEEDED","player",SECRET,SECRET)
check(p.auras.seal.expires>directEnd,"Recasting the same Seal restarts only from a successful request")
local refreshed=p.auras.seal.expires
C_UnitAuras.GetPlayerAuraBySpellID=function(id)
    if id==20154 then return {spellId=20154,name="Seal of Righteousness",duration=120,expirationTime=directEnd}end
end
sync(.2)
check(p.auras.seal.expires==refreshed,"Late old same-Seal buff cannot overwrite its recast during handoff")
C_UnitAuras.GetPlayerAuraBySpellID=nil
sync(121)
for _,key in ipairs({"seal","ground","holy","justice"})do check(p[key.."Tile"].motion.state=="hidden","Expired hidden timer leaves no stale front-of-rail icon: "..key)end
check(p.bulwarkTile:IsShown() and p.bulwarkTile.count.text~="?","Long defensive cooldown continues after shorter timers end")
sync(200)
check(p.bulwarkTile.motion.state=="hidden","Expired defensive estimate also leaves no placeholder")
-- Secrecy is per spell: a readable missing NeverSecret buff really is absent.
C_Secrets.ShouldSpellAuraBeSecret=function()return false end
C_UnitAuras.GetPlayerAuraBySpellID=function()return nil end
p:RefreshAuras()
check(not p.auras.seal.uncertain,"Spell-specific readable absence overrides global combat secrecy")
C_Secrets.ShouldSpellAuraBeSecret=nil
C_UnitAuras.GetPlayerAuraBySpellID=nil
AURA_ERROR=true
p:ClearUsedTimers();p.memory={};p.ground=nil
ACTION_DESCRIPTIONS[10]={"macro",7};MACRO_SPELLS[7]=20166
UseAction(10);event("UNIT_SPELLCAST_SENT","player","target",SECRET,SECRET)
event("UNIT_SPELLCAST_SUCCEEDED","player",SECRET,SECRET)
check(p.activeSeal.name=="Seal of Wisdom" and p.auras.seal.estimated,"Macro action resolves a readable requested Seal even with hidden success data")
CastSpellByName("Seal of Command(Rank 2)")
event("UNIT_SPELLCAST_SENT","player","target",SECRET,SECRET)
event("UNIT_SPELLCAST_SUCCEEDED","player",SECRET,SECRET)
check(p.activeSeal.name=="Seal of Command" and p.auras.seal.expires==NOW+90,"Ranked name casts use cached client identity and their own learned duration")
local endBeforePress=p.auras.seal.expires
CastSpellByID(20154);sync(.1)
check(p.activeSeal.name=="Seal of Command" and p.auras.seal.expires==endBeforePress,"Pressing another Seal without SENT and success does not start it")
p:ClearUsedTimers();p.memory={}
ACTION_DESCRIPTIONS[11]={SECRET,SECRET}
UseAction(11);event("UNIT_SPELLCAST_SENT","player","target",SECRET,SECRET)
event("UNIT_SPELLCAST_SUCCEEDED","player",SECRET,SECRET)
check(not p.activeSeal and not p.used.justice,"Unreadable action identity cannot create a guessed timer")
GetNumTalentTabs=function()return 1 end
GetNumTalents=function()return 2 end
GetTalentInfo=function(_,index)
    return index==1 and "Improved Hammer of Justice" or "Sacred Duty",0,0,0,index==1 and 3 or 2
end
p.cooldownLengths={};p:RefreshTimerKnowledge()
check(p:EstimatedCooldownLength("justice")==45 and p:EstimatedCooldownLength("bulwark")==240,"Readable talent ranks adjust initial stun and defensive cooldown estimates")
print("PASS: "..n.." fully hidden combat, input ordering, concurrent timers and aura reconciliation checks.")

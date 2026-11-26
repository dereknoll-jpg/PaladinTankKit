local p,n=TEST_NS,0
local function check(v,message) assert(v,message);n=n+1 end
local function refresh()p:RefreshAuras();p:Render()end
local function aura(id,seconds,extra)
    local a={spellId=id,name=C_Spell.GetSpellInfo(id).name,expirationTime=NOW+seconds,duration=seconds}
    for k,v in pairs(extra or {})do a[k]=v end
    return a
end
local function settle()for _=1,35 do NOW=NOW+1/60;p:Render()end end
p.db.effects=true;KNOWN[1311015]=true;KNOWN[4987]=true;KNOWN[642]=true;KNOWN[498]=true;KNOWN[1022]=true
p:DiscoverSpells();p:ToggleSettings();p:SelectSettingsPage("protection")
check(p.settingsPages.protection:IsShown(),"Protection settings have their own page")
check(#p.timerKeys==5,"New effects do not add moving rail icons")
HELPFUL={aura(1311033,6),aura(1328551,6),aura(1311015,8,{points={700}})}
HARMFUL={aura(25771,50)}
refresh();settle()
local positions={}
for _,key in ipairs({"iron","block","absorb","forbearance"})do
    local t=p.statusTiles[key]
    check(t:IsShown(),key.." is shown only as an active fixed status")
    check(t.point[5]>0 and t.motion.state=="active",key.." stays above the rail")
    check(t.icon.desaturated==false and t.icon.alpha==1,key.." retains full-colour artwork")
    check(t.halo.alpha>0 and t.trail.alpha==0,key.." uses soft light without travel trails")
    positions[key]=t.point[4]
end
check(p.protection.absorb.amount==700,"Readable absorb amount is retained for tooltip")
check(p:ForbearanceDetails():find("Templar's Bulwark") and p:ForbearanceDetails():find("Divine Shield"),"Forbearance lists learned defensives")
check(p:ForbearanceDetails():find("depends on its target"),"Forbearance explains target eligibility for Protection")
check(p.bulwarkTile.lock:IsShown(),"Forbearance flags the existing Bulwark timer")
local ironExpiry=p.protection.iron.expires
COMBAT=true;UNITS.target={guid="Creature-0-1-36-1-999-a",name="Other",hostile=true}
p:NoteCast("player",678,true);p:Render()
check(p.protection.iron.expires==ironExpiry,"Holy Strike casts do not invent or refresh protection without a buff")
settle()
for key,x in pairs(positions)do check(p.statusTiles[key].point[4]==x,"Status never slides: "..key)end
HELPFUL[1]=aura(1311033,6);refresh()
check(p.protection.iron.expires>ironExpiry,"Observed buff refresh updates only its own deadline")
check(p.protection.block.expires< p.protection.iron.expires,"Other protection timers retain independent deadlines")
local expiry=p.protection.iron.expires
RESTRICTED=true;AURA_ERROR=true;refresh()
check(p.protection.iron.estimated and p.protection.iron.expires==expiry,"Hidden combat reads retain only the observed deadline")
check(p.protection.absorb.amount==nil,"Hidden absorb data does not claim a stale remaining amount")
NOW=expiry+.1;refresh()
check(p.protection.iron==nil and p.protection.block==nil,"Remembered protection never survives its deadline")
RESTRICTED=false;AURA_ERROR=false
HELPFUL={aura(1311033,6)};refresh();local visibleExpiry=p.protection.iron.expires
HELPFUL[1].expirationTime=SECRET;refresh()
check(p.protection.iron and p.protection.iron.estimated and p.protection.iron.expires==visibleExpiry,"A secret expiry on an identified buff retains only its existing deadline")
HELPFUL={{spellId=SECRET,name=SECRET,expirationTime=SECRET}};refresh()
check(p.protection.iron and p.protection.iron.expires==visibleExpiry,"Incomplete aura identity cannot prove buff removal")
HELPFUL={aura(1311033,6),aura(1328551,6),aura(1311015,8)};refresh()
table.remove(HELPFUL,3);refresh()
check(p.protection.absorb==nil and p.protection.iron~=nil,"Early shield depletion clears only active Bulwark")
HELPFUL[3]=aura(1311015,8,{points={0}});refresh()
check(p.protection.absorb==nil,"A depleted zero-absorb shield is not reported as active protection")
p.protection={};HELPFUL={{spellId=1311033,name="Iron Creed",expirationTime=SECRET,duration=SECRET}};refresh()
check(p.protection.iron==nil,"Unreadable initial deadlines never create a question-mark timer")
HELPFUL={aura(1311033,6),aura(1328551,6),aura(1311015,8)};refresh();settle()
p.db.reducedMotion=true;p:Render();local alpha=p.statusTiles.iron.halo.alpha
NOW=NOW+.2;p:Render()
check(p.statusTiles.iron.halo.alpha==alpha and p.statusTiles.iron.scale==1,"Reduced motion keeps status lighting static")
p.db.effects=false;p:Render()
check(p.statusTiles.iron.halo.alpha==0 and p.statusTiles.iron.sweep.alpha==0,"Effects-off removes status decoration")
p.db.effects=true;p.db.reducedMotion=false
for _,def in ipairs(p.protectionDefs)do
    local model=p.protection[def.key]
    p.statusTiles[def.key].scripts.OnClick(nil,"MiddleButton")
    check(not p.db[def.option] and not p.statusTiles[def.key]:IsShown(),"Middle-click immediately hides "..def.key)
    check(p.protection[def.key]==model,"Hiding does not clear "..def.key.." tracking")
    p.checks[def.option].scripts.OnClick()
    check(p.db[def.option],"Each protection effect can be restored independently")
end
p.db.forbearanceAware=false;p:Render()
check(not p.bulwarkTile.lock:IsShown() and p.forbearanceTile:IsShown(),"Forbearance awareness and badge have separate switches")
p.db.forbearanceAware=true
p:RenderLane("bulwark",nil,NOW,"ready")
check(p.bulwarkTile.count.text=="Locked","Cooldown completion cannot say Ready while Forbearance blocks Bulwark")
REMOVABLE={{spellId=90001,name="Test poison",dispelName="Poison"}}
refresh();check(p.personalCleanse and p.personalCleanse.kind=="Poison","Learned Cleanse detects a client-removable personal poison")
check(p.statusTiles.cleanse:IsShown(),"Cleanse reminder occupies a fixed status slot")
p.statusTiles.cleanse.scripts.OnClick(nil,"MiddleButton")
check(not p.db.warnCleanse and not p.statusTiles.cleanse:IsShown(),"Cleanse reminder supports middle-click hiding")
p:Command("restore");refresh()
check(p.personalCleanse~=nil,"Restore command restores the cleanse reminder")
KNOWN[4987]=nil;KNOWN[1152]=true;p:DiscoverSpells()
REMOVABLE={{spellId=90002,name="Test magic",dispelName="Magic"}};refresh()
check(p.personalCleanse==nil,"Purify never offers to remove Magic")
REMOVABLE={{spellId=90003,name="Test disease",dispelName="Disease"}};refresh()
check(p.personalCleanse and p.personalCleanse.spell==1152,"Purify supports Disease while leveling")
REMOVABLE={{spellId=90004,name="Test curse",dispelName="Curse"}};refresh()
check(p.personalCleanse==nil,"Paladin cleanse never claims Curse removal")
KNOWN[4987]=true;p:DiscoverSpells()
REMOVABLE={{spellId=25771,name="Forbearance",dispelName="Magic"}};refresh()
check(p.personalCleanse==nil,"Forbearance never prompts a cleanse")
REMOVABLE={{spellId=90001,name="Poison",dispelName=SECRET}};refresh()
check(p.personalCleanse==nil,"Secret dispel types remain quiet")
REMOVABLE={{spellId=90001,name="Poison",dispelName="Poison"}};RESTRICTED=true;refresh()
check(p.personalCleanse==nil,"Restricted cleanse data remains quiet")
RESTRICTED=false;p.db.warnings=false;refresh()
check(p.personalCleanse==nil,"Master reminders toggle suppresses personal cleanse")
p.db.warnings=true;KNOWN[4987]=nil;KNOWN[1152]=nil;p:DiscoverSpells();refresh()
check(p.personalCleanse==nil,"No prompt without a learned removal spell")
KNOWN[4987]=true;p:DiscoverSpells();DEAD=true;refresh()
check(next(p.protection)==nil and not p.statusTiles.cleanse:IsShown(),"Death clears protection and suppresses cleanse")
DEAD=false;MOUNTED=true;refresh()
check(not p.statusTiles.iron:IsShown() and p.personalCleanse==nil,"Mounting suppresses the status row")
MOUNTED=false;HELPFUL={};HARMFUL={};REMOVABLE={};refresh();settle()
for _,t in pairs(p.statusTiles)do check(not t:IsShown(),"Inactive status leaves no idle clutter")end
check(#SENT_CHAT==0 and #SOUNDS==0,"Protection and cleanse never spam chat or sounds")
print("PASS: "..n.." fixed protection, Forbearance and personal cleanse checks.")

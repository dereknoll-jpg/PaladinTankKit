local p, n = TEST_NS, 0
local function check(v,message) assert(v,message); n=n+1 end
local function refresh() p:RefreshAuras(); return p:Warnings() end
HELPFUL={{spellId=25780,name="Righteous Fury",expirationTime=0,duration=0}}
check(refresh()=="","Missing Seal never produces a reminder")
PALADIN_FORMS={{active=false,spellID=465},{active=false,spellID=7294}}
check(refresh()=="Missing: Aura","No selected aura produces quiet reminder")
p.db.effects=false; LEADER=true; INSTANCE_KIND="party"; INSTANCE_ID=36
p:Render(); check(p.warning.text=="Missing: Aura","Aura reminder appears in existing little text")
HELPFUL[2]={spellId=7294,name="Retribution Aura",sourceUnit="party1",expirationTime=0,duration=0}
check(refresh()=="Missing: Aura","Another Paladin's buff cannot hide missing own aura")
PALADIN_FORMS[2].active=true
p.events.scripts.OnEvent(p.events,"UPDATE_SHAPESHIFT_FORM")
check(p:Warnings()=="","Any selected aura clears reminder immediately")
PALADIN_FORMS[1].active=true; PALADIN_FORMS[2].active=false
check(refresh()=="","Aura reminder never demands a specific aura")
PALADIN_FORMS[1].active=false; HELPFUL={}
check(refresh()=="Missing: Righteous Fury / Aura","Righteous Fury reminder is preserved")
RESTRICTED=true
check(refresh()=="Missing: Aura","Readable stance can identify missing own aura despite hidden buffs")
PALADIN_FORMS[1].active=SECRET
check(refresh()=="","Hidden stance state cannot create false missing-aura alert")
PALADIN_FORMS[1].active=false; FORM_ERROR=true
check(refresh()=="","Refused stance query cannot create false alert")
FORM_ERROR=false; FORM_COUNT_OVERRIDE=SECRET
check(refresh()=="","Secret form count handled safely")
FORM_COUNT_OVERRIDE=nil; PALADIN_FORMS={}
check(refresh()=="","No learned auras creates no reminder")
PALADIN_FORMS={{active=false,spellID=465}}; RESTRICTED=false
HELPFUL={{spellId=25780,name="Righteous Fury",expirationTime=0,duration=0}}
MOUNTED=true; check(refresh()=="","Mounted player gets no buff reminder")
MOUNTED=false; DEAD=true; check(refresh()=="","Dead player gets no buff reminder")
DEAD=false; GROUP=false; UNITS={}; check(refresh()=="","Idle solo player gets no aura nagging")
GROUP=true; p.db.warnings=false; check(refresh()=="","Reminder setting still controls aura alert")
print("PASS: "..n.." aura-selection and reminder checks.")

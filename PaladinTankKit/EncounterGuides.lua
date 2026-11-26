local _,P=...

-- Original summaries of Wowhead Forever pages; reviewed 2026-11-26.
-- Live cues use only this version-scoped catalog, never legacy reference notes.
P.foreverGuides={}
local base="https://www.wowhead.com/forever/"
local function plan(instance,name,path,note,options)
    local e={name=name,note=note,boss=true,source=base..path,gameVersion="1.60.1",
        confidence="forever-wowhead",reviewed="2026-11-26"}
    for k,v in pairs(options or {}) do e[k]=v end
    P.foreverGuides[instance]=P.foreverGuides[instance] or {}
    P.foreverGuides[instance][name:lower()]=e
end
local dm="dungeon-journal/the-deadmines/"
plan(36,"Edwin VanCleef",dm.."edwin-vancleef",
    "Plan: Blackguards {skull}, then {cross}; control one if needed. Gather the extra guards around half health.",
    {adds={["defias blackguard"]=true},addCue="Blackguards active: gather and control or kill the guards.",
     phases={{at=.55,text="Half health approaching: prepare to gather new Blackguards."}}})
plan(36,"Mr. Smite",dm.."mr-smite",
    "Plan: remove the Blackguards before his first stomp. Prepare for group stuns and weapon changes.",
    {adds={["defias blackguard"]=true},addCue="Blackguards active: deal with escorts before pushing Smite.",
     phases={{at=.70,text="Stomp approaching: finish escorts and prepare for the stun."},
         {at=.37,text="Another weapon change approaching: prepare for the stun."}}})
plan(36,"Captain Greenskin",dm.."captain-greenskin",
    "Plan: control the Squallshaper; kill Companion, then Pirate, then Greenskin. Face him away. Non-elites stay unmarked.")
plan(36,"Cookie",dm.."cookie",
    "Plan: pull clear of pirates and stop Cookie's Cooking to prevent healing.",
    {casts={["cookie's cooking"]="Cookie's Cooking: stop the heal."}})
local hot="guide/hall-of-thanes-dungeon-overview-location-rewards"
plan(3065,"Faldrim Anvilmar",hot,
    "Plan: clear nearby enemies first. Watch Mind Blast and Anvilmar's Curse; Paladin cleanse cannot remove curses.",
    {casts={["mind blast"]="Mind Blast: stop the cast if your group can."}})
plan(3065,"Magmatus",hot,
    "Plan: kill the Dark Iron Summoner first. Keep Magmatus away from the party; avoid Fire Nova and remove Combust when possible.",
    {adds={["dark iron summoner"]=true},addCue="Summoner active: focus the Summoner before Magmatus.",
     casts={["fire nova"]="Fire Nova: move clear of the blast."}})
plan(3065,"Plunder",hot,
    "Plan: use a clear wall or corner as a backstop. Keep uncleared packs away from the knockback direction.",
    {casts={["knock away"]="Knock Away: check your backstop."}})
plan(3065,"Durgen Dirgehammer",hot,
    "Plan: clear surrounding Looters before pulling. Kill golems one at a time and prepare for Fear and heavy tank damage.",
    {casts={["fear"]="Fear: keep the fight away from uncleared enemies."}})
local rol="dungeon-journal/ruins-of-lordaeron/"
plan(2999,"Witherfang",rol.."witherfang",
    "Plan: deal with the accompanying spiders; use stuns and remove Leech Poison from the tank.")
plan(2999,"The Abandoned",rol.."the-abandoned",
    "Plan: gather the statue's waves, then stop Life Drain. Watch Frost Nova and the melee slow.",
    {casts={["life drain"]="Life Drain: stop the channel.",["drain life"]="Drain Life: stop the channel."}})
plan(2999,"Rath'mael",rol.."rathmael",
    "Plan: leave the tank's original position when Flamestrike begins; use a stun to prevent the cast when possible.",
    {casts={["flamestrike"]="Flamestrike: move away from the cast's starting location."}})
plan(43,"Lady Anacondra","dungeon-journal/wailing-caverns/lady-anacondra",
    "Plan: stop Sleep first. Avoid extra Druids of the Fang; control an accidental extra druid.",
    {casts={["sleep"]="Sleep: stop the cast to protect your tank or healer."}})

function P:IsForeverNotesClient()
    local version=self:Call(GetBuildInfo)
    return version=="1.60.1"
end

function P:BossPlan(entry)
    if not entry then return end
    local guides=self.foreverGuides[self:Instance()]
    return guides and guides[entry.name:lower()] or entry
end

function P:EncounterUnits()
    local units={"target","boss1","boss2","boss3","boss4","boss5"}
    local plates=self:Call(C_NamePlate and C_NamePlate.GetNamePlates)
    if type(plates)=="table" then
        for _,plate in ipairs(plates) do
            local unit=self:Field(plate,"namePlateUnitToken")
            if type(unit)=="string" then units[#units+1]=unit end
        end
    end
    return units
end

function P:UpdateEncounterCue()
    self.encounterCue=nil
    if not self.db.enabled or not self.db.bossNotes or not self.db.encounterCues or self.preview
        or not self:IsForeverNotesClient() or IsInRaid() or UnitIsDeadOrGhost("player") or IsMounted() then
        self.encounterState=nil;return
    end
    local instance,kind=self:Instance()
    if kind~="party" then self.encounterState=nil;return end
    local guides=self.foreverGuides[instance]
    if not guides then self.encounterState=nil;return end
    local units=self:EncounterUnits()
    local bossUnit,plan,guid
    for _,unit in ipairs(units) do
        if self:Call(UnitExists,unit)==true and self:Call(UnitIsDeadOrGhost,unit)==false
            and self:Call(UnitAffectingCombat,unit)==true and self:Call(UnitCanAttack,"player",unit)==true then
            local identity,_,name=self:UnitIdentity(unit)
            local candidate=type(name)=="string" and guides[name:lower()]
            if candidate and identity then
                bossUnit,plan,guid=unit,candidate,identity
                if self.encounterState and identity==self.encounterState.guid then break end
            end
        end
    end
    if not plan then self.encounterState=nil;return end
    local now=GetTime()
    local state=self.encounterState
    if not state or state.guid~=guid or state.instance~=instance then
        state={guid=guid,instance=instance,plan=plan,phases={}};self.encounterState=state
    end
    state.plan=plan
    local function cue(key,message)
        self.encounterCue={key=guid..":"..key,text=message,plan=plan}
    end
    local cast=self:Call(UnitCastingInfo,bossUnit) or self:Call(UnitChannelInfo,bossUnit)
    if type(cast)=="string" and plan.casts and plan.casts[cast:lower()] then
        cue("cast:"..cast,plan.casts[cast:lower()]);return
    end
    if plan.adds then
        for _,unit in ipairs(units) do
            if self:Call(UnitExists,unit)==true and self:Call(UnitIsDeadOrGhost,unit)==false
                and self:Call(UnitAffectingCombat,unit)==true and self:Call(UnitCanAttack,"player",unit)==true then
                local _,_,name=self:UnitIdentity(unit)
                if type(name)=="string" and plan.adds[name:lower()] then cue("adds",plan.addCue);return end
            end
        end
    end
    local hp,maximum=self:Call(UnitHealth,bossUnit),self:Call(UnitHealthMax,bossUnit)
    if self:Number(hp) and self:Number(maximum) and maximum>0 and hp>=0 then
        local fraction=hp/maximum
        for i,phase in ipairs(plan.phases or {}) do
            if state.health and state.health>phase.at and fraction<=phase.at and not state.phases[i] then
                state.phases[i]=true;state.phaseUntil=now+5;state.phaseText=phase.text;state.phaseKey=i
            end
        end
        state.health=fraction
    end
    if state.phaseUntil and state.phaseUntil>now then cue("phase:"..state.phaseKey,state.phaseText) end
end

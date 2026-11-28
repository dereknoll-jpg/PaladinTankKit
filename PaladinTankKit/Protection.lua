local _, P = ...

-- Forever 1.60.1 effect IDs, not the similarly named passive talents.
P.protectionDefs = {
    {key="iron", id=1311033, talentID=1311034, name="Iron Creed", duration=6, option="showIronCreed", short="Creed",
        icon="Interface\\Icons\\Spell_Holy_ImprovedResistanceAuras"},
    {key="block", id=1328551, talentID=1328544, name="Shieldsworn", duration=6, option="showSpellBlock", short="Block",
        icon="Interface\\Icons\\Spell_Holy_GreaterBlessingofSanctuary"},
    {key="absorb", id=1311015, name="Templar's Bulwark", duration=8, option="showBulwarkActive", short="Bulwark",
        icon="Interface\\Icons\\Spell_Holy_PowerWordShield"},
}
P.protectionOptions={"showIronCreed","showSpellBlock","showBulwarkActive","warnCleanse"}
local holyStrikeIDs={[678]=true,[679]=true,[680]=true,[1866]=true,[2495]=true,[5569]=true,[10332]=true,[10333]=true}
local selfImmunities={[642]=true,[1020]=true,[498]=true,[5573]=true}
local protectionBlessings={[1022]=true,[5599]=true,[10278]=true}

function P:DiscoverProtection()
    self.protectionNames={}
    self.protectionTalentKnown={}
    self.holyStrikeNames={}
    self.playerCastName=self:Call(UnitName,"player")
    self.playerCastNames={}
    if type(self.playerCastName)=="string" then self.playerCastNames[self.playerCastName]=true end
    if type(UnitFullName)=="function" then
        local ok,name,realm=pcall(UnitFullName,"player")
        if ok and self:Readable(name) and type(name)=="string" and self:Readable(realm)
            and type(realm)=="string" and realm~="" then self.playerCastNames[name.."-"..realm]=true end
    end
    for id in pairs(holyStrikeIDs) do
        local name=self:Field(self:SpellInfo(id),"name")
        if type(name)=="string" then self.holyStrikeNames[name]=true end
    end
    for _,def in ipairs(self.protectionDefs) do
        local info=self:SpellInfo(def.id)
        def.localName=self:Field(info,"name") or def.name
        def.texture=self:Field(info,"iconID") or def.icon
        self.protectionNames[def.localName]=def.key
        if def.talentID then
            local ranks=self.talentRanks or {}
            self.protectionTalentKnown[def.key]=self:IsKnownSpell(def.talentID)==true
                or (ranks[def.localName:lower()] or ranks[def.name:lower()] or 0)>0
        end
        if self.statusTiles then self.statusTiles[def.key].icon:SetTexture(def.texture) end
    end
    self.cleanseSpell=self:IsKnownSpell(4987)==true and 4987 or (self:IsKnownSpell(1152)==true and 1152 or nil)
    self.forbearanceSpells={}
    for _,ids in ipairs({{1311015},{642,1020},{498,5573},{1022,5599,10278}}) do
        for _,id in ipairs(ids) do
            if self:IsKnownSpell(id)==true then
                local info=self:SpellInfo(id)
                local name=self:Field(info,"name")
                if name then self.forbearanceSpells[#self.forbearanceSpells+1]=name end
                break
            end
        end
    end
end

-- Only the existing request + successful-player-cast correlation may seed an
-- estimate. No combat-log proc, button press, cooldown recovery or refresh scan
-- is allowed to create a new protection deadline.
function P:NoteProtectionCast(id,name,intentional,selfTarget)
    if not intentional then return end
    local now=GetTime()
    self.protectionCasts=self.protectionCasts or {}
    local function start(def)
        local observed=self.db.observedDurations["protection:"..def.key]
        local duration=self:Number(observed) and observed>0 and observed<=60 and observed or def.duration
        local previous=self.protection and self.protection[def.key]
        self.protectionCasts[def.key]={active=true,expires=now+duration,duration=duration,
            estimated=true,holdUntil=now+.75,previousExpiry=previous and previous.expires}
    end
    local function forbearance()
        local rank=math.max(0,math.min(2,(self.talentRanks or {})["sacred duty"] or 0))
        local observed=self.db.observedDurations.forbearance
        local learnedRank=self.db.observedDurations.forbearanceTalentRank
        if learnedRank~=nil and learnedRank~=rank then observed=nil end
        local duration=self:Number(observed) and observed>0 and observed<=60 and observed or (60-5*rank)
        self.memory.forbearance=nil
        self.effectTimers.forbearance={active=true,expires=now+duration,duration=duration,
            estimated=true,holdUntil=now+.75}
    end
    if id==1311015 and self.spells.bulwark.known then
        start(self.protectionDefs[3]);forbearance()
    elseif holyStrikeIDs[id] or self.holyStrikeNames[name] then
        local learned=self.protectionTalentKnown or {}
        if learned.iron and self.lastKnownFury==true then start(self.protectionDefs[1]) end
        if learned.block and (self.shieldEquipped==true or (self.shieldEquipped==nil and self.lastKnownShield==true)) then start(self.protectionDefs[2]) end
    elseif selfImmunities[id] or (protectionBlessings[id] and selfTarget==true) then
        forbearance()
    end
end

function P:ForbearanceActive(now)
    local fb=self.auras and self.auras.forbearance
    return fb and fb.active and fb.expires and fb.expires>(now or GetTime()) and fb or nil
end

function P:ForbearanceDetails()
    local fb=self:ForbearanceActive()
    local names=self.forbearanceSpells or {}
    return "Forbearance prevents these learned abilities from being used on yourself:\n"..
        (#names>0 and table.concat(names,", ") or "No affected learned abilities could be identified.")..
        (fb and ("\nRemaining: "..self:FormatTime(fb.expires-GetTime(),fb.estimated)) or "")..
        "\n~ means a confirmed self-cast estimate or remembered buff deadline."..
        "\nBlessing of Protection eligibility also depends on its target."
end

function P:RefreshProtection()
    local api=C_UnitAuras or {}
    local found,absent,uncertain,depleted={},{},{},{}
    local now=GetTime()
    local byID={}
    for _,def in ipairs(self.protectionDefs) do byID[def.id]=def.key end
    local function accept(aura,hint)
        if type(aura)~="table" or not self:Readable(aura) then return end
        local id,name=self:Field(aura,"spellId"),self:Field(aura,"name")
        local key=(self:Number(id) and byID[id]) or (type(name)=="string" and self.protectionNames[name]) or hint
        if not key then return end
        local expires,duration=self:Field(aura,"expirationTime"),self:Field(aura,"duration")
        if not self:Number(expires) or expires==0 then uncertain[key]=true;return end
        if expires<=now then found[key]=nil;absent[key]=true;uncertain[key]=nil;return end
        local entry={active=true,expires=expires,duration=self:Number(duration) and duration or nil}
        local points=self:Field(aura,"points")
        local amount=self:Field(points,1)
        if key=="absorb" and self:Number(amount) and amount>=0 then
            if amount==0 then found[key]=nil;absent[key]=true;uncertain[key]=nil;depleted[key]=true;return end
            entry.amount=amount
        end
        found[key]=entry;depleted[key]=nil
    end
    for _,def in ipairs(self.protectionDefs) do
        for _,query in ipairs({{api.GetPlayerAuraBySpellID,def.id},{api.GetPlayerAuraBySpellName,def.localName}}) do
            if type(query[1])=="function" then
                local aura,ok=self:Call(query[1],query[2])
                if ok and aura then accept(aura,def.key)
                elseif ok and not self:AurasRestricted(def.id) then absent[def.key]=true end
            end
        end
    end
    if type(api.GetAuraDataByIndex)=="function" then
        local complete,ended=true,false
        for i=1,255 do
            local aura,ok=self:AuraAt(i,"HELPFUL")
            if not ok then complete=false;break end
            if aura==nil then ended=true;break end
            if type(aura)~="table" then complete=false;break end
            if not self:Field(aura,"spellId") and not self:Field(aura,"name") then complete=false end
            accept(aura)
        end
        if complete and ended then
            for _,def in ipairs(self.protectionDefs) do if not self:AurasRestricted(def.id) then absent[def.key]=true end end
        end
    end
    self.protection=self.protection or {}
    for _,def in ipairs(self.protectionDefs) do
        local old=self.protection[def.key]
        local pending=self.protectionCasts and self.protectionCasts[def.key]
        if pending and pending.expires<=now then self.protectionCasts[def.key]=nil;pending=nil end
        local live=found[def.key]
        if pending and live and pending.previousExpiry and now<pending.holdUntil
            and live.expires<=pending.previousExpiry+.001 then
            found[def.key]=nil;uncertain[def.key]=true
        end
        if depleted[def.key] then
            self.protection[def.key]=nil
            if self.protectionCasts then self.protectionCasts[def.key]=nil end
        elseif found[def.key] then
            local effect=found[def.key]
            if self.protectionCasts then self.protectionCasts[def.key]=nil end
            if def.talentID then self.protectionTalentKnown[def.key]=true end
            if effect.duration and effect.duration>0 and effect.duration<=60 then
                self.db.observedDurations["protection:"..def.key]=effect.duration
            end
            if def.key=="absorb" and effect.amount then
                -- This is an observed baseline, never a health-derived maximum.
                local same=old and math.abs(old.expires-effect.expires)<.15
                effect.capacity=math.max(effect.amount,(same and old.capacity) or 0)
            end
            self.protection[def.key]=effect
        elseif pending and (now<pending.holdUntil or not (absent[def.key] and not uncertain[def.key])) then
            self.protection[def.key]=pending
        elseif (absent[def.key] and not uncertain[def.key]) or not old or old.expires<=now then
            self.protection[def.key]=nil
            if self.protectionCasts then self.protectionCasts[def.key]=nil end
        else
            -- Retain only a previously observed deadline when reads become hidden.
            self.protection[def.key]={active=true,expires=old.expires,duration=old.duration,estimated=true,capacity=old.capacity}
        end
    end
    if UnitIsDeadOrGhost("player") then self.protection={};self.protectionCasts={} end
    self:RefreshPersonalCleanse()
end

function P:RefreshPersonalCleanse()
    self.personalCleanse=nil
    if not self.db.warnings or not self.db.warnCleanse or not self.cleanseSpell
        or UnitIsDeadOrGhost("player") or IsMounted() then return end
    local api=C_UnitAuras or {}
    if type(api.GetAuraDataByIndex)~="function" then return end
    -- RAID asks the client for removable debuffs. Never infer dispellability from
    -- a Magic/Poison/Disease label on an unfiltered or secret aura.
    for i=1,255 do
        local aura,ok=self:AuraAt(i,"HARMFUL|RAID")
        if not ok or aura==nil or type(aura)~="table" then return end
        local id=self:Field(aura,"spellId")
        local kind=self:Field(aura,"dispelName")
        local name=self:Field(aura,"name")
        local can=kind=="Poison" or kind=="Disease" or (kind=="Magic" and self.cleanseSpell==4987)
        if can and self:Number(id) and id~=25771 and type(name)=="string" and not self:AurasRestricted(id) then
            self.personalCleanse={name=name,kind=kind,id=id,spell=self.cleanseSpell}
            return
        end
    end
end

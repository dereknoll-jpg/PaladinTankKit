local _,P=...
local devotionIDs={465,10290,643,10291,1032,10292,10293}
local devotionRanks={}
for rank,id in ipairs(devotionIDs) do devotionRanks[id]=rank end

function P:IsAssignedTank()
    if not IsInGroup() then return false end
    if self:Call(UnitGroupRolesAssigned,"player")=="TANK" then return true end
    return self:Call(GetPartyAssignment,"MAINTANK","player")==true
end

function P:MissingShield()
    return self.db.enabled and self.db.warnings and self.db.warnMissingShield and not self.preview
        and not UnitIsDeadOrGhost("player") and not IsMounted()
        and self.shieldEquipped==false and self:IsAssignedTank()
end

function P:IsGroupPaladin(unit)
    if type(unit)~="string" or unit=="player" or self:Call(UnitIsUnit,unit,"player")==true then return false end
    local exists=self:Call(UnitExists,unit)
    if exists==nil then return nil end
    if exists~=true or self:Call(UnitIsDeadOrGhost,unit)==true then return false end
    local partyMember,partyOK=self:Call(UnitInParty,unit)
    local member=partyMember==true
    local raidIndex,raidOK=self:Call(UnitInRaid,unit)
    if self:Number(raidIndex) and raidIndex>0 then member=true end
    -- Legacy clients may not expose the membership helpers for unit tokens.
    local index=tonumber(unit:match(IsInRaid() and "^raid(%d+)$" or "^party(%d+)$"))
    if not partyOK and not raidOK and index and index>=1 and index<=(IsInRaid() and 40 or 4) then member=true end
    if not member or type(UnitClass)~="function" then return false end
    local ok,_,class=pcall(UnitClass,unit)
    if not ok or not self:Readable(class) or type(class)~="string" then return nil end
    return class=="PALADIN"
end

function P:RefreshTankBuffs()
    self.devotionState={status="unknown"}
    if not self:IsAssignedTank() then return end
    local stance=self.paladinAura
    if not stance or stance.uncertain or not stance.known then return end
    local best,unknown=0,false
    for rank,id in ipairs(devotionIDs) do
        local known=self:IsKnownSpell(id)
        if known==true then best=rank elseif known==nil then unknown=true end
    end
    if InCombatLockdown() or unknown then best=math.max(best,self.bestDevotionRank or 0) end
    local own=false
    local count=self:Call(GetNumShapeshiftForms)
    if self:Number(count) then
        for index=1,math.min(20,count) do
            local ok,_,active,_,id=pcall(GetShapeshiftFormInfo,index)
            if ok and self:Readable(active) and active==true then
                if not self:Number(id) then return end
                if devotionRanks[id] then own=true;best=math.max(best,devotionRanks[id]) end
            end
        end
    end
    self.bestDevotionRank=best
    if best==0 then self.devotionState={status=unknown and "unknown" or "unlearned"};return end
    if own then self.devotionState={status="covered",own=true,rank=best};return end
    local coverage,uncertain=false,false
    local names={["Devotion Aura"]=true}
    for _,id in ipairs(devotionIDs) do
        local info=(self.spellInfoCache and self.spellInfoCache[id]) or self:SpellInfo(id)
        if info and info.name then names[info.name]=true end
    end
    local function accept(aura,idHint)
        local id=self:Field(aura,"spellId") or idHint
        local name=self:Field(aura,"name")
        local rank=devotionRanks[id]
        if not rank and not names[name] then return end
        local expires=self:Field(aura,"expirationTime")
        if self:Number(expires) and expires>0 and expires<=GetTime() then return end
        local source=self:Field(aura,"sourceUnit")
        if not source then uncertain=true;return end
        if not rank then uncertain=true;return end
        if rank<best then return end
        local paladin=self:IsGroupPaladin(source)
        if paladin==true then coverage=true elseif paladin==nil then uncertain=true end
    end
    local api=C_UnitAuras or {}
    local absence=false
    if type(api.GetAuraDataByIndex)=="function" then
        local complete=true
        for index=1,255 do
            local aura,ok=self:AuraAt(index,"HELPFUL")
            if not ok then complete=false;break end
            if aura==nil then break end
            if type(aura)~="table" then complete=false;break end
            if not self:Field(aura,"spellId") and not self:Field(aura,"name") then complete=false end
            accept(aura)
        end
        absence=complete and not self:AurasRestricted(devotionIDs[best])
    end
    local function probe(fn,id,...)
        if type(fn)~="function" then return end
        local aura,ok=self:Call(fn,...)
        if ok and type(aura)=="table" then accept(aura,id)
        elseif ok and aura==nil and not self:AurasRestricted(id or devotionIDs[best]) then absence=true end
    end
    for name in pairs(names) do
        probe(api.GetAuraDataBySpellName,nil,"player",name,"HELPFUL")
        probe(api.GetPlayerAuraBySpellName,nil,name)
    end
    for _,id in ipairs(devotionIDs) do probe(api.GetPlayerAuraBySpellID,id,id) end
    self.devotionState={status=coverage and "covered" or (absence and not uncertain and "missing" or "unknown"),rank=best}
end

function P:TankBuffStatus()
    if not self.db.enabled or not self.db.warnings or self.preview or not self:IsAssignedTank()
        or UnitIsDeadOrGhost("player") or IsMounted() then return nil end
    local fury=self.auras and self.auras.fury
    if fury and not fury.active and self.furyCastGrace and GetTime()<self.furyCastGrace then fury={uncertain=true} end
    return {fury=self.db.warnFury and self.spells.fury.known and
        (fury and not fury.uncertain and (fury.active and "covered" or "missing") or "unknown") or "disabled",
        devotion=self.db.warnAura and self.devotionState and self.devotionState.status or "disabled"}
end

function P:RenderTankBuffAlerts(now)
    local status=self:TankBuffStatus()
    local urgent=self:MissingShield() or false
    self.buffAlertEpisodes=self.buffAlertEpisodes or {}
    local _,kind=self:Instance()
    local sound=false
    for _,key in ipairs({"fury","devotion"}) do
        local state=status and status[key]
        local episode=self.buffAlertEpisodes[key]
        if state=="missing" then
            urgent=true
            if not episode then episode={since=now};self.buffAlertEpisodes[key]=episode end
            if self.db.warningSounds and kind=="party" and not episode.sounded and now-episode.since>=0.4
                and (not self.lastBuffAlertSound or now-self.lastBuffAlertSound>=2) then
                sound=true;episode.sounded=true
            end
        elseif state~="unknown" then self.buffAlertEpisodes[key]=nil end
    end
    if sound then
        self.lastBuffAlertSound=now
        if type(PlaySound)=="function" then pcall(PlaySound,SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959,"Master") end
    end
    local pulse=urgent and not self.db.reducedMotion and (.5+.5*math.sin(now*6)) or 1
    self.warning:SetAlpha(urgent and (.58+.42*pulse) or 1)
    self.warning:SetTextColor(1,urgent and .38 or .64,urgent and .12 or .40)
    if self.warningUrgent~=urgent then
        self.warning:SetFont(STANDARD_TEXT_FONT,urgent and 13 or 10,"OUTLINE")
        self.warningUrgent=urgent
    end
    self.warningGlow:SetAlpha(urgent and (.10+.16*pulse) or 0)
end

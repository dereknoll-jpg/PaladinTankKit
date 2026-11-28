local _, P = ...

-- One refresh can serve the timer, Devotion, protection and cleanse readers.
-- Cache only within that refresh; events must never inherit an old snapshot.
function P:AuraAt(index,filter)
    local cache=self.auraScanCache
    if cache then
        cache[filter]=cache[filter] or {}
        local hit=cache[filter][index]
        if hit then return hit.value,hit.ok end
    end
    local value,ok=self:Call(C_UnitAuras and C_UnitAuras.GetAuraDataByIndex,"player",index,filter)
    if cache then cache[filter][index]={value=value,ok=ok} end
    return value,ok
end

function P:AurasRestricted(id)
    if id and C_Secrets then
        local value, ok = self:Call(C_Secrets.ShouldSpellAuraBeSecret,id)
        if ok and type(value)=="boolean" then return value end
        if type(C_Secrets.ShouldSpellAuraBeSecret)=="function" and not ok then return true end
        local level, readable = self:Call(C_Secrets.GetSpellAuraSecrecy,id)
        local levels = Enum and Enum.SecrecyLevel
        if readable and levels then
            if level==levels.NeverSecret then return false end
            if level==levels.AlwaysSecret then return true end
        end
    end
    if not C_Secrets or type(C_Secrets.ShouldAurasBeSecret)~="function" then return false end
    local hidden, ok = self:Call(C_Secrets.ShouldAurasBeSecret)
    return not ok or type(hidden)~="boolean" or hidden
end

-- Reading a buff never mutates a timer or the active Seal. Selection happens once,
-- after all observations, so an old buff encountered first cannot undo a new cast.
function P:ReadAuras(filter)
    local found, candidates, status = {}, {}, {}
    local keys = filter=="HARMFUL" and {"forbearance"} or {"seal","holy","fury","ground"}
    local api, now = C_UnitAuras or {}, GetTime()
    local function accept(aura,hint,idHint,nameHint)
        if not self:Readable(aura) or type(aura)~="table" then return end
        local id,name = self:Field(aura,"spellId"),self:Field(aura,"name")
        id = self:Number(id) and id or idHint
        name = type(name)=="string" and name or nameHint
        local key = (id and self.byID[id]) or (name and self.byName[name]) or hint
        if not key and self:IsAdditionalSeal(id,name) then key="seal" end
        if not key or (hint and key~=hint) then return end
        local expires,duration = self:Field(aura,"expirationTime"),self:Field(aura,"duration")
        local entry={active=true,id=id,name=name,expires=self:Number(expires) and expires or nil,
            duration=self:Number(duration) and duration or nil,estimated=false}
        entry.uncertain=entry.expires==nil or ((key=="seal" or key=="holy") and entry.expires==0)
        if key=="seal" then candidates[#candidates+1]=entry
        elseif not found[key] or (entry.expires and entry.expires>now and found[key].uncertain) then found[key]=entry end
    end
    for _,key in ipairs(keys) do
        local absent, failed = false,false
        local function query(fn,id,name,...)
            if type(fn)~="function" then return end
            local aura,ok=self:Call(fn,...)
            if not ok or (aura~=nil and type(aura)~="table") then failed=true
            elseif aura then accept(aura,key,id,name)
            elseif not self:AurasRestricted(id) then absent=true end
        end
        local names={}
        for name in pairs(self.spells[key].names) do names[#names+1]=name end
        table.sort(names)
        for _,name in ipairs(names) do
            query(api.GetAuraDataBySpellName,nil,name,"player",name,filter)
            if filter=="HELPFUL" then query(api.GetPlayerAuraBySpellName,nil,name,name) end
        end
        for _,id in ipairs(self.definitions[key].ids) do
            local info=(self.spellInfoCache and self.spellInfoCache[id]) or self:SpellInfo(id)
            query(api.GetPlayerAuraBySpellID,id,self:Field(info,"name"),id)
        end
        status[key]=not absent -- a readable direct absence is more useful than a failed alternate API
    end
    if type(api.GetAuraDataByIndex)=="function" then
        local complete=true
        for index=1,255 do
            local aura,ok=self:AuraAt(index,filter)
            if not ok then complete=false;break end
            if aura==nil then break end
            if type(aura)~="table" then complete=false;break end
            if not self:Field(aura,"spellId") and not self:Field(aura,"name") then complete=false end
            accept(aura)
        end
        if complete then
            for _,key in ipairs(keys) do
                if not self:AurasRestricted(self.spells[key].id) then status[key]=false end
            end
        end
    end
    local pending=self.sealPending
    if pending and now>pending.untilTime then self.sealPending=nil;pending=nil end
    local chosen
    for _,entry in ipairs(candidates) do
        local matches=not pending or entry.name==pending.name or entry.id==pending.id
        if pending and pending.previousExpiry and entry.expires and entry.expires<=pending.previousExpiry+0.001 then matches=false end
        if matches and (not chosen or
            ((entry.expires or 0)>(chosen.expires or 0))) then chosen=entry end
    end
    if chosen then found.seal=chosen
    elseif pending then status.seal=true end
    return found,false,status
end

function P:RefreshAuras()
    self.auraScanCache={}
    self:RefreshPaladinAura();self:RefreshShieldState(false)
    local helpful,_,hidden=self:ReadAuras("HELPFUL")
    local harmful,_,debuffHidden=self:ReadAuras("HARMFUL")
    local now=GetTime()
    self.auras={}
    self.effectTimers=self.effectTimers or {}
    self.db.observedDurations=self.db.observedDurations or {}
    for _,key in ipairs({"seal","holy","fury","forbearance"}) do
        local live=key=="forbearance" and harmful[key] or helpful[key]
        local restricted=key=="forbearance" and debuffHidden[key] or hidden[key]
        local cast=self.effectTimers[key]
        if key=="seal" and live then self:SelectSeal(live.id,live.name) end
        local memory=self.memory[key]
        if cast and cast.expires<=now then self.effectTimers[key]=nil;cast=nil end
        if live and live.expires and live.expires>now then
            live.uncertain=false
            self.auras[key]=live
            self.memory[key]={active=true,expires=live.expires,duration=live.duration,estimated=true}
            if live.duration and live.duration>0 and live.duration<86400 then
                self.db.observedDurations[key=="seal" and (live.name or "seal") or key]=live.duration
                if key=="forbearance" then self.db.observedDurations.forbearanceTalentRank=(self.talentRanks or {})["sacred duty"] or 0 end
            end
            self.effectTimers[key]=nil
            if key=="holy" then self.used.holy=true end
        elseif live and key=="fury" and live.expires==0 then
            self.auras[key]=live;self.memory[key]=nil
        elseif live and live.expires and live.expires>0 and live.expires<=now then
            self.auras[key]={active=false};self.memory[key]=nil;self.effectTimers[key]=nil
        elseif live or restricted or (cast and now<(cast.holdUntil or 0)) then
            -- Hidden reads never rewrite a deadline or start a new duration.
            local kept=cast or (memory and memory.expires>now and memory)
            self.auras[key]=kept or {active=live and true or nil,uncertain=true}
            if not kept then self.memory[key]=nil end
        else
            self.auras[key]={active=false};self.memory[key]=nil;self.effectTimers[key]=nil
        end
    end
    local fury=self.auras.fury
    if fury and fury.active and not fury.uncertain then self.lastKnownFury=true
    elseif fury and fury.active==false and not hidden.fury
        and not (self.furyCastGrace and now<self.furyCastGrace) then self.lastKnownFury=false end
    self:RefreshGround(helpful.ground)
    self:RefreshTankBuffs()
    self:RefreshProtection()
    self.auraScanCache=nil
    self.lastAuraRefresh=now
end

function P:NoteCast(unit,id,intentional,selfTarget)
    if not self:Readable(unit) or unit~="player" or not self:Number(id) then return end
    local info=self:SpellInfo(id)
    local name=self:Field(info,"name")
    local key=self.byID[id] or (name and self.byName[name])
    self:NoteProtectionCast(id,name,intentional,selfTarget)
    if not key and self:IsAdditionalSeal(id,name) then key="seal" end
    local now=GetTime()
    if key=="seal" then
        if not intentional then
            return -- even a different Seal's late proc must not undo a swap
        end
        local previous=self.auras and self.auras.seal
        local previousExpiry=self.activeSeal and self.activeSeal.name==name and previous and previous.expires
        self:SelectSeal(id,name)
        self.sealPending={id=id,name=self.activeSeal.name,untilTime=now+3,previousExpiry=previousExpiry}
        self.lastSealCast=now
        self:StartEffectEstimate("seal",id)
    elseif key=="ground" then
        if not intentional and self.ground and self.ground.expires>now then return end
        self.ground={active=true,expires=now+self.db.groundDuration,duration=self.db.groundDuration,estimated=true}
        self:NoteUsedCooldown(key,id)
    elseif key=="holy" then
        self.used.holy=true;self.lastHolyCast=now;self:StartEffectEstimate(key,id)
    elseif key=="justice" or (key=="bulwark" and (self.spells.bulwark.known or self:IsKnownSpell(id)==true)) then
        self:NoteUsedCooldown(key,id)
    elseif key=="fury" then
        self.memory.fury=nil;self.furyCastGrace=now+1.5
        if intentional then self.lastKnownFury=true end
    end
end

function P:StartEffectEstimate(key,id)
    local name=key=="seal" and self.activeSeal.name or key
    local learned=self.db.observedDurations and self.db.observedDurations[name]
    local duration=self:Number(learned) and learned>0 and learned<86400 and learned or (key=="seal" and 30 or 10)
    self.effectTimers=self.effectTimers or {}
    self.memory[key]=nil
    self.effectTimers[key]={active=true,expires=GetTime()+duration,duration=duration,estimated=true,
        holdUntil=GetTime()+3,id=id}
end

local _,P=...

function P:RefreshTimerKnowledge()
    self.cooldownLengths=self.cooldownLengths or {}
    local ranks={}
    local tabs=self:Call(GetNumTalentTabs)
    if self:Number(tabs) and tabs>=0 and tabs<=10 then
        for tab=1,tabs do
            local count=self:Call(GetNumTalents,tab)
            if self:Number(count) and count>=0 and count<=100 and type(GetTalentInfo)=="function" then
                for index=1,count do
                    local ok,name,_,_,_,rank=pcall(GetTalentInfo,tab,index)
                    if ok and self:Readable(name) and type(name)=="string" and self:Number(rank) then ranks[name:lower()]=rank end
                end
            end
        end
        self.talentRanks=ranks
    else ranks=self.talentRanks or {} end
    self.baseCooldowns={ground=self.db.groundDuration,
        justice=60-math.max(0,math.min(3,ranks["improved hammer of justice"] or 0))*5,
        bulwark=300-math.max(0,math.min(2,ranks["sacred duty"] or 0))*30}
end

function P:EstimatedCooldownLength(key)
    if not self.baseCooldowns then self:RefreshTimerKnowledge() end
    local observed=self.cooldownLengths and self.cooldownLengths[key]
    if self:Number(observed) and observed>1.5 then return observed end
    return self.baseCooldowns[key]
end

-- These hooks only observe readable spell requests. They never cast, retarget,
-- replace a secure function, or treat pressing a button as a successful cast.
function P:NoteSpellIntent(id)
    if not self.isPaladin or not self.db.enabled then return end
    self.spellIntent={id=self:Number(id) and id or nil,at=GetTime()}
    local request=self.pendingCast
    if request and not request.id and GetTime()-request.at<=0.15 then
        request.id=self.spellIntent.id
    end
end

function P:InstallCastObservers()
    if self.castObserversInstalled or type(hooksecurefunc)~="function" then return end
    self.castObserversInstalled=true
    local function observe(name,callback)
        if type(_G[name])=="function" then pcall(hooksecurefunc,name,callback) end
    end
    observe("CastSpellByID",function(id) self:NoteSpellIntent(id) end)
    observe("CastSpellByName",function(name)
        if not self:Readable(name) or type(name)~="string" then self:NoteSpellIntent(nil);return end
        local info=self:SpellInfo((name:gsub("%s*%b()","")))
        self:NoteSpellIntent(self:Field(info,"spellID"))
    end)
    observe("UseAction",function(slot)
        local ok,kind,id,subtype=pcall(GetActionInfo,slot)
        if not ok or not self:Readable(kind) or not self:Readable(id) then self:NoteSpellIntent(nil);return end
        if kind=="macro" then
            if not self:Readable(subtype) or subtype~="spell" then id=self:Call(GetMacroSpell,id) end
        elseif kind~="spell" then id=nil end
        self:NoteSpellIntent(id)
    end)
end

function P:RememberCastRequest(unit,guid,id,targetName)
    if not self:Readable(unit) or unit~="player" then return end
    local now,intent=GetTime(),self.spellIntent
    local readableID=self:Number(id) and id or nil
    if not readableID and intent and now-intent.at<=0.5 then readableID=intent.id end
    local token=self:Readable(guid) and type(guid)=="string" and guid or nil
    if not readableID and self.pendingCast and now-self.pendingCast.at<=0.5
        and token and token==self.pendingCast.guid then readableID=self.pendingCast.id end
    -- A new SENT supersedes the old request, including untracked spells.
    local previous=self.pendingCast
    local selfTarget=self:Readable(targetName) and type(targetName)=="string" and self.playerCastNames
        and self.playerCastNames[targetName]==true or false
    -- START has no target-name payload; preserve the original SENT target only
    -- when its readable cast GUID identifies the very same request.
    if self:Readable(targetName) and targetName==nil and previous and token and token==previous.guid then selfTarget=previous.selfTarget end
    self.pendingCast={id=readableID,guid=token,at=now,selfTarget=selfTarget}
    self.spellIntent=nil
end

function P:CancelCast(unit,guid)
    if not self:Readable(unit) or unit~="player" then return end
    local pending=self.pendingCast
    if pending and self:Readable(guid) and type(guid)=="string" and pending.guid and guid~=pending.guid then return end
    self.pendingCast,self.spellIntent=nil,nil
end

function P:SuccessfulCast(unit,guid,id)
    if not self:Readable(unit) or unit~="player" then return end
    local request=self.pendingCast
    local token=self:Readable(guid) and type(guid)=="string" and guid or nil
    if request and (GetTime()-request.at>2 or (request.guid and token and request.guid~=token)) then request=nil end
    local readableID=self:Number(id) and id or nil
    if request and readableID and request.id and readableID~=request.id then request=nil end
    if request then self.pendingCast=nil end
    self.spellIntent=nil
    -- Fully hidden combat payloads can still confirm the one player SENT request.
    -- Without SENT + a readable spell request there is no fallback identity.
    self:NoteCast(unit,readableID or (request and request.id),request and request.id~=nil,request and request.selfTarget)
end

function P:NoteUsedCooldown(key,id)
    local now=GetTime()
    self.used[key]={at=now,holdUntil=now+0.5}
    self.spells[key].id,self.spells[key].known=id,true
    local duration=self:EstimatedCooldownLength(key)
    self.cooldownTimers[key]={active=true,expires=now+duration,duration=duration,estimated=true,cooldown=true}
    self.readyUntil[key]=nil
    self:RefreshUsedCooldowns(now)
end

function P:RefreshUsedCooldowns(now)
    now=now or GetTime()
    self.cooldownLengths=self.cooldownLengths or {}
    for _,key in ipairs({"ground","justice","bulwark"}) do
        local used=self.used[key]
        if type(used)=="table" then
            local remaining,_,duration=self:Cooldown(key)
            local timer=self.cooldownTimers[key]
            local groundActive=key=="ground" and self.ground and self.ground.expires>now
            if remaining and remaining>0 then
                self.cooldownTimers[key]={active=true,expires=now+remaining,duration=duration,estimated=false,cooldown=true}
                if duration and duration>1.5 then self.cooldownLengths[key]=duration end
                used.confirmed,used.done=true,nil;self.readyUntil[key]=nil
            elseif remaining==0 and now>=(used.holdUntil or used.at) and not groundActive then
                self.cooldownTimers[key]=nil
                if not used.done and used.confirmed then self.readyUntil[key]=now+0.8 end
                used.done=true
            elseif timer and timer.expires>now then
                timer.estimated=true
            elseif timer and not groundActive then
                self.cooldownTimers[key]=nil;used.done=true
            end
        end
    end
    self:RefreshGround()
end

function P:RecoverCooldowns()
    local now=GetTime()
    self.cooldownLengths=self.cooldownLengths or {}
    for _,key in ipairs({"ground","justice","bulwark"}) do
        local remaining,_,duration=self:Cooldown(key)
        if remaining and remaining>0 then
            self.cooldownLengths[key]=duration
            if not self.used[key] or self.used[key].done then self.used[key]={at=now,confirmed=true} end
            self.cooldownTimers[key]={active=true,expires=now+remaining,duration=duration,cooldown=true,estimated=false}
        end
    end
end

function P:UsedTimerView(key,now)
    if self.definitions[key].talentOnly and not self.spells[key].known then return nil end
    local timer=self.cooldownTimers[key]
    if timer and timer.expires>now then return timer,"cooldown" end
    if self.readyUntil[key] and self.readyUntil[key]>now then return nil,"ready" end
end

function P:ClearUsedTimers()
    self.used,self.cooldownTimers,self.readyUntil={},{},{}
    self.effectTimers,self.pendingCast,self.spellIntent,self.sealPending={},nil,nil,nil
    self.activeSeal,self.lastSealCast,self.lastHolyCast=nil,nil,nil
    self.protectionCasts,self.protection,self.lastKnownFury={},{},nil
end

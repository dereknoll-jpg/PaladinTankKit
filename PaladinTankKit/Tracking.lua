local _, P = ...

function P:SpellInfo(identifier)
    if not self:Readable(identifier) or (type(identifier)~="number" and type(identifier)~="string") then return nil end
    self.spellInfoCache=self.spellInfoCache or {}
    local cached=self.spellInfoCache[identifier]
    local info=self:Call(C_Spell and C_Spell.GetSpellInfo,identifier)
    local name,icon,id=self:Field(info,"name"),self:Field(info,"iconID"),self:Field(info,"spellID")
    if type(name)~="string" then return cached end
    local result={name=name,iconID=icon or (cached and cached.iconID),
        spellID=self:Number(id) and id or (type(identifier)=="number" and identifier or (cached and cached.spellID))}
    self.spellInfoCache[identifier]=result
    if result.spellID then self.spellInfoCache[result.spellID]=result end
    self.spellInfoCache[name]=result
    return result
end

function P:ReadCooldown(id)
    local api = C_Spell and C_Spell.GetSpellCooldown or GetSpellCooldown
    if type(api) ~= "function" then return nil end
    local ok, info, legacyDuration, legacyEnabled, legacyRate = pcall(api, id)
    if not ok or not self:Readable(info) then return nil end
    local start, duration, enabled, rate
    if type(info) == "table" then
        start, duration = self:Field(info,"startTime"), self:Field(info,"duration")
        local enabledOK, rateOK
        enabled, enabledOK = self:Field(info,"isEnabled")
        rate, rateOK = self:Field(info,"modRate")
        if not enabledOK or not rateOK then return nil end
    else
        start, duration, enabled, rate = info, legacyDuration, legacyEnabled, legacyRate
    end
    if not self:Number(start) or not self:Number(duration) or start < 0 or duration < 0
        or not self:Readable(enabled) or enabled == false or enabled == 0
        or not self:Readable(rate) then return nil end
    rate = self:Number(rate) and rate > 0 and rate or 1
    local remaining = math.max(0,start+duration/rate-GetTime())
    if remaining > 0 and duration <= 1.5 then return nil end
    return remaining, start, duration/rate
end

function P:RefreshGround(aura)
    if UnitIsDeadOrGhost("player") then return end
    local now = GetTime()
    local function adopt(expires, duration, estimated, source)
        if not self:Number(expires) or expires <= now then return end
        self.ground = {active=true,expires=expires,duration=duration,estimated=estimated,source=source}
    end
    if aura and aura.expires and aura.expires > now then
        adopt(aura.expires,aura.duration,false,"aura"); return
    end
    -- Forever can represent the persistent ground effect in a player totem slot.
    if type(GetTotemInfo) == "function" then
        for slot=1,4 do
            local ok, have, name, start, duration = pcall(GetTotemInfo,slot)
            if ok and self:Readable(have) and have == true and self:Readable(name)
                and type(name) == "string" and (self.spells.ground.names[name] or name == "Consecration")
                and self:Number(start) and self:Number(duration) and duration > 0 and start+duration > now then
                adopt(start+duration,duration,false,"totem"); return
            end
        end
    end
    if self.ground and self.ground.expires > now then return end
    -- Recover a missed cast from the ability's own cooldown start, never the GCD.
    local remaining, start = self:Cooldown("ground")
    if remaining and remaining > 0 and start and start+self.db.groundDuration > now then
        adopt(start+self.db.groundDuration,self.db.groundDuration,true,"cooldown")
    end
end

function P:IsKnownSpell(id)
    local known = self:Call(C_SpellBook and C_SpellBook.IsSpellKnown, id)
    if known ~= true then
        local alternate = self:Call(IsPlayerSpell,id)
        if alternate == true then return true end
        if known == nil then known=alternate end
    end
    return known
end

function P:RefreshShieldState(force)
    local now=GetTime()
    if force==false and self.lastShieldCheck and now-self.lastShieldCheck<2 then return end
    self.lastShieldCheck=now
    self.shieldWarning = nil
    self.shieldEquipped=nil
    local id,known = self:Call(GetInventoryItemID, "player", 17)
    if known and id==nil then self.shieldEquipped=false;return end
    local itemAPI = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
    if not self:Number(id) or type(itemAPI) ~= "function" or type(GetInventoryItemDurability) ~= "function" then return end
    local ok, _, _, _, equipLoc = pcall(itemAPI, id)
    if not ok or not self:Readable(equipLoc) or type(equipLoc)~="string" or equipLoc=="" then return end
    self.shieldEquipped=equipLoc=="INVTYPE_SHIELD"
    if not self.shieldEquipped then return end
    local readable, current, maximum = pcall(GetInventoryItemDurability, 17)
    if not readable or not self:Number(current) or not self:Number(maximum)
        or maximum <= 0 or current < 0 or current > maximum then return end
    local fraction = current/maximum
    if fraction <= 0.20 then
        self.shieldWarning = current == 0 and "Shield broken" or ("Shield durability: " .. math.floor(fraction*100) .. "%")
    end
end

function P:RefreshPaladinAura()
    -- Paladin auras use Blizzard's stance bar. This checks YOUR selected aura,
    -- rather than mistaking another Paladin's party buff for your own selection.
    local count = self:Call(GetNumShapeshiftForms)
    local state = {known = false, active = false, uncertain = true}
    self.paladinAura = state
    if not self:Number(count) or count < 1 or count > 20 or count%1 ~= 0
        or type(GetShapeshiftFormInfo) ~= "function" then return end
    state.known, state.uncertain = true, false
    for index=1,count do
        local ok, _, active = pcall(GetShapeshiftFormInfo, index)
        if not ok or not self:Readable(active) or type(active) ~= "boolean" then state.uncertain = true
        elseif active then state.active = true end
    end
end

function P:IsAdditionalSeal(id, name)
    if not self:Readable(name) or type(name) ~= "string" or name:sub(1,8) ~= "Seal of " then return false end
    if not self:Number(id) or self:Call(C_SpellBook and C_SpellBook.IsSpellKnown, id) ~= true then return false end
    self.byID[id], self.byName[name] = "seal", "seal"
    return true
end

function P:SelectSeal(id, name)
    local info = self:SpellInfo(id or name)
    local selected = {id = id, name = name or "Seal", icon = self.definitions.seal.icon}
    if type(info) == "table" then
        if self:Readable(info.name) and type(info.name) == "string" then selected.name = info.name end
        if self:Readable(info.iconID) and info.iconID then selected.icon = info.iconID end
    end
    if not self:Readable(selected.name) or type(selected.name) ~= "string" then return end
    -- Never carry one Seal's verified expiration into a different Seal.
    if self.activeSeal and self.activeSeal.name ~= selected.name then
        self.memory.seal=nil
        if self.effectTimers then self.effectTimers.seal=nil end
    end
    self.activeSeal, self.used.seal = selected, true
    self.spells.seal.names[selected.name] = true
    if self.sealTile then self.sealTile.icon:SetTexture(selected.icon) end
end

local _, P = ...

-- Forever 1.60.1 effect IDs, not the similarly named passive talents.
P.protectionDefs = {
    {key="iron", id=1311033, name="Iron Creed", option="showIronCreed", short="Creed",
        icon="Interface\\Icons\\Spell_Holy_ImprovedResistanceAuras"},
    {key="block", id=1328551, name="Shieldsworn", option="showSpellBlock", short="Block",
        icon="Interface\\Icons\\Spell_Holy_GreaterBlessingofSanctuary"},
    {key="absorb", id=1311015, name="Templar's Bulwark", option="showBulwarkActive", short="Bulwark",
        icon="Interface\\Icons\\Spell_Holy_PowerWordShield"},
}
P.protectionOptions={"showIronCreed","showSpellBlock","showBulwarkActive","warnCleanse"}

function P:DiscoverProtection()
    self.protectionNames={}
    for _,def in ipairs(self.protectionDefs) do
        local info=self:SpellInfo(def.id)
        def.localName=self:Field(info,"name") or def.name
        def.texture=self:Field(info,"iconID") or def.icon
        self.protectionNames[def.localName]=def.key
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
        "\nBlessing of Protection eligibility also depends on its target."
end

function P:RefreshProtection()
    local api=C_UnitAuras or {}
    local found,absent,uncertain={},{},{}
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
            if amount==0 then found[key]=nil;absent[key]=true;uncertain[key]=nil;return end
            entry.amount=amount
        end
        found[key]=entry
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
        if found[def.key] then
            local effect=found[def.key]
            if def.key=="absorb" and effect.amount then
                -- This is an observed baseline, never a health-derived maximum.
                local same=old and math.abs(old.expires-effect.expires)<.15
                effect.capacity=math.max(effect.amount,(same and old.capacity) or 0)
            end
            self.protection[def.key]=effect
        elseif (absent[def.key] and not uncertain[def.key]) or not old or old.expires<=now then self.protection[def.key]=nil
        else
            -- Retain only a previously observed deadline when reads become hidden.
            self.protection[def.key]={active=true,expires=old.expires,duration=old.duration,estimated=true,capacity=old.capacity}
        end
    end
    if UnitIsDeadOrGhost("player") then self.protection={} end
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

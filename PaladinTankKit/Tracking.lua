local _, P = ...

function P:IsKnownSpell(id)
    local known = self:Call(C_SpellBook and C_SpellBook.IsSpellKnown, id)
    if known == nil then known = self:Call(IsPlayerSpell, id) end
    return known
end

function P:RefreshShieldState()
    self.shieldWarning = nil
    local id = self:Call(GetInventoryItemID, "player", 17)
    local itemAPI = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
    if not self:Number(id) or type(itemAPI) ~= "function" or type(GetInventoryItemDurability) ~= "function" then return end
    local ok, _, _, _, equipLoc = pcall(itemAPI, id)
    if not ok or not self:Readable(equipLoc) or equipLoc ~= "INVTYPE_SHIELD" then return end
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
    local info = self:Call(C_Spell and C_Spell.GetSpellInfo, id or name)
    local selected = {id = id, name = name or "Seal", icon = self.definitions.seal.icon}
    if type(info) == "table" then
        if self:Readable(info.name) and type(info.name) == "string" then selected.name = info.name end
        if self:Readable(info.iconID) and info.iconID then selected.icon = info.iconID end
    end
    if not self:Readable(selected.name) or type(selected.name) ~= "string" then return end
    -- Never carry one Seal's verified expiration into a different Seal.
    if self.activeSeal and self.activeSeal.name ~= selected.name then self.memory.seal = nil end
    self.activeSeal, self.used.seal = selected, true
    if self.sealTile then self.sealTile.icon:SetTexture(selected.icon) end
end

function P:NoteUsedCooldown(key, spellID)
    local now = GetTime()
    self.used[key] = {at = now}
    self.cooldownTimers[key], self.readyUntil[key] = nil, nil
    -- Keep the actual cast rank; cooldown queries must not use an unrelated highest rank.
    self.spells[key].id, self.spells[key].known = spellID, true
    self:RefreshUsedCooldowns(now)
end

function P:RefreshUsedCooldowns(now)
    now = now or GetTime()
    for _, key in ipairs({"ground", "justice", "bulwark"}) do
        local used = self.used[key]
        if type(used) == "table" then
            local remaining = self:Cooldown(key)
            local previous = self.cooldownTimers[key]
            local groundActive = key == "ground" and self.ground and self.ground.expires > now
            if remaining and remaining > 0 then
                self.cooldownTimers[key] = {active = true, expires = now+remaining, estimated = false, cooldown = true}
                used.unknown, used.done, used.confirmed = nil, nil, true
                self.readyUntil[key] = nil
            elseif not used.done and remaining == 0 and not groundActive
                and (used.confirmed or (key == "ground" and now-used.at >= self.db.groundDuration)) then
                used.done = true; self.cooldownTimers[key] = nil; self.readyUntil[key] = now+0.8
            elseif not used.done and remaining == nil then
                if previous and previous.expires > now then previous.estimated = true
                elseif previous then
                    -- A remembered cooldown expiring while hidden is not proof of readiness.
                    self.cooldownTimers[key] = nil; used.done = true
                else used.unknown = true end
            elseif not used.done and remaining == 0 and not groundActive then
                -- A zero immediately after casting may be a delayed server update.
                used.unknown = true
            end
        end
    end
end

function P:RecoverCooldowns()
    local now = GetTime()
    for _, key in ipairs({"ground", "justice", "bulwark"}) do
        local remaining = self:Cooldown(key)
        if remaining and remaining > 0 and (not self.used[key] or self.used[key].done) then
            self.used[key] = {at=now, confirmed=true}
            self.cooldownTimers[key] = {active=true, expires=now+remaining, cooldown=true, estimated=false}
        end
    end
end

function P:UsedTimerView(key, now)
    if self.definitions[key].talentOnly and not self.spells[key].known then return nil end
    local used = self.used[key]
    if type(used) ~= "table" then return nil end
    local cd = self.cooldownTimers[key]
    if cd and cd.expires > now then return cd, "cooldown" end
    if self.readyUntil[key] and self.readyUntil[key] > now then return nil, "ready" end
    if not used.done and (used.unknown or now-used.at < 0.25) then return nil, "unknown" end
end

function P:ClearUsedTimers()
    self.used, self.cooldownTimers, self.readyUntil = {}, {}, {}
    self.activeSeal, self.lastSealCast, self.lastHolyCast = nil, nil, nil
end

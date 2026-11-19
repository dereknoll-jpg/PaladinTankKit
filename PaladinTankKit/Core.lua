local _, PTK = ...

PTK.version = "1.0.2"
PTK.timerKeys = {"seal", "ground", "justice", "holy", "bulwark"}
PTK.defaults = { enabled = true, locked = true, scale = 1, horizon = 30,
    warnings = true, showForbearance = true, idleFade = true, groundDuration = 8,
    autoMark = true, bossNotes = true, effects = true, reducedMotion = false,
    warnFury=true, warnAura=true, warnShield=true,
    trackSeal=true, trackGround=true, trackJustice=true, trackHoly=true, trackBulwark=true }
PTK.definitions = {
    seal = { label = "Seal", ids = {
        20154, 21084, 20287, 20288, 20289, 20290, 20291, 20292, 20293,
        21082, 20162, 20305, 20306, 20307, 20308, 20164,
        20165, 20347, 20348, 20349, 20166, 20356, 20357,
        20375, 20915, 20918, 20919, 20920,
        1311649, 1311656, 20163, 20419, 20421, 20422, 20423},
        icon = "Interface\\Icons\\Spell_Holy_SealOfFury" },
    fury = { label = "Righteous Fury", ids = {25780}, icon = "Interface\\Icons\\Spell_Holy_SealOfFury" },
    ground = { label = "Consecration", ids = {26573, 20116, 20922, 20923, 20924},
        icon = "Interface\\Icons\\Spell_Holy_InnerFire" },
    justice = { label = "Hammer of Justice", ids = {853, 5588, 5589, 10308},
        icon = "Interface\\Icons\\Spell_Holy_SealOfMight" },
    holy = { label = "Holy Shield", ids = {1239570, 20925, 20927, 20928},
        icon = "Interface\\Icons\\Spell_Holy_BlessingOfProtection" },
    bulwark = { label = "Templar's Bulwark", ids = {1311015}, talentOnly = true,
        icon = "Interface\\Icons\\Spell_Holy_PowerWordShield" },
    forbearance = { label = "Forbearance", ids = {25771}, icon = "Interface\\Icons\\Spell_Holy_RemoveCurse" },
}

-- Always test for secrecy BEFORE a nil comparison, boolean test, arithmetic or indexing.
function PTK:Readable(value)
    return not (issecretvalue and issecretvalue(value))
end

function PTK:Call(fn, ...)
    if type(fn) ~= "function" then return nil, false end
    local ok, value = pcall(fn, ...)
    if not ok or not self:Readable(value) then return nil, false end
    return value, true
end

function PTK:Number(value)
    return self:Readable(value) and type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

function PTK:Field(object, key)
    if not self:Readable(object) or type(object) ~= "table" then return nil end
    return self:Call(function() return object[key] end)
end

function PTK:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cfff0c878Paladin TankKit|r  " .. message)
end

function PTK:InitializeDB()
    if type(PaladinTankKitDB) ~= "table" then PaladinTankKitDB = {} end
    self.db = PaladinTankKitDB
    for key, value in pairs(self.defaults) do
        if type(self.db[key]) ~= type(value) then self.db[key] = value end
    end
    for _, key in ipairs({"scale", "horizon", "groundDuration"}) do
        if not self:Number(self.db[key]) then self.db[key] = self.defaults[key] end
    end
    self.db.scale = math.max(0.75, math.min(1.5, self.db.scale))
    if self.db.horizon ~= 15 and self.db.horizon ~= 30 and self.db.horizon ~= 60 then self.db.horizon = 30 end
    self.db.groundDuration = math.max(4, math.min(20, self.db.groundDuration))
    if type(self.db.observedDurations)~="table" then self.db.observedDurations={} end
    self.memory, self.spells, self.byID, self.byName = {}, {}, {}, {}
    self.used, self.cooldownTimers, self.readyUntil = {}, {}, {}
end

function PTK:DiscoverSpells()
    self.spells, self.byID, self.byName = {}, {}, {}
    for key, def in pairs(self.definitions) do
        local spell = { name = def.label, icon = def.icon, known = false, names = {}, ids = def.ids }
        for _, id in ipairs(def.ids) do
            self.byID[id] = key
            local info = self:SpellInfo(id)
            if type(info) == "table" then
                if self:Readable(info.name) and type(info.name) == "string" then
                    spell.names[info.name] = true
                    self.byName[info.name] = key
                    spell.name = info.name
                end
                local known = self:IsKnownSpell(id)
                if known == true then
                    spell.known, spell.id = true, id
                    if self:Readable(info.iconID) and info.iconID then spell.icon = info.iconID end
                end
            end
        end
        self.spells[key] = spell
        if def.talentOnly and not spell.known then
            self.used[key], self.cooldownTimers[key], self.readyUntil[key] = nil, nil, nil
        end
    end
    self.spells.seal.name = "Seal"
    if self.activeSeal then self:SelectSeal(self.activeSeal.id, self.activeSeal.name) end
    self:RefreshTimerKnowledge()
end

function PTK:Cooldown(key)
    local spell = self.spells[key]
    if not spell or not spell.known then return nil end
    local remaining, start, duration = self:ReadCooldown(spell.id)
    if remaining and remaining > 0 then return remaining, start, duration end
    -- A learned rank can differ from the ID used by the server's cooldown family.
    for _, id in ipairs(spell.ids) do
        if id ~= spell.id and self:IsKnownSpell(id) == true then
            local other, otherStart, otherDuration = self:ReadCooldown(id)
            if other and other > 0 then return other, otherStart, otherDuration end
        end
    end
    return remaining, start, duration
end

function PTK:Mark(icon)
    if not self.isPaladin or not self.db or not self.db.enabled then return end
    if icon ~= 0 and icon ~= 7 and icon ~= 8 then return end
    local issue = self:MarkPermissionIssue()
    if issue then self:Print(issue); return end
    local unit
    for _, candidate in ipairs({"mouseover", "target"}) do
        local exists = self:Call(UnitExists, candidate)
        local hostile = self:Call(UnitCanAttack, "player", candidate)
        local dead = self:Call(UnitIsDeadOrGhost, candidate)
        if exists == true and hostile == true and dead == false and (icon == 0 or self:IsEliteEnemy(candidate)) then
            unit = candidate; break
        end
    end
    if not unit then self:Print("Mouse over or target a living elite enemy first."); return end
    local current, readable = self:Call(GetRaidTargetIndex, unit)
    if not readable then self:Print("That enemy's mark is currently unavailable."); return end
    if current == icon then
        if icon ~= 0 then self:NoteManualMark(unit, icon) end
        return
    end
    if icon == 0 and current == nil then return end
    local ok = pcall(SetRaidTarget, unit, icon)
    if not ok then self:Print("WoW could not apply that mark.")
    else
        self:NoteManualMark(unit, icon)
        if self.QueueMarkFeedback then self:QueueMarkFeedback(unit, icon, current == 7 and icon == 8) end
    end
end

function PTK:FormatTime(seconds, estimated)
    if seconds <= 0 then return "" end
    local rounded = math.max(1,math.ceil(seconds-0.000001))
    local text = rounded >= 60 and string.format("%d:%02d", math.floor(rounded/60), rounded%60) or tostring(rounded)
    return (estimated and "~" or "") .. text
end

function PTK:Fraction(expires, now)
    return math.max(0, math.min(1, (expires - now) / self.db.horizon))
end

function PTK:Warnings()
    if not self.db.warnings or UnitIsDeadOrGhost("player") or IsMounted() then return "" end
    local shield = self.db.warnShield and self.shieldWarning or nil
    if not IsInGroup() and self:Call(UnitCanAttack, "player", "target") ~= true then return shield or "" end
    local missing = {}
    for _, key in ipairs({"fury"}) do
        local aura = self.auras and self.auras[key]
        if self.db.warnFury and self.spells[key].known and aura and not aura.active and not aura.uncertain then
            missing[#missing + 1] = self.spells[key].name
        end
    end
    local stance = self.paladinAura
    if self.db.warnAura and stance and stance.known and not stance.active and not stance.uncertain then missing[#missing+1] = "Aura" end
    local buffs = #missing > 0 and ("Missing: " .. table.concat(missing, " / ")) or ""
    return shield and (shield .. (buffs ~= "" and (" / " .. buffs) or "")) or buffs
end

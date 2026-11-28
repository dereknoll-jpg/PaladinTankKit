local _, PTK = ...

function PTK:Instance()
    if type(GetInstanceInfo) ~= "function" then return nil end
    local ok, _, kind, _, _, _, _, _, id = pcall(GetInstanceInfo)
    if not ok or not self:Readable(kind) or not self:Number(id) then return nil end
    return id, kind
end

function PTK:HasMarkingLead()
    if not IsInGroup() then return true end
    return self:Call(UnitIsGroupLeader, "player") == true
        or self:Call(UnitIsGroupAssistant, "player") == true
end

function PTK:MarkPermissionIssue()
    local _, kind = self:Instance()
    if IsInGroup() and (kind == "party" or IsInRaid()) and not self:HasMarkingLead() then
        return "Marking paused: request party leader or raid assist. Tank role alone does not grant marking leadership."
    end
end

function PTK:ReadRaidMark(unit)
    local mark,ok=self:Call(GetRaidTargetIndex,unit)
    if not ok then return nil,false end
    if mark==nil or mark==0 then return nil,true end
    if not self:Number(mark) or mark%1~=0 or mark<1 or mark>8 then return nil,false end
    return mark,true
end

function PTK:MarkingStatus()
    if self.assistedMarking then
        if not self.db.enabled then return "OFF","TankKit is disabled." end
        return "ASSIST", "Select a target, then click Skull or X. Shift-click Skull: X; Ctrl-click: clear. Bind the secure actions under Paladin TankKit, or use WoW's Raid Targeting bindings. Group permissions still apply."
    end
    local instanceID,kind=self:Instance()
    local m=self.marking
    if not self.db.enabled then return "OFF","TankKit is disabled." end
    if not kind then return "HOLD","WoW is hiding instance data; dungeon eligibility cannot be verified." end
    if not IsInGroup() then return "MAN","Automatic marking requires a dungeon party." end
    if IsInRaid() or kind~="party" or (m and m.worldBoss) then return "MAN","Automatic marks are dungeon-party only; raids, world bosses and outdoors stay manual." end
    if self.dungeons[instanceID] and self.dungeons[instanceID].manualOnly then return "MAN","This dungeon catalog requires manual marking." end
    if not self.db.autoMark then return "MAN","Automatic marking is switched off." end
    local permission=self:MarkPermissionIssue()
    if permission then return "LEAD",permission end
    if self.markingBlocked then return "BLOCK",self.markingBlocked end
    if m and m.paused then return "PAUSE",m.paused end
    if self.preview then return "DEMO","Preview never marks enemies." end
    if UnitIsDeadOrGhost("player") or IsMounted() then return "WAIT","Marking waits while dead or mounted." end
    if m then
        local pending=false
        for guid,owned in pairs(m.owned) do
            local record=m.candidates[guid]
            if owned.confirmed and record and record.unit and not record.dead
                and self:UnitIdentity(record.unit)==guid and self:ReadRaidMark(record.unit)==owned.icon then
                return "AUTO","Automatic mark confirmed on an eligible dungeon enemy."
            end
            if not owned.confirmed then pending=true end
        end
        if pending then return "SET","Mark requested; waiting for the client to confirm it." end
        if next(m.owned) then return "HOLD","Previous marks are no longer readable or visible; absence is not proof of death." end
    end
    if not self:IsAutoMarkEnemy("target") then return "WAIT","Select a living elite enemy to begin. Non-elites are never marked." end
    if not self:UnitIdentity("target") then return "HOLD","WoW is hiding this target's identity; no automatic mark can be verified." end
    local _,readable=self:ReadRaidMark("target")
    if not readable then return "HOLD","WoW is hiding this target's marker; automatic marking cannot safely overwrite it." end
    return m and m.armed and "ARM" or "WAIT",m and m.armed and "Elite selected; preparing the first mark." or "Select a living elite to start marking."
end

function PTK:PrintMarkingStatus()
    local status,reason=self:MarkingStatus()
    local _,kind=self:Instance()
    self:Print("v"..self.version.." marking "..status..": "..reason)
    self:Print("Auto="..tostring(self.db.autoMark)..", group="..tostring(IsInGroup())..
        ", leader/assist="..tostring(self:HasMarkingLead())..", tank="..tostring(self:IsAssignedTank())..
        ", instance="..tostring(kind)..", target elite="..tostring(self:IsAutoMarkEnemy("target")))
end

function PTK:MarkActionBlocked(addon,action)
    if not self:Readable(addon) or type(addon)~="string" or addon~="PaladinTankKit" then return end
    if not self:Readable(action) or type(action)~="string" then return end
    if not action:find("SetRaidTarget",1,true) and not self.markAttempt then return end
    if self.assistedMarking then
        self.secureMarkBlocked=true
        return
    end
    self.markingBlocked="WoW blocked addon marking. Use Blizzard's target-marker keybindings or target menu; leader status cannot override this client restriction."
    self:PauseMarking(self.markingBlocked)
end

function PTK:UpdatePermissionAlert()
    if self.assistedMarking then return end
    local issue = self.db.enabled and self:MarkPermissionIssue() or nil
    if issue and not self.permissionWarned then
        self:Print(issue); self.permissionWarned = true
    elseif not issue then self.permissionWarned = nil end
end

function PTK:ResetMarking()
    self.marking = {candidates = {}, slots = {}, owned = {}, ignored = {}, scouted = {}, sequence = 0}
    self.markFeedback, self.markFlash = nil, nil
    self.markAdvice=nil
end

function PTK:UnitIdentity(unit)
    if not self:Readable(unit) or type(unit) ~= "string" then return nil end
    local guid = self:Call(UnitGUID, unit)
    if type(guid) ~= "string" then return nil end
    -- Parse only a readable GUID. Nameplate slot numbers are never persistent identity.
    local npcID = tonumber(guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-"))
        or tonumber(guid:match("^Vehicle%-%d+%-%d+%-%d+%-%d+%-(%d+)%-"))
    local name = self:Call(UnitName, unit)
    if type(name) ~= "string" then name = nil end
    return guid, npcID, name
end

function PTK:IsEliteEnemy(unit)
    if self:Call(UnitExists, unit) ~= true or self:Call(UnitCanAttack, "player", unit) ~= true
        or self:Call(UnitIsDeadOrGhost, unit) ~= false then return false end
    local kind = self:Call(UnitClassification, unit)
    return kind == "elite" or kind == "rareelite" or kind == "worldboss"
end

function PTK:GroupEngaged(unit)
    if self:Call(UnitAffectingCombat, unit) ~= true then return false end
    for _, member in ipairs({"player", "party1", "party2", "party3", "party4"}) do
        local threat = self:Call(UnitThreatSituation, member, unit)
        if self:Number(threat) and threat > 0 then return true end
        if self:Call(UnitExists, member) == true and self:Call(UnitIsUnit, unit .. "target", member) == true then
            return true
        end
    end
    -- Combat alone is insufficient: this could be somebody else's nearby pull.
    return false
end

function PTK:AutoMarkAllowed()
    if self.assistedMarking then return false end
    local instanceID, kind = self:Instance()
    local catalog = self.dungeons[instanceID]
    return self.isPaladin and self.db and self.db.enabled and self.db.autoMark and not self.preview
        and kind == "party" and IsInGroup() and not IsInRaid() and self:HasMarkingLead()
        and not self.markingBlocked
        and not (self.marking and self.marking.worldBoss)
        and not (catalog and catalog.manualOnly) and not UnitIsDeadOrGhost("player") and not IsMounted()
end

-- Advice never writes markers or changes secure button attributes. Hidden data
-- means no recommendation. Mouseover can scout a caster but cannot select it.
function PTK:UpdateMarkAdvice()
    self.markAdvice=nil
    if not self.db.enabled or not self.db.autoMark or self.preview
        or UnitIsDeadOrGhost("player") or IsMounted() then return end
    local id,kind=self:Instance()
    if kind~="party" or not IsInGroup() or IsInRaid() then return end
    local catalog=self.dungeons[id]
    if not catalog or catalog.manualOnly then return end
    if not self.marking then self:ResetMarking() end
    local m=self.marking
    local guid=self:UnitIdentity("mouseover")
    if guid and self:IsAutoMarkEnemy("mouseover") then
        local cast=self:Call(UnitCastingInfo,"mouseover") or self:Call(UnitChannelInfo,"mouseover")
        if type(cast)=="string" and (m.scouted[guid] or (m.scoutCount or 0)<256) then
            if not m.scouted[guid] then m.scoutCount=(m.scoutCount or 0)+1 end
            m.scouted[guid]={caster=true}
        end
    end
    if not self:IsAutoMarkEnemy("target") then return end
    local targetGUID,npcID,name=self:UnitIdentity("target")
    if not targetGUID then return end
    local mark,readable=self:ReadRaidMark("target")
    if not readable or mark then return end -- Respect every existing marker.
    local entry=self:CatalogEntry(id,npcID,name)
    if entry and (entry.confidence or entry.neverAutoMark or entry.boss) then return end
    local cast=self:Call(UnitCastingInfo,"target") or self:Call(UnitChannelInfo,"target")
    local caster=type(cast)=="string" or (m.scouted[targetGUID] and m.scouted[targetGUID].caster)
        or (entry and entry.caster)
    if entry and entry.score and entry.score>40 then self.markAdvice="Priority enemy"
    elseif caster then self.markAdvice="Priority caster" end
end

function PTK:IsAutoMarkEnemy(unit)
    -- World-boss classification is manual-only, even in a party map.
    return self:IsEliteEnemy(unit) and self:Call(UnitClassification, unit) ~= "worldboss"
end

function PTK:ObserveMarkUnit(unit, seed)
    local guid, npcID, name = self:UnitIdentity(unit)
    if not guid then return nil end
    local m = self.marking
    local old = m.candidates[guid]
    if old and self:Call(UnitIsDeadOrGhost, unit) == true then
        old.dead, old.unit = true, nil; return old
    end
    if not seed and not self:IsAutoMarkEnemy(unit) then return nil end
    if seed and not self:IsEliteEnemy(unit) then return nil end
    if not seed and not self:GroupEngaged(unit) and not (old and old.seed) then return nil end
    local id = self:Instance()
    local e = self:CatalogEntry(id, npcID, name)
    if not seed and e and e.neverAutoMark then return nil end
    if not old then
        if m.sequence >= 256 then return nil end
        m.sequence = m.sequence + 1
        old = {guid = guid, npcID = npcID, name = name, sequence = m.sequence, entry = e}
        m.candidates[guid] = old
        if not m.started then m.started = GetTime() end
    end
    old.unit, old.lastSeen, old.seed, old.dead = unit, GetTime(), seed or old.seed, false
    old.entry = e or old.entry
    old.caster = old.caster or (m.scouted[guid] and m.scouted[guid].caster)
    local cast = self:Call(UnitCastingInfo, unit)
    if type(cast) ~= "string" then cast = self:Call(UnitChannelInfo, unit) end
    if type(cast) == "string" then old.caster = true end
    if not m.initial and self:Call(UnitIsUnit, unit, "target") == true then m.initial = guid end
    return old
end

function PTK:MarkUnitTokens()
    local units, used = {}, {}
    local function add(unit)
        if self:Readable(unit) and type(unit) == "string" and not used[unit] then
            used[unit] = true; units[#units + 1] = unit
        end
    end
    add("target"); add("mouseover")
    for i = 1, 5 do add("boss" .. i) end
    for i = 1, 4 do add("party" .. i .. "target") end
    local plates = self:Call(C_NamePlate and C_NamePlate.GetNamePlates)
    if type(plates) == "table" then
        for _, plate in ipairs(plates) do
            if self:Readable(plate) and type(plate) == "table" then add(plate.namePlateUnitToken) end
        end
    end
    return units
end

function PTK:PauseMarking(reason)
    if self.marking.paused then return end
    self.marking.paused = reason
    self:Print(reason .. (self.markingBlocked and "" or " /ptk resume to retry."))
end

function PTK:SyncMarkOwnership()
    local m, now = self.marking, GetTime()
    for guid, owned in pairs(m.owned) do
        local r = m.candidates[guid]
        if r and r.dead then
            if m.slots[owned.icon] == guid then m.slots[owned.icon] = nil end
            m.owned[guid] = nil
        elseif r and r.unit and now >= owned.verifyAt then
            local actual, ok = self:ReadRaidMark(r.unit)
            if not ok then self:PauseMarking("Marking paused: WoW is hiding raid marks."); return false end
            if actual ~= owned.icon then
                self:PauseMarking("Marking paused: a mark changed or WoW refused it."); return false
            end
            owned.confirmed=true
        end
    end
    for _, r in pairs(m.candidates) do
        if r.unit and not r.dead then
            local mark, ok = self:ReadRaidMark(r.unit)
            if not ok then self:PauseMarking("Marking paused: WoW is hiding raid marks."); return false end
            r.mark = mark
            if (mark == 7 or mark == 8) and not m.owned[r.guid] then
                -- Existing marks are player decisions: adopt, pin, and never silently replace.
                if m.slots[mark] and m.slots[mark] ~= r.guid then
                    self:PauseMarking("Marking paused: another marker is using Skull or Cross."); return false
                end
                m.slots[mark], r.manual = r.guid, true
            end
        end
    end
    for icon, guid in pairs(m.slots) do
        local r = m.candidates[guid]
        if r and r.dead then m.slots[icon] = nil
        elseif r and r.unit and r.manual and GetTime() >= (r.manualVerifyAt or 0) and r.mark ~= icon then
            self:PauseMarking("Marking paused: a manual mark changed."); return false
        end
    end
    return true
end

function PTK:ActiveMarkBoss()
    local chosen
    for _, r in pairs(self.marking.candidates) do
        if not r.dead and r.entry and r.entry.boss then
            if not chosen or r.sequence < chosen.sequence then chosen = r end
        end
    end
    return chosen
end

function PTK:MarkScore(r, bossRecord)
    local e = r.entry
    if e and e.confidence then e = nil end
    local score = e and e.score or ((r.caster or (e and e.caster)) and 40 or 10)
    local context = bossRecord and bossRecord.entry
    if context and context.confidence then context = nil end
    if context and r.guid ~= bossRecord.guid then
        local specific = context.adds and (context.adds[r.npcID] or (r.name and context.adds[r.name:lower()]))
        if specific then score = specific
        elseif context.addsFirst and not (e and e.boss) then score = math.max(score, 120) end
    end
    return score
end

function PTK:AssignAutoMark(r, icon)
    local m = self.marking
    if not self:AutoMarkAllowed() or not m.armed then return false end
    -- Recheck eligibility and identity immediately before the mutation, including slot recycling.
    if not r or not r.unit or (r.entry and r.entry.neverAutoMark)
        or not self:IsAutoMarkEnemy(r.unit) or self:UnitIdentity(r.unit) ~= r.guid then return false end
    if r.guid ~= m.armed and not self:GroupEngaged(r.unit) then return false end
    local actual, readable = self:ReadRaidMark(r.unit)
    if not readable or (actual and actual ~= 7 and actual ~= 8) then return false end
    if not self:HasMarkingLead() then return false end
    self.markAttempt=true
    local ok = pcall(SetRaidTarget, r.unit, icon)
    self.markAttempt=nil
    if self.markingBlocked then return false end
    if not ok then self:PauseMarking("Marking paused: WoW blocked the marking action."); return false end
    if self.QueueMarkFeedback then self:QueueMarkFeedback(r.unit, icon, actual == 7 and icon == 8) end
    local previous = m.slots[icon]
    if previous and previous ~= r.guid then m.owned[previous] = nil end
    for slot, guid in pairs(m.slots) do if guid == r.guid then m.slots[slot] = nil end end
    m.slots[icon] = r.guid
    m.owned[r.guid] = {icon = icon, verifyAt = GetTime() + 0.75}
    r.mark = icon
    return true
end

function PTK:AutoMarkTick(seed)
    if not self.marking then self:ResetMarking() end
    self:UpdatePermissionAlert()
    if not self:AutoMarkAllowed() then return end
    local m = self.marking
    if m.paused then return end
    -- Retargeting during the initial delay must not strand a never-marked pull.
    if m.armed and not m.engaged and not next(m.owned) and not next(m.slots)
        and self:IsAutoMarkEnemy("target") then
        local current=self:UnitIdentity("target")
        if current and current~=m.armed then
            local scouting,scoutCount=m.scouted,m.scoutCount
            self:ResetMarking();m=self.marking;m.scouted,m.scoutCount=scouting,scoutCount
        end
    end
    if self:Call(UnitClassification,"target") == "worldboss" then m.worldBoss=true; return end
    -- Mouseover can remember a caster, but can never arm or seed a pull.
    local scoutGUID = self:UnitIdentity("mouseover")
    if scoutGUID and (m.scouted[scoutGUID] or (m.scoutCount or 0) < 256) then
        local cast = self:Call(UnitCastingInfo, "mouseover") or self:Call(UnitChannelInfo, "mouseover")
        if not m.scouted[scoutGUID] then m.scoutCount = (m.scoutCount or 0)+1 end
        m.scouted[scoutGUID] = {caster = type(cast) == "string" or (m.scouted[scoutGUID] and m.scouted[scoutGUID].caster)}
    end
    if not m.armed then
        if not self:IsAutoMarkEnemy("target") then return end
        local guid, npcID, name = self:UnitIdentity("target")
        if not guid then return end
        local entry = self:CatalogEntry(self:Instance(), npcID, name)
        if entry and entry.neverAutoMark then return end
        m.armed, m.initial, m.started = guid, guid, GetTime()
    end
    for _, r in pairs(m.candidates) do r.unit = nil end
    local foreignMark, hasCandidate, worldBoss = false, false, false
    for _, unit in ipairs(self:MarkUnitTokens()) do
        if not m.engaged and self:GroupEngaged(unit) then m.engaged=true; m.openingUntil=GetTime()+1 end
        if self:Call(UnitClassification, unit) == "worldboss" and self:GroupEngaged(unit) then worldBoss = true end
        local record = self:ObserveMarkUnit(unit, unit == "target" and self:UnitIdentity(unit) == m.armed)
        if record and not record.dead then hasCandidate = true end
        if self:Call(UnitExists, unit) == true then
            local mark = self:ReadRaidMark(unit)
            if (mark == 7 or mark == 8) and not record then
                foreignMark = true
            end
        end
    end
    if worldBoss then m.worldBoss = true; return end
    if foreignMark and hasCandidate then
        self:PauseMarking("Marking paused: Skull or Cross is already used outside this pull."); return
    end
    if not self:SyncMarkOwnership() then return end
    if not m.started or (not seed and GetTime() - m.started < 0.4) then return end
    local bossRecord, list = self:ActiveMarkBoss(), {}
    if bossRecord and bossRecord.entry.manualOrder then
        self:PauseMarking("Auto marking paused: this boss needs a manual phase kill order."); return
    end
    for _, r in pairs(m.candidates) do
        if r.unit and not r.dead and self:IsAutoMarkEnemy(r.unit) and not m.ignored[r.guid]
            and (not r.mark or r.mark == 7 or r.mark == 8) then list[#list + 1] = r end
    end
    table.sort(list, function(a, b)
        if a.guid == b.guid then return false end
        local x, y = self:MarkScore(a, bossRecord), self:MarkScore(b, bossRecord)
        if x ~= y then return x > y end
        if a.guid == m.initial then return true end
        if b.guid == m.initial then return false end
        return a.sequence < b.sequence
    end)
    local skull = m.slots[8] and m.candidates[m.slots[8]]
    -- Boss-specific add rules may replace an automatic boss Skull; manual Skull stays pinned.
    local best = list[1]
    local override = skull and not skull.manual and best and best.guid ~= skull.guid
        and self:MarkScore(best, bossRecord) > self:MarkScore(skull, bossRecord)
        and ((bossRecord and bossRecord.entry.preempt and skull.entry and skull.entry.boss)
            or (best.entry and best.entry.preemptBoss)
            or (m.openingUntil and GetTime() <= m.openingUntil))
    if not skull or override then
        local cross = m.slots[7] and m.candidates[m.slots[7]]
        local nextSkull = not override and cross and not cross.dead and cross or best
        -- Losing sight of Cross is not death: wait until it can be marked again.
        if nextSkull then self:AssignAutoMark(nextSkull, 8) end
    end
    local skullGUID = m.slots[8]
    local currentCross = m.slots[7] and m.candidates[m.slots[7]]
    if currentCross and not currentCross.manual then
        for _, r in ipairs(list) do
            if r.guid ~= skullGUID and self:MarkScore(r, bossRecord) > self:MarkScore(currentCross, bossRecord) then
                self:AssignAutoMark(r, 7); break
            end
        end
    end
    if not m.slots[7] and skullGUID then
        for _, r in ipairs(list) do
            if r.guid ~= skullGUID then self:AssignAutoMark(r, 7); break end
        end
    end
end

function PTK:NoteManualMark(unit, icon)
    if not self.marking then self:ResetMarking() end
    local r = self:ObserveMarkUnit(unit, true)
    if not r then return end
    local m = self.marking
    for slot, guid in pairs(m.slots) do if guid == r.guid then m.slots[slot] = nil end end
    m.owned[r.guid] = nil
    if icon == 0 then
        m.ignored[r.guid] = true
        self:PauseMarking("Auto marking paused after your manual clear.")
    else
        local previous = m.slots[icon]
        if previous then m.owned[previous] = nil end
        m.slots[icon], r.manual, r.manualVerifyAt = r.guid, true, GetTime() + 0.75
    end
end

function PTK:MarkUnitDied(guid)
    if not self:Readable(guid) or type(guid) ~= "string" or not self.marking then return end
    local r = self.marking.candidates[guid]
    if r then r.dead, r.unit = true, nil end
end

function PTK:SmartMarkPull()
    if self.assistedMarking then self:Print(select(2,self:MarkingStatus()));return end
    if not self.isPaladin or not self.db.enabled then return end
    if self:MarkPermissionIssue() then self:Print(self:MarkPermissionIssue()); return end
    if not self.db.autoMark then self:Print("Enable Auto mark pulled elites in settings first."); return end
    self:AutoMarkTick(true); self:Render()
end

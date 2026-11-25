local addonName, PTK = ...
BINDING_HEADER_PALADINTANKKIT = "Paladin TankKit"
BINDING_NAME_PALADINTANKKIT_SKULL = "Mark Skull (mouseover / target)"
BINDING_NAME_PALADINTANKKIT_CROSS = "Mark Cross (mouseover / target)"
BINDING_NAME_PALADINTANKKIT_CLEAR = "Clear mark (mouseover / target)"
BINDING_NAME_PALADINTANKKIT_PULL = "Mark Pull (smart elite priorities)"
function PaladinTankKit_Mark(icon) PTK:Mark(icon) end
function PaladinTankKit_Pull() PTK:SmartMarkPull() end

local events = CreateFrame("Frame")
PTK.events = events
local auraEvents = {UNIT_AURA=true, UNIT_SPELLCAST_SUCCEEDED=true, SPELLS_CHANGED=true,
    PLAYER_TALENT_UPDATE=true, PLAYER_ENTERING_WORLD=true, PLAYER_DEAD=true, PLAYER_ALIVE=true,
    PLAYER_UNGHOST=true, PLAYER_MOUNT_DISPLAY_CHANGED=true, UPDATE_SHAPESHIFT_FORM=true,
    UPDATE_SHAPESHIFT_FORMS=true}
events:RegisterEvent("ADDON_LOADED")

function PTK:Command(message)
    local cmd, argument = (message or ""):lower():match("^%s*(%S*)%s*(.-)%s*$")
    if not self.isPaladin then self:Print("This toolkit is for Paladins."); return end
    if cmd == "on" or cmd == "off" then
        self.db.enabled = cmd == "on"; self:ResetMarking(); self:RecoverCooldowns(); self:UpdatePermissionAlert()
    elseif cmd == "auto" then self.db.autoMark = not self.db.autoMark; self:ResetMarking()
    elseif cmd == "pull" then self:SmartMarkPull(); return
    elseif cmd == "resume" then
        if self.markingBlocked then self:Print(self.markingBlocked);return end
        self:ResetMarking(); self:Print("Auto marking reset; existing marks remain respected.")
    elseif cmd == "notes" then self:ShowBossNoteInChat(); return
    elseif cmd == "share" then self:ShareBossNote(); return
    elseif cmd == "unlock" or cmd == "lock" then self.db.locked = cmd == "lock"
    elseif cmd == "preview" then self:TogglePreview(); return
    elseif cmd == "version" then self:Print("Loaded version "..self.version);return
    elseif cmd == "restore" then self:RestoreTimers();return
    elseif cmd == "markstatus" then self:PrintMarkingStatus();return
    elseif cmd == "reset" then self.db.position = nil; self.db.scale = 1; self:Position()
    elseif cmd == "ground" then
        local seconds = tonumber(argument)
        if not seconds or seconds < 4 or seconds > 20 then self:Print("Use /ptk ground 4-20 (seconds)."); return end
        self.db.groundDuration = seconds; self:Print("Ground-effect estimate: " .. seconds .. " seconds.")
    elseif cmd == "help" then
        self:Print("/ptk settings | on | off | auto | pull | resume | notes | share")
        self:Print("/ptk unlock | lock | preview | restore | reset | ground 8")
        self:Print("Bind Skull, Cross and Clear in WoW's Key Bindings under Paladin TankKit.")
    else self:ToggleSettings() end
    self:SyncSettings(); self:Render()
end

events:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        if ... ~= addonName then return end
        events:UnregisterEvent("ADDON_LOADED")
        local _, class = UnitClass("player")
        PTK.isPaladin = class == "PALADIN"
        PTK:InitializeDB()
        SLASH_PALADINTANKKIT1, SLASH_PALADINTANKKIT2 = "/ptk", "/paladintankkit"
        SlashCmdList.PALADINTANKKIT = function(message) PTK:Command(message) end
        if not PTK.isPaladin then return end
        PTK:ResetMarking(); PTK:DiscoverSpells(); PTK:InstallCastObservers(); PTK:RecoverCooldowns(); PTK:RefreshAuras(); PTK:CreateUI()
        for _, name in ipairs({"PLAYER_ENTERING_WORLD", "UNIT_AURA", "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_SENT", "UNIT_SPELLCAST_START",
            "ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN",
            "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED",
            "SPELLS_CHANGED", "SPELL_UPDATE_COOLDOWN", "UPDATE_SHAPESHIFT_FORM", "UPDATE_SHAPESHIFT_FORMS", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
            "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST", "PLAYER_MOUNT_DISPLAY_CHANGED",
            "GROUP_ROSTER_UPDATE", "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT", "RAID_TARGET_UPDATE",
            "PLAYER_ROLES_ASSIGNED", "ROLE_CHANGED_INFORM",
            "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "UNIT_DIED"}) do events:RegisterEvent(name) end
        for _, name in ipairs({"UPDATE_INVENTORY_DURABILITY", "PLAYER_EQUIPMENT_CHANGED", "PLAYER_TALENT_UPDATE"}) do events:RegisterEvent(name) end
        local animationElapsed, auraElapsed, markingElapsed = 0, 0, 0
        events:SetScript("OnUpdate", function(_, elapsed)
            if not PTK.db.enabled then return end
            animationElapsed, auraElapsed = animationElapsed + elapsed, auraElapsed + elapsed
            markingElapsed = markingElapsed + elapsed
            if markingElapsed >= 0.35 then PTK:AutoMarkTick(); markingElapsed = 0 end
            if auraElapsed >= 0.2 then PTK:RefreshAuras(); auraElapsed = 0 end
            if animationElapsed >= 1/60 then PTK:Render(); animationElapsed = 0 end
        end)
        PTK:UpdatePermissionAlert(); PTK:Render()
        PTK:Print("Loaded "..PTK.version..". /ptk for settings; bind Skull in WoW's Key Bindings.")
        return
    end
    if not PTK.isPaladin or not PTK.db then return end
    if event=="ADDON_ACTION_BLOCKED" or event=="ADDON_ACTION_FORBIDDEN" then
        PTK:MarkActionBlocked(...);PTK:Render();return
    end
    if event == "UNIT_SPELLCAST_SENT" then
        local unit, _, guid, spellID = ...
        PTK:RememberCastRequest(unit,guid,spellID)
        return
    elseif event == "UNIT_SPELLCAST_START" then
        PTK:RememberCastRequest(...)
        return
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        PTK:SuccessfulCast(...)
    elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
        PTK:CancelCast(...)
        return
    elseif event == "UNIT_AURA" then
        local unit = ...
        if not PTK:Readable(unit) or unit ~= "player" then return end
    elseif event == "SPELLS_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
        if InCombatLockdown() then PTK.spellKnowledgeDirty=true;return end
        PTK:DiscoverSpells()
        for _, key in ipairs({"ground", "justice", "holy", "bulwark"}) do PTK[key .. "Tile"].icon:SetTexture(PTK.spells[key].icon) end
    elseif event == "PLAYER_REGEN_DISABLED" then
        PTK.preview = false; PTK:SyncSettings()
    elseif event == "PLAYER_REGEN_ENABLED" then
        PTK:ResetMarking()
        if PTK.spellKnowledgeDirty then PTK.spellKnowledgeDirty=nil;PTK:DiscoverSpells() end
        PTK:RecoverCooldowns();PTK:RefreshAuras()
    elseif event == "UNIT_DIED" then
        PTK:MarkUnitDied(...)
    elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_DEAD" then
        PTK.memory, PTK.ground, PTK.preview = {}, nil, false
        PTK:ClearUsedTimers()
        PTK:ResetMarking()
        PTK:DiscoverSpells(); PTK:RecoverCooldowns(); PTK:SyncSettings()
    end
    if event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then PTK:UpdatePermissionAlert() end
    if event=="GROUP_ROSTER_UPDATE" or event=="PLAYER_ROLES_ASSIGNED" or event=="ROLE_CHANGED_INFORM" then PTK:RefreshTankBuffs() end
    if event == "SPELL_UPDATE_COOLDOWN" or event == "SPELLS_CHANGED" then PTK:RecoverCooldowns() end
    -- Target/nameplate/marker changes must not invalidate the player's buff snapshot.
    if auraEvents[event] then PTK:RefreshAuras()
    elseif event == "UPDATE_INVENTORY_DURABILITY" or event == "PLAYER_EQUIPMENT_CHANGED" then PTK:RefreshShieldState() end
    PTK:RefreshUsedCooldowns(); PTK:Render()
end)

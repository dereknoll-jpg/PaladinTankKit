local _, PTK = ...

function PTK:CurrentBossNote()
    if not self.db.enabled or not self.db.bossNotes then return nil end
    if self.preview then return self.dungeons[36].byName["edwin vancleef"] end
    local instanceID, kind = self:Instance()
    if kind ~= "party" then return nil end
    for _, unit in ipairs({"target", "boss1", "boss2", "boss3", "boss4", "boss5"}) do
        if self:Call(UnitExists, unit) == true and self:Call(UnitIsDeadOrGhost, unit) == false then
            local _, npcID, name = self:UnitIdentity(unit)
            local e = self:CatalogEntry(instanceID, npcID, name)
            if e and e.boss and e.note then return e end
        end
    end
    local r = self.marking and self:ActiveMarkBoss()
    if r and r.entry.note and r.unit then return r.entry end
end

function PTK:BossNoteMessage(note)
    return "[TankKit] " .. note.name .. ": " .. note.note
end

function PTK:ShowBossNoteInChat()
    local note = self:CurrentBossNote()
    if note then self:Print(note.name .. ": " .. note.note)
    else self:Print("Target a supported dungeon boss to see its notes.") end
end

function PTK:ShareBossNote()
    if self.preview then self:Print("Preview notes stay private."); return end
    local note = self:CurrentBossNote()
    if not note then self:Print("No supported boss selected."); return end
    if not IsInGroup() or IsInRaid() then self:Print("Join a dungeon party to share boss notes."); return end
    if self.lastNoteShare and GetTime() - self.lastNoteShare < 15 then
        self:Print("Please wait before sharing another boss note."); return
    end
    local message = self:BossNoteMessage(note)
    if #message > 255 then self:Print("That boss note is too long to share."); return end
    local inInstanceGroup = self:Call(IsInGroup, LE_PARTY_CATEGORY_INSTANCE) == true
    local channel = inInstanceGroup and "INSTANCE_CHAT" or "PARTY"
    local ok = type(SendChatMessage) == "function" and pcall(SendChatMessage, message, channel)
    if ok then self.lastNoteShare = GetTime()
    else self:Print("WoW could not send that note.") end
end

function PTK:CreateNotesUI()
    local button = self:QuietButton(self.frame,"Notes",60,22,function()
        self.notesOpen = not self.notesOpen; self:RenderNotes()
    end)
    self.notesButton = button
    button:SetPoint("TOPLEFT", 456, -5)
    local card = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
    self.notesCard = card
    card:SetSize(720, 28); card:SetPoint("TOP", self.frame, "BOTTOM", 0, -8)
    card:SetClampedToScreen(true)
    card:EnableMouse(true)
    card:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    card:SetBackdropColor(0.035, 0.04, 0.05, 0.97); card:SetBackdropBorderColor(0.55, 0.45, 0.26, 0.35)
    self.noteBody = card:CreateFontString(nil, "OVERLAY")
    self.noteBody:SetFont(STANDARD_TEXT_FONT, 11, "")
    self.noteBody:SetPoint("LEFT", 10, 0); self.noteBody:SetWidth(591)
    self.noteBody:SetJustifyH("LEFT"); self.noteBody:SetWordWrap(false); self.noteBody:SetMaxLines(1)
    self.noteBody:SetTextColor(0.9, 0.85, 0.73)
    card:SetScript("OnEnter", function()
        local note = self:CurrentBossNote()
        if not note then return end
        GameTooltip:SetOwner(card, "ANCHOR_TOP")
        GameTooltip:SetText(note.name, 0.94, 0.78, 0.47)
        GameTooltip:AddLine(note.note:gsub("{skull}", "Skull"):gsub("{cross}", "Cross"), 0.87, 0.87, 0.86, true)
        local confidence = note.confidence == "classic-reference" and "Classic reference; verify in Forever."
            or (note.confidence == "limited" and "Mechanics still need confirmation; manual order." or "Guide recommendation; not tested live.")
        GameTooltip:AddLine(confidence, 0.55, 0.58, 0.61, true)
        GameTooltip:Show()
    end)
    card:SetScript("OnLeave", function() GameTooltip:Hide() end)
    local share = self:QuietButton(card,"Share",72,20,function() self:ShareBossNote() end)
    share:SetPoint("RIGHT", -29, 0); self.noteShareButton=share
    local close = self:QuietButton(card,"x",20,20,function() self.notesOpen = false; self:RenderNotes() end)
    close:SetPoint("RIGHT", -5, 0)
    button:Hide(); card:Hide()
end

function PTK:RenderNotes()
    local note = self:CurrentBossNote()
    if note ~= self.displayedNote then
        self.notesOpen = false; self.displayedNote = note
        self.noteProgress = 0; self.notesCard:Hide()
    end
    self.notesButton:SetShown(note ~= nil)
    self:AnimateNotes(note ~= nil and self.notesOpen, GetTime())
    self.noteShareButton.label:SetText(self.preview and "Preview" or "Share")
    if note then
        self.noteBody:SetText((self.preview and "PREVIEW  |  " or "")..note.name .. "  |  " .. (note.note:gsub("{skull}", "Skull"):gsub("{cross}", "Cross")))
    end
end

local _, PTK = ...
local gold = {0.94, 0.78, 0.47}

local function text(parent, size, r, g, b)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont(STANDARD_TEXT_FONT, size, "OUTLINE")
    label:SetTextColor(r or 0.88, g or 0.88, b or 0.87)
    return label
end

local function tooltip(frame, title, body)
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(type(title) == "function" and title() or title, gold[1], gold[2], gold[3])
        local detail=type(body)=="function" and body() or body
        if frame.timerOption then detail=detail.."\n\nMiddle-click to hide. Restore in /ptk > Ability timers or Protection; /ptk restore enables all." end
        GameTooltip:AddLine(detail, 0.85, 0.85, 0.85, true)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function tile(parent, texture, size)
    local frame = CreateFrame("Button", nil, parent)
    frame:SetSize(size, size)
    frame.bg = frame:CreateTexture(nil, "BACKGROUND", nil, 0)
    frame.bg:SetAllPoints(); frame.bg:SetTexture("Interface\\AddOns\\PaladinTankKit\\Media\\IconFace")
    frame.bg:SetVertexColor(0.025, 0.025, 0.03, 0.96)
    frame.icon = frame:CreateTexture(nil, "ARTWORK", nil, 0)
    frame.icon:SetPoint("TOPLEFT", 1, -1); frame.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    frame.icon:SetTexture(texture); frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    -- Soft corners and fine numerals match the study without replacing spell art.
    if frame.CreateMaskTexture and frame.icon.AddMaskTexture then
        frame.iconMask = frame:CreateMaskTexture()
        frame.iconMask:SetTexture("Interface\\AddOns\\PaladinTankKit\\Media\\IconFace", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        frame.iconMask:SetAllPoints(frame.icon); frame.icon:AddMaskTexture(frame.iconMask)
    end
    frame.count = frame:CreateFontString(nil, "OVERLAY", nil)
    frame.count:SetFont("Fonts\\ARIALN.TTF", 10, "")
    frame.count:SetShadowColor(0, 0, 0, 0.95); frame.count:SetShadowOffset(0, -1)
    frame.count:SetTextColor(0.88, 0.84, 0.75)
    frame.count:SetPoint("TOP", frame, "BOTTOM", 0, -2)
    return frame
end

function PTK:AttachTimerHiding(frame,option)
    frame.timerOption=option
    frame:RegisterForClicks("MiddleButtonUp")
    frame:SetScript("OnClick",function(_,button)
        if button~="MiddleButton" then return end
        self.db[option]=false
        if frame.motion then frame.motion.alpha=0 end
        frame:Hide()
        if frame.pin then frame.pin:Hide() end
        self:SyncSettings();self:Render()
        self:Print("Item hidden. Restore in /ptk > Ability timers or Protection; /ptk restore enables all.")
    end)
end

function PTK:RestoreTimers()
    for _,key in ipairs(self.timerKeys) do self.db["track"..key:sub(1,1):upper()..key:sub(2)]=true end
    self.db.showForbearance=true
    for _,option in ipairs(self.protectionOptions) do self.db[option]=true end
    self:SyncSettings();self:Render()
    self:Print("All timers and protection reminders restored. Inactive effects remain hidden.")
end

function PTK:Position()
    local f, p = self.frame, self.db.position
    f:ClearAllPoints()
    if type(p) == "table" and self:Number(p.x) and self:Number(p.y) then
        -- Center offsets survive UI resolution changes; clamping keeps the anchor reachable.
        f:SetPoint("CENTER", UIParent, "CENTER", p.x, p.y)
    else f:SetPoint("CENTER", UIParent, "CENTER", 0, -155) end
    f:SetScale(self.db.scale)
end

function PTK:CreateUI()
    local f = CreateFrame("Frame", "PaladinTankKitFrame", UIParent)
    self.frame = f
    f:SetSize(self.layout.width, self.layout.height); f:SetClampedToScreen(true); f:SetMovable(true)
    f:SetFrameStrata("MEDIUM"); f:EnableMouse(false)
    local anchor = CreateFrame("Button", nil, f)
    self.anchor = anchor
    anchor:SetAllPoints(); anchor:RegisterForDrag("LeftButton")
    anchor:SetScript("OnDragStart", function() if not self.db.locked then f:StartMoving() end end)
    anchor:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        local x, y = f:GetCenter()
        local px, py = UIParent:GetCenter()
        if x and y and px and py then self.db.position = {x = x - px, y = y - py} end
    end)
    anchor:SetScript("OnClick", function(_, button) if button == "RightButton" then self:ToggleSettings() end end)
    anchor:RegisterForClicks("RightButtonUp")
    anchor:SetFrameLevel(f:GetFrameLevel() + 1)
    self.anchorLabel = text(anchor, 10, gold[1], gold[2], gold[3])
    self.anchorLabel:SetPoint("TOP", 0, 26); self.anchorLabel:SetText("PALADIN TANKKIT  /  DRAG TO MOVE")
    self.anchorBG = anchor:CreateTexture(nil, "BACKGROUND")
    self.anchorBG:SetAllPoints(); self.anchorBG:SetColorTexture(0.06, 0.065, 0.075, 0.82)
    local skull = CreateFrame("Button", nil, f)
    self.skull = skull
    skull:SetSize(24, 24); skull:SetPoint("TOPLEFT", 0, -5)
    skull:SetFrameLevel(f:GetFrameLevel() + 3)
    skull.icon = skull:CreateTexture(nil, "ARTWORK"); skull.icon:SetAllPoints()
    skull.icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
    skull:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    skull:SetScript("OnClick", function(_, button)
        if button == "RightButton" then self:ToggleSettings()
        elseif IsControlKeyDown() then self:Mark(0)
        elseif IsShiftKeyDown() then self:Mark(7)
        else self:Mark(8) end
    end)
    tooltip(skull,"Paladin TankKit",function()
        local status,reason=self:MarkingStatus()
        return status..": "..reason.."\n\nElites only. Click: pin Skull\nShift-click: pin Cross\nCtrl-click: clear/pause\nRight-click: settings\nMouseover scouts; only a selected elite starts auto marks.\nTank role is separate from leader/assistant permission.\n/ptk markstatus prints the current blocker."
    end)
    self.markStatus = text(f, 8, gold[1], gold[2], gold[3])
    self.markStatus:SetPoint("TOPLEFT", 0, -32)
    self:CreateMarkEffects()
    local line = f:CreateTexture(nil, "BACKGROUND")
    line:SetPoint("TOPLEFT", self.layout.start, self.layout.y); line:SetSize(self.layout.length, 1)
    line:SetTexture("Interface\\AddOns\\PaladinTankKit\\Media\\Rail")
    line:SetVertexColor(gold[1], gold[2], gold[3], 0.25)
    for _, key in ipairs(self.timerKeys) do
        local icon = tile(f, self.spells[key].icon, 20)
        icon:SetFrameLevel(f:GetFrameLevel() + 2)
        local defensiveTip = key == "holy" and "Holy Shield's actual buff duration.\nAppears after use or when the active buff is readable.\nClears when Blizzard reports the buff ended.\n~ means a cast estimate or remembered expiry. Timers without a deadline stay hidden."
            or (key == "bulwark" and "Templar's Bulwark cooldown: only while learned and after your cast.\nUses Blizzard's cooldown, including readable talent reductions.\nReady briefly lights up, then clears.\n~ means a cast estimate or remembered expiry. Timers without a deadline stay hidden.")
        tooltip(icon, key == "seal" and function() return self.activeSeal and self.activeSeal.name or "Last cast Seal" end or self.spells[key].name, key=="bulwark" and function()
            return defensiveTip..(self.db.forbearanceAware and self:ForbearanceActive() and ("\n\n"..self:ForbearanceDetails()) or "")
        end or defensiveTip or (key == "ground"
            and "Moves right to left as the ground effect expires.\n~ marks an estimated duration based on your successful cast.\nReady refers to cooldown only; it does not promise enough mana.\nReadable player ground-effect timing takes priority."
            or (key == "justice" and "Hammer of Justice cooldown, shown only after your cast.\n~ marks a cast estimate or remembered timing while hidden.\nReadiness briefly lights up, then the icon clears."
            or "Tracks your active Seal using Blizzard's buff expiration.\nJudgement and hits do not restart or clear this timer.\n~ marks a cast estimate or remembered expiry. Real player buff timers take priority.")))
        self[key .. "Tile"] = icon
        self:AttachTimerEffects(icon)
        self:AttachTimerHiding(icon,"track"..key:sub(1,1):upper()..key:sub(2))
    end
    self.nowLabel = text(f, 8, 0.48, 0.48, 0.48)
    self.nowLabel:SetPoint("TOPLEFT", self.layout.start-3, -31); self.nowLabel:SetText("0")
    self.horizonLabel = text(f, 8, 0.48, 0.48, 0.48)
    self.horizonLabel:SetPoint("TOPLEFT", self.layout.start+self.layout.length-10, -31)
    self.warning = text(f, 10, 1, 0.64, 0.40)
    self.warning:SetPoint("BOTTOM", f, "TOP", 0, 4); self.warning:SetWidth(620)
    self.warning:SetWordWrap(false); self.warning:SetMaxLines(1)
    self.warningGlow=f:CreateTexture(nil,"BACKGROUND")
    self.warningGlow:SetTexture("Interface\\AddOns\\PaladinTankKit\\Media\\Halo")
    self.warningGlow:SetBlendMode("ADD");self.warningGlow:SetVertexColor(1,.28,.05)
    self.warningGlow:SetSize(360,32);self.warningGlow:SetPoint("CENTER",self.warning,"CENTER");self.warningGlow:SetAlpha(0)
    self.forbearanceTile = tile(f, self.spells.forbearance.icon, 17)
    self.forbearanceTile:SetPoint("TOPLEFT", 35, -8)
    tooltip(self.forbearanceTile, self.spells.forbearance.name,
        "Forbearance is active. Certain protective abilities are unavailable.\n~ marks a remembered estimate.")
    self:AttachTimerHiding(self.forbearanceTile,"showForbearance")
    self:CreateProtectionUI(tile,tooltip,text)
    self:Position()
    self:CreateNotesUI()
end

function PTK:RenderLane(key, aura, now, state)
    if state=="ready" then
        local locked=key=="bulwark" and self.db.forbearanceAware and self:ForbearanceActive(now)
        self:PresentTimer(key,"ready",nil,now,locked and "Locked" or "Ready");return
    end
    if state=="hidden" or not aura or not aura.active or not aura.expires or aura.expires<=now then
        self:PresentTimer(key,"hidden",nil,now,"");return
    end
    self:PresentTimer(key,state=="cooldown" and "cooldown" or "active",aura,now,
        self:FormatTime(aura.expires-now,aura.estimated))
end
function PTK:Render()
    if not self.frame then return end
    local enabled = self.isPaladin and self.db.enabled
    self.frame:SetShown(enabled)
    if not enabled then self.buffAlertEpisodes=nil;return end
    local now = GetTime()
    if not self.lastCooldownRefresh or now-self.lastCooldownRefresh >= 0.1 then
        self:RefreshUsedCooldowns(now); self.lastCooldownRefresh = now
    end
    local seal = self.auras and self.auras.seal
    local ground, fb = self.ground, self.auras and self.auras.forbearance
    local justice, justiceState = self:UsedTimerView("justice",now)
    local holy = self.auras and self.auras.holy
    local bulwark, bulwarkState = self:UsedTimerView("bulwark",now)
    local groundCooldown, groundState = self:UsedTimerView("ground",now)
    local warning = self:Warnings()
    local markingIssue = self:MarkPermissionIssue() or self.markingBlocked or (self.marking and self.marking.paused)
    if self.markingBlocked then markingIssue="WoW blocked addon marking; use native target-marker bindings." end
    if markingIssue then warning = warning ~= "" and (warning .. " / " .. markingIssue) or markingIssue end
    if ground and ground.expires <= now then ground = nil; self.ground = nil end
    if self.preview then
        local elapsed = (now - self.previewStart) % 30
        seal = {active = true, expires = now + 30 - elapsed}
        local groundPhase = elapsed % 10
        ground = groundPhase < 8 and {active = true, expires = now + 8 - groundPhase, estimated = true} or nil
        groundCooldown, groundState = nil, groundPhase >= 8 and groundPhase < 8.8 and "ready" or nil
        justice = elapsed < 20 and {active=true, expires=now+20-elapsed, cooldown=true} or nil
        justiceState = justice and "cooldown" or nil
        holy = elapsed < 10 and {active=true, expires=now+10-elapsed} or nil
        bulwark, bulwarkState = {active=true, expires=now+60-elapsed, cooldown=true}, "cooldown"
        fb = {active = true, expires = now + 21}
        warning = "PREVIEW  /  right-click Skull for settings"
        local cycle = math.floor((now-self.previewStart)/10)
        if self.lastPreviewCycle ~= cycle then
            self.lastPreviewCycle = cycle; self.markFlash = {at = now, icon = 8, promotion = true}
        end
    end
    local suppressed = UnitIsDeadOrGhost("player") or IsMounted()
    if suppressed and not self.preview then seal, ground, fb, warning, justice = nil, nil, nil, "", nil end
    local active = self.preview or not self.db.locked or InCombatLockdown() or self:CurrentBossNote()
        or (seal and seal.active) or ground or justice or (holy and holy.active) or bulwark or warning ~= "" or (fb and fb.active)
        or next(self.protection or {})~=nil or self.personalCleanse~=nil
    self:HUDOpacity(active and 1 or (self.db.idleFade and 0.25 or 1), now)
    self.anchor:EnableMouse(not self.db.locked)
    self.anchorLabel:SetShown(not self.db.locked)
    self.anchorBG:SetShown(not self.db.locked)
    self.horizonLabel:SetText(self.db.horizon .. "s")
    if suppressed and not self.preview then
        for _, key in ipairs(self.timerKeys) do self[key.."Tile"]:Hide(); self[key.."Tile"].pin:Hide() end
    else
        if not ground then ground = groundCooldown end
        local sealState = seal and seal.active and "active" or (seal and seal.uncertain and self.used.seal and "unknown" or "hidden")
        local actualGroundState = ground and (ground.cooldown and "cooldown" or "active") or groundState or "hidden"
        local holyState = holy and holy.active and "active" or (holy and holy.uncertain and self.used.holy and "unknown" or "hidden")
        local views={seal={aura=seal,state=sealState}, ground={aura=ground,state=actualGroundState},
            justice={aura=justice,state=justiceState or "hidden"}, holy={aura=holy,state=holyState},
            bulwark={aura=bulwark,state=bulwarkState or "hidden"}}
        for _,key in ipairs(self.timerKeys) do
            local option="track"..key:sub(1,1):upper()..key:sub(2)
            local view=views[key]
            if not self.db[option] or view.state=="unknown"
                or (view.state~="ready" and view.aura and (not view.aura.expires or view.aura.expires<=now)) then
                views[key]={state="hidden"}
            end
        end
        self:BuildTimerLayout(views,now)
        for _,key in ipairs(self.timerKeys) do
            local view=views[key]
            self:RenderLane(key,view.aura,now,view.state=="active" and nil or view.state)
        end
    end
    self.warning:SetText(warning)
    self:RenderTankBuffAlerts(now)
    self:RenderProtection(now,fb,suppressed and not self.preview)
    local markingStatus=self:MarkingStatus()
    self.markStatus:SetText(markingStatus)
    self:RenderNotes()
    self:TickMarkEffects(now)
end

function PTK:SetScale(value)
    self.db.scale = math.max(0.75, math.min(1.5, value))
    self.frame:SetScale(self.db.scale); self:SyncSettings()
end

function PTK:TogglePreview()
    if InCombatLockdown() then self:Print("Preview is available out of combat."); return end
    if not self.db.enabled then self:Print("Turn on Tank mode to preview the layout."); return end
    self.preview = not self.preview; self.previewStart = GetTime()
    self.lastPreviewCycle = nil
    self:SyncSettings(); self:Render()
end

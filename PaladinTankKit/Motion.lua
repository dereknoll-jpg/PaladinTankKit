local _, P = ...
P.layout = {width = 520, height = 42, start = 76, length = 362, y = -16}
local media = "Interface\\AddOns\\PaladinTankKit\\Media\\"
local function clamp(x) return math.max(0, math.min(1, x)) end
local function ease(x) x = clamp(x); return 1 - (1-x)^3 end
local function approach(current, target, dt, speed)
    if math.abs(current - target) < 0.002 then return target end
    return current + (target-current) * (1-math.exp(-speed*dt))
end

function P:AttachTimerEffects(tile)
    tile.motion = {alpha = 0, state = "hidden", entered = GetTime()}
    tile.halo = tile:CreateTexture(nil, "BACKGROUND", nil, -8)
    tile.halo:SetTexture(media .. "IconGlow"); tile.halo:SetBlendMode("ADD")
    tile.halo:SetPoint("CENTER"); tile.halo:SetSize(44, 44)
    tile.trail = tile:CreateTexture(nil, "BACKGROUND", nil, -7)
    tile.trail:SetTexture(media .. "Trail"); tile.trail:SetBlendMode("ADD")
    tile.trail:SetPoint("LEFT", tile, "RIGHT", -4, 0); tile.trail:SetSize(52, 8)
    tile.shade = tile:CreateTexture(nil, "ARTWORK", nil, 1)
    tile.shade:SetAllPoints(tile.icon); tile.shade:SetTexture(media .. "IconShade")
    tile.shade:SetVertexColor(0, 0, 0)
    tile.wash = tile:CreateTexture(nil, "ARTWORK", nil, 2)
    tile.wash:SetAllPoints(tile.icon); tile.wash:SetTexture(media .. "IconFace")
    tile.faceLight = tile:CreateTexture(nil, "ARTWORK", nil, 3)
    tile.faceLight:SetAllPoints(tile.icon); tile.faceLight:SetTexture(media .. "IconLight")
    tile.faceLight:SetBlendMode("ADD")
    tile.sweep = tile:CreateTexture(nil, "ARTWORK", nil, 4)
    tile.sweep:SetTexture(media .. "Sweep"); tile.sweep:SetBlendMode("ADD")
    tile.sweep:SetPoint("CENTER"); tile.sweep:SetSize(20, 20)
    if tile.iconMask then tile.sweep:AddMaskTexture(tile.iconMask) end
    tile.rim = tile:CreateTexture(nil, "ARTWORK", nil, 5)
    tile.rim:SetAllPoints(); tile.rim:SetTexture(media .. "IconRim")
    tile.pin = self.frame:CreateTexture(nil, "OVERLAY")
    tile.pin:SetColorTexture(1, 1, 1, 0.35); tile.pin:SetSize(2, 4)
end

function P:TimerX(aura, now)
    local l = self.layout
    if not aura or not aura.active then return l.start end
    return l.start + l.length * (aura.expires and aura.expires > 0 and self:Fraction(aura.expires, now) or 1)
end

function P:BuildTimerLayout(views, now)
    local items = {}
    for i, key in ipairs(self.timerKeys) do
        local v = views[key]
        if v and v.state ~= "hidden" then items[#items+1] = {key=key, x=self:TimerX(v.aura,now), order=i} end
    end
    table.sort(items, function(a,b) if a.x == b.x then return a.order < b.order end; return a.x < b.x end)
    local right = self.layout.start+self.layout.length
    for i=#items,1,-1 do items[i].position = math.min(items[i].x, right); right = items[i].position-28 end
    local left = self.layout.start
    self.timerPositions = {}
    for _, item in ipairs(items) do
        item.position = math.max(left,item.position); left = item.position+28
        self.timerPositions[item.key] = item.position
    end
end

function P:TimerDisplayX(key, aura, now)
    return self.timerPositions and self.timerPositions[key] or self:TimerX(aura,now)
end

function P:PresentTimer(key, state, aura, now, label)
    local tile, l = self[key .. "Tile"], self.layout
    local m = tile.motion
    local dt = math.max(0, math.min(0.1, now - (m.at or now)))
    local changed = state ~= m.state
    local newExpiration = aura and aura.expires
    local refresh = state == "active" and m.state == "active" and newExpiration and m.expiration
        and newExpiration > m.expiration + 1
    if changed or refresh then
        m.entered = now
        if refresh and m.x then m.fromX, m.refreshAt = m.x, now end
    end
    m.state, m.expiration, m.at = state, newExpiration, now
    local shown = state ~= "hidden"
    local target = shown and 1 or 0
    local animated = self.db.effects
    if animated then m.alpha = approach(m.alpha, target, dt, self.db.reducedMotion and 36 or 20)
    else m.alpha = target end
    if shown then tile:Show() end
    if not shown and m.alpha <= 0.002 then tile:Hide(); tile.pin:Hide() end
    local x = shown and self:TimerDisplayX(key, aura, now) or m.x or l.start
    local age = now-m.entered
    if m.refreshAt and animated and not self.db.reducedMotion then
        local blend = ease((now-m.refreshAt)/0.28)
        x = m.fromX + (x-m.fromX)*blend
        if blend >= 1 then m.refreshAt = nil end
    end
    m.x = x
    tile:ClearAllPoints(); tile:SetPoint("CENTER", self.frame, "TOPLEFT", x, l.y)
    tile.count:SetText(label or "")
    local remaining = aura and aura.expires and aura.expires-now
    local r, g, b = 0.96, 0.79, 0.45
    if key == "ground" then r, g, b = 0.96, 0.62, 0.35 end
    if key == "justice" then r, g, b = 0.83, 0.77, 1 end
    if key == "holy" then r, g, b = 0.82, 0.90, 0.66 end
    if state == "ready" then r, g, b = 0.79, 0.9, 0.65 end
    local locked=key=="bulwark" and self.db.forbearanceAware and self:ForbearanceActive(now)
    if locked then r,g,b=1,.67,.35 end
    local warning = state == "active" and remaining and remaining > 0 and remaining <= 5
    local pulse = 0
    if animated and not self.db.reducedMotion then
        if warning then pulse = (math.sin(age*4.2)+1)*0.5
        elseif state == "ready" and not locked and age < 1.25 then pulse = math.sin(clamp(age/1.25)*math.pi) end
    end
    local reveal = animated and not self.db.reducedMotion and math.max(0, 1-age/0.48) or 0
    tile.halo:SetVertexColor(r, g, b); tile.trail:SetVertexColor(r, g, b)
    tile.halo:SetAlpha(animated and shown and state ~= "unknown" and (state == "cooldown" and 0.09 or (0.16 + pulse*0.10 + reveal*0.10)) or 0)
    local trailSpace = math.max(0, l.start+l.length-x-8)
    tile.trail:SetWidth(math.max(1, math.min(52, trailSpace)))
    tile.trail:SetAlpha(animated and state == "active" and trailSpace > 0 and 0.28 or 0)
    tile.sweep:ClearAllPoints(); tile.sweep:SetPoint("CENTER", tile, "CENTER", tile.iconMask and (-10+ease(age/0.48)*20) or 0, 0)
    tile.sweep:SetAlpha(animated and state ~= "unknown" and reveal > 0 and math.sin(clamp(age/0.48)*math.pi)*0.5 or 0)
    local lit = animated and shown and state ~= "unknown"
    tile.rim:SetVertexColor(r, g, b); tile.rim:SetAlpha(state == "unknown" and 0.25 or (0.65 + pulse*0.12))
    tile.shade:SetAlpha(0.44)
    tile.wash:SetVertexColor(r, g, b); tile.wash:SetAlpha(lit and state ~= "cooldown" and 0.12 or 0)
    tile.faceLight:SetVertexColor(r, g, b); tile.faceLight:SetAlpha(lit and (state == "cooldown" and 0.055 or (0.16+reveal*0.06+pulse*0.025)) or 0)
    -- Timer state belongs in the countdown, never in washed-out spell artwork.
    tile.icon:SetDesaturated(false)
    tile.icon:SetAlpha(1)
    tile.count:SetTextColor(warning and 1 or 0.88, warning and 0.6 or 0.86, warning and 0.35 or 0.8)
    local settle = animated and not self.db.reducedMotion and (1 + reveal*0.07 + pulse*0.015) or 1
    tile:SetScale(settle); tile:SetAlpha(m.alpha)
    tile.pin:ClearAllPoints(); tile.pin:SetPoint("CENTER", self.frame, "TOPLEFT", self:TimerX(aura, now), l.y)
    tile.pin:SetShown(state == "active"); tile.pin:SetVertexColor(r, g, b)
end

function P:CreateMarkEffects()
    self.markGlow = self.skull:CreateTexture(nil, "BACKGROUND")
    self.markGlow:SetTexture(media .. "Halo"); self.markGlow:SetBlendMode("ADD")
    self.markGlow:SetPoint("CENTER"); self.markGlow:SetSize(50, 50); self.markGlow:SetAlpha(0)
    self.markGhost = self.skull:CreateTexture(nil, "OVERLAY")
    self.markGhost:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_7")
    self.markGhost:SetSize(12, 12); self.markGhost:SetAlpha(0)
end

function P:QueueMarkFeedback(unit, icon, promotion)
    if icon == 0 then return end
    local guid = self:UnitIdentity(unit)
    if guid then self.markFeedback = {unit = unit, guid = guid, icon = icon,
        promotion = promotion, untilTime = GetTime()+1.5} end
end

function P:TickMarkEffects(now)
    local pending = self.markFeedback
    if pending and now >= (pending.checkAt or 0) then
        pending.checkAt = now+0.08
        if self:UnitIdentity(pending.unit) == pending.guid and self:Call(GetRaidTargetIndex, pending.unit) == pending.icon then
            self.markFlash = {at = now, icon = pending.icon, promotion = pending.promotion}; self.markFeedback = nil
        elseif now > pending.untilTime then self.markFeedback = nil end
    end
    local flash = self.markFlash
    local t = flash and (now-flash.at)/0.5 or 1
    if self.assistedMarking then
        local glow=self.markAdvice and self.db.effects and .13 or 0
        if glow>0 and not self.db.reducedMotion then glow=glow+.035*(1+math.sin(now*2.5)) end
        self.markGlow:SetVertexColor(1,.78,.42)
        self.markGlow:SetAlpha(glow);self.markGhost:SetAlpha(0)
        return
    end
    if not self.db.effects or self.db.reducedMotion or t >= 1 then
        self.markGlow:SetAlpha(0); self.markGhost:SetAlpha(0); return
    end
    self.markGlow:SetVertexColor(1, 0.78, 0.42)
    self.markGlow:SetAlpha(math.sin(t*math.pi)*0.45)
    self.markGhost:ClearAllPoints()
    self.markGhost:SetPoint("CENTER", self.skull, "CENTER", 24*(1-ease(t)), 3*math.sin(t*math.pi))
    self.markGhost:SetAlpha(flash.promotion and (1-t)*0.85 or 0)
end

function P:HUDOpacity(target, now)
    local dt = math.max(0, math.min(0.25, now-(self.lastHUDTime or now)))
    self.lastHUDTime = now
    self.hudAlpha = self.db.effects and approach(self.hudAlpha or target, target, dt, 14) or target
    self.frame:SetAlpha(self.hudAlpha)
end

function P:AnimateNotes(show, now)
    local target = show and 1 or 0
    local dt = math.max(0, math.min(0.1, now-(self.noteMotionAt or now)))
    self.noteMotionAt = now
    self.noteProgress = self.db.effects and not self.db.reducedMotion
        and approach(self.noteProgress or 0, target, dt, 23) or target
    if show then self.notesCard:Show() end
    self.notesCard:SetAlpha(self.noteProgress)
    self.notesCard:ClearAllPoints()
    self.notesCard:SetPoint("TOP", self.frame, "BOTTOM", 0, -8 + (1-self.noteProgress)*4)
    if not show and self.noteProgress <= 0.002 then self.notesCard:Hide() end
end

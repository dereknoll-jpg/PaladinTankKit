local _,P=...

function P:CreateProtectionUI(makeTile,tooltip,makeText)
    self.statusTiles={}
    local specs={}
    for _,def in ipairs(self.protectionDefs) do specs[#specs+1]=def end
    specs[#specs+1]={key="forbearance",option="showForbearance",short="Locked",name="Forbearance",
        icon=self.spells.forbearance.icon}
    specs[#specs+1]={key="cleanse",option="warnCleanse",short="Cleanse",name="Personal cleanse",
        icon="Interface\\Icons\\Spell_Holy_Purify"}
    self.statusSpecs=specs
    for i,def in ipairs(specs) do
        local tile=def.key=="forbearance" and self.forbearanceTile or makeTile(self.frame,def.texture or def.icon,18)
        tile:SetFrameLevel(self.frame:GetFrameLevel()+3)
        tile:ClearAllPoints();tile:SetPoint("CENTER",self.frame,"TOPLEFT",self.layout.start+20+(i-1)*52,30)
        self:AttachTimerEffects(tile)
        self:AttachTimerHiding(tile,def.option)
        tile.caption=makeText(tile,8,.72,.72,.67)
        tile.caption:SetPoint("TOP",tile,"BOTTOM",0,-3);tile.caption:SetText(def.short)
        tile.count:ClearAllPoints();tile.count:SetPoint("BOTTOMRIGHT",tile,"TOPRIGHT",4,-3)
        tooltip(tile,def.name,function()
            if def.key=="forbearance" then return self:ForbearanceDetails() end
            if def.key=="cleanse" then
                local effect=self.personalCleanse
                return effect and (effect.kind..": "..effect.name.."\nRemovable with your learned cleanse spell.\nReminder only; use your normal spell binding.")
                    or "A personal reminder for a readable debuff you can remove."
            end
            local effect=self.protection and self.protection[def.key]
            local detail=def.key=="iron" and "Holy Strike's Iron Creed protection is active."
                or (def.key=="block" and "Shieldsworn's spell-block window is active." or "Templar's Bulwark absorb shield is active.")
            if effect and effect.amount then detail=detail.."\nRemaining absorb: "..math.floor(effect.amount) end
            return detail.."\nUses the observed player buff, including early removal.\n~ means the last observed deadline is temporarily remembered."
        end)
        tile:Hide();tile.pin:Hide()
        self.statusTiles[def.key]=tile
    end
    self.bulwarkTile.lock=makeText(self.bulwarkTile,10,1,.65,.28)
    self.bulwarkTile.lock:SetPoint("TOPRIGHT",4,4);self.bulwarkTile.lock:SetText("!");self.bulwarkTile.lock:Hide()
end

function P:RenderProtection(now,fb,suppressed)
    local any=false
    for _,def in ipairs(self.statusSpecs) do
        local tile=self.statusTiles[def.key]
        local aura=self.protection and self.protection[def.key]
        if def.key=="forbearance" then aura=fb end
        if def.key=="cleanse" then aura=self.personalCleanse and {active=true} or nil end
        if self.preview then
            local elapsed=(now-self.previewStart)%12
            aura=elapsed<8 and {active=true,expires=now+8-elapsed,duration=8} or nil
            if def.key=="forbearance" then aura=fb end
            if def.key=="cleanse" then aura=elapsed>=8 and {active=true} or nil end
        end
        local visible=self.db[def.option] and not suppressed and aura and aura.active
            and (def.key=="cleanse" or (aura.expires and aura.expires>now))
        if def.key=="cleanse" and not self.db.warnings then visible=false end
        local m=tile.motion
        if visible and m.state~="active" then m.entered=now end
        local dt=math.max(0,math.min(.1,now-(m.at or now)))
        m.at=now;m.state=visible and "active" or "hidden"
        -- Disabling/hiding a feature is immediate; natural arrivals/departures ease.
        local immediate=not self.db[def.option] or suppressed or not self.db.effects or self.db.reducedMotion
        m.alpha=immediate and (visible and 1 or 0) or (m.alpha+((visible and 1 or 0)-m.alpha)*(1-math.exp(-22*dt)))
        if m.alpha<.002 then m.alpha=0 end
        tile:SetShown(visible or m.alpha>0);tile:SetAlpha(m.alpha)
        local age=now-m.entered
        local animated=self.db.effects and not self.db.reducedMotion
        local arrival=animated and visible and math.max(0,1-age/.45) or 0
        local glow=animated and visible and (math.sin(age*2.6)+1)*.025 or 0
        local r,g,b=.94,.79,.46
        if def.key=="block" then r,g,b=.61,.81,1 end
        if def.key=="absorb" then r,g,b=.74,.91,.69 end
        if def.key=="forbearance" or def.key=="cleanse" then r,g,b=1,.67,.35 end
        tile.halo:SetVertexColor(r,g,b);tile.halo:SetAlpha(self.db.effects and visible and (.13+glow+arrival*.12) or 0)
        tile.rim:SetVertexColor(r,g,b);tile.rim:SetAlpha(.78)
        tile.faceLight:SetVertexColor(r,g,b);tile.faceLight:SetAlpha(self.db.effects and .13 or 0)
        tile.shade:SetAlpha(.36);tile.wash:SetAlpha(0);tile.trail:SetAlpha(0);tile.pin:Hide()
        tile.sweep:SetAlpha(arrival>0 and math.sin((1-arrival)*math.pi)*.35 or 0)
        tile.icon:SetDesaturated(false);tile.icon:SetAlpha(1)
        tile:SetScale(1+arrival*.045)
        tile.count:SetText(visible and aura.expires and self:FormatTime(aura.expires-now,aura.estimated) or "")
        if tile:IsShown() then any=true end
    end
    self.bulwarkTile.lock:SetShown(self.db.forbearanceAware and fb and fb.active and fb.expires and fb.expires>now and not suppressed or false)
    self.warning:ClearAllPoints();self.warning:SetPoint("BOTTOM",self.frame,"TOP",0,any and 53 or 4)
    self.anchorLabel:ClearAllPoints();self.anchorLabel:SetPoint("TOP",0,any and 80 or 26)
    return any
end

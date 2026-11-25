local _, P = ...
local media = "Interface\\AddOns\\PaladinTankKit\\Media\\"
local function label(parent, value, size, r,g,b)
    local t=parent:CreateFontString(nil,"OVERLAY")
    t:SetFont("Fonts\\ARIALN.TTF",size or 12,"")
    t:SetTextColor(r or .86,g or .85,b or .80); t:SetText(value)
    return t
end
local function backdrop(frame, r,g,b,a, border)
    frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    frame:SetBackdropColor(r,g,b,a)
    frame:SetBackdropBorderColor(.52,.43,.27,border or .22)
end

function P:QuietButton(parent, value, width, height, callback)
    local b=CreateFrame("Button",nil,parent,"BackdropTemplate")
    b:SetSize(width,height); backdrop(b,.055,.064,.074,.97)
    b.label=label(b,value,12); b.label:SetPoint("CENTER")
    b.glow=b:CreateTexture(nil,"BACKGROUND",nil,-1)
    b.glow:SetTexture(media.."Halo"); b.glow:SetBlendMode("ADD")
    b.glow:SetPoint("CENTER"); b.glow:SetSize(width+22,height+28); b.glow:SetVertexColor(.95,.77,.42); b.glow:SetAlpha(0)
    b:SetScript("OnEnter",function() b.hovered=true; b:SetBackdropBorderColor(.85,.68,.36,.65); b.glow:SetAlpha(.12) end)
    b:SetScript("OnLeave",function() b.hovered=false; b:SetBackdropBorderColor(.52,.43,.27,b.selected and .65 or .22); b.glow:SetAlpha(b.selected and .08 or 0) end)
    b:SetScript("OnClick",callback)
    return b
end

function P:SelectSettingsPage(key)
    self.settingsPage=key
    for name,page in pairs(self.settingsPages) do page:SetShown(name==key) end
    for name,b in pairs(self.settingsTabs) do
        b.selected=name==key
        b:SetBackdropColor(b.selected and .12 or .055,b.selected and .115 or .064,b.selected and .085 or .074,.97)
        b:SetBackdropBorderColor(.70,.56,.31,b.selected and .65 or .15)
        b.label:SetTextColor(b.selected and .96 or .63,b.selected and .81 or .66,b.selected and .55 or .66)
        b.glow:SetAlpha(b.selected and .08 or 0)
    end
end

function P:ToggleSettings()
    if self.settings then self.settings:SetShown(not self.settings:IsShown()); self:SyncSettings(); return end
    local panel=CreateFrame("Frame","PaladinTankKitSettings",UIParent,"BackdropTemplate")
    self.settings=panel
    panel:SetSize(660,540); panel:SetPoint("CENTER"); panel:SetFrameStrata("DIALOG")
    panel:SetClampedToScreen(true); panel:EnableMouse(true); panel:SetMovable(true); panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart",panel.StartMoving); panel:SetScript("OnDragStop",panel.StopMovingOrSizing)
    backdrop(panel,.030,.039,.052,.99,.50)
    local halo=panel:CreateTexture(nil,"BACKGROUND",nil,-8)
    halo:SetTexture(media.."Halo"); halo:SetBlendMode("ADD"); halo:SetVertexColor(.95,.75,.38)
    halo:SetPoint("TOPLEFT",-65,75); halo:SetSize(380,240); halo:SetAlpha(.13)
    local logo=panel:CreateTexture(nil,"ARTWORK")
    logo:SetTexture(media.."AddonIcon"); logo:SetSize(56,56); logo:SetPoint("TOPLEFT",22,-20)
    label(panel,"PALADIN TANKKIT",23,.96,.83,.60):SetPoint("TOPLEFT",94,-24)
    label(panel,"MARK. TRACK. PROTECT.",10,.55,.59,.60):SetPoint("TOPLEFT",95,-54)
    local close=self:QuietButton(panel,"x",26,26,function() panel:Hide() end); close:SetPoint("TOPRIGHT",-18,-18)
    local rule=panel:CreateTexture(nil,"ARTWORK")
    rule:SetTexture(media.."Rail"); rule:SetVertexColor(.84,.67,.36,.35); rule:SetSize(616,1); rule:SetPoint("TOPLEFT",22,-94)
    self.settingsPages,self.settingsTabs,self.checks={},{},{}
    local function page(key,title,description)
        local f=CreateFrame("Frame",nil,panel); f:SetSize(440,364); f:SetPoint("TOPLEFT",194,-116)
        label(f,title,19,.92,.88,.78):SetPoint("TOPLEFT",0,0)
        label(f,description,11,.55,.60,.63):SetPoint("TOPLEFT",0,-27)
        self.settingsPages[key]=f; return f
    end
    local general=page("general","Ready when you are.","Quiet reminders. No extra bars.")
    local timers=page("timers","Your abilities, one timeline.","Choose what appears. Unused abilities stay hidden.")
    local marking=page("marking","You choose the pull.","Select a living elite to begin. Mouseover only scouts.")
    local appearance=page("appearance","A little light.","Soft edges and fluid motion, at your preferred scale.")
    for i,tab in ipairs({{"general","Overview"},{"timers","Ability timers"},{"marking","Dungeon marking"},{"appearance","Appearance"}}) do
        local key=tab[1]
        local b=self:QuietButton(panel,tab[2],150,36,function() self:SelectSettingsPage(key) end)
        b:SetPoint("TOPLEFT",22,-116-(i-1)*45); self.settingsTabs[key]=b
    end
    label(panel,"PALADIN ONLY",9,.40,.45,.47):SetPoint("TOPLEFT",28,-318)
    label(panel,"/ptk help",11,.61,.57,.46):SetPoint("TOPLEFT",28,-338)
    local function toggle(parent,index,key,title,hint)
        local row=self:QuietButton(parent,"",440,44,function()
            self.db[key]=not self.db[key]
            if key=="autoMark" or key=="enabled" then self:ResetMarking() end
            self:SyncSettings(); self:Render()
        end)
        row:SetPoint("TOPLEFT",0,-53-(index-1)*48); row.label:Hide()
        label(row,title,13):SetPoint("TOPLEFT",12,-7)
        label(row,hint,10,.49,.55,.58):SetPoint("TOPLEFT",12,-25)
        row.track=row:CreateTexture(nil,"ARTWORK"); row.track:SetTexture(media.."IconFace")
        row.track:SetSize(32,16); row.track:SetPoint("RIGHT",-13,0)
        row.knob=row:CreateTexture(nil,"OVERLAY"); row.knob:SetTexture(media.."IconFace"); row.knob:SetSize(12,12)
        self.checks[key]=row
        return row
    end
    toggle(general,1,"enabled","Tank mode","Enable the toolkit on this Paladin.")
    toggle(general,2,"warnings","Reminders","Master switch for buff and shield reminders.")
    toggle(general,3,"warnFury","Righteous Fury","Assigned tank: flashing missing-buff reminder.")
    toggle(general,4,"warnAura","Devotion Aura","Accepts another group Paladin's equal/higher rank.")
    toggle(general,5,"warnShield","Equipped shield","Warn at 20% durability or below.")
    toggle(general,6,"warningSounds","Dungeon alert sound","One sound per missing tank-buff episode.")
    for i,option in ipairs({{"trackSeal","Active Seal","Uses Blizzard's actual buff expiration."},
        {"trackGround","Consecration","Ground-effect estimate, then remaining cooldown."},
        {"trackJustice","Hammer of Justice","Cooldown after use; clears after readiness."},
        {"trackHoly","Holy Shield","Actual buff duration, including early removal."},
        {"trackBulwark","Templar's Bulwark","Only when talented and a cooldown is active."},
        {"showForbearance","Forbearance","A small badge only while active."}}) do toggle(timers,i,option[1],option[2],option[3]) end
    toggle(marking,1,"autoMark","Automatic dungeon marks","Skull and Cross. Requires leader or assistant.")
    toggle(marking,2,"bossNotes","Boss notes","Private first. Share only when you choose.")
    label(marking,"TARGET  >  PRIORITIZE  >  PROMOTE",11,.85,.70,.43):SetPoint("TOPLEFT",12,-174)
    local explanation=label(marking,"Your target starts the queue, including before combat.\nEngaged enemies join as the pull develops.\nDangerous enemies and casters may take priority.\n\nNon-elites are never marked. Raids, world bosses\nand outdoor encounters remain manual.",12,.63,.68,.70)
    explanation:SetPoint("TOPLEFT",12,-201); explanation:SetJustifyH("LEFT")
    local resume=self:QuietButton(marking,"Resume marking",150,30,function() self:Command("resume") end); resume:SetPoint("TOPLEFT",12,-316)
    for i,option in ipairs({{"effects","Light effects","Soft halos, face lighting and feathered trails."},
        {"reducedMotion","Reduced motion","Keep the light. Remove pulses and travel effects."},
        {"idleFade","Fade while idle","Keep the HUD quiet between pulls."},
        {"locked","Lock HUD position","Unlock to drag the HUD anchor."}}) do toggle(appearance,i,option[1],option[2],option[3]) end
    local minus=self:QuietButton(appearance,"-",30,28,function() self:SetScale(self.db.scale-.05) end); minus:SetPoint("TOPLEFT",12,-260)
    self.scaleLabel=label(appearance,"",12); self.scaleLabel:SetPoint("TOPLEFT",51,-268)
    local plus=self:QuietButton(appearance,"+",30,28,function() self:SetScale(self.db.scale+.05) end); plus:SetPoint("TOPLEFT",132,-260)
    self.horizonButton=self:QuietButton(appearance,"",180,28,function()
        self.db.horizon=self.db.horizon==15 and 30 or (self.db.horizon==30 and 60 or 15)
        self:SyncSettings(); self:Render()
    end); self.horizonButton:SetPoint("TOPLEFT",182,-260)
    local reset=self:QuietButton(appearance,"Reset position",150,28,function() self.db.position=nil; self:Position() end); reset:SetPoint("TOPLEFT",12,-303)
    local footer=panel:CreateTexture(nil,"ARTWORK"); footer:SetTexture(media.."Rail"); footer:SetSize(616,1); footer:SetPoint("TOPLEFT",22,-483); footer:SetVertexColor(.84,.67,.36,.22)
    self.settingsStatus=label(panel,"",10,.55,.59,.60); self.settingsStatus:SetPoint("BOTTOMLEFT",24,22)
    self.previewButton=self:QuietButton(panel,"Preview HUD",126,30,function() self:TogglePreview() end); self.previewButton:SetPoint("BOTTOMRIGHT",-22,14)
    self.moveButton=self:QuietButton(panel,"Move HUD",106,30,function() self.db.locked=not self.db.locked; self:SyncSettings(); self:Render() end); self.moveButton:SetPoint("BOTTOMRIGHT",-158,14)
    panel:SetScript("OnUpdate",function(_,elapsed) self:TickSettings(elapsed) end)
    tinsert(UISpecialFrames,"PaladinTankKitSettings")
    self:SelectSettingsPage("general"); self:SyncSettings()
end

function P:TickSettings(elapsed)
    for key,row in pairs(self.checks or {}) do
        local target=self.db[key] and 1 or 0
        row.position=(not self.db.effects or self.db.reducedMotion) and target or ((row.position or target)+(target-(row.position or target))*(1-math.exp(-20*math.min(elapsed or .016,.1))))
        row.track:SetVertexColor(.88,.72,.43,.12+row.position*.23)
        row.knob:ClearAllPoints(); row.knob:SetPoint("LEFT",row.track,"LEFT",2+row.position*16,0)
        row.knob:SetVertexColor(.48+row.position*.47,.53+row.position*.26,.56-row.position*.06)
    end
end

function P:SyncSettings()
    if not self.settings then return end
    self.scaleLabel:SetText(math.floor(self.db.scale*100+.5).."% scale")
    self.horizonButton.label:SetText(self.db.horizon.." second timeline")
    self.previewButton.label:SetText(self.preview and "End preview" or "Preview HUD")
    self.moveButton.label:SetText(self.db.locked and "Move HUD" or "Lock HUD")
    local status=self:MarkingStatus()
    self.settingsStatus:SetText("v"..self.version.."  /  Marking: "..status.."  /  /ptk markstatus")
    self:TickSettings(.016)
end

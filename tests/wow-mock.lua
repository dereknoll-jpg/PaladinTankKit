unpack = table.unpack
TEST_NS, FRAMES, MARKS, MESSAGES = {}, {}, {}, {}
NOW, COMBAT, RESTRICTED, GROUP, RAID, LEADER, ASSISTANT = 100, false, false, true, false, false, false
DEAD, MOUNTED, CLASS = false, false, "PALADIN"
HELPFUL, HARMFUL, COOLDOWNS, KNOWN, UNITS = {}, {}, {}, {}, {}
PALADIN_FORMS = {{active=true, spellID=465}}
PLAYER_ROLE,MAIN_TANK,SOUNDS="TANK",false,{}
function UnitGroupRolesAssigned()return PLAYER_ROLE end
function GetPartyAssignment()return MAIN_TANK end
function PlaySound(id,channel) SOUNDS[#SOUNDS+1]={id=id,channel=channel} end
function GetNumShapeshiftForms() return FORM_COUNT_OVERRIDE or #PALADIN_FORMS end
function GetShapeshiftFormInfo(index)
    if FORM_ERROR then error("restricted forms") end
    local form = PALADIN_FORMS[index]
    return form.spellID, form.active, true, form.spellID
end
SECRET = setmetatable({}, {__add = function() error("Secret arithmetic") end,
    __lt = function() error("Secret comparison") end, __le = function() error("Secret comparison") end,
    __tostring = function() error("Secret string conversion") end})
function issecretvalue(value) return rawequal(value, SECRET) end
local definitions = {
    [1311649] = "Seal of Fury", [1311656] = "Seal of Fury", [20163] = "Seal of Fury",
    [20419] = "Seal of Fury", [20421] = "Seal of Fury", [20422] = "Seal of Fury", [20423] = "Seal of Fury",
    [25780] = "Righteous Fury", [26573] = "Consecration", [20116] = "Consecration",
    [20922] = "Consecration", [20923] = "Consecration", [20924] = "Consecration",
    [25771] = "Forbearance", [20154] = "Seal of Righteousness", [20271] = "Judgement",
    [21082] = "Seal of the Crusader", [20164] = "Seal of Justice", [20165] = "Seal of Light",
    [20166] = "Seal of Wisdom", [20375] = "Seal of Command", [20920] = "Seal of Command",
    [853] = "Hammer of Justice", [10308] = "Hammer of Justice",
    [1239570] = "Holy Shield", [20925] = "Holy Shield", [20927] = "Holy Shield", [20928] = "Holy Shield",
    [1311015] = "Templar's Bulwark",
    [1311033] = "Iron Creed", [1328551] = "Shieldsworn", [678] = "Holy Strike",
    [4987] = "Cleanse", [1152] = "Purify", [642] = "Divine Shield",
    [498] = "Divine Protection", [1022] = "Blessing of Protection",
}
KNOWN[1311656], KNOWN[25780], KNOWN[26573] = true, true, true
KNOWN[465]=true
C_Spell = {
    GetSpellInfo = function(id)
        if type(id)=="string" then for candidate,name in pairs(definitions) do if id==name then id=candidate;break end end end
        if definitions[id] then return {name=definitions[id],iconID=id,spellID=id} end
    end,
    GetSpellCooldown = function(id) return COOLDOWNS[id] or {startTime = 0, duration = 0, isEnabled = true, modRate = 1} end,
}
C_SpellBook = {IsSpellKnown = function(id) return KNOWN[id] or false end}
ACTION_DESCRIPTIONS,MACRO_SPELLS,CAST_HOOKS={},{},{}
function GetActionInfo(slot) local a=ACTION_DESCRIPTIONS[slot] or {};return a[1],a[2],a[3] end
function GetMacroSpell(id) return MACRO_SPELLS[id] end
function UseAction() end
function CastSpellByID() end
function CastSpellByName() end
function hooksecurefunc(name,callback)
    CAST_HOOKS[name]=callback
    local original=_G[name]
    _G[name]=function(...) original(...);callback(...) end
end
EQUIPPED_OFFHAND, ITEM_EQUIP_LOC, ITEM_DURABILITY = nil, "INVTYPE_SHIELD", {100,100}
function GetInventoryItemID(_,slot) assert(slot==17); return EQUIPPED_OFFHAND end
function GetInventoryItemDurability(slot)
    assert(slot==17); if DURABILITY_ERROR then error("unavailable") end
    return ITEM_DURABILITY[1],ITEM_DURABILITY[2]
end
C_Item = {GetItemInfoInstant = function(id)
    if ITEM_ERROR then error("item uncached") end
    return id,"Armor","Shield",ITEM_EQUIP_LOC
end}
C_Secrets = {ShouldAurasBeSecret = function() return RESTRICTED end}
C_UnitAuras = {GetAuraDataByIndex = function(_, index, filter)
    if AURA_ERROR then error("restricted") end
    if filter=="HARMFUL|RAID" then return (REMOVABLE or {})[index] end
    return (filter == "HELPFUL" and HELPFUL or HARMFUL)[index]
end}
local methods = {}
function methods:SetScript(name, value) self.scripts[name] = value end
function methods:RegisterEvent(name) self.events[name] = true end
function methods:UnregisterEvent(name) self.events[name] = nil end
function methods:SetText(value) assert(not issecretvalue(value)); self.text = value end
function methods:SetShown(value) self.shown = not not value end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:IsShown() return self.shown end
function methods:SetAlpha(value) self.alpha = value end
function methods:SetDesaturated(value) self.desaturated = value end
function methods:SetChecked(value) self.checked = value end
function methods:GetChecked() return self.checked end
function methods:EnableMouse(value) self.mouse = value end
function methods:SetPoint(...) self.point = {...} end
function methods:SetScale(value) self.scale = value end
function methods:SetTexture(value) self.texture = value end
function methods:AddMaskTexture(value) self.mask = value end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:GetCenter() return 400, 300 end
function methods:GetFrameLevel() return 2 end
function methods:StartMoving() self.moving = true end
function methods:StopMovingOrSizing() self.moving = false end
local noop = {"ClearAllPoints", "SetAllPoints", "SetColorTexture", "SetTexCoord", "SetFont",
    "SetTextColor", "SetWordWrap", "SetWidth", "SetHeight", "SetMaxLines", "SetJustifyH", "SetFrameLevel", "SetFrameStrata",
    "SetBlendMode", "SetVertexColor", "SetShadowColor", "SetShadowOffset",
    "SetClampedToScreen", "SetMovable", "RegisterForDrag", "RegisterForClicks", "SetBackdrop",
    "SetBackdropColor", "SetBackdropBorderColor", "SetOwner", "AddLine"}
for _, name in ipairs(noop) do methods[name] = function() end end
local function make(name)
    local f = setmetatable({scripts = {}, events = {}, shown = true}, {__index = methods})
    if name then _G[name] = f end
    return f
end
function methods:CreateTexture() return make() end
function methods:CreateMaskTexture() return make() end
function methods:CreateFontString() return make() end
function CreateFrame(_, name) local f = make(name); FRAMES[#FRAMES + 1] = f; return f end
UIParent, GameTooltip = make(), make()
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
UISpecialFrames, SlashCmdList = {}, {}
DEFAULT_CHAT_FRAME = {AddMessage = function(_, msg) MESSAGES[#MESSAGES + 1] = msg end}
function tinsert(t, v) table.insert(t, v) end
function GetTime() return NOW end
function GetBuildInfo() return BUILD_VERSION or "1.60.1" end
function InCombatLockdown() return COMBAT end
function UnitClass(unit)
    if unit and unit~="player" then local class=UNITS[unit] and UNITS[unit].class;return class,class end
    return CLASS,CLASS
end
function IsInGroup(category) if category == LE_PARTY_CATEGORY_INSTANCE then return INSTANCE_GROUP end; return GROUP end
function IsInRaid() return RAID end
function UnitIsGroupLeader() return LEADER end
function UnitIsGroupAssistant() return ASSISTANT end
function UnitExists(unit) return UNITS[unit] ~= nil end
function UnitGUID(unit) return UNITS[unit] and UNITS[unit].guid end
function UnitName(unit) return UNITS[unit] and UNITS[unit].name end
function UnitClassification(unit) return UNITS[unit] and (UNITS[unit].classification or "elite") end
function UnitAffectingCombat(unit) return UNITS[unit] and UNITS[unit].combat or false end
function UnitHealth(unit) return UNITS[unit] and UNITS[unit].health end
function UnitHealthMax(unit) return UNITS[unit] and UNITS[unit].healthMax end
function UnitThreatSituation(member, unit)
    if not UNITS[unit] then return nil end
    return UNITS[unit].threat and UNITS[unit].threat[member]
end
function UnitCastingInfo(unit) return UNITS[unit] and UNITS[unit].cast end
function UnitChannelInfo(unit) return UNITS[unit] and UNITS[unit].channel end
function UnitIsUnit(a, b)
    local first = UNITS[a]
    if not first and a:sub(-6) == "target" then
        local base = UNITS[a:sub(1, -7)]
        first = base and UNITS[base.target]
    end
    if not first or not UNITS[b] then return false end
    return first == UNITS[b] or (first.guid and first.guid == UNITS[b].guid) or false
end
function GetInstanceInfo() return "Test Dungeon", INSTANCE_KIND or "none", 1, "Normal", 5, 0, false, INSTANCE_ID or 0 end
C_NamePlate = {GetNamePlates = function() return PLATES or {} end}
function UnitCanAttack(_, unit) return UNITS[unit] and UNITS[unit].hostile or false end
function UnitIsDeadOrGhost(unit) if unit == "player" then return DEAD end; return UNITS[unit] and UNITS[unit].dead or false end
function GetRaidTargetIndex(unit) return UNITS[unit].mark end
function SetRaidTarget(unit, icon)
    if MARK_ERROR then error("protected") end
    MARKS[#MARKS + 1] = {unit, icon}
    if SILENT_MARK_FAILURE then return end
    if icon ~= 0 then
        for _, enemy in pairs(UNITS) do if enemy.mark == icon then enemy.mark = nil end end
    end
    UNITS[unit].mark = icon ~= 0 and icon or nil
end
function IsMounted() return MOUNTED end
function IsControlKeyDown() return CONTROL or false end
function IsShiftKeyDown() return SHIFT or false end
LE_PARTY_CATEGORY_INSTANCE = 2
SENT_CHAT, INSTANCE_GROUP = {}, false
function SendChatMessage(message, channel)
    if CHAT_ERROR then error("restricted") end
    SENT_CHAT[#SENT_CHAT + 1] = {message, channel}
end

local p = TEST_NS
p.db.effects = false
local count = 0
local function check(value, message) assert(value, message); count = count + 1 end
local function event(name, ...) p.events.scripts.OnEvent(p.events, name, ...) end
local function refresh() p:RefreshAuras(); p:Render() end
check(p.frame and p.frame:IsShown(), "Paladin UI initializes")
check(p.spells.seal.id == 1311656, "Forever Fury rank discovered")
check(p.spells.ground.known, "Consecration discovered")
check(p:Warnings():find("Missing:"), "Real absence warns when grouped")
check(#MARKS == 0, "Loading never marks enemies")

UNITS.target = {hostile = true}; UNITS.mouseover = {hostile = true}
PaladinTankKit_Mark(8)
check(MARKS[1][1] == "mouseover" and MARKS[1][2] == 8, "Mouseover priority")
PaladinTankKit_Mark(8); check(#MARKS == 1, "Repeated Skull never toggles off")
UNITS.mouseover = {hostile = false}
PaladinTankKit_Mark(7)
check(MARKS[2][1] == "target" and MARKS[2][2] == 7, "Friendly mouseover falls back to target")
PaladinTankKit_Mark(0); check(UNITS.target.mark == nil, "Explicit clear")
local n = #MARKS
PaladinTankKit_Mark(0); check(#MARKS == n, "Empty clear has no effect")
UNITS.mouseover = {hostile = true, dead = true}; UNITS.target.dead = true
PaladinTankKit_Mark(8); check(#MARKS == n, "Dead enemies rejected")
UNITS.target.dead = false; RAID = true
PaladinTankKit_Mark(8); check(#MARKS == n, "Raid permissions enforced")
ASSISTANT = true; PaladinTankKit_Mark(8); check(#MARKS == n + 1, "Raid assistant may mark")
RAID, ASSISTANT = false, false
UNITS.target.mark = SECRET; n = #MARKS
PaladinTankKit_Mark(7); check(#MARKS == n, "Hidden mark is never compared")
UNITS.target.mark = nil; MARK_ERROR = true
check(pcall(PaladinTankKit_Mark, 8), "Protected marking failure handled")
MARK_ERROR = false

HELPFUL = {{spellId = 1311656, name = "Seal of Fury", expirationTime = 130, duration = 30},
    {spellId = 25780, name = "Righteous Fury", expirationTime = 0, duration = 0}}
refresh()
check(p:Warnings() == "", "Healthy buffs have no reminders")
check(p.auras.seal.expires == 130 and not p.auras.seal.estimated, "Authoritative seal timer")
check(p.sealTile.point[4] == 438, "Timer starts at right end")
NOW = 115; p:Render()
check(p.sealTile.point[4] == 257, "Timer slides left as time passes")
COMBAT, RESTRICTED, HELPFUL = true, true, {}; refresh()
check(p.auras.seal.estimated and p.auras.seal.expires == 130, "Hidden aura retains marked estimate")
check(p:Warnings() == "", "Combat absence never creates false missing-buff alert")
NOW = 131; refresh()
check(p.auras.seal.uncertain and not p.auras.seal.active, "Expired estimate becomes unknown")
check(p.sealTile.count.text == "?", "Unknown seal displays question mark")
event("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-1", 1311656)
check(p.auras.seal.uncertain and p.memory.seal == nil, "Seal cast waits for Blizzard buff timing")
event("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-2", 20154)
check(p.activeSeal.name == "Seal of Righteousness" and p.memory.seal == nil, "Seal swap cannot invent duration")
event("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-3", 1311656)
HELPFUL = {{spellId = 1311656, name = "Seal of Fury", expirationTime = 251, duration = 120}}
refresh()
event("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-4", 20271)
check(p.auras.seal.expires == 251 and p.memory.seal.expires == 251, "Judgement leaves Seal expiration unchanged")
event("UNIT_SPELLCAST_SUCCEEDED", SECRET, SECRET, SECRET)
check(p.memory.seal.expires == 251, "Secret cast payload is ignored safely")
HELPFUL, p.memory.seal = {}, nil
event("UNIT_SPELLCAST_SUCCEEDED", "party1", "Cast-5", 26573)
check(p.ground == nil, "Other players cannot start ground timer")
event("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-6", 26573)
check(p.ground.expires == 139 and p.ground.estimated, "Ground lifetime estimated from successful cast")
check(p.groundTile.count.text == "~8", "Ground estimate visibly labelled")
NOW = 140; p:Render(); check(p.ground == nil, "Ground expires independently of cooldown")

COOLDOWNS[26573] = {startTime = 138, duration = 8, isEnabled = true, modRate = 1}
check(p:Cooldown("ground") == 6, "Readable cooldown uses live time")
COOLDOWNS[26573].startTime = SECRET
check(p:Cooldown("ground") == nil, "Secret cooldown never used in arithmetic")
COOLDOWNS[26573] = {startTime = 139.5, duration = 1.5, isEnabled = true}
check(p:Cooldown("ground") == nil, "Global cooldown is not ability cooldown")
COOLDOWNS[26573] = nil

COMBAT, RESTRICTED = false, true
p.used.seal = true
refresh(); check(p.auras.seal.uncertain, "Restrictions respected outside combat too")
RESTRICTED, AURA_ERROR = false, true
refresh(); check(p.auras.seal.uncertain, "Refused aura API becomes unknown")
AURA_ERROR = false
HELPFUL = {{spellId = SECRET, name = SECRET, expirationTime = SECRET, duration = SECRET}}
refresh(); check(p.auras.seal.uncertain, "Secret aura identity makes absence uncertain")
HELPFUL = {{spellId = 1311656, name = "Seal of Fury", expirationTime = SECRET, duration = SECRET}}
refresh(); check(p.auras.seal.active and p.auras.seal.uncertain, "Known aura with hidden timing is active and unknown")
HELPFUL = {}; refresh()
check(not p.auras.seal.active and not p.auras.seal.uncertain, "Readable scan clears stale memory")
HARMFUL = {{spellId = 25771, name = "Forbearance", expirationTime = 200, duration = 60}}
refresh(); check(p.forbearanceTile:IsShown(), "Forbearance appears only when active")
p.db.showForbearance = false; p:Render()
check(not p.forbearanceTile:IsShown(), "Forbearance option honored")
p.db.showForbearance, HARMFUL = true, {}; refresh()
check(not p.forbearanceTile:IsShown(), "Forbearance disappears on removal")

GROUP = false; UNITS = {}; refresh()
check(p:Warnings() == "", "No idle solo nagging")
check(p.frame.alpha == 0.25, "Prepared idle layout fades")
p:Command("settings"); check(p.settings:IsShown(), "Settings constructs with strict frame mock")
p:Command("settings"); check(not p.settings:IsShown(), "Settings toggles closed")
p:Command("unlock"); check(not p.db.locked and p.anchor.mouse, "Unlock enables drag surface")
p:Command("lock"); check(p.db.locked and not p.anchor.mouse, "Lock preserves click-through space")
p:SetScale(100); check(p.db.scale == 1.5, "Scale clamped")
p:SetScale(-2); check(p.db.scale == 0.75, "Minimum scale clamped")
p:Command("ground 12"); check(p.db.groundDuration == 12, "Custom ground lifetime")
p:Command("ground 999"); check(p.db.groundDuration == 12, "Invalid lifetime rejected")
p:Command("preview"); check(p.preview and p.warning.text:find("PREVIEW"), "Preview clearly labelled")
COMBAT = true; event("PLAYER_REGEN_DISABLED")
check(not p.preview, "Combat cancels preview")
p:Command("preview"); check(not p.preview, "Combat preview refused")
COMBAT = false
COMBAT, DEAD = true, true; p:Render()
check(not p.sealTile:IsShown() and not p.groundTile:IsShown(), "Death suppresses combat ready indicators")
COMBAT, DEAD = false, false
p:Command("off"); check(not p.frame:IsShown(), "Tank mode off hides UI")
n = #MARKS; PaladinTankKit_Mark(8); check(#MARKS == n, "Disabled toolkit cannot mark")
p:Command("on"); check(p.frame:IsShown(), "Tank mode restores")
p:Command("reset"); check(p.db.position == nil and p.db.scale == 1, "Recover default position and scale")
p.events.scripts.OnUpdate(p.events, 0.6)
check(#MARKS == n, "Periodic updates never mark")
event("PLAYER_DEAD"); check(p.ground == nil and next(p.memory) == nil, "Death clears estimates")
PaladinTankKitDB = {scale = 0/0, horizon = 99, warnings = "bad", groundDuration = math.huge}
p:InitializeDB()
check(p.db.scale == 1 and p.db.horizon == 30 and p.db.warnings == true and p.db.groundDuration == 8,
    "Damaged saved settings repaired")
print("PASS: " .. count .. " behavior checks (marking, timers, restricted data, settings and lifecycle).")

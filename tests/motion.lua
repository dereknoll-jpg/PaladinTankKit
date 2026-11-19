local p, n = TEST_NS, 0
local function check(v, message) assert(v, message); n = n+1 end
local function render(dt) NOW = NOW + (dt or 1/60); p:Render() end
local function advance(seconds)
    for _ = 1, math.ceil(seconds*60) do render(1/60) end
end
p.db.effects, p.db.reducedMotion = true, false
GROUP, LEADER, COMBAT, INSTANCE_KIND, INSTANCE_ID = true, true, true, "party", 36
p.auras = {seal = {active = true, expires = NOW+30, duration = 30}, forbearance = {active = false}}
p.ground = {active = true, expires = NOW+30, duration = 30, estimated = true}
p:Render()
check(p.frame.height == 42 and p.frame.width == 520, "One horizontal rail replaces tall HUD")
check(p.notesCard.height == 28 and p.notesCard.width == 720, "Boss notes use one long ribbon")
check(p.sealTile.point[5] == p.groundTile.point[5], "Abilities share a single row")
check(math.abs(p.sealTile.point[4]-p.groundTile.point[4]) >= 28, "Coincident icons separate horizontally")
check(p.sealTile.pin.point[4] == p.groundTile.pin.point[4], "True-position ticks remain accurate when icons separate")
advance(0.4)
check(p.sealTile.alpha > 0.9 and p.sealTile.alpha <= 1, "Timers fade in smoothly")
check(p.sealTile.trail.alpha > 0 and p.sealTile.halo.alpha > 0, "Active timers have layered trails and halos")
advance(1.6)
local oldX = p.sealTile.motion.x
p.auras.seal.expires = NOW+30; p.ground = nil
render()
check(p.sealTile.motion.refreshAt ~= nil, "Aura refresh triggers a settle transition")
check(math.abs(p.sealTile.motion.x-oldX) < 15, "Refresh avoids a full-track teleport")
advance(0.4)
check(p.sealTile.motion.refreshAt == nil, "Refresh settles in bounded time")
check(p.sealTile.motion.x >= 76 and p.sealTile.motion.x <= 438, "Timer stays inside rail bounds")

p.auras.seal.expires = NOW+3
render(); local glowA = p.sealTile.halo.alpha
advance(0.25); local glowB = p.sealTile.halo.alpha
check(glowA ~= glowB and glowB <= 0.54, "Expiry breath is bounded and animated")
p.db.reducedMotion = true; render()
local quiet = p.sealTile.halo.alpha
advance(0.4)
check(p.sealTile.halo.alpha == quiet and p.sealTile.scale == 1, "Reduced motion removes pulse and scale movement")
p.db.effects = false; render()
check(p.sealTile.halo.alpha == 0 and p.sealTile.trail.alpha == 0 and p.sealTile.sweep.alpha == 0, "Effects-off clears all decorative layers")

p.db.effects, p.db.reducedMotion = true, false
p.used.seal = true
p.auras.seal = {uncertain = true}; render()
check(p.sealTile.motion.state == "unknown" and p.sealTile.count.text == "?", "Hidden data has a distinct unknown state")
check(p.sealTile.halo.alpha == 0 and p.sealTile.sweep.alpha == 0, "Unknown state never shows a success/expiry effect")
p.auras.seal = {active = false}; p.ground = nil
COOLDOWNS[26573] = {startTime = NOW, duration = 5, isEnabled = true}
p:NoteUsedCooldown("ground",26573)
render()
COOLDOWNS[26573] = {startTime = 0, duration = 0, isEnabled = true}
advance(0.4)
check(p.groundTile.motion.state == "ready", "Ready state is separate from active time")
advance(0.4)
check(p.groundTile.halo.alpha > 0.08, "Ready has a brief arrival pulse")
advance(1.4)
check(not p.groundTile:IsShown(), "Completed used cooldown fades away")

p:AnimateNotes(true, NOW); NOW = NOW+0.05; p:AnimateNotes(true, NOW)
check(p.notesCard:IsShown() and p.noteProgress > 0 and p.noteProgress < 1, "Boss ribbon eases open")
for _=1,60 do NOW=NOW+1/60; p:AnimateNotes(false,NOW) end
check(not p.notesCard:IsShown(), "Boss ribbon completes its close fade")
p.db.reducedMotion = true; p:AnimateNotes(true,NOW)
check(p.noteProgress == 1, "Reduced-motion ribbon opens without translation")

local function mob(id, kind)
    return {guid = "Creature-0-1-36-1-"..id.."-abc", name = "Test", hostile = true,
        classification = kind or "elite", combat = true, threat = {player = 1}}
end
UNITS = {target = mob(12345)}
p.db.reducedMotion = false
p:QueueMarkFeedback("target", 8, true); p:TickMarkEffects(NOW)
check(p.markFlash == nil, "Mark flash waits for actual marker confirmation")
UNITS.target.mark = 8; NOW=NOW+0.1; p:TickMarkEffects(NOW)
NOW=NOW+0.15; p:TickMarkEffects(NOW)
check(p.markGlow.alpha > 0 and p.markGhost.alpha > 0, "Confirmed promotion animates Cross into Skull")
p.db.reducedMotion = true; p:TickMarkEffects(NOW)
check(p.markGlow.alpha == 0 and p.markGhost.alpha == 0, "Reduced motion suppresses marking flash")

p:ResetMarking(); UNITS.target = mob(12346)
p:ObserveMarkUnit("target", true)
local r = p.marking.candidates[UNITS.target.guid]
local marks = #MARKS
RAID = true
check(not p:AssignAutoMark(r,8) and #MARKS == marks, "Low-level setter independently blocks raid groups")
p:SmartMarkPull(); p:AutoMarkTick()
check(#MARKS == marks, "Smart key and automatic tick cannot mark in raids")
RAID, INSTANCE_KIND = false, "raid"
check(not p:AssignAutoMark(r,8), "Raid instance blocks automation even without raid roster flag")
INSTANCE_KIND = "none"
check(not p:AssignAutoMark(r,8), "Outdoor areas are manual-only")
INSTANCE_KIND, INSTANCE_ID = "party", 36
UNITS.target.classification = "worldboss"
check(not p:AssignAutoMark(r,8), "World-boss classification blocked at mutation boundary")
p:Mark(8)
check(UNITS.target.mark == 8, "Explicit manual world-boss marking remains available")
p:ResetMarking(); UNITS.target = mob(12347, "worldboss")
UNITS.nameplate1 = mob(12348); PLATES = {{namePlateUnitToken="nameplate1"}}
p:AutoMarkTick(true); NOW=NOW+1; p:AutoMarkTick()
check(UNITS.target.mark == nil and UNITS.nameplate1.mark == nil, "World-boss encounter also leaves its adds manual")
p:Render(); check(p.markStatus.text == "MAN", "Manual-only mode is visible")

p:ResetMarking(); INSTANCE_ID = 230; UNITS = {target=mob(12349)}
UNITS.target.name = "Princess Moira Bronzebeard"
p:AutoMarkTick(); NOW=NOW+1; p:AutoMarkTick()
check(UNITS.target.mark == nil, "Rescue NPC is excluded from automatic kill marking")
local wanted = {389,48,34,90,47,129,70,209,349,109,230,229,429,329,2994,2974,3001}
for _, id in ipairs(wanted) do check(p.dungeons[id] ~= nil, "Remaining dungeon catalog exists: " .. id) end
check(p.dungeons[429].byName["cho'rush the observer"].neverAutoMark, "Tribute companion is excluded from kill markers")
check(p.dungeons[109].byName["avatar of hakkar"].confidence == "classic-reference", "Inherited tactics are explicitly labeled")
check(p.dungeons[2875] == nil and p.dungeons[2784] == nil, "Unconfirmed inherited instances do not get invented Forever tactics")
print("PASS: " .. n .. " motion, geometry, new coverage and manual-only checks.")

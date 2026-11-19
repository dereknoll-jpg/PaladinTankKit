local p, checks = TEST_NS, 0
p.db.effects = false
local function check(value, message) assert(value, message); checks = checks + 1 end
local function enemy(id, name, options)
    local u = {guid = "Creature-0-1-36-1-" .. id .. "-" .. tostring(NOW) .. tostring(math.random(100000)),
        name = name, hostile = true, dead = false, classification = "elite", combat = true, threat = {player = 1}}
    for k, v in pairs(options or {}) do u[k] = v end
    return u
end
local function setup(id)
    INSTANCE_KIND, INSTANCE_ID, GROUP, RAID, LEADER, ASSISTANT = "party", id or 36, true, false, true, false
    COMBAT, DEAD, MOUNTED, MARK_ERROR, SILENT_MARK_FAILURE = true, false, false, false, false
    UNITS, PLATES, MARKS = {}, {}, {}
    p.db.enabled, p.db.autoMark, p.db.bossNotes, p.preview = true, true, true, false
    p:ResetMarking(); NOW = NOW + 10
end
local function plate(unit, data)
    UNITS[unit] = data; PLATES[#PLATES + 1] = {namePlateUnitToken = unit}; return data
end
local function tick(seconds) NOW = NOW + (seconds or 0.5); p:AutoMarkTick() end
local function assign() p:AutoMarkTick(); tick() end

setup()
local melee = plate("nameplate1", enemy(90001, "Melee")); UNITS.target = melee
local caster = plate("nameplate2", enemy(90002, "Caster", {cast = "Fireball"}))
local normal = plate("nameplate3", enemy(90003, "Normal", {classification = "normal", cast = "Heal"}))
assign()
check(caster.mark == 8 and melee.mark == 7 and normal.mark == nil, "Caster wins; normals never marked")
check(#MARKS == 2, "Exactly Skull and Cross assigned")
tick(1); check(#MARKS == 2, "No repeated marking/toggling")
local stronger = plate("nameplate4", enemy(90004, "Defias Evoker"))
tick()
check(caster.mark == 8 and stronger.mark == 7, "Stable Skull; dangerous newcomer becomes Cross")
caster.dead = true; p:MarkUnitDied(caster.guid); tick()
check(stronger.mark == 8 and melee.mark == 7, "Confirmed death promotes Cross and refills queue")
check(#SENT_CHAT == 0, "Automatic marking never sends chat")

setup()
local first = plate("nameplate1", enemy(90101, "First")); UNITS.target = first
local second = plate("nameplate2", enemy(90102, "Second"))
local third = plate("nameplate3", enemy(90103, "Third"))
assign(); check(first.mark == 8 and second.mark == 7 and third.mark == nil, "All melee use initial target then stable order")
UNITS.target, UNITS.nameplate1 = nil, nil; PLATES = {{namePlateUnitToken = "nameplate2"}, {namePlateUnitToken = "nameplate3"}}
tick(1); check(second.mark == 7 and third.mark == nil, "Lost Skull nameplate is not treated as death")
p:MarkUnitDied(first.guid); tick()
check(second.mark == 8 and third.mark == 7, "Readable death event works after Skull leaves sight")

setup()
first = plate("nameplate1", enemy(90201, "First")); UNITS.target = first
second = plate("nameplate2", enemy(90202, "Second")); assign()
UNITS.mouseover = first; p:Mark(8)
check(p.marking.candidates[first.guid].manual, "Clicking existing automatic Skull pins it")
local evoker = plate("nameplate3", enemy(90203, "Defias Evoker")); tick(1)
check(first.mark == 8 and evoker.mark == 7, "Manual Skull remains pinned")
evoker.mark = 1; tick(1)
check(p.marking.paused ~= nil and evoker.mark == 1, "External change pauses instead of fighting marks")

setup()
first = plate("nameplate1", enemy(90301, "First", {mark = 8})); UNITS.target = first
second = plate("nameplate2", enemy(90302, "Second", {mark = 1})); assign()
check(first.mark == 8 and second.mark == 1 and #MARKS == 0, "Existing Skull and crowd-control mark respected")
first.dead = true; tick()
check(second.mark == 1, "CC target excluded even after Skull death")

setup()
first = plate("nameplate1", enemy(90401, "First")); UNITS.target = first
second = plate("nameplate2", enemy(90402, "Other group's pull", {threat = {other = 2}})); assign()
check(first.mark == 8 and second.mark == nil, "Nearby combat alone does not establish group engagement")
setup()
first = plate("nameplate1", enemy(90403, "Unpulled", {combat = false, threat = {}})); UNITS.target = first
assign(); check(first.mark == 8 and #MARKS == 1, "Selecting an elite permits pre-pull Skull")
p:SmartMarkPull(); check(first.mark == 8, "Explicit Mark Pull may seed the current elite before combat")

setup()
first = plate("nameplate1", enemy(90501, "First")); UNITS.target = first
LEADER = false; p.permissionWarned = nil
local messages = #MESSAGES
assign(); check(#MARKS == 0 and p:MarkPermissionIssue(), "Dungeon nonleader cannot auto mark")
check(#MESSAGES == messages + 1, "Missing leadership alert sent once")
tick(); check(#MESSAGES == messages + 1, "Leadership alert does not spam")
p:Render(); check(p.warning.text:find("request party leader"), "Persistent request-leader HUD alert")
p.db.warnings = false; p:Render(); check(p.warning.text:find("request party leader"), "Permission alert independent of buff reminders")
LEADER = true; tick(); tick()
check(first.mark == 8 and not p.permissionWarned, "Leadership restored without reload")
setup(); RAID = true; ASSISTANT = true; LEADER = false
first = plate("nameplate1", enemy(90502, "Raid elite")); UNITS.target = first
assign(); check(#MARKS == 0, "Auto marking remains dungeon-party only")

setup()
first = plate("nameplate1", enemy(90601, "Secret identity", {guid = SECRET})); UNITS.target = first
second = plate("nameplate2", enemy(90602, "Secret classification", {classification = SECRET}))
third = plate("nameplate3", enemy(90603, "Secret threat", {threat = {player = SECRET}}))
assign(); check(#MARKS == 0, "Secret identity, classification and threat cause no inferred marks")
setup()
first = plate("nameplate1", enemy(90604, "Secret casts", {cast = SECRET})); UNITS.target = first
second = plate("nameplate2", enemy(90605, "Melee")); assign()
check(first.mark == 8 and second.mark == 7, "Hidden cast does not cause arithmetic/string errors")
setup()
first = plate("nameplate1", enemy(90606, "Secret mark", {mark = SECRET})); UNITS.target = first
assign(); check(#MARKS == 0 and p.marking.paused, "Hidden marks pause safely")
setup()
first = plate("nameplate1", enemy(90607, "First")); UNITS.target = first
SILENT_MARK_FAILURE = true; assign(); tick(1)
check(p.marking.paused ~= nil, "Silent marking refusal detected by delayed readback")

setup()
first = plate("nameplate1", enemy(90701, "Non elite", {classification = "normal"})); UNITS.target = first
p:Mark(8); check(#MARKS == 0, "Manual Skull also rejects non-elites")
first.classification = "rare"; p:Mark(7); check(#MARKS == 0, "Non-elite rare is not an elite")
first.classification = "rareelite"; p:Mark(7); check(first.mark == 7, "Rare elite is eligible")
first.mark = nil; first.classification = "worldboss"; p:Mark(8); check(first.mark == 8, "Boss classification eligible")
p:Mark(0); check(p.marking.paused and first.mark == nil, "Manual clear pauses auto marking")

setup()
local van = plate("nameplate1", enemy(639, "Edwin VanCleef")); UNITS.target = van
assign(); check(van.mark == 8, "Boss initially marked if adds not yet observed")
local guard = plate("nameplate2", enemy(636, "Defias Blackguard"))
local guard2 = plate("nameplate3", enemy(636, "Defias Blackguard"))
tick(1)
check(guard.mark == 8 and guard2.mark == 7 and van.mark == nil, "VanCleef adds override automatic boss Skull")
guard.dead = true; tick(1)
check(guard2.mark == 8 and van.mark == 7, "First guard death promotes second guard")
guard2.dead = true; tick(1)
check(van.mark == 8, "Boss receives Skull after both guards die")
setup(2999)
local wither = plate("nameplate1", enemy(90711, "Witherfang")); UNITS.target = wither
local add = plate("nameplate2", enemy(90712, "Skeletal Mage", {cast = "Frostbolt"}))
assign(); check(wither.mark == 8 and add.mark == 7, "Boss-first exception overrides caster-first")
setup(2959)
local enigma = plate("nameplate1", enemy(90713, "Arcanic Enigma")); UNITS.target = enigma
local phantom = plate("nameplate2", enemy(90714, "Mana Phantom"))
assign(); check(phantom.mark == 8 and enigma.mark == 7, "Dalaran Mana Phantom encounter priority")
setup(189)
local mograine = plate("nameplate1", enemy(3976, "Scarlet Commander Mograine")); UNITS.target = mograine
assign()
local whitemane = plate("nameplate2", enemy(3977, "High Inquisitor Whitemane")); tick(1)
check(whitemane.mark == 8 and mograine.mark == 7, "Whitemane encounter exception changes automatic Skull")
setup(3039)
local ashka = plate("nameplate1", enemy(90901, "War Handler Ashka")); UNITS.target = ashka
local pet = plate("nameplate2", enemy(90902, "Snarlfang")); assign()
check(pet.mark == 8 and ashka.mark == 7, "Known Ashka pet precedes boss")
setup(2970)
local marrow = plate("nameplate1", enemy(90903, "Deathless Marrow")); UNITS.target = marrow
assign(); check(p.marking.paused and #MARKS == 0, "Phase-dependent plan does not invent endless add priority")
p:Mark(8); check(marrow.mark == 8, "Manual marking remains usable for phase-dependent boss")
setup()
first = plate("nameplate1", enemy(90904, "Unengaged marked mob", {mark = 8, combat = false})); UNITS.target = first
assign(); check(not p.marking.paused, "Idle preexisting marks do not generate false conflict alerts")
second = plate("nameplate2", enemy(90905, "Current pull")); p:ResetMarking(); UNITS.target=second; assign()
check(p.marking.paused and first.mark == 8 and second.mark == nil, "External Skull on another pull is not stolen")
setup()
first = plate("nameplate1", enemy(90906, "First")); UNITS.target = first
second = plate("nameplate2", enemy(90907, "Second"))
third = plate("nameplate3", enemy(90908, "Third")); assign()
first.dead = true; UNITS.nameplate2 = nil
PLATES = {{namePlateUnitToken = "nameplate1"}, {namePlateUnitToken = "nameplate3"}}
tick(1)
check(third.mark == nil and p.marking.slots[7] == second.guid, "Unseen living Cross is retained after Skull death")
setup()
local member = {guid = "Player-1-1234", name = "Party Member"}; UNITS.party1 = member
first = plate("nameplate1", enemy(90909, "Attacking party member", {threat = {}, target = "party1"})); UNITS.target=first; assign()
check(first.mark == 8, "Readable party target provides alternate engagement evidence")
setup()
first = plate("nameplate1", enemy(90910, "First")); UNITS.target = first; assign()
local record = p.marking.candidates[first.guid]
UNITS.nameplate1 = enemy(90911, "Recycled nameplate")
record.unit = "nameplate1"
check(not p:AssignAutoMark(record, 7) and UNITS.nameplate1.mark == nil, "Identity rechecked before assigning recycled unit token")

setup()
van = plate("nameplate1", enemy(639, "Edwin VanCleef", {combat = false})); UNITS.target = van
p:Render()
check(p.notesButton:IsShown() and not p.notesCard:IsShown(), "Boss notes stay collapsed initially")
p.notesOpen = true; p:RenderNotes()
check(p.notesCard:IsShown() and p.noteBody.text:find("Blackguards"), "Compact boss notes show kill order")
check(#SENT_CHAT == 0, "Reading notes never auto broadcasts")
p:ShowBossNoteInChat(); check(MESSAGES[#MESSAGES]:find("Blackguards"), "Private chat note available")
NOW = NOW + 20; p:ShareBossNote()
check(#SENT_CHAT == 1 and SENT_CHAT[1][2] == "PARTY" and SENT_CHAT[1][1]:find("{skull}"), "Explicit share sends one party plan")
p:ShareBossNote(); check(#SENT_CHAT == 1, "Boss share rate limited")
NOW = NOW + 16; INSTANCE_GROUP = true; p:ShareBossNote()
check(SENT_CHAT[2][2] == "INSTANCE_CHAT", "Instance group uses instance chat")
INSTANCE_GROUP = false; UNITS.target = enemy(90801, "Unknown boss")
p:RenderNotes(); check(not p.notesButton:IsShown() and not p.notesCard:IsShown(), "Unsupported boss never receives fabricated notes")
local sent = #SENT_CHAT; p:ShareBossNote(); check(#SENT_CHAT == sent, "Unsupported note cannot be shared")
p.db.bossNotes = false; UNITS.target = van; p:RenderNotes()
check(not p.notesButton:IsShown(), "Boss notes option hides UI")

local bosses, mobs, dungeons = 0, 0, 0
for id, catalog in pairs(p.dungeons) do
    dungeons = dungeons + 1
    check(type(id) == "number" and catalog.source:match("^https://") and catalog.reviewed, "Catalog has provenance")
    local unique = {}
    for _, e in pairs(catalog.byName) do
        if not unique[e] then
            unique[e] = true
            if e.boss then
                bosses = bosses + 1
                check(#p:BossNoteMessage(e) <= 255, "Every boss plan fits one chat message: " .. e.name)
            else mobs = mobs + 1 end
        end
    end
end
check(p:CatalogEntry(33, 639, "Edwin VanCleef") == nil, "Catalog identity never leaks across dungeons")
print("PASS: " .. checks .. " marking/note checks; " .. dungeons .. " dungeon catalogs, " .. bosses .. " boss notes, " .. mobs .. " priority enemies.")

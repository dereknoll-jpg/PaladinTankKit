local _, PTK = ...

-- Original, short recommendations. Scores are TankKit policy, not game statistics.
-- Reviewed 2026-11-18. English name fallbacks are exact and instance-scoped.
-- Never infer elite status from this catalog: the live unit must pass that check.
PTK.dungeons = {}
local function dungeon(id, name, source)
    local d = {name = name, source = source, reviewed = "2026-11-18", byID = {}, byName = {}}
    PTK.dungeons[id] = d
    return d
end
local function entry(d, id, name, score, caster, reason)
    local e = {name = name, score = score, caster = caster, reason = reason, source = d.source}
    if id then d.byID[id] = e end
    d.byName[name:lower()] = e
    return e
end
local function boss(d, id, name, note, options)
    local e = entry(d, id, name, 10, false)
    e.boss, e.note = true, note
    for k, v in pairs(options or {}) do e[k] = v end
    return e
end
local method = "https://www.method.gg/wow-forever/dungeons/"
local calc = "https://wowcalc.net/en/forever/guides/dungeons/"
local d = dungeon(36, "The Deadmines", method .. "the-deadmines")
entry(d, nil, "Defias Evoker", 90, true, "Interrupt Flamestrike; leave the fire.")
entry(d, nil, "Defias Overseer", 65, false, "Empowers nearby allies.")
entry(d, nil, "Defias Taskmaster", 60, false, "Ranged armor reduction.")
entry(d, nil, "Goblin Engineer", 80, true, "Summons additional enemies.")
entry(d, nil, "Defias Squallshaper", 75, true, "Caster; interrupt and pull into line of sight.")
entry(d, 636, "Defias Blackguard", 100, false, "VanCleef escort.")
boss(d, 639, "Edwin VanCleef", "Plan: Blackguards {skull}, then {cross}, then VanCleef. Start with full mana; gather new guards near half health. Control or kill extra guards if tank damage is high.",
    {adds = {[636] = 150, ["defias blackguard"] = 150}, preempt = true})
boss(d, 646, "Mr. Smite", "Plan: kill his escorts before pushing Smite. Top the tank before his group stun and weapon swaps.", {addsFirst = true, preempt = true})
boss(d, 647, "Captain Greenskin", "Plan: clear accompanying pirates, then Greenskin. Fight down the deck; avoid pulling VanCleef.", {addsFirst = true, preempt = true})
boss(d, 645, "Cookie", "Plan: isolate Cookie; interrupt his heal. Keep clear of nearby pirates.")

d = dungeon(3065, "Hall of Thanes", method .. "hall-of-thanes")
entry(d, nil, "Dark Iron Summoner", 95, true, "Interrupt summons and Fireball; respect crowd control.")
entry(d, nil, "Dark Iron Engineer", 65, true, "Move from bomb landing spots.")
entry(d, nil, "Dark Iron Looter", 75, false, "Heavy melee damage.")
entry(d, nil, "Lesser Stone Golem", 70, false, "Fast, hard-hitting melee.")
boss(d, nil, "Faldrim Anvilmar", "Plan: clear the tomb first. Interrupt Mind Blast; remove Anvilmar's Curse when possible.")
boss(d, nil, "Magmatus", "Plan: Summoner first, then Magmatus. Pull the elemental away from the group; watch Fire Nova.",
    {adds = {["dark iron summoner"] = 150}, preempt = true})
boss(d, nil, "Plunder", "Plan: clear the corridor, then pull Plunder into a safe corner. Keep knockbacks away from uncleared packs.")
boss(d, nil, "Durgen Dirgehammer", "Plan: clear nearby Looters, then focus Durgen before his golems. Prepare for Fear and heavy tank damage.", {score = 180})

d = dungeon(2999, "Ruins of Lordaeron", method .. "ruins-of-lordaeron")
entry(d, nil, "Ragged Ghoul", 100, false, "First target in ghoul packs; pull back from neighbors.")
entry(d, nil, "Living Monstrosity", 95, false, "Heavy hitter; avoid combining with another pack.")
entry(d, nil, "Flesh Golem", 75, false, "Knockback can pull nearby enemies.")
entry(d, nil, "Skeletal Mage", 55, true, "Caster in mixed skeleton packs.")
boss(d, nil, "Witherfang", "Plan: Witherfang first, then his two adds. Clear the patrol path and handle tank poison.", {score = 180})
boss(d, nil, "The Baron", "Plan: keep the tank near full health before Knockout. Use stuns; fight away from other packs.")
boss(d, nil, "Viktor the Vile", "Plan: start the chimney event with full mana. Conserve through the waves; gather each wave before damage starts.")
boss(d, nil, "The Abandoned", "Plan: prepare for waves, then interrupt or stun Life Drain. Keep the event near the tank.")
boss(d, nil, "Bjork", "Plan: isolate from ghoul packs. Casters wait out Anti-Magic Shield; melee keep attacking.")
boss(d, nil, "Rath'mael", "Plan: interrupt or stun casts and leave Flamestrike immediately.")

d = dungeon(2998, "Excavation Site: Wetlands", method .. "excavation-site-wetlands")
entry(d, nil, "Dragonmaw Warder", 90, false, "Healing reduction; Freedom can remove the net.")
entry(d, nil, "Thicket Matriarch", 85, false, "Heavy physical damage over time.")
entry(d, nil, "Thicket Hunter", 75, false, "Cleanse its disease.")
entry(d, nil, "Young Riptooth", 70, false, "Focus one at a time to reduce tank damage.")
entry(d, nil, "Dragonmaw Saboteur", 60, true, "Avoid bomb landing spots.")
boss(d, nil, "Saltspine", "Plan: pull alone. Dust Storm hurts threat generation; give the tank time before opening up.")
boss(d, nil, "Shadetooth", "Plan: Thicket Hunters first, then Shadetooth. Clear grass before pulling; prepare for Fear and the low-health enrage.",
    {adds = {["thicket hunter"] = 150}, preempt = true})
boss(d, nil, "Highland Horror", "Plan: isolate from slimes. Interrupt regeneration when possible; avoid pulling the surrounding trash.")
boss(d, nil, "Relic Guardian", "Plan: face away from the group; keep a safe backstop. Watch knockback threat loss; ranged avoid close stuns.")

d = dungeon(2959, "City of Dalaran", method .. "city-of-dalaran")
entry(d, nil, "Kirin Tor Necromancer", 95, true, "Raises and empowers adds.")
entry(d, nil, "Mana Phantom", 100, true, "Interrupt Mana Burn.")
entry(d, nil, "Phantasm", 90, true, "Reflection Field can reflect magic.")
entry(d, nil, "Fallen Mage", 55, true, "Use line of sight to gather.")
boss(d, nil, "Atrexis the Grave Knight", "Plan: remove nearby Necromancers before the pull. Control the first adds, then focus Atrexis; gather new skeletons.",
    {adds = {["kirin tor necromancer"] = 150}, preempt = true})
boss(d, nil, "Arcanic Enigma", "Plan: Mana Phantoms first; stop Mana Burn. Dispel Manamorph and manage summoned adds.",
    {adds = {["mana phantom"] = 150}, preempt = true})
boss(d, nil, "Lyn the Ignored", "Plan: control raised undead, interrupt the volley and remove Curse of Thorns from the tank.")
boss(d, nil, "Arcane Anomaly", "Plan: avoid the rotating Focal Blast beam; give the tank room to position.")
boss(d, nil, "Unstable Sentinel", "Plan: face away from the party. Ranged stay outside Malfunction's damage area.")
boss(d, nil, "Fel Ancient", "Plan: move away from poison pools before roots trap you. Freedom can help with Entangle.")
boss(d, nil, "Mana Devourer", "Plan: start with mana available; sustained mana drain makes this a short, focused fight.")
boss(d, nil, "Shade of the Archmage", "Plan: dodge the mana orb both ways. Expect group Polymorph before Evocation; regroup and resume damage.")

d = dungeon(2970, "The Drowned City", method .. "the-drowned-city")
entry(d, nil, "Saltseer Coronor", 100, true, "Stop Healing Wave and Chain Lightning.")
entry(d, nil, "Profane Necromancer", 95, true, "Stop Conjure Spirit.")
entry(d, nil, "Brinescale Sorceress", 90, true, "Stop Fear to avoid extra pulls.")
entry(d, nil, "Brinescale Priestess", 100, true, "Heals the boss and allies.")
entry(d, nil, "Chasm Crawler", 75, false, "Heavy physical hits; avoid armor-reduction stacks.")
boss(d, nil, "Var'Taka", "Plan: kill or crowd-control the two Priestesses before Var'Taka. Interrupt heals; face the boss away from the party.",
    {adds = {["brinescale priestess"] = 150}, preempt = true})
boss(d, nil, "Zul'Alai", "Plan: move out before Monstrous Slam finishes. Ranged stay back; prepare defensives for the low-health damage increase.")
boss(d, nil, "Primeval Elemental", "Plan: watch your breath underwater; surface or use water breathing. Stay ready for the group slow.")
boss(d, nil, "Captain Dreadrise", "Plan: break Abyssal Bubbles immediately to save trapped players. Interrupt Waterbolt Volley; pull away from other packs.",
    {adds = {["abyssal bubble"] = 160}, preempt = true})
boss(d, nil, "Deathless Marrow", "Manual plan: clear the first add wave, Guardians first; then focus Marrow while controlling later waves. Pin Skull yourself for the phase switch.", {manualOrder = true})
boss(d, nil, "Min'loth the Serpent", "Plan: keep the tank healthy for Drench; recover during Deluge. In serpent phase, cleanse poison promptly and prepare for Fear.")

d = dungeon(3039, "Krol'dok Stronghold", method .. "kroldok-stronghold")
entry(d, nil, "Twilight Grunt", 95, false, "Dangerous group melee damage; use stuns.")
entry(d, nil, "Krol'dok Shaman", 100, true, "Interrupt casts; Bloodlust empowers nearby melee.")
entry(d, nil, "Krol'dok Centurion", 85, false, "Mortal Strike reduces healing.")
-- Non-elite Peons are deliberately NOT marking candidates, even though dangerous.
d.unmarkedTip = "Twilight Peons are non-elites: stun or slow runners. TankKit will never mark them."
entry(d, nil, "Snarlfang", 90, false, "Ashka's fixating pet.")
entry(d, nil, "Terrorhowl", 90, false, "Ashka's fixating pet.")
boss(d, nil, "Slavecrusher Grox", "Plan: clear space before pulling; kill called prisoners. Prepare for Bloodlust and tank stuns.", {addsFirst = true, preempt = true})
boss(d, nil, "Twilight Commander Zarmok", "Plan: clear Grunts before engaging Zarmok. Melee watch his area damage; prepare for low-health Enrage.")
boss(d, nil, "War Handler Ashka", "Plan: Snarlfang and Terrorhowl first, then Ashka. Stun fixating pets; be ready to protect threatened party members.",
    {adds = {["snarlfang"] = 150, ["terrorhowl"] = 150}, preempt = true})
boss(d, nil, "Nar'gurk", "Plan: clear or control escorts first. Handle mind-controlled players carefully; avoid killing them with burst damage.", {addsFirst = true, preempt = true})
boss(d, nil, "Bossman Toof", "Plan: kill his Shamans first, then Toof. Control extra Brutes; avoid being trapped in endless add clearing.",
    {adds = {["krol'dok shaman"] = 150}, preempt = true})
boss(d, nil, "Overlord Mugg", "Plan: Centurions first, then Mugg. Reduce incoming physical damage and prepare for harder weapon phases.",
    {adds = {["krol'dok centurion"] = 150}, preempt = true})

d = dungeon(43, "Wailing Caverns", method .. "wailing-caverns")
entry(d, 3840, "Druid of the Fang", 95, true, "Interrupt healing and sleep.")
entry(d, nil, "Deviate Shambler", 85, true, "Interrupt regeneration.")
entry(d, nil, "Deviate Dreadfang", 90, true, "Interrupt or stun Fear.")
boss(d, 3671, "Lady Anacondra", "Plan: pull away from surrounding mobs. Interrupt heals and sleep; avoid collecting extra packs.")
d.byName["lady andacondra"] = d.byID[3671]
boss(d, 3669, "Lord Cobrahn", "Plan: clear the small snakes quickly without marking them. Interrupt healing and sleep; prepare for Serpent Form.")

d = dungeon(33, "Shadowfang Keep", method .. "shadowfang-keep")
entry(d, nil, "Lupine Horror", 100, true, "Kill before summons accumulate.")
entry(d, nil, "Wailing Guardsman", 95, true, "Repeated melee-range silence.")
entry(d, nil, "Haunted Servitor", 75, true, "Curse summons additional ghosts.")
boss(d, 4278, "Commander Springvale", "Plan: Guardsman first, then Servitor, then Springvale. Prevent silence and interrupt heals; wait out his shield.",
    {adds = {["wailing guardsman"] = 160, ["haunted servitor"] = 150}, preempt = true})
boss(d, 3914, "Rethilgore", "Plan: remove accompanying adds, then Rethilgore. Stun to limit Soul Drain.", {addsFirst = true, preempt = true})
boss(d, 3886, "Razorclaw the Butcher", "Plan: kill accompanying adds, then Razorclaw. Watch resource drain on the tank.", {addsFirst = true, preempt = true})

d = dungeon(189, "Scarlet Monastery", calc .. "scarlet-monastery")
boss(d, 3977, "High Inquisitor Whitemane", "Plan: once Mograine returns, Whitemane first, then Mograine. Interrupt her healing and recover quickly after sleep.", {score = 180, preemptBoss = true})
boss(d, 3976, "Scarlet Commander Mograine", "Plan: clear the chapel, then Mograine. After resurrection, switch to Whitemane first; keep mana for both phases.")
boss(d, 3975, "Herod", "Plan: keep the group ready for the trainee wave after Herod falls. Non-elite trainees remain unmarked.")

d = dungeon(289, "Scholomance", calc .. "scholomance")
boss(d, 10504, "Lord Alexei Barov", "Plan: kill the guards before Alexei. Tank away from the group and remove Veil of Shadow when possible.", {addsFirst = true, preempt = true})
boss(d, 10503, "Jandice Barov", "Plan: gather loose illusions; find and focus the real Jandice. Do not follow random illusion marks.", {score = 180})
boss(d, 1853, "Darkmaster Gandling", "Plan: trapped players kill their room's undead and return. The group outside maintains damage on Gandling.", {score = 180})

function PTK:AddDungeon(...) return dungeon(...) end
function PTK:AddPriority(...) return entry(...) end
function PTK:AddBoss(...) return boss(...) end

function PTK:CatalogEntry(instanceID, npcID, name)
    local catalog = self.dungeons[instanceID]
    if not catalog then return nil end
    return (npcID and catalog.byID[npcID]) or (name and catalog.byName[name:lower()])
end

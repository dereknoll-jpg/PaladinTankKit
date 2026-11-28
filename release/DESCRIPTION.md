# Paladin TankKit

**Mark. Track. Protect.**

Paladin TankKit is a clean, minimalist tanking companion built specifically for **Paladins in World of Warcraft: Forever**. Keep your important timers, active protection, target markers and quick encounter guidance together in one compact HUD, with warm light effects and smooth animations.

## Assisted Skull and X marking

Compact **Skull and X buttons stay anchored to the bar**, with a quiet **ASSIST** status. Select your target, then apply the mark yourself through Blizzard's secure marker actions.

- Click Skull or X to set that marker on your selected target.
- Shift-click Skull for X; Ctrl-click either button to clear the selected target's mark.
- Right-click either button to open settings.
- Assign secure Skull/X actions under **Paladin TankKit** in WoW's Key Bindings, or use the game's native **Raid Targeting** bindings.

An optional **priority glow** highlights your selected, readable dangerous elite or observed caster in supported dungeon parties. It respects existing markers and stays off for non-elites, raids and world bosses. Mouseover can scout casters, but never selects or marks enemies.

**Every mark requires your click or keypress.** There is no automatic marking or automatic X-to-Skull promotion. Manual controls follow native targeting rules and can mark non-elites too; the elite filter applies to priority advice. Group permissions and client restrictions still apply. Native Raid Targeting bindings remain the fallback.

## Important timers, one clean timeline

The sliding rail keeps five independent trackers:

- **Active Seal:** follows your current Seal's buff expiration. Judgement and hit procs do not restart it.
- **Consecration:** tracks the ground-effect duration, with remaining cooldown shown separately when applicable.
- **Hammer of Justice:** tracks its cooldown after use.
- **Holy Shield:** tracks its active protection duration, including readable early removal.
- **Templar's Bulwark:** tracks its cooldown when learned and used.

Inactive abilities stay hidden. Readable Blizzard buff and cooldown information takes priority. When combat hides timing data, supported trackers can retain a bounded remembered deadline or confirmed-cast estimate, marked **~**. Expired or untimed effects do not leave question-mark placeholders on the rail. Ability artwork stays full-colour.

## Protection at a glance

Small fixed icons above the bar show **Iron Creed**, **Shieldsworn spell block**, **Bulwark's active shield** and **Forbearance** while active, without adding more sliding timers.

- Optional amber edges emphasize the final two seconds of observed Iron Creed and spell-block protection.
- An optional Bulwark fill shows readable absorb remaining relative to the largest amount observed for that application. It hides when values are concealed and never guesses shield strength from health.
- Forbearance awareness flags Bulwark's cooldown while locked out and explains affected learned self-protection abilities on hover.
- A silent personal **Cleanse/Purify reminder** appears for readable, client-filtered removable debuffs matching your learned spell.

These features have individual controls. Reduced Motion keeps expiration lighting steady and makes absorb-fill changes immediate.

## Useful reminders for Paladin tanks

Grouped Paladins assigned Tank receive a prominent warning when **Righteous Fury** or **Devotion Aura** is confirmed missing. Another group Paladin's Devotion counts when its buff reaches you at an equal or higher spell rank. Unknown coverage does not trigger a guessed loss warning.

Party dungeons can play one debounced alert sound per missing tank-buff episode. Audio is independently configurable.

An optional **missing-shield reminder** warns assigned group tanks to equip a shield. Separate durability warnings cover an equipped shield at **20% durability or below**, including a broken-shield warning. No missing-Seal or low-mana alerts.

## Compact boss notes and Paladin guidance

Browse **193 selected boss notes across 28 dungeon instance catalogs** in a slim, single-line ribbon. Hover for details, print a plan privately, or explicitly share it with your party. Notes never auto-post to chat.

Fourteen reviewed encounter plans across Deadmines, Hall of Thanes, Ruins of Lordaeron and Wailing Caverns use **Wowhead Forever 1.60.1** sources. Six plans highlight Paladin tools, including Hammer of Justice opportunities, Purify/Cleanse guidance and curse-dispel limitations.

Optional private cues respond to readable casts, engaged adds, selected health crossings and supported personal Leech Poison reminders. They do not predict hidden casts or use retail encounter data. Coverage is selected, rather than a complete dungeon journal; inherited reference or limited-confidence notes remain labeled. Some encounter matching relies on English names.

## Clean, configurable and lightweight

Warm lighting, soft icon edges and fluid transitions keep the interface readable. Background aura readers share snapshots, fallback scans slow between events, and animations update independently.

- **Middle-click any timer, protection badge or cleanse reminder to hide it.**
- Restore individual items in **/ptk > Ability timers** or **Protection**, use **Restore all**, or type **/ptk restore**.
- Adjust scale, move and lock the HUD, enable idle fading, turn effects off, or use **Reduced Motion**.
- Preview the HUD outside combat with **/ptk preview**.
- Preferences are saved per character. Protected HUD movement, scale and visibility changes wait until combat ends.

**Type /ptk to open settings.** Built for the Forever 1.60.1 client, Interface 16001.

**Updating from 1.0.5:** reassign old TankKit marking bindings to the new secure Skull/X actions. Existing keys are never overwritten automatically.

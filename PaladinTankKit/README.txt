Paladin TankKit 1.0.7 - WoW Forever (Interface 16001)
Mark. Track. Protect.

/ptk opens settings. /ptk version prints the currently loaded build.
/ptk markstatus prints the actual marking state, blocker and permission details.
Middle-click an ability timer, protection badge or cleanse reminder to hide it.
Restore items in /ptk > Ability timers or Protection; Restore all or /ptk restore
enables all again. The new status icons stay fixed above the five-icon rail.
Hiding is saved per character and does not stop tracking or cancel a buff.

PROTECTION: Optional final-two-second amber edges emphasize observed Iron Creed
and Shieldsworn expiration. Bulwark can show a soft readable-absorb fill relative
to the largest amount observed for that application, never a health estimate.
Hidden values remove the fill. Both visuals have Protection switches.
Missing shield has a separate Overview switch for assigned group tanks only.

PROTECTION: Iron Creed, Shieldsworn spell block and active Templar's Bulwark use
readable player buffs, with bounded confirmed-cast fallback during hidden combat
timing (~). Holy Strike estimates require learned talents and confirmed Fury/shield
conditions. Forbearance fallback covers Bulwark/self-immunities and proven self BoP.
Readable timing/removal wins; hidden early removal cannot be detected immediately.
Bulwark's remaining absorb appears on hover only when readable. Forbearance moves
above the rail and can flag Bulwark as locked, with affected learned spells on hover.
Personal cleanse is an optional, silent prompt for a client-filtered removable
debuff matching your learned Cleanse/Purify. Each new feature has its own switch.

ENCOUNTER CUES: Fourteen reviewed plans in four dungeons use only Wowhead Forever
1.60.1 sources. Relevant observed casts, engaged adds or health crossings can show
a private cue in the existing ribbon. Disable Encounter cues for manual plans only.
Older reference plans cannot trigger automatic cues. See FOREVER_1_60_1.md.

ASSISTED MARKING: Click the anchored Skull or X to mark your selected target.
Shift-click Skull for X; Ctrl-click either to clear; right-click for settings.
Bind secure Skull/X under WoW Key Bindings > Paladin TankKit, or use the native
Raid Targeting bindings. Reassign old TankKit bindings; keys are not overwritten.
Every mark needs your input. No automatic marks or death promotion.
Group permissions still apply. ASSIST stays quiet; fallback help lives on hover.
Priority glow advises on selected, readable dangerous elites/casters in dungeons.
Existing marks, non-elites, raids and world bosses suppress advice. Disable it in
Dungeon marking. Reduced Motion keeps it steady; Effects Off hides the glow.
Manual secure buttons use native semantics and can mark non-elites too; the
elite filter applies only to advice. They always use target, never mouseover.
HUD movement, scale and visibility changes defer while in combat.
Live secure-click behavior still needs testing on the Forever client.

TIMERS: Active Seal, Consecration, Hammer of Justice, Holy Shield and talented
Templar's Bulwark each own an independent deadline on one horizontal rail.
Real player buff, ground-effect and cooldown timers take priority. A confirmed
requested cast can start a bounded estimate when combat hides timing information.
Seals learn duration separately by Seal name (30-second reference fallback);
Holy Shield uses observed duration or a 10-second reference fallback.
Consecration's cast estimate defaults to 8 seconds, configurable with /ptk ground 8.
Cooldown estimates use observed duration, or 60 seconds for Hammer of Justice and
300 seconds for Bulwark, adjusted by readable relevant talent ranks.
~ means estimated. Hidden resets and early buff removal can make estimates stale.
Readable real timers reconcile during combat. Estimates never prove readiness.
Expired or untimed effects do not leave question-mark placeholders on the rail.
Judgement and Seal hit procs never refresh the Seal. Recasting/switching Seals only
changes its own tracker. Artwork stays full-colour at full artwork opacity.

Read-only post-hooks observe action, spell and macro requests. Pressing alone never
starts a timer; a recent player SENT plus matching success is required for hidden
cast identity. Readable GUIDs are matched; fully hidden payloads use one recent
player request within a bounded interval. Failed/interrupted requests are discarded.
Spell metadata is cached; combat spellbook refreshes are deferred until combat ends.

REMINDERS: Assigned group tanks get larger blinking Righteous Fury and Devotion Aura alerts.
Equal/higher-rank Devotion from another group Paladin counts only while on the player.
Dungeon losses play one debounced sound per episode. Audio has a separate switch.
Unknown rank/caster/coverage does not produce a guessed loss. Reduced Motion stays static.
Optional durability reminders still cover an equipped
shield at 20% durability or below. No missing-Seal or low-mana alerts.
NOTES: 28 instance catalogs, 193 selected boss notes and 58 priority entries.
Notes are a compact one-line ribbon; hover for full text. Sharing is explicit.
Reference/limited-confidence guidance is labeled. Some identities use English names.
/ptk preview shows labeled samples outside combat and never marks or sends chat.
Reduced Motion and Effects Off are available. See SOURCES.md and COVERAGE.md.

Background scans share indexed aura reads within each refresh. Aura and absorb
events refresh immediately; fallback is 1 second idle / .5 seconds in combat,
with .2-second Seal/Holy Shield handoffs. Equipment events bypass shield polling
limits. Animation updates remain smooth and independent.

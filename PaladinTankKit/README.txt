Paladin TankKit 1.0.5 - WoW Forever (Interface 16001)
Mark. Track. Protect.

/ptk opens settings. /ptk version prints the currently loaded build.
/ptk markstatus prints the actual marking state, blocker and permission details.
Middle-click an ability timer, protection badge or cleanse reminder to hide it.
Restore items in /ptk > Ability timers or Protection; Restore all or /ptk restore
enables all again. The new status icons stay fixed above the five-icon rail.
Hiding is saved per character and does not stop tracking or cancel a buff.

PROTECTION: Iron Creed, Shieldsworn spell block and active Templar's Bulwark use
observed player buffs; hidden reads retain only an observed bounded deadline (~).
Bulwark's remaining absorb appears on hover only when readable. Forbearance moves
above the rail and can flag Bulwark as locked, with affected learned spells on hover.
Personal cleanse is an optional, silent prompt for a client-filtered removable
debuff matching your learned Cleanse/Purify. Each new feature has its own switch.

ENCOUNTER CUES: Twelve refreshed plans in four dungeons use only Wowhead Forever
1.60.1 sources. Relevant observed casts, engaged adds or health crossings can show
a private cue in the existing ribbon. Disable Encounter cues for manual plans only.
Older reference plans cannot trigger automatic cues. See FOREVER_1_60_1.md.

Marking is client-dependent. Forever can protect addon SetRaidTarget calls even
outside combat; leadership cannot override this. When blocked, use WoW's native
target-marker bindings or target menu. No automatic-marking bypass is claimed.
LEAD needs leader/assist (tank role is separate); ARM is armed; SET awaits client
confirmation; AUTO is a confirmed visible automatic marker; HOLD lacks readable
data; BLOCK is a native refusal; PAUSE needs attention; MAN is manual-only.

MARKING: Select a living elite in a dungeon party to begin. Mouseover scouts only.
Before combat only the selected elite is seeded; other elites need party engagement.
Dangerous enemies/casters can take opening priority; then Skull stays stable until
confirmed death, with selected boss-add exceptions. Cross promotes after death.
Requires leader/assistant. Raids, world bosses and outdoors remain manual.
Non-elites are never marked. Manual pins and crowd-control marks are respected.

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

# 1.0.2

- Replaced the earlier combat timer flow with independent aura and cast/cooldown tracking modules.
- Added read-only action-button, spell and macro intent observers, including fully hidden combat success payloads and both SENT/post-hook event orders.
- Confirmed requested casts now keep bounded countdowns when combat hides timers; real player buff/cooldown deadlines reconcile as soon as readable.
- Learned Seal durations are stored separately by Seal name. Reference fallback durations are labeled estimates; Judgement and Seal procs never refresh them.
- Prevented late old-Seal and same-Seal snapshots from overriding a fresh recast during handoff.
- Cached spell identity/artwork and deferred combat spellbook rediscovery so hidden metadata cannot erase an active tracker.
- Removed unknown and expired timer placeholders from the rail, retaining full-colour artwork.
- Added per-spell aura secrecy handling, faster resync and a loaded-version message with /ptk version.
- Added 43 focused tests for fully hidden combat, all five simultaneous timers, macros, request ordering, swaps, proc events, failed casts and mid-combat authoritative reconciliation.

# 1.0.1

- Fixed Seal procs being mistaken for recasts and clearing an existing buff timer.
- Added direct player aura lookups by name and spell ID when indexed buff scanning is unavailable.
- Consecration now prefers a readable player buff or ground-effect slot, preserves its independent cast deadline, and recovers missed casts from the ability cooldown start.
- Correlates readable cast requests with the exact successful cast GUID; requests alone never start timers.
- Added cooldown tuple compatibility and recovery through other learned spell ranks.
- Removed greyscale and artwork dimming from cooldown and unknown timer states.
- Added 28 regression checks for overlapping timers, target changes, restricted reads, cast correlation and icon colour.

# 1.0.0

- Automatic dungeon marking now starts from the Paladin's selected living elite. Mouseover and nearby party combat cannot start a queue by themselves.
- Selected targets can receive a pre-pull Skull; other elites join only with readable group engagement. Opening caster/danger priorities can adjust Skull before the queue settles.
- Kept manual overrides, CC protection, elite-only markers, confirmed-death promotion and manual-only raids/world bosses/outdoors.
- Fixed delayed cooldown updates being mistaken for readiness.
- Restored readable ongoing cooldowns after reloads, zoning and death.
- Rebuilt `/ptk` with the original emblem, gold lighting, animated switches and four focused pages.
- Added individual ability visibility and separate Righteous Fury, aura and equipped-shield reminder controls.
- Restyled boss-note buttons. Preview mode includes sample notes and cannot send party chat.
- Kept actual buff expiration for Seals and Holy Shield, talented/used Bulwark cooldowns and the equipped-only 20% shield warning.
- Added release descriptions, updated documentation and a media capture guide.

Automated checks cover simulated client behavior. Native-client visual review and real dungeon behavior should be recorded separately; passing offline checks is not proof of live combat behavior.

# 1.0.7

- Fixed upper protection icons failing to start when the first ability use occurs during combat and WoW hides the buff's numeric timing.
- Added bounded, labeled confirmed-cast estimates for active Templar's Bulwark and its separate Forbearance timer. Readable player-buff timing immediately replaces estimates; readable removal/depletion clears them.
- Added the same combat-start support for Iron Creed and Shieldsworn across all eight verified Holy Strike ranks. Estimates require cached learned talents and the relevant last-confirmed Fury/shield conditions. Random proc notifications and failed or unconfirmed requests cannot start protection.
- Added Forbearance estimates for confirmed self-immunity casts and proven self-targeted Blessing of Protection. Casting Blessing on somebody else, an unknown target or a same-name character on another realm cannot start your lockout timer.
- Retained observed durations when available, with verified duration references and cached Sacred Duty ranks for fallback. Observed Forbearance duration is not reused across a known talent-rank change.
- Added a short application/refresh handoff so an old aura snapshot cannot immediately undo a new confirmed cast. Scans and target changes never restart timers, and recovering a long cooldown never invents an active shield.
- Kept absorb strength and expiration emphasis dependent on real readable data. An estimated Bulwark timer never generates an absorb fill; the ~ prefix distinguishes estimates and remembered timing.
- Preserved independent timers, middle-click hiding/restoration, full-colour artwork, the existing fixed layout and assisted marking.

**Validation:** reproduced the first-cast failure before the fix; all 1,051 automated checks now pass, including 48 new combat-protection cases. Live Forever verification remains needed. Hidden early depletion or removal cannot be detected until the client exposes it; estimates end at their bounded deadline.

# 1.0.6

## Assisted marking

- Replaced automatic marking with compact, anchored secure Skull and X buttons and a quiet **ASSIST** status.
- Click Skull/X to set the selected target's mark; Shift-click Skull for X, Ctrl-click either to clear, and right-click for settings. Repeated clicks set the mark instead of toggling it off.
- Added secure Skull/X actions under **Paladin TankKit** in WoW's Key Bindings. Native **Raid Targeting** bindings remain the fallback. **Reassign old TankKit marking bindings after updating; existing keys are never overwritten.**
- Added optional subtle priority glow for selected, readable dangerous dungeon elites and observed casters. Existing markers, restricted data, non-elites, raids and world bosses suppress advice.
- Every marker change now requires player input. No automatic marks or death promotion occur in normal play. Mouseover only scouts; manual controls follow native selected-target rules, including non-elites.
- Replaced the persistent marking-block warning with help on hover. Group permissions and client restrictions still apply.
- Deferred protected HUD movement, scale and visibility changes until combat ends.

## Protection and reminders

- Added optional amber edges in the final two seconds of observed Iron Creed and Shieldsworn protection. Remembered estimates do not trigger the cue; Reduced Motion keeps it steady and Effects Off suppresses it.
- Added an optional soft absorb fill inside the existing active Bulwark icon. It uses this application's largest observed readable amount as its baseline, hides on secret values or removal, and preserves full-colour spell art. It never estimates capacity from health.
- Added an independent **Missing shield** reminder for grouped, assigned tanks. Equipment events update it immediately. Dead, mounted, solo, other-role and uncertain-equipment states suppress it.
- Added switches for expiration cues and Bulwark fill on **Protection**, and Missing shield on **Overview**, within the existing settings panel.
- Middle-click hiding and all existing restore controls continue to work on timers, protection badges and cleanse reminders.

## Paladin encounter guidance

- Updated six reviewed Forever 1.60.1 plans with Paladin-specific control and dispel guidance, including two additional reviewed plans for **The Baron** and **Viktor the Vile**.
- The reviewed override catalog now contains fourteen plans across four dungeons. Inherited reference notes retain their confidence labels.
- Witherfang and Viktor can show a private Purify/Cleanse cue only when the existing personal reminder detects your readable, removable Leech Poison. No automatic casts or party messages were added.

## Background scanning

- Shared indexed aura snapshots among timer, Devotion, protection and cleanse readers within each refresh. Each event receives a fresh snapshot.
- Kept immediate player aura/absorb updates, with fallback scans every second while idle and every half-second in combat. Seal and Holy Shield handoffs retain faster reconciliation.
- Throttled shield inventory fallback checks between immediate equipment/durability events.
- Kept animation pacing independent from background scans.

**Validation:** all 1,003 automated checks pass, including 34 assisted-marking and 44 protection/scanning checks. Secure clicks, keybindings and native combat data visibility remain client-dependent; offline checks do not replace live-client validation.

# 1.0.5

- Added fixed icons above the existing five-icon timeline for Iron Creed, Shieldsworn spell block, active Bulwark and Forbearance. New protection effects follow observed player buffs, including readable early removal and bounded remembered deadlines when timing is hidden.
- Added readable Bulwark absorb details on hover and optional Forbearance awareness for its existing cooldown and affected learned self-protection spells.
- Added a silent personal Cleanse/Purify reminder for client-filtered removable player debuffs. It respects learned spell capabilities, the Reminders master switch and its own toggle.
- Added a Protection settings page, individual switches, middle-click hiding, Restore all and /ptk restore support. Existing effects and Reduced Motion preferences apply to the new icons.
- Added twelve refreshed plans across four dungeons using Wowhead Forever 1.60.1 sources. Optional private ribbon cues respond to observed casts, engaged adds and selected health crossings; older reference notes cannot trigger these cues.
- Kept the existing sliding timer keys and automatic marking behavior. No loose-Skull/threat-loss alert was added.
- Added protection/cleanse and encounter regression scenarios, expanded hide/restore coverage and updated source/release documentation.

# 1.0.4

- Added middle-click hiding for all five ability timers and Forbearance, using saved per-character visibility settings without clearing tracking.
- Added restoration through individual Ability timers switches, a Restore all button and /ptk restore, plus tooltip guidance.
- Added 58 focused checks for hiding during combat, independent settings, tracking preservation and both restore controls.
- Added CurseForge packaging metadata and curated release notes for tagged release builds.

- Corrected the AUTO badge: it now requires a confirmed, currently readable automatic marker instead of merely an armed queue.
- Added LEAD, ARM, SET, HOLD and BLOCK states with live tooltip reasons and /ptk markstatus diagnostics.
- Clarified that assigned tank role does not satisfy TankKit's leader/assistant ownership policy.
- Normalized zero and nil unmarked results and fixed pre-pull retargeting stranding an unmarked queue.
- Detects ADDON_ACTION_BLOCKED / ADDON_ACTION_FORBIDDEN for marker writes, including a native refusal that does not throw a Lua error. Stops retries and never records phantom successful markers.
- A client-protected marking refusal is not repairable by leadership or /ptk resume. Direct users to Blizzard's own target-marker controls in that state.
- Removed Bindings.xml from the normal TOC XML list; it remains available to WoW's dedicated bindings loader.
- Added 25 regression checks for reporting, permissions, zero markers, pre-pull retargeting and refused marking actions.

# 1.0.3

- Missing Righteous Fury now gets a larger blinking orange warning and soft glow while grouped and assigned the tank role (or legacy main-tank assignment).
- Added the same alert for missing Devotion Aura. Another active aura type no longer substitutes for Devotion.
- Suppresses Devotion warnings when another group Paladin's aura is actually on the player and its rank is equal to or higher than the tank's best learned rank.
- Adds one debounced alert sound per missing-buff episode in party dungeons, with a separate sound toggle. No repeated sound spam for a continuously missing buff.
- Keeps unknown role, aura rank, caster or coverage data from creating false loss alerts. Death, mounting, solo play, other roles and preview mode suppress tank-buff alerts.
- Reduced Motion retains the stronger text/glow without blinking. Existing reminder switches remain independent.
- Updated reminder validation with 51 assigned-role, rank, caster, range, suppression, blink and audio checks.

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

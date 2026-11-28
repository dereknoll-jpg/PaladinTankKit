# Paladin TankKit 1.0.6

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

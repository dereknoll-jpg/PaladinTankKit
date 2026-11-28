# 1.0.6 assisted marking validation

Offline validation covers production-default ASSIST status, two SecureActionButtonTemplate controls, fixed selected-target raidtarget actions, modifier-independent CLICK keybindings, no ordinary marker writes from events/ticks/commands/deaths, existing-marker protection for advice, non-elite/raid/world-boss advice suppression, hidden identity, caster scouting, optional effects, Reduced Motion, and deferred combat layout changes.

Historical queue tests still run in explicitly labeled legacy fixtures, with assisted mode disabled only within those fixtures. The live addon defaults to assisted mode; no saved option or slash command enables the old queue. The production OnUpdate loop only updates read-only advice.

Before publishing, test on Forever 1.60.1:

1. Reload out of combat. Verify /ptk version reports 1.0.6 and the bar reads ASSIST.
2. Select an enemy; click Skull twice. It should retain Skull. Click X, Shift-click Skull, and Ctrl-click either. Only the selected target should change.
3. Repeat during combat with appropriate group permission. No protected-action error should appear. If refused, verify native Raid Targeting keybindings and report the exact error.
4. Assign the new secure actions in Key Bindings > Paladin TankKit. Test unmodified and modified keys. Shift-bound Skull must remain Skull; Ctrl-bound X must remain X.
5. Check an unmarked selected dungeon caster: soft priority glow. Existing CC markers, non-elites, raids and world bosses suppress advice. Mouseover alone never marks.
6. Disable Priority glow, Effects, and enable Reduced Motion independently. The secure buttons should remain functional.
7. Verify missing Fury/Devotion alerts and all five timers still work alongside protection badges.
8. Try scale/move/visibility changes during combat. Protected layout should stay stable and apply after combat.

No live-game click/keybinding result is claimed by the offline suite. No GitHub release or CurseForge upload is performed by this build step.

## Protection polish and scanning

Additional offline tests cover observed-only expiration cues, hidden/zero/refreshed absorb values, per-application observed capacity, smooth/static fill updates, middle-click hiding, assigned-role/equipment gates, immediate inventory and absorb events, one shared indexed helpful snapshot per refresh, fresh snapshots on events, other-unit event isolation and adaptive polling intervals. Live review is still needed for aura-point updates, colour/legibility and these six encounter tips.

Test the new Protection toggles and Overview Missing shield switch. Verify actual Bulwark consumption updates its fill without dimming spell art. Exercise rapid Seal swaps and Holy Shield recasts during overlapping timers to confirm event-based updates and fast handoff fallback remain correct.

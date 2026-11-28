# 1.0.7 combat protection validation

The new regression reproduced failure of the first Bulwark cast in fully hidden combat before the fix. Afterward, the full suite passes 1,051 checks, including 48 dedicated cases covering first-use combat Bulwark, Forbearance, both Holy Strike effects/all eight ranks, independent expiry, readable reconciliation/removal, secret timestamps/points, failed/unconfirmed/foreign casts, Fury/shield/talent conditions, self-versus-ally Blessing targets, realm-qualified identities, stale refresh snapshots, short application handoffs, immediate zero-absorb removal, cooldown-only recovery, hide/restore and death cleanup.

Live verification: reload outside combat and confirm version 1.0.7. Enter combat without pre-casting Bulwark, then use it. The upper Bulwark and Forbearance icons should appear independently of the cooldown rail. Use Holy Strike with Iron Creed/Shieldsworn learned, Fury active and a shield equipped; both six-second badges should initialize. ~ means confirmed-cast or remembered timing while native deadlines are hidden. Verify real buff deadlines replace estimates and readable depletion/removal clears them. Absorb fill stays hidden until real points are readable. Also test middle-click hide and /ptk restore during combat.

No screen/HUD layout changes or external publication are part of this fix.

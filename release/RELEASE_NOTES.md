# Paladin TankKit 1.0.7

- Fixed upper protection icons failing to start when the first ability use occurs during combat and WoW hides the buff's numeric timing.
- Added bounded, labeled confirmed-cast estimates for active Templar's Bulwark and its separate Forbearance timer. Readable player-buff timing immediately replaces estimates; readable removal/depletion clears them.
- Added the same combat-start support for Iron Creed and Shieldsworn across all eight verified Holy Strike ranks. Estimates require cached learned talents and the relevant last-confirmed Fury/shield conditions. Random proc notifications and failed or unconfirmed requests cannot start protection.
- Added Forbearance estimates for confirmed self-immunity casts and proven self-targeted Blessing of Protection. Casting Blessing on somebody else, an unknown target or a same-name character on another realm cannot start your lockout timer.
- Retained observed durations when available, with verified duration references and cached Sacred Duty ranks for fallback. Observed Forbearance duration is not reused across a known talent-rank change.
- Added a short application/refresh handoff so an old aura snapshot cannot immediately undo a new confirmed cast. Scans and target changes never restart timers, and recovering a long cooldown never invents an active shield.
- Kept absorb strength and expiration emphasis dependent on real readable data. An estimated Bulwark timer never generates an absorb fill; the ~ prefix distinguishes estimates and remembered timing.
- Preserved independent timers, middle-click hiding/restoration, full-colour artwork, the existing fixed layout and assisted marking.

**Validation:** reproduced the first-cast failure before the fix; all 1,051 automated checks now pass, including 48 new combat-protection cases. Live Forever verification remains needed. Hidden early depletion or removal cannot be detected until the client exposes it; estimates end at their bounded deadline.

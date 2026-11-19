# Paladin TankKit — WoW Forever

**Mark. Track. Protect.** A compact Paladin tank companion for Forever Interface **16001**. Current build: **1.0.1**.

## Install

Download this repository, then copy its inner `PaladinTankKit` folder into the game's `Interface/AddOns` folder. The resulting path should be `Interface/AddOns/PaladinTankKit/PaladinTankKit.toc`. Restart WoW after adding the addon. Developers can run `npm ci` and `npm run package` to build `dist/PaladinTankKit-1.0.1.zip`. Generated archives and local installation backups are excluded from this repository.

![Paladin TankKit settings](release/media/gallery/01-overview.png)

[View the in-game Preview animation](release/media/gallery/06-in-game-preview-under-2MB.gif). The sample timers are visibly labeled Preview; this is not dungeon combat footage.

The AddOns list now uses the project's original gold shield-and-hammer emblem, supplied as a game texture in `Media/AddonIcon.tga`. The matching CurseForge upload is `Branding/PaladinTankKit-CurseForge-400.png`; the master and small-size previews are alongside it. `scripts/export-branding.ps1` regenerates the PNG exports and game texture from the master. Spell timers retain their actual ability artwork.

Type `/ptk` for the redesigned settings: Overview, Ability timers, Dungeon marking and Appearance. Each tracked ability and each reminder has its own switch. Unlock the anchor to move it, then lock it. Bind **Mark Pull**, **Mark Skull**, **Cross** and **Clear** in WoW's Key Bindings under Paladin TankKit. Existing bindings are never changed. Settings are saved per character; other classes do not run the toolkit.

## Timers and motion

Version 1.0.1 adds direct player aura lookups by name and ID alongside indexed scanning. Seal procs never clear or restart the buff timer. Readable cast requests are matched to the exact successful cast GUID; a request alone never starts a timer. Player buff snapshots are refreshed by aura/cast/lifecycle events and periodic resync, not target or nameplate changes. Every displayed timer retains full-colour spell artwork and full artwork opacity; cooldown and unknown states use their countdown labels instead of greyscale.

The HUD is a **520 × 42 single horizontal rail**. Timers move right to left. Icons separate when their remaining times coincide; small ticks retain the actual active-effect positions. Effects beyond the selected horizon wait at the right edge while the countdown continues in minutes:seconds.

- **Seal:** uses the active buff's expiration and duration reported by Blizzard, updating the icon and tooltip with it. Covers Fury, Righteousness, the Crusader, Justice, Light, Wisdom and Command and their listed ranks. A readable active Seal also restores tracking after loading. Judgement and hits have no special Seal timer handling: neither clears nor restarts it. Casting a Seal identifies it but does not invent a duration while waiting for the buff update.
- **Consecration:** prefers a readable player buff or ground-effect slot, with a cast-based duration estimate as a fallback. A missed cast event can recover from the ability cooldown's start. Target changes, Seals and Judgement do not clear or restart it. Once the ground effect ends, a remaining readable cooldown can continue on the rail.
- **Hammer of Justice:** appears after your successful cast and tracks the actual cast rank's readable cooldown, including cooldown adjustments exposed by WoW.
- **Holy Shield:** shows the actual remaining buff duration after use or when Blizzard exposes the active buff. Readable early buff removal clears it, including when its charges have been consumed. Casting alone supplies no assumed duration. This is a buff timer; it does not add a charge counter or idle reminder.
- **Templar's Bulwark:** appears only when the ability is learned through its talent and after use, or when an ongoing readable cooldown is recovered. Tracks Blizzard's actual cooldown, including readable talent reductions. Removing the talent clears its tracking. No fixed cooldown is assumed.
- Completed readable cooldowns briefly light up **Ready**, then disappear. Unused spells have no placeholder icon. Ready describes cooldown only; it does not promise mana, range or cast eligibility.
- **Forbearance:** appears as a small badge only while active or covered by a remembered duration.
- Quiet reminders cover learned Righteous Fury and having no Paladin aura selected while grouped or targeting an enemy. Missing Seals never trigger a reminder. Any selected Paladin aura is accepted, using Blizzard's stance-bar selection rather than another Paladin's buff. No learned auras, uncertain selection data, death, mounting and idle solo play suppress the aura reminder. Aura selection changes update it immediately.
- **Shield durability:** a quiet text warning appears at **20% or less**, only when the item equipped in your offhand is a shield. At zero durability it reads **Shield broken**. Empty slots, offhand weapons, held items and shields in your bags do not qualify. Repairs and equipment changes refresh the warning immediately. It can appear while solo so you can repair before a pull. Missing/hidden item data produces no guessed warning. Separate reminder controls are in the Overview page; death and mounting suppress it.

Soft halos, short trails, a reveal sweep, eased refresh motion, subtle expiry breathing and confirmed-marker feedback add motion without enlarging the rail. **Reduced Motion** removes pulses, scaling and decorative travel. **Effects Off** removes decorative light layers. Idle fading, scale (75–150%), 15/30/60-second horizon and other controls are in settings. `/ptk preview` shows clearly labeled sample timers outside combat and ends upon combat entry.

The motion study's light treatment carries into the native icons: softly rounded artwork, a fine warm rim, shaded inner edges, a gentle face highlight and an outside glow that remains visible around opaque spell art. The original game icon texture is preserved, including when the active Seal changes. Countdown numbers use a light sans-serif face with a small dark shadow. The rail fades at its ends. Reduced Motion retains static lighting; Effects Off keeps a quiet icon frame. All five timers share the same rail; the 20-unit timer tiles and 42-unit HUD height are unchanged.

**~ means estimated. ? means unavailable information.** Seals have no fixed-duration cast estimate. Only a previously readable Blizzard buff expiration can continue as an estimate while hidden; a newly cast Seal with unavailable buff timing shows ?. Swapping Seals cannot carry over the previous Seal's expiration. Readable buff removal clears its timer, including in combat. Consecration still defaults to an 8-second ground estimate; `/ptk ground 12` changes only that estimate. Previously readable cooldown timing can continue as an estimate while hidden, but its expiration cannot falsely trigger Ready. Estimates can become stale if a buff ends while hidden. Unused abilities stay hidden. Loading screens and death clear cast estimates; readable ongoing cooldowns are recovered from Blizzard.

## Marking

Automatic marking starts only after you select a readable, living elite in a dungeon party. Mouseover can scout and remember observed casters, but cannot start a marking queue. Nameplates, nearby combat and party targets alone cannot start one either.

Before combat, the selected elite can receive Skull. Other elites join when readable group engagement is confirmed. During a short opening priority check, a dangerous enemy or caster can take Skull. After that, Skull stays stable until confirmed death, with selected encounter-specific add exceptions. Cross promotes only after confirmed death; losing a nameplate is not a death notification.

Leader/assistant is TankKit's single-owner policy. A quiet alert requests leadership when missing. **Raids, world bosses and outdoor encounters remain manual.** Non-elites are never marked. Marking never changes your selected target.

Manual pins, visible existing Skull/Cross marks and crowd-control markers are respected. Hidden/refused information or conflicting mark changes can pause the queue; `/ptk resume` retries while preserving visible marks. Readable identity is rechecked before applying each mark. Unverified reference entries do not contribute special priority scores.

Click Skull to pin Skull, Shift-click for Cross, Ctrl-click to clear/pause, and right-click for settings. Explicit manual clicks use mouseover first, then your target. `/ptk pull` starts from your selected eligible target immediately. `WAIT` means select an elite, `AUTO` means an armed queue, `PAUSE` needs attention, and `MAN` means manual-only mode.
## Boss notes and coverage

The catalog includes **28 dungeon instances, 193 selected boss notes and 58 named priority enemies**, covering the original eleven and seventeen additional instance catalogs. Wing groups such as Blackrock Spire, Dire Maul and Stratholme share instance catalogs. See [COVERAGE.md](PaladinTankKit/COVERAGE.md) for the generated inventory and [SOURCES.md](PaladinTankKit/SOURCES.md) for research and confidence.

Target a supported boss to reveal **Notes**. Notes start collapsed and open as a **720 × 28 single-line ribbon**. Hover for the full note if it is clipped. Opening notes sends no chat. Click **Share** or use `/ptk share` to explicitly send a short party plan, limited to once per 15 seconds. `/ptk notes` prints the current plan privately.

This is selected encounter coverage, not a complete dungeon journal. Some notes and mob identities use exact English names; full localization is not claimed. Sunken Temple's inherited tactics are explicitly labeled **Classic reference**. Several Shaper's Terrace entries have limited-confidence preparation notes and manual ordering. Unconfirmed inherited dungeon availability is recorded in the source ledger. Unsupported bosses receive no invented strategy; generic elite/caster marking still works in eligible dungeons.

## Commands

| Command | Action |
| --- | --- |
| `/ptk` | Settings |
| `/ptk on` / `/ptk off` | Enable / disable tank mode |
| `/ptk auto` | Toggle dungeon automatic marking |
| `/ptk pull` | Seed marking with current elite target |
| `/ptk resume` | Reset paused queue |
| `/ptk notes` | Private boss plan |
| `/ptk share` | Share current plan to party |
| `/ptk unlock` / `/ptk lock` | Move / lock display |
| `/ptk preview` | Labeled sample timers outside combat |
| `/ptk reset` | Default position and scale |
| `/ptk ground 8` | Ground estimate, 4–20 seconds |

## Development and validation

`npm test` checks Lua 5.1 syntax, loading, bindings, non-Paladin isolation, marking rules, restricted-data handling, catalogs, timer tracking, geometry, animation state and all nine shipped textures using a mocked client. `npm run media` regenerates original TGA light textures; `npm run preview:skin` creates a browser material check using those textures, with optional local example icon references. The browser check uses representative WoW artwork and is not a live-client capture. Reference artwork is not shipped with the addon. `node scripts/catalog-report.cjs` regenerates the coverage inventory. `npm run package` builds the versioned ZIP from the TOC. Old versioned archives remain available.

**Validation:** offline checks pass. Native UI capture and real dungeon validation are recorded separately in the release files. Confirm spell icons and durations, Hammer of Justice cooldown updates, overlapping timers, reduced motion, marking permissions and boss notes in the live Forever client. The browser file in `previews` is a cosmetic motion study with substitute glyphs, not an in-game screenshot. WoW supplies the actual spell artwork.

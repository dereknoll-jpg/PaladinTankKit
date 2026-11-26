# Paladin TankKit — WoW Forever

**Mark. Track. Protect.** A compact Paladin tank companion for Forever Interface **16001**. Current build: **1.0.5**.

## Install

Download this repository, then copy its inner `PaladinTankKit` folder into the game's `Interface/AddOns` folder. The resulting path should be `Interface/AddOns/PaladinTankKit/PaladinTankKit.toc`. Restart WoW after adding the addon. Developers can run `npm ci` and `npm run package` to build `dist/PaladinTankKit-1.0.5.zip`. Generated archives and local installation backups are excluded from this repository.

![Paladin TankKit settings](release/media/gallery/01-overview.png)

[View the in-game Preview animation](release/media/gallery/06-in-game-preview-under-2MB.gif). The sample timers are visibly labeled Preview; this is not dungeon combat footage.

The AddOns list now uses the project's original gold shield-and-hammer emblem, supplied as a game texture in `Media/AddonIcon.tga`. The matching CurseForge upload is `Branding/PaladinTankKit-CurseForge-400.png`; the master and small-size previews are alongside it. `scripts/export-branding.ps1` regenerates the PNG exports and game texture from the master. Spell timers retain their actual ability artwork.

Type `/ptk` for the redesigned settings: Overview, Ability timers, Dungeon marking and Appearance. Each tracked ability and each reminder has its own switch. Unlock the anchor to move it, then lock it. Bind **Mark Pull**, **Mark Skull**, **Cross** and **Clear** in WoW's Key Bindings under Paladin TankKit. Existing bindings are never changed. Settings are saved per character; other classes do not run the toolkit.

## Timers and motion

Middle-click an ability timer, protection badge or cleanse reminder to hide it. Restore individual items in `/ptk` > **Ability timers** or **Protection**, click **Restore all**, or type `/ptk restore`. Preferences are saved per character; enabling a timer does not display inactive effects.

The combat tracking flow uses separate player-aura and cast/cooldown trackers. Each ability owns an independent deadline. Changing targets, Judgement, Seal procs and updates to another ability cannot restart it.

- **Seals:** one selected Seal at a time. Real player buff expiration wins. A confirmed requested cast starts a fallback countdown using that Seal's previously observed duration, or a 30-second reference default if no duration has been observed. Neither Judgement nor hit procs refresh it. A brief handoff prevents the previous Seal or a stale same-Seal snapshot from undoing a recast.
- **Consecration:** uses a readable player ground-effect slot or buff timer when possible. Otherwise it counts the successful cast's configured ground lifetime (8 seconds by default). A readable ability cooldown start can recover a missed cast. Ground lifetime and remaining cooldown are distinct.
- **Hammer of Justice:** readable ability cooldown, otherwise an independent successful-cast estimate. Previously observed cooldown duration is preferred; the default is 60 seconds, reduced by readable Improved Hammer of Justice ranks.
- **Holy Shield:** readable player buff duration, otherwise a bounded successful-cast estimate using its observed duration or a 10-second reference default. Readable buff removal clears it after the cast handoff. Hidden early charge consumption cannot be detected until the client exposes it.
- **Templar's Bulwark:** only when learned and used, or an ongoing readable cooldown is recovered. Readable cooldown duration is preferred; fallback is previously observed duration, or 300 seconds reduced by readable Sacred Duty ranks.
- **Forbearance:** a small badge while a timed player effect is available.

Version **1.0.5** adds a fixed row above the existing five-icon timeline: Iron Creed, Shieldsworn's spell-block window, active Templar's Bulwark and Forbearance. These use observed player buff deadlines, clear on readable early removal, and never slide along the rail. Hidden reads retain only a previously observed bounded deadline, marked `~`. Bulwark's remaining absorb is shown on hover only when readable; it is never guessed from maximum health. Forbearance awareness flags the existing Bulwark cooldown and lists affected learned self-protection spells. Its badge and awareness switch are independent.

An optional fixed personal cleanse reminder uses client-filtered removable debuffs and your learned Cleanse/Purify capabilities. It never prompts for curses, Forbearance or unreadable data, never casts for you, and adds no sound. The Reminders master switch also controls it. The Protection settings page provides individual switches; Reduced Motion and effects preferences apply to all status icons.

**A leading `~` means estimated timing.** Cast estimates are replaced by readable client deadlines without waiting for combat to end. Estimates are not proof of readiness, and can be stale after a hidden reset or early buff removal. Timers with no usable deadline, and expired estimates, do not leave question-mark icons on the rail.

Read-only secure post-hooks observe spell, action-button and macro requests. A request alone does not start a timer: it must be followed by player SENT and a matching successful cast. Readable cast GUIDs are matched when available; fully hidden payloads use the single recent player request within a bounded interval, as in the supplied Tankadin Line reference. Failed/interrupted requests are discarded. Hooks never cast, replace secure behavior or change targets. Spell identity/artwork and observed buff durations are cached before combat restrictions; spellbook refreshes are deferred during combat.

The HUD remains a **520 × 42 horizontal rail**. Timers move right to left, separate when they coincide, and keep full-colour artwork at full artwork opacity. Soft light, trails and transitions remain optional. Reduced Motion removes decorative pulses and scaling; idle fading never applies during combat. `/ptk preview` shows labeled sample timers outside combat; `/ptk version` prints the currently loaded version.

Grouped Paladins assigned **Tank** (or legacy Main Tank) get larger blinking orange warnings for missing **Righteous Fury** and **Devotion Aura**. Selecting another aura does not satisfy the Devotion reminder. Another group Paladin can provide coverage only when their Devotion buff is on you and its spell rank is equal to or higher than your best learned Devotion rank. Lower-rank or out-of-range coverage does not suppress the warning. Unreadable rank/source/coverage data is treated as uncertain, not proof of a missing aura. Rank comparison covers the seven cataloged Devotion ranks; it does not compare another player's talent-enhanced armor amount.

Inside a party dungeon, a confirmed missing tank buff plays one sound after a short debounce. Persistent absence does not repeat the sound; confirmed restoration rearms it. A readable gap does not rearm an already sounded episode. The Overview page has independent reminder switches and a Dungeon alert sound switch. Reduced Motion keeps a strong static warning. Buff alerts are suppressed while solo, unassigned, in another role, dead, mounted or previewing. Raid tank warnings remain visual. Equipped-shield durability reminders still work separately, including solo. Missing Seals and low mana do not produce alerts.
## Marking

**Client-dependent:** TankKit can only apply automatic markers when WoW permits addon marker writes and exposes the needed target information. Forever reports show that `SetRaidTarget` can be protected, including outside combat. Leader status cannot override a protected-function restriction. If the client blocks the action, TankKit stops retrying and directs you to WoW's native target-marker keybindings or target menu. Automatic marking and automatic death promotion are not guaranteed on a restricted client.

The marker badge now reports verified state: `LEAD` requests leader/assistant; `WAIT` needs an eligible selection; `ARM` has selected an elite; `SET` awaits marker confirmation; `AUTO` has a confirmed visible automatic marker; `HOLD` lacks readable/visible data; `PAUSE` needs attention; `BLOCK` is a client refusal; `MAN` is manual-only. The tooltip explains the current state. `/ptk markstatus` prints the build, reason, auto setting, grouping, leadership, tank role and target eligibility without printing a unit GUID. Being assigned Tank is separate from TankKit's leader/assistant policy.

Automatic marking starts only after you select a readable, living elite in a dungeon party. Mouseover can scout and remember observed casters, but cannot start a marking queue. Nameplates, nearby combat and party targets alone cannot start one either.

Before combat, the selected elite can receive Skull. Other elites join when readable group engagement is confirmed. During a short opening priority check, a dangerous enemy or caster can take Skull. After that, Skull stays stable until confirmed death, with selected encounter-specific add exceptions. Cross promotes only after confirmed death; losing a nameplate is not a death notification.

Leader/assistant is TankKit's single-owner policy. A quiet alert requests leadership when missing. **Raids, world bosses and outdoor encounters remain manual.** Non-elites are never marked. Marking never changes your selected target.

Manual pins, visible existing Skull/Cross marks and crowd-control markers are respected. Hidden/refused information or conflicting mark changes can pause the queue; `/ptk resume` retries while preserving visible marks. Readable identity is rechecked before applying each mark. Unverified reference entries do not contribute special priority scores.

Click Skull to pin Skull, Shift-click for Cross, Ctrl-click to clear/pause, and right-click for settings. Explicit manual clicks use mouseover first, then your target. `/ptk pull` starts from your selected eligible target immediately. `WAIT` means select an elite, `AUTO` means an armed queue, `PAUSE` needs attention, and `MAN` means manual-only mode.
## Boss notes and coverage

The catalog includes **28 dungeon instances, 193 selected boss notes and 58 named priority enemies**, covering the original eleven and seventeen additional instance catalogs. Wing groups such as Blackrock Spire, Dire Maul and Stratholme share instance catalogs. See [COVERAGE.md](PaladinTankKit/COVERAGE.md) for the generated inventory and [SOURCES.md](PaladinTankKit/SOURCES.md) for research and confidence.

Target a supported boss to reveal **Notes**. Notes start collapsed and open as a **720 × 28 single-line ribbon**. Hover for the full note if it is clipped. Opening notes sends no chat. Click **Share** or use `/ptk share` to explicitly send a short party plan, limited to once per 15 seconds. `/ptk notes` prints the current plan privately.

This is selected encounter coverage, not a complete dungeon journal. Some notes and mob identities use exact English names; full localization is not claimed. Sunken Temple's inherited tactics are explicitly labeled **Classic reference**. Several Shaper's Terrace entries have limited-confidence preparation notes and manual ordering. Unconfirmed inherited dungeon availability is recorded in the source ledger. Unsupported bosses receive no invented strategy; generic elite/caster marking still works in eligible dungeons.

The new private encounter cues use twelve refreshed plans across The Deadmines, Hall of Thanes, Ruins of Lordaeron and Wailing Caverns, checked against Wowhead **Forever 1.60.1** pages. They respond only to readable casts, engaged adds or observed health crossings, without predicted cast schedules or automatic chat. Disable **Dungeon marking > Encounter cues** to keep plans manual. Older catalog plans retain their existing confidence labels and cannot generate these automatic cues. See [the source ledger](PaladinTankKit/FOREVER_1_60_1.md) for precise coverage and limitations.

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

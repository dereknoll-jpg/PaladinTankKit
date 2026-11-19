# Dungeon catalog sources

Research checked **November 18, 2026**. These are original, brief recommendations derived from published Forever guides. They are **guide-backed, not personally verified in the live game**. Numerical priority scores are TankKit design choices, not a ranking published by Blizzard or the guide authors.

## Version 0.3 coverage and presentation

The catalog now spans **28 instance IDs, 193 boss notes and 58 named priority entries**, including shared catalogs for multi-wing dungeons. See [COVERAGE.md](COVERAGE.md) for per-dungeon counts and links. The table below records the initial research; the additional sources are listed afterward.

The display uses one 520×42 horizontal rail. Boss guidance is a collapsed-by-default 720×28 single-line ribbon, with the complete note available on hover or through private chat. Native rendering, texture loading and animation pacing still require live-client review.

## Initial catalog sources

| Dungeon | Instance ID | Source | Coverage in this build |
| --- | --- | --- | --- |
| The Deadmines | 36 | [Method — Jurdi](https://www.method.gg/wow-forever/dungeons/the-deadmines) | Dangerous trash; VanCleef, Smite, Greenskin, Cookie |
| Hall of Thanes | 3065 | [Method — Jurdi](https://www.method.gg/wow-forever/dungeons/hall-of-thanes) | Four bosses and selected Dark Iron threats |
| Ruins of Lordaeron | 2999 | [Method — Jurdi](https://www.method.gg/wow-forever/dungeons/ruins-of-lordaeron) | Six bosses and selected heavy hitters |
| Excavation Site: Wetlands | 2998 | [Method — Jurdi](https://www.method.gg/wow-forever/dungeons/excavation-site-wetlands), [Wowcalc](https://wowcalc.net/en/forever/guides/dungeons/excavation-site-wetlands) | Four bosses; raptor and Dragonmaw threats |
| City of Dalaran | 2959 | [Method — Jurdi](https://www.method.gg/wow-forever/dungeons/city-of-dalaran), [Wowcalc](https://wowcalc.net/en/forever/guides/dungeons/city-of-dalaran) | Eight bosses and selected caster priorities |
| The Drowned City | 2970 | [Method — Jurdi](https://www.method.gg/wow-forever/dungeons/the-drowned-city) | Six main bosses and selected casters |
| Krol'dok Stronghold | 3039 | [Method — Jurdi](https://www.method.gg/wow-forever/dungeons/kroldok-stronghold) | Six bosses, pets and selected heavy hitters |
| Wailing Caverns | 43 | [Method — Jurdi](https://www.method.gg/wow-forever/dungeons/wailing-caverns) | Selected healer/fear priorities; Anacondra and Cobrahn notes |
| Shadowfang Keep | 33 | [Method — Jurdi](https://www.method.gg/wow-forever/dungeons/shadowfang-keep) | Selected summoner/silence priorities; three boss plans |
| Scarlet Monastery | 189 | [Wowcalc](https://wowcalc.net/en/forever/guides/dungeons/scarlet-monastery) | Herod and Cathedral boss notes |
| Scholomance | 289 | [Wowcalc](https://wowcalc.net/en/forever/guides/dungeons/scholomance) | Alexei, Jandice and Gandling notes |

New Forever instance IDs were cross-checked against the installed DBM-Party-Forever zone declarations, including City of Dalaran's **2959**. No DBM implementation is included. Legacy NPC IDs are included only for established identities; most newer enemies use exact, instance-scoped English names. This is not full localization or full dungeon coverage.

## Decisions when strategies differ

- **VanCleef:** kill the opening Blackguards first; the notes tell the tank to gather the later wave and control or kill it if needed. The engine prioritizes observed elite Blackguards throughout the pull as a conservative policy. A manual boss Skull overrides this. [Method](https://www.method.gg/wow-forever/dungeons/the-deadmines) and [Rabble's Ready Raiders](https://rabblesreadyraiders.com/forever/dungeons/deadmines) differ in how aggressively they recommend killing the later wave.
- **Durgen:** follows Method's boss-first recommendation. Another guide allows different approaches, so this is a selected strategy, not a universal rule. Manually pin Skull to choose a different plan.
- **Witherfang:** boss-first overrides generic caster-first sorting.
- **Deathless Marrow:** the plan changes after an initial wave. Since the engine cannot reliably determine that phase, it pauses automatic ordering for this encounter and leaves Skull/Cross to the tank. The note explains the proposed order; no unverified wave counter is used.
- **Non-elites:** the live elite filter always wins, including snakes, trainees, dangerous runners and any encounter add. A note can explain that a non-elite should die or be controlled without placing a marker on it. Twilight Peons are a notable example of dangerous enemies deliberately excluded from marking.
- **Crowd control:** all markers other than Skull/Cross are reserved. The engine does not infer hidden crowd-control auras, so unmarked controlled enemies cannot always be recognized. Put a reserved marker on a CC target to exclude it.

## Technical references and limits

Automatic marking is now guarded both at the update loop and immediately before each mutation: party dungeon only, no raid roster, no raid instance, and no world-boss classification. A detected world-boss encounter keeps its other enemies manual too. Manual Skull/Cross controls remain available for eligible enemies in those contexts.

- [Forever unit API: classification, threat, casts, identity and death events](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua)
- [Forever nameplate API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/NamePlateDocumentation.lua)
- [Forever secure action system](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua)
- [DBM marking implementation, used only to research the API pattern](https://github.com/DeadlyBossMods/DeadlyBossMods/blob/master/DBM-Core/modules/Icons.lua)

The game can restrict identity, casts and threat. The engine does not bypass that system, infer secret values, automatically change your selected target, or assume that a vanished nameplate is dead. It sees only exposed nameplates, target/mouseover, party targets and boss tokens. An invisible enemy or a distant marker holder can therefore be outside its knowledge. Mark permissions and automatic setter behavior must be verified in the actual Forever client.

TankKit intentionally requires leader/assistant status in dungeon parties to establish one marking owner. That is **TankKit's policy**; ordinary party marking permissions in the game can be broader. The alert requests leadership rather than falsely claiming an API probe proved that every nonleader is forbidden by WoW.

To update the catalog, add a dated source and exact identity to `Dungeons.lua`, keep each plan within the one-message limit, preserve the live elite gate, and exercise its ordering in `tests/marking.lua`. Prefer current Forever footage or first-hand dungeon reporting to an assumed Classic strategy.

## Additional dungeon research

All additional guide material was checked November 18, 2026. Short recommendations and priority scores are original summaries; source scripts and guide text are not bundled.

- [Method: Ragefire Chasm](https://www.method.gg/wow-forever/dungeons/ragefire-chasm)
- [Method: Blackfathom Deeps](https://www.method.gg/wow-forever/dungeons/blackfathom-deeps)
- [Method: The Stockade](https://www.method.gg/wow-forever/dungeons/the-stockade)
- [Method: Gnomeregan](https://www.method.gg/wow-forever/dungeons/gnomeregan)
- [Method: Razorfen Kraul](https://www.method.gg/wow-forever/dungeons/razorfen-kraul)
- [Wowcalc: Razorfen Downs](https://wowcalc.net/en/forever/guides/dungeons/razorfen-downs)
- [Wowcalc: Uldaman](https://wowcalc.net/en/forever/guides/dungeons/uldaman)
- [Mobalytics: Zul'Farrak](https://mobalytics.gg/wow-forever/profile/ruse_cruize/dungeons/zul-farrak-guide-bosses-loot-and-quests)
- [Wowcalc: Maraudon](https://wowcalc.net/en/forever/guides/dungeons/maraudon)
- [Sunken Temple overview](https://www.wowforeveraddon.com/dungeons/sunken-temple/) and [ONN's explicitly Classic-based notes](https://oraclenewsnetwork.com/guides/sunken-temple). Inherited notes are labeled Classic reference in the actual displayed and shared text. Their current mechanics are unverified. Ogom-first is a chosen reference strategy; the tank may override it manually.
- [Wowcalc: Blackrock Depths](https://wowcalc.net/en/forever/guides/dungeons/blackrock-depths)
- [Wowcalc: Blackrock Spire](https://wowcalc.net/en/forever/guides/dungeons/blackrock-spire)
- [Wowcalc: Dire Maul](https://wowcalc.net/en/forever/guides/dungeons/dire-maul)
- [Wowcalc: Stratholme](https://wowcalc.net/en/forever/guides/dungeons/stratholme)
- [Mobalytics / Uncas: Alcaz Prison](https://mobalytics.gg/wow-forever/dungeons/alcaz-prison-complete-dungeon-guide-uncas)
- [Warcraft Tavern: Blackmaw Hold](https://www.warcrafttavern.com/forever/guides/blackmaw-hold). The page could be researched through indexed excerpts when direct fetches were blocked; details outside those excerpts are not asserted. The Unbound Spirit event uses manual ordering.
- [Warcraft Tavern: Shaper's Terrace](https://www.warcrafttavern.com/forever/guides/shapers-terrace/). The roster and available tactic excerpts are recorded. Snowtalon, Tor'Rel, Izha'Rel and Vitrix have limited-confidence preparation notes and manual ordering, rather than invented mechanics.

Moira is excluded from automatic kill markers to protect the rescue objective. Cho'Rush is excluded to protect a Gordok-focused tribute plan. Tribute guard encounters use manual order. Non-elite bombs, wards, totems, spirits and runners remain excluded even when notes correctly recommend dealing with them.

## Researched but excluded availability

[Method's current dungeon list](https://www.method.gg/wow-forever/dungeons) and [Bonkr's level 13–60 list](https://www.bonkr.net/wow-forever-guides) define the coverage scope. [ForeverDB flags Karazhan Crypts as unannounced inherited content](https://foreverdb.net/dungeon/2875-karazhan-crypts); [the guild client-data index](https://guide.wow4ever.se/en/instances) also flags several inherited records as potentially unopened. Public Demon Fall Canyon entries conflict on availability. These two inherited instances have no automatic strategy catalog in this build. This is an explicit research gap, not proof that a future client cannot open them.

## Seal timer correction in 0.3.1

Seal duration and expiration come from Blizzard's player helpful-aura data via `C_UnitAuras.GetAuraDataByIndex`; see [Blizzard UI API documentation mirror, Forever branch](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitAuraDocumentation.lua). Checked November 18, 2026. The previous cast-based 30-second assumption and Judgement consumption handling were removed following live-client feedback. No Judgement debuffs or hit-refresh rules are tracked. If timing is hidden, only the last verified buff expiration may be remembered; a new Seal gets no invented duration. Aura changes are scanned on UNIT_AURA and periodically. These changes are covered offline; live-client validation remains required.

## Aura reminders in 0.3.3

Missing-Seal reminders were removed. The new missing-aura reminder uses the player's own aura selection from `GetNumShapeshiftForms` and `GetShapeshiftFormInfo`, matching Blizzard's [StanceBar implementation for shapeshifts, auras and aspects](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_ActionBar/Shared/StanceBar.lua), checked November 18, 2026. Any selected aura is accepted; another Paladin's received buff does not substitute for the player's selection. Unknown or refused selection data and zero learned forms suppress the reminder. The existing Righteous Fury reminder remains. Aura selection events and periodic updates refresh the state.

## Defensive tracking and shield durability in 0.4

Holy Shield uses the same Blizzard player-buff expiration reader as Seals, without a fixed-duration cast estimate. The starter IDs are 1239570, 20925, 20927 and 20928; rank-name matching uses the client's localized spell information. Templar's Bulwark uses starter ID 1311015, verified as learned by the client's spellbook before accepting an own-player cast. Its timer comes from readable `C_Spell.GetSpellCooldown` data, so the addon does not assume a five-minute cooldown or apply a second talent reduction. Removing the talent clears its record. See Blizzard's generated [Spell API](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellDocumentation.lua), [SpellBook API](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellBookDocumentation.lua) and [Aura API](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitAuraDocumentation.lua).

Shield durability is checked only for the equipped offhand item (slot 17). The item must report `INVTYPE_SHIELD` through `C_Item.GetItemInfoInstant` (or the legacy fallback), and current/maximum durability must be readable and valid. See the generated [Item API](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua). The 20% warning threshold is an addon design choice. Empty slots, offhand weapons, held items and bag items are excluded. Inventory durability/equipment events and periodic refreshes update it. Defensive tracking and equipped-item cases are covered offline; live-client validation remains necessary.

## Addon emblem in 0.4.1

The original gold shield-and-hammer emblem was generated for this project on November 19, 2026. Its master and PNG exports are under `Branding` in the development project. The 400 x 400 PNG export follows CurseForge's [project logo guidance](https://support.curseforge.com/support/solutions/articles/9000199552-project-submission-guide-and-tips). The packaged 128 x 128 `Media/AddonIcon.tga` is a resized format conversion of that same artwork, selected by the TOC's IconTexture metadata. No original Blizzard spell icon was modified or included in this emblem. The generated master is retained and exports can be rebuilt with `scripts/export-branding.ps1`.

## Version 1.0 behavior and validation

Automatic marking now requires a selected, readable living elite to arm the pull. Mouseover can cache observed caster information but cannot arm or seed automatic marking. Only the selected elite is eligible for pre-pull seeding; other enemies need readable group engagement. A short opening priority window permits a dangerous enemy/caster to replace an automatic pre-pull Skull. Manual pins remain respected. Unverified confidence-tagged entries no longer contribute special priority scores. The core dungeon-party/elite-only/identity checks remain at the final marking boundary.

Cooldown tracking waits for a confirmed positive cooldown instead of interpreting an initial delayed zero as Ready. Previously readable ongoing cooldowns can restore tracking after reloads, loading screens and death; missing data never supplies a guessed cooldown. Version 1.0 adds a native four-page settings panel, individual timer and reminder controls, and preview-only boss notes that cannot share chat. Automated checks and native-client visual captures are tracked separately in the release validation files.

## Motion texture implementation

Halo, Trail, Sweep, IconFace, IconRim, IconLight, IconShade, IconGlow and Rail are original procedural textures generated by `scripts/build-media.cjs`, shipped as power-of-two 32-bit TGA. The 0.3.2 icon skin preserves the original spell texture and layers rounded masking, a shaded edge, tinted face light, a fine rim and an outside glow around it. Countdown fonts use the client's Arial Narrow with a small shadow. They are colored and animated by `Motion.lua`, using readable local model state only. Confirmation effects wait for a readable matching raid marker. Reduced Motion removes pulse, scale and travel effects; disabling effects removes decorative light layers. Motion does not trigger gameplay actions.

Native mask and explicit texture layer support were checked against Blizzard's generated Forever-branch [Frame API](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua) and [Texture API](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleTextureAPIDocumentation.lua). Rounded artwork has a square fallback when mask support is unavailable; the animated sweep is masked to the artwork when supported. The browser material check uses example Blizzard icon artwork obtained through Wowhead's public icon CDN, for local visual review only. That reference artwork is outside the packaged addon; the live addon uses game-supplied spell icons. Browser compositing and the game's rendering are different, so the material check does not establish pixel-identical live-client appearance.

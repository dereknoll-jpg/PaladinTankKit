# Forever 1.60.1 protection and encounter sources

Reviewed November 26, 2026 for Paladin TankKit 1.0.5. These additions use Wowhead's
Forever database and guides, not retail, Classic, PTR guides, or reader comments.
Guide pages explicitly identify patch 1.60.1. Live encounter cues also require the
client's reported version to be exactly 1.60.1 and a party dungeon context.

## Protection effects

| Effect | Actual aura ID | Source |
| --- | ---: | --- |
| Iron Creed | 1311033 | https://www.wowhead.com/forever/spell=1311033/iron-creed |
| Shieldsworn spell block | 1328551 | https://www.wowhead.com/forever/spell=1328551/shieldsworn |
| Templar's Bulwark | 1311015 | https://www.wowhead.com/forever/spell=1311015/templars-bulwark |
| Forbearance | 25771 | https://www.wowhead.com/forever/guide/classes/paladin/protection/overview-pve-tank |

The Iron Creed and Shieldsworn passive talent IDs are not their active buff IDs.
No mitigation percentages are hardcoded: the guide and talent tooltip disagree on
some values. New status timers start only from a readable active player buff.
They recover on reload from that buff and clear on readable early removal.
Hidden reads may retain an already observed deadline, marked `~`, never extend it.
Initial hidden timing creates no timer. Bulwark absorb values are shown only if the
client exposes a numeric aura point; no absorb amount is inferred from player health.

Personal cleanse uses client-filtered `HARMFUL|RAID` auras and learned spell checks:

- Cleanse (4987): https://www.wowhead.com/forever/spell=4987/cleanse
- Purify (1152): https://www.wowhead.com/forever/spell=1152/purify

It is an indication of removability, not an encounter instruction or automatic cast.
Curses, Forbearance, missing spell knowledge and unreadable data produce no prompt.
The reminder checks only the player and never creates party chat or alert sounds.

Forbearance details list only learned Bulwark, Divine Shield, Divine Protection and
Blessing of Protection ranks. The list concerns self-protection, not ally readiness:

- https://www.wowhead.com/forever/spell=642/divine-shield
- https://www.wowhead.com/forever/spell=498/divine-protection
- https://www.wowhead.com/forever/spell=1022/blessing-of-protection

## Twelve refreshed plans

| Dungeon | Bosses | Forever source |
| --- | --- | --- |
| Deadmines | Edwin VanCleef | https://www.wowhead.com/forever/dungeon-journal/the-deadmines/edwin-vancleef |
| Deadmines | Mr. Smite | https://www.wowhead.com/forever/dungeon-journal/the-deadmines/mr-smite |
| Deadmines | Captain Greenskin | https://www.wowhead.com/forever/dungeon-journal/the-deadmines/captain-greenskin |
| Deadmines | Cookie | https://www.wowhead.com/forever/dungeon-journal/the-deadmines/cookie |
| Hall of Thanes | Faldrim Anvilmar, Magmatus, Plunder, Durgen Dirgehammer | https://www.wowhead.com/forever/guide/hall-of-thanes-dungeon-overview-location-rewards |
| Ruins of Lordaeron | Witherfang | https://www.wowhead.com/forever/dungeon-journal/ruins-of-lordaeron/witherfang |
| Ruins of Lordaeron | The Abandoned | https://www.wowhead.com/forever/dungeon-journal/ruins-of-lordaeron/the-abandoned |
| Ruins of Lordaeron | Rath'mael | https://www.wowhead.com/forever/dungeon-journal/ruins-of-lordaeron/rathmael |
| Wailing Caverns | Lady Anacondra | https://www.wowhead.com/forever/dungeon-journal/wailing-caverns/lady-anacondra |

Deadmines guide cross-check (patch label and encounter descriptions):
https://www.wowhead.com/forever/guide/the-deadmines-dungeon-overview-location-rewards

The summaries are original short recommendations, not copied guide passages.
VanCleef and Smite health prompts are advance preparation thresholds chosen by
TankKit, not exact mechanic timers. They require an observed downward crossing,
last five seconds and trigger once per observed encounter. Cast cues require an
actual readable cast/channel name; add cues require a living engaged named add
and a readable engaged boss. Losing a nameplate never proves a death or a phase.
No scheduled boss casts, automatic chat, sounds or marker changes are added.

These twelve plans override the corresponding older manual summaries. Other
existing manual plans keep their original confidence labels and sources in
SOURCES.md/COVERAGE.md; they have not been re-certified by this update and cannot
generate the new automatic cues. This is selected coverage, not a complete
Forever encounter journal. Name/cast matching currently relies on English names.

Native spell data visibility, filter behavior, icon loading and animation pacing
still need live Forever review. Offline tests simulate readable and restricted
data, alternate client versions, encounter transitions, personal dispels and all
new controls. They cannot establish that every cast is exposed in live combat.

## November 27, 2026 — Paladin-specific refinements

The reviewed override catalog now contains fourteen plans in four dungeons. Six Paladin-oriented plans were updated or added: Faldrim Anvilmar, Durgen Dirgehammer, Witherfang, The Baron, Viktor the Vile and Rath'mael. No retail/Classic encounter data or reader comments were used for these additions.

- Hall of Thanes mechanics and explicit stun advice: https://www.wowhead.com/forever/guide/hall-of-thanes-dungeon-overview-location-rewards (patch 1.60.1, reviewed November 27). Durgen's golem advice names Hammer of Justice; Faldrim's curse reminder explains the Paladin dispel limitation.
- Ruins mechanics and stun/poison advice: https://www.wowhead.com/forever/guide/ruins-of-lordaeron-dungeon-overview-location-rewards (patch 1.60.1, reviewed November 27). The Baron has Knockout/threat loss; Viktor has opening waves and Leech Poison; Rath'mael can be stunned or his Flamestrike avoided.
- Shared Paladin utility spells: https://www.wowhead.com/forever/guide/classes/paladin/retribution/dps-abilities . Hammer of Justice is a stun; Purify removes poison/disease and Cleanse also handles magic. Applying those class tools to the cited stun/dispel opportunities is TankKit's recommendation, not a claim that a spell is currently learned, ready or guaranteed to land.

Leech Poison encounter cues require an already-detected, client-filtered removable personal debuff with the matching readable English name. They inherit the personal-reminder toggle and require an observed engaged supported boss. No boss cast schedule or party-debuff scan is added.

Bulwark's fill uses observed aura points and the largest readable value for that application; hidden data hides the fill while retaining only the historical baseline and deadline. A first observation after partial consumption can start at full relative fill: it is not the original maximum.

## November 28, 2026 — first-use combat protection correction

This supersedes the observed-only initialization policy above. Combat may hide a buff's initial numeric deadline even while the successful player cast can be correlated. The upper row now follows the main rail's bounded confirmed-cast fallback policy, marked ~. Readable aura data wins; hidden early removal cannot be inferred. No absorb amount, enemy debuff or cleanse eligibility is invented.

Verified Forever sources:

- Active Iron Creed (6 seconds): https://www.wowhead.com/forever/spell=1311033/iron-creed . Talent identity 1311034: https://www.wowhead.com/forever/spell=1311034/iron-creed . Its fallback requires the talent and last-confirmed Righteous Fury.
- Active spell block (6 seconds): https://www.wowhead.com/forever/spell=1328551/shieldsworn . Passive talent identity 1328544 and all affected Holy Strike ranks: https://www.wowhead.com/forever/spell=1328544/shieldsworn . Verified playable ranks: 678, 679, 680, 1866, 2495, 5569, 10332 and 10333. The overview guide links an older NPC Holy Strike ID; it is not used as the fallback identity.
- Bulwark's 8-second absorb and Forbearance application: https://www.wowhead.com/forever/guide/classes/paladin/protection/overview-pve-tank . Only an intentional correlated player success can seed these estimates, never cooldown recovery.
- Sacred Duty's Forbearance duration reduction: https://www.wowhead.com/forever/spell=1224697/sacred-duty . The rank details show 5/10-second reductions; cached ranks adjust the 60-second fallback. A readable observed duration takes priority when its recorded rank still matches.
- Self-only immunity references: https://www.wowhead.com/forever/spell=642/divine-shield and https://www.wowhead.com/forever/spell=498/divine-protection . Blessing of Protection requires a readable SENT target matching the cached player name/realm; unknown and other targets never create self Forbearance.

A short 0.75-second handoff tolerates initial aura-application lag and an older pre-refresh snapshot. Readable absence after handoff clears the estimate. A readable zero absorb clears Bulwark immediately, including during handoff. Learned duration values are historical observations, not proof a hidden effect remains active.

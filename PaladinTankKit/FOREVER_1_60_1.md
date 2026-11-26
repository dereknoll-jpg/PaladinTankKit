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

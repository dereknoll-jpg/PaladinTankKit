# Paladin TankKit 1.0

**Mark. Track. Protect.**

Paladin TankKit is a clean, minimalist tanking companion built specifically for **Paladins in World of Warcraft: Forever**. Keep your kill order, important timers, and quick boss guidance close at hand with a compact HUD, subtle holy light effects, and smooth animations.

## Smart dungeon marking

**You choose the pull.** Automatic marking begins when you select a living elite in a dungeon party—even before combat. Mouseover can scout enemies, but it never starts marking by itself.

- Assigns Skull and Cross to eligible elites, with opening priority for known dangerous enemies and observed casters.
- Promotes Cross to Skull after Skull's confirmed death.
- Respects manual kill marks and crowd-control markers.
- Never marks non-elites or changes your selected target.
- Shows a quiet reminder when leader or assistant permission is missing.

Other enemies join the queue as your party engages them. After the opening priority check, Skull stays stable until confirmed death, with selected boss-add exceptions. **Automatic marking is limited to dungeon parties. Raids, world bosses, and outdoor encounters remain manual.**

## Important timers, one clean timeline

Abilities move from right to left as their timers run down. Unused abilities stay hidden, and each tracker can be switched on or off.

- **Seals:** tracks your active Seal using Blizzard's buff expiration. Judgement and melee hits do not restart its timer.
- **Consecration:** estimated ground-effect duration, followed by any remaining readable cooldown.
- **Hammer of Justice:** cooldown after use.
- **Holy Shield:** actual buff duration, including early buff removal.
- **Templar's Bulwark:** cooldown when talented and used.

A small badge shows active Forbearance. Readable cooldowns already in progress can restore tracking after reloading, zoning, or death. Confirmed cooldown completion briefly lights up before clearing.

## Compact boss notes

Includes **193 selected boss notes across 28 dungeon instance catalogs**, plus **58 named priority enemies**. Check a quick kill order and encounter tips in a slim, single-line ribbon, then hover for the full note. Guidance stays private unless you choose to share it with your party.

Coverage is selected rather than a complete dungeon journal. Reference-based or limited-confidence guidance is labeled, and unverified entries do not receive special automatic priority scores. Some encounter identification currently relies on English names.

## Quiet, useful reminders

Optional alerts cover missing **Righteous Fury**, having **no Paladin aura selected**, and an **equipped shield at 20% durability or below**. A broken equipped shield receives a clear warning. Missing Seals and low mana do not trigger alerts.

## Minimalist by design

Original spell artwork, softly rounded icons, warm lighting, feathered trails, and smooth transitions keep the HUD clear and readable. Version 1.0 includes the shield-and-hammer logo and a refreshed settings panel with dedicated pages for timers, dungeon marking, and appearance.

Adjust the scale, move and lock the HUD, fade it while idle, or enable **Reduced Motion**. Built-in Preview mode demonstrates the timers and sample boss notes outside combat without marking enemies or sending party chat.

**Type `/ptk` to open settings.** Find Mark Pull, Skull, Cross, and Clear bindings under **Paladin TankKit** in WoW's Key Bindings.

### Timing and compatibility

Built for **WoW Forever**. TankKit uses information the client exposes to addons; hidden data can limit timer tracking or automatic marking. **`~` indicates estimated timing, and `?` indicates unavailable timing.** Consecration's ground duration is an adjustable estimate; use `/ptk ground 8` to set it to eight seconds.

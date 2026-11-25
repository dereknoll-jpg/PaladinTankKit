# Paladin TankKit 1.0.4

- **Middle-click to hide timers:** middle-click an ability icon or the Forbearance badge to hide it. Your choice is saved per character, and tracking continues in the background.
- **Easy restoration:** open `/ptk` > **Ability timers** to re-enable individual items. Click **Restore all** or type `/ptk restore` to enable all timers again. Unused abilities stay hidden until active.
- **Clearer marking status:** the Skull button now explains whether marking needs leader/assistant permission, is armed, is waiting for confirmation, or has been blocked by the game. **AUTO** only appears after an automatic mark is confirmed and readable.
- Fixed pre-pull target switching leaving an unmarked queue stuck, and improved compatibility with the game's unmarked-target results.
- Improved handling of blocked marking attempts to stop repeated retries and avoid reporting marks that were never applied. Added `/ptk markstatus` for troubleshooting.

Automatic marking remains limited to eligible elites in dungeon parties and depends on the game allowing addon marking. Being assigned Tank does not grant leader/assistant permission. If the client blocks addon marking, use WoW's built-in target-marker controls. Raids, world bosses, and outdoor encounters remain manual.

const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');
const parse = require('luaparse').parse;
const root = path.resolve(__dirname, '..');
const dir = path.join(root, 'PaladinTankKit');
const toc = fs.readFileSync(path.join(dir, 'PaladinTankKit.toc'), 'utf8');
const files = toc.split(/\r?\n/).map(x => x.trim()).filter(x => x && !x.startsWith('#'));
assert.match(toc, /## Interface: 16001/);
for (const file of files) assert.ok(fs.existsSync(path.join(dir, file)), `Missing TOC file: ${file}`);
const xml = fs.readFileSync(path.join(dir, 'Bindings.xml'), 'utf8');
assert.match(xml, /name="PALADINTANKKIT_PULL"[^>]*>\s*PaladinTankKit_Pull\(\)/);
for (const [binding, icon] of [['SKULL', 8], ['CROSS', 7], ['CLEAR', 0]]) {
  assert.match(xml, new RegExp(`name="PALADINTANKKIT_${binding}"[^>]*>\\s*PaladinTankKit_Mark\\(${icon}\\)`));
}
function scenario(className) {
  const L = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(L);
  function run(source, name) {
    if (lauxlib.luaL_loadbuffer(L, to_luastring(source), null, to_luastring(name)) !== lua.LUA_OK ||
        lua.lua_pcall(L, 0, 0, 0) !== lua.LUA_OK) {
      throw new Error(`${name}: ${to_jsstring(lua.lua_tostring(L, -1))}`);
    }
  }
  run(fs.readFileSync(path.join(__dirname, 'wow-mock.lua'), 'utf8'), 'WoW mock');
  run(`CLASS = ${JSON.stringify(className)}`, 'Class selection');
  for (const file of files.filter(x => x.endsWith('.lua'))) {
    const source = fs.readFileSync(path.join(dir, file), 'utf8');
    parse(source, { luaVersion: '5.1' });
    run(`assert(load(${JSON.stringify(source)}, ${JSON.stringify(file)}))('PaladinTankKit', TEST_NS)`, file);
  }
  run("TEST_NS.events.scripts.OnEvent(TEST_NS.events, 'ADDON_LOADED', 'PaladinTankKit')", 'Addon load');
  return run;
}
const run = scenario('PALADIN');
run(fs.readFileSync(path.join(__dirname, 'behavior.lua'), 'utf8'), 'Behavior tests');
const marking = scenario('PALADIN');
marking(fs.readFileSync(path.join(__dirname, 'marking.lua'), 'utf8'), 'Dungeon marking and notes');
const motion = scenario('PALADIN');
motion(fs.readFileSync(path.join(__dirname, 'motion.lua'), 'utf8'), 'Motion and manual-only safeguards');
const tracking = scenario('PALADIN');
tracking(fs.readFileSync(path.join(__dirname, 'tracking.lua'), 'utf8'), 'Used spell tracking');
const reminders = scenario('PALADIN');
reminders(fs.readFileSync(path.join(__dirname, 'reminders.lua'), 'utf8'), 'Paladin aura reminders');
const defensives = scenario('PALADIN');
defensives(fs.readFileSync(path.join(__dirname, 'defensives.lua'), 'utf8'), 'Defensive timers and equipped shield');
const release = scenario('PALADIN');
release(fs.readFileSync(path.join(__dirname, 'release.lua'), 'utf8'), 'Version 1 release safeguards');
const regressions = scenario('PALADIN');
regressions(fs.readFileSync(path.join(__dirname, 'tracking-regressions.lua'), 'utf8'), 'Live tracking regressions');
const combatTracking = scenario('PALADIN');
combatTracking(fs.readFileSync(path.join(__dirname, 'combat-tracking.lua'), 'utf8'), 'Fully hidden combat tracking');
for (const [file, w, h] of [['Halo',64,64], ['Trail',128,8], ['Sweep',32,32],
  ['IconFace',64,64], ['IconRim',64,64], ['IconLight',64,64], ['IconShade',64,64], ['IconGlow',64,64], ['Rail',256,4]]) {
  const b = fs.readFileSync(path.join(dir, 'Media', `${file}.tga`));
  assert.equal(b[2], 2); assert.equal(b[16], 32); assert.equal(b[17], 0x28);
  assert.equal(b.readUInt16LE(12), w); assert.equal(b.readUInt16LE(14), h);
  assert.equal(b.length, 18 + w*h*4);
  const alpha = Array.from({length:w*h}, (_,i) => b[21+i*4]);
  assert.ok(Math.max(...alpha) > 120 && Math.min(...alpha) === 0, `${file} has a visible smooth alpha range`);
}
const other = scenario('WARRIOR');
other(`assert(TEST_NS.frame == nil); assert(TEST_NS.events.scripts.OnUpdate == nil)
  PaladinTankKit_Mark(8); assert(#MARKS == 0)
  SlashCmdList.PALADINTANKKIT('preview'); assert(TEST_NS.frame == nil)`, 'Non-Paladin isolation');
console.log('PASS: Lua 5.1 syntax, TOC/bindings, Paladin initialization and non-Paladin isolation.');

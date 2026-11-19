const fs = require('node:fs');
const path = require('node:path');
const {lua, lauxlib, lualib, to_luastring, to_jsstring} = require('fengari');
const root = path.resolve(__dirname, '..');
const L = lauxlib.luaL_newstate(); lualib.luaL_openlibs(L);
function run(source) {
  if (lauxlib.luaL_loadbuffer(L,to_luastring(source),null,to_luastring('catalog report')) !== lua.LUA_OK ||
      lua.lua_pcall(L,0,0,0) !== lua.LUA_OK) throw new Error(to_jsstring(lua.lua_tostring(L,-1)));
}
run('CATALOG = {}');
for (const file of ['Dungeons.lua','DungeonsMore.lua']) {
  const source = fs.readFileSync(path.join(root,'PaladinTankKit',file),'utf8');
  run(`assert(load(${JSON.stringify(source)}))('PaladinTankKit', CATALOG)`);
}
run(`local rows, notes, mobs = {}, 0, 0
for id, d in pairs(CATALOG.dungeons) do
 local b, t, limited, reference, seen = 0, 0, 0, 0, {}
 for _, e in pairs(d.byName) do if not seen[e] then seen[e] = true
  if e.boss then b = b+1 else t = t+1 end
  if e.confidence == 'limited' then limited = limited+1 end
  if e.confidence == 'classic-reference' then reference = reference+1 end
 end end
 notes, mobs = notes+b, mobs+t
 rows[#rows+1] = {id=id, name=d.name, b=b, t=t, source=d.source, limited=limited, reference=reference,
   wings=d.wings and table.concat(d.wings, ', ') or ''}
end
table.sort(rows, function(a,b) return a.name < b.name end)
local out = {'# Dungeon coverage — Paladin TankKit 0.3 beta', '',
 #rows .. ' instance catalogs; ' .. notes .. ' boss notes; ' .. mobs .. ' named priority entries.', '',
 'Every previously uncovered dungeon in the current level 13–60 guide list has a catalog. Counts below describe selected notes, not complete encounter or rare-spawn rosters. Scarlet Monastery, Blackrock Spire, Dire Maul and Stratholme share catalogs across their wings.', '',
 '| Dungeon | Boss notes | Named priorities | Confidence / scope |', '| --- | ---: | ---: | --- |'}
for _, r in ipairs(rows) do
 local status = r.limited > 0 and (r.limited .. ' limited-mechanics notes; manual order')
   or (r.reference > 0 and (r.reference .. ' clearly labeled Classic references') or 'Guide recommendations; not tested live')
 out[#out+1] = '| [' .. r.name .. '](' .. r.source .. ') | ' .. r.b .. ' | ' .. r.t .. ' | ' .. status .. ' |'
end
out[#out+1] = ''
out[#out+1] = 'Blackrock Spire includes Lower and Upper; Dire Maul includes East, West and North; Stratholme includes both entrances; Scarlet Monastery includes all four wings. A raid-group version of any instance remains manual-only.'
out[#out+1] = ''
out[#out+1] = 'Demon Fall Canyon and Karazhan Crypts were researched but are excluded: inherited client records and conflicting public availability claims do not establish a live Forever strategy. No Season of Discovery tactics are silently imported. See SOURCES.md.'
out[#out+1] = ''
out[#out+1] = 'Newer identities often use exact English names. All automatic marking still requires the live elite filter, readable engagement evidence and party-dungeon context. Raids, outdoor areas and world-boss encounters are manual-only.'
REPORT = table.concat(out, '\\n') .. '\\n'`);
lua.lua_getglobal(L,to_luastring('REPORT'));
fs.writeFileSync(path.join(root,'PaladinTankKit','COVERAGE.md'),to_jsstring(lua.lua_tostring(L,-1)));
console.log('Updated COVERAGE.md from the shipped Lua catalog.');

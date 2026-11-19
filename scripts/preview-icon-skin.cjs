// Browser review of the actual shipped light textures; not an in-game renderer.
const fs = require('node:fs');
const path = require('node:path');
const zlib = require('node:zlib');
const root = path.resolve(__dirname,'..');
function crc32(b) {
  let c=0xffffffff;
  for (const v of b) {c^=v;for(let i=0;i<8;i++)c=(c>>>1)^((c&1)?0xedb88320:0);}
  return (c^0xffffffff)>>>0;
}
function chunk(type,b) {
  const name=Buffer.from(type),length=Buffer.alloc(4),crc=Buffer.alloc(4);
  length.writeUInt32BE(b.length);crc.writeUInt32BE(crc32(Buffer.concat([name,b])));
  return Buffer.concat([length,name,b,crc]);
}
function texture(name) {
  const b=fs.readFileSync(path.join(root,'PaladinTankKit/Media',name+'.tga'));
  const w=b.readUInt16LE(12),h=b.readUInt16LE(14),raw=Buffer.alloc((w*4+1)*h);
  for(let y=0;y<h;y++)for(let x=0;x<w;x++) {
    const i=18+(y*w+x)*4,j=y*(w*4+1)+1+x*4;
    raw[j]=b[i+2];raw[j+1]=b[i+1];raw[j+2]=b[i];raw[j+3]=b[i+3];
  }
  const ihdr=Buffer.alloc(13);ihdr.writeUInt32BE(w);ihdr.writeUInt32BE(h,4);ihdr[8]=8;ihdr[9]=6;
  return 'data:image/png;base64,'+Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),chunk('IHDR',ihdr),chunk('IDAT',zlib.deflateSync(raw)),chunk('IEND',Buffer.alloc(0))]).toString('base64');
}
const media=Object.fromEntries(['IconFace','IconRim','IconLight','IconShade','IconGlow','Trail','Sweep','Rail'].map(n=>[n,texture(n)]));
const referenceIcons=Object.fromEntries(['spell_holy_sealoffury','spell_holy_innerfire','spell_holy_sealofmight'].map(name=>{
  const local=path.join(root,'previews/reference-'+name+'.jpg');
  return [name,fs.existsSync(local)?'data:image/jpeg;base64,'+fs.readFileSync(local).toString('base64'):'https://wow.zamimg.com/images/wow/icons/large/'+name+'.jpg'];
}));
const html=String.raw`<!doctype html><html lang="en"><meta charset="utf-8"><title>Paladin TankKit — icon lighting</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#11151a;color:#e1d7bf;font:13px system-ui,sans-serif;min-height:100vh;background-image:radial-gradient(ellipse at 50% 45%,#29302e66,transparent 60%)}header{padding:32px 40px}small{font-size:10px;color:#91988d;letter-spacing:2px}h1{font-size:24px;font-weight:450;margin:12px 0}p{color:#92998f;line-height:1.6;font-size:12px;max-width:710px}.stage{position:relative;margin:10px auto 50px;width:860px;height:125px;background:linear-gradient(120deg,#1e2824,#151c19 50%,#202723);border:1px solid #ffffff08;border-radius:8px}.label{position:absolute;top:15px;left:20px;color:#8b958b;font-size:10px;letter-spacing:1px}.row{position:absolute;top:58px;left:20px;display:flex;align-items:center;gap:80px}.row.original{gap:85px}.sample{position:relative;width:20px;height:20px;isolation:isolate}.sample>div,.sample>img{position:absolute}.sample .back{inset:0;background:#070708}.sample .art{inset:1px;width:18px;height:18px;object-fit:cover;object-position:center;mask-image:var(--face);mask-size:100% 100%}.sample .halo{inset:-12px;z-index:-2;background:currentColor;mask-image:var(--glow);mask-size:100% 100%;opacity:.16;mix-blend-mode:plus-lighter}.sample .trail{left:26px;top:17px;width:52px;height:8px;background:currentColor;mask-image:var(--trail);mask-size:100% 100%;opacity:.28;mix-blend-mode:plus-lighter;z-index:-1}.sample .shade{inset:1px;background:#000;mask-image:var(--shade);mask-size:100% 100%;opacity:.44}.sample .wash{inset:1px;background:currentColor;mask-image:var(--face);mask-size:100% 100%;opacity:.12}.sample .light{inset:1px;background:currentColor;mask-image:var(--light);mask-size:100% 100%;opacity:.16;mix-blend-mode:plus-lighter}.sample .rim{inset:0;background:currentColor;mask-image:var(--rim);mask-size:100% 100%;opacity:.65}.sample .back{mask-image:var(--face);mask-size:100% 100%}.sample .count{top:22px;left:-20px;width:60px;text-align:center;font:10px Arial,sans-serif;color:#e1d7bf;text-shadow:0 1px 1px #000}.name{position:absolute;top:64px;left:-35px;width:90px;text-align:center;font-size:9px;color:#798477}.original .sample .art{mask:none}.original .sample .back{mask:none}.original .sample .count{font:10px Georgia,serif;-webkit-text-stroke:.5px #000;paint-order:stroke fill}.zoom .row{transform:scale(2.5);transform-origin:left center;left:60px;gap:50px}.zoom{height:245px}.zoom .name{top:38px;font-size:5px}.zoom .row{top:95px}.quiet .halo,.quiet .trail,.quiet .wash,.quiet .light{display:none}.quiet .art{filter:grayscale(1);opacity:.45}footer{margin:0 auto 30px;width:860px;color:#747f74;font-size:11px}button{background:#1c2422;color:#c6bfac;border:1px solid #6a715755;padding:8px 12px;border-radius:4px;cursor:pointer}#status{margin-left:12px;font-size:11px}.bright{background:linear-gradient(120deg,#9aa984,#7c8e6a 50%,#bec5a1)}
</style>
<header><small>PALADIN TANKKIT · ICON LIGHTING</small><h1>The original artwork, with softer light.</h1><p>Browser material check using the addon's actual generated light textures and example WoW artwork. In game, the artwork comes from your active spell. This is not a live game capture.</p><button id="terrain">Switch terrain brightness</button><span id="status">Loading artwork…</span></header>
<div class="stage"><span class="label">PREVIOUS ICON FACE · ACTUAL SIZE</span><div class="row original" id="old"></div></div>
<div class="stage"><span class="label">NEW LIGHT TREATMENT · ACTUAL SIZE</span><div class="row" id="new"></div></div>
<div class="stage zoom"><span class="label">MATERIAL DETAIL · 250% FOR INSPECTION</span><div class="row" id="detail"></div></div>
<footer>Rounded corners · original spell artwork · warm face light · soft edge glow · feathered trail · fine countdown text. Reduced Motion keeps the static lighting.</footer>
<script>
const textures=MEDIA;
const references=REFERENCES;
for(const [name,key] of [['IconFace','face'],['IconRim','rim'],['IconLight','light'],['IconShade','shade'],['IconGlow','glow'],['Trail','trail']]) document.documentElement.style.setProperty('--'+key,'url("'+textures[name]+'")');
const examples=[['Seal sample','spell_holy_sealoffury','#f5c973','1:35'],['Ground','spell_holy_innerfire','#f59e59','~6'],['Hammer sample','spell_holy_sealofmight','#d4c4ff','24'],['Ready','spell_holy_innerfire','#c9e6a5','Ready'],['Unknown','spell_holy_sealoffury','#80858c','?']];
let loaded=0,failed=0;
for(const id of ['old','new','detail'])for(const [label,icon,color,count] of examples){const item=document.createElement('div');item.className='sample'+(count==='?'&&id!=='old'?' quiet':'');item.style.color=color;item.innerHTML='<div class="halo"></div><div class="back"></div><img class="art" alt=""><div class="shade"></div><div class="wash"></div><div class="light"></div><div class="rim"></div><div class="count">'+count+'</div><span class="name">'+label+'</span>';if(id!=='old'&&(count==='1:35'||count==='~6')){const trail=document.createElement('div');trail.className='trail';trail.style.left='16px';trail.style.top='6px';item.append(trail)}if(id==='old')for(const c of ['halo','shade','wash','light','rim'])item.querySelector('.'+c).remove();const img=item.querySelector('img');img.onload=()=>{loaded++;document.getElementById('status').textContent=loaded+' / 15 artwork samples loaded'};img.onerror=()=>{failed++;document.getElementById('status').textContent=failed+' artwork loads failed'};img.src=references[icon];document.getElementById(id).append(item)}
document.getElementById('terrain').onclick=()=>document.querySelectorAll('.stage').forEach(x=>x.classList.toggle('bright'));
if(new URLSearchParams(location.search).has('bright'))document.getElementById('terrain').click();
</script></html>`;
fs.writeFileSync(path.join(root,'previews/IconLightStudy.html'),html.replace('const textures=MEDIA;',`const textures=${JSON.stringify(media)};`).replace('const references=REFERENCES;',`const references=${JSON.stringify(referenceIcons)};`));
console.log('Wrote previews/IconLightStudy.html using shipped TGA textures.');

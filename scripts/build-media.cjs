// Original procedural RGBA textures; uncompressed, top-origin TGA supported by WoW.
const fs = require('node:fs');
const path = require('node:path');
const destination = path.resolve(__dirname, '../PaladinTankKit/Media');
fs.mkdirSync(destination, {recursive: true});
function texture(name, width, height, sample) {
  const bytes = Buffer.alloc(18 + width * height * 4);
  bytes[2] = 2; bytes.writeUInt16LE(width, 12); bytes.writeUInt16LE(height, 14);
  bytes[16] = 32; bytes[17] = 0x28;
  for (let y=0; y<height; y++) for (let x=0; x<width; x++) {
    const i = 18 + (y*width+x)*4;
    bytes[i] = bytes[i+1] = bytes[i+2] = 255;
    bytes[i+3] = Math.round(Math.max(0, Math.min(1, sample((x+.5)/width, (y+.5)/height)))*255);
  }
  fs.writeFileSync(path.join(destination, `${name}.tga`), bytes);
}
texture('Halo',64,64,(x,y)=>Math.max(0,1-Math.hypot((x-.5)*2,(y-.5)*2))**2.1);
texture('Trail',128,8,(x,y)=>(1-x)**2.5*Math.sin(Math.PI*y)**2);
texture('Sweep',32,32,(x,y)=>Math.max(0,1-Math.abs(x+y-1)*5)**3*Math.sin(Math.PI*x)*Math.sin(Math.PI*y));
const clamp=x=>Math.max(0,Math.min(1,x));
// Signed distance to a 20px rounded icon; sample at 64px to antialias the skin.
function rounded(x,y,half=10,radius=2) {
  const qx=Math.abs(x)-(half-radius), qy=Math.abs(y)-(half-radius);
  return Math.hypot(Math.max(qx,0),Math.max(qy,0))+Math.min(Math.max(qx,qy),0)-radius;
}
const face=(x,y)=>clamp(.5-rounded((x-.5)*20,(y-.5)*20));
texture('IconFace',64,64,face);
texture('IconRim',64,64,(x,y)=>{
  const d=rounded((x-.5)*20,(y-.5)*20);
  return clamp(.5-d)*clamp(d+1.05)*(.5+.5*(1-(x+y)*.5));
});
texture('IconLight',64,64,(x,y)=>face(x,y)*clamp(.15+.85*(1-(x+y)*.5)));
texture('IconShade',64,64,(x,y)=>{
  const d=rounded((x-.5)*20,(y-.5)*20);
  return face(x,y)*clamp(Math.exp(Math.min(0,d)/2.2)*.72+y*.16);
});
// Most of the glow sits OUTSIDE the artwork, where it can actually be seen.
texture('IconGlow',64,64,(x,y)=>{
  const d=Math.max(0,rounded((x-.5)*44,(y-.5)*44));
  return Math.exp(-d/3.4)*clamp((11-d)/3);
});
texture('Rail',256,4,(x,y)=>clamp((x-.01)*12)*clamp((.99-x)*12)*Math.sin(Math.PI*y));
console.log('Built timer light, rounded icon skin, shadow and rail textures.');

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const binary = new WebAssembly.Module(readFileSync(process.argv[2] ?? new URL("ferry.wasm", import.meta.url)));
assert.deepEqual(WebAssembly.Module.imports(binary).map(({ module, name }) => module+"."+name).sort(),
  ["ferry.frame", "ferry.moving", "ferry.world"]);
assert.deepEqual(WebAssembly.Module.exports(binary).map(({ name }) => name).sort(),
  ["_start", "cancel_action", "memory", "reset", "tick"]);

let engine, frame, world, moving, worldSends = 0;
function view(pointer, count, max, stride) {
  assert(Number.isInteger(pointer) && pointer >= 0 && pointer % 4 === 0);
  assert(Number.isInteger(count) && count > 0 && count <= max && count % stride === 0);
  assert(pointer + count * 4 <= engine.memory.buffer.byteLength);
  return new Float32Array(engine.memory.buffer, pointer, count);
}

engine = new WebAssembly.Instance(binary, { ferry: {
  frame(p,n) { assert.equal(n,30); frame=view(p,n,30,1).slice(); assert(frame.every(Number.isFinite)); },
  world(p,n) { worldSends++; assert(n>45000); assert(view(p,n,73728,18).every(Number.isFinite)); world=[p,n]; },
  moving(p,n) { view(p,n,29184,18); moving=[p,n]; },
}}).exports;

const step = 1 / 60;
const tick = (x=0,z=0,flags=0,dt=step,aspect=1.65) => engine.tick(dt,x,z,flags,aspect);
const run = (n,x=0,z=0,flags=0,dt=step) => { for(let i=0;i<n;i++) tick(x,z,flags,dt); };
const spot = () => [frame[26],frame[27]];
const rawMoving = () => view(...moving,29184,18);
const clamp = (x,lo,hi) => Math.max(lo,Math.min(hi,x));

function walkTo(x,z) {
  for(let i=0;i<780;i++) {
    const dx=x-frame[26],dz=z-frame[27],d=Math.hypot(dx,dz);
    if(d<.11)return;
    tick(dx/Math.max(.28,d),dz/Math.max(.28,d),1);
  }
  assert.fail("Walk blocked at "+spot().join(",")+" trying "+x+","+z);
}
function mount() {
  tick(0,0,2);
  assert.equal(frame[16],1);
}
function pickup() {
  walkTo(2.1,10.15); walkTo(6.16,10.15);
  assert.equal(frame[20],3);
  tick(0,0,2);
  assert.equal(frame[17],1);
  assert.equal(frame[18],90);
}
function driver(target,result,limit=540) {
  const events=[];
  let seq=frame[22];
  for(let i=0;i<limit;i++) {
    const [x,z]=typeof target==="function"?target():target;
    const dx=x-frame[26],dz=z-frame[27],a=Math.atan2(dx,dz)-frame[28];
    const turn=Math.atan2(Math.sin(a),Math.cos(a));
    tick(clamp(turn*3.75,-1,1),Math.abs(turn)>.7&&Math.hypot(dx,dz)<6?.64:1);
    if(frame[22]!==seq){
      seq=frame[22]; events.push(frame[21]);
      if(frame[21]===result)break;
    }
  }
  return events;
}
function ped(i) {
  const vertices=rawMoving(), first=(5*330+(frame[16]===0?210:0)+4*150+i*210)*6;
  let xmin=Infinity,xmax=-Infinity,ymin=Infinity,ymax=-Infinity,zmin=Infinity,zmax=-Infinity;
  for(let q=first;q<first+210*6;q+=6) {
    xmin=Math.min(xmin,vertices[q]); xmax=Math.max(xmax,vertices[q]);
    ymin=Math.min(ymin,vertices[q+1]); ymax=Math.max(ymax,vertices[q+1]);
    zmin=Math.min(zmin,vertices[q+2]); zmax=Math.max(zmax,vertices[q+2]);
  }
  return [(xmin+xmax)/2,(zmin+zmax)/2,ymax-ymin];
}

engine._start();
engine.reset(0);
assert.equal(frame[16],0); assert.equal(frame[17],0); assert.equal(frame[18],90); assert.equal(frame[20],1);
assert.equal(worldSends,1);
assert(world[0]+world[1]*4<=moving[0] || moving[0]+moving[1]*4<=world[0]);
const scenery=view(...world,73728,18).slice(), prior=rawMoving().slice(), projection=frame[0];
tick(0,0,0,0,.53);
assert.notEqual(frame[0],projection); assert.deepEqual(rawMoving(),prior);
tick(0,0,2,.003); assert.equal(frame[16],0);
engine.cancel_action();
tick(0,0,0,.015); assert.equal(frame[16],0);
tick(0,0,2,.003); tick(0,0,0,0,.53); assert.equal(frame[16],0);
tick(0,0,0,.015); assert.equal(frame[16],1);
run(24); assert.equal(frame[16],1);
tick(0,0,2); assert.equal(frame[16],0);

engine.reset(0); pickup();
for(const p of [[10.6,10.15],[10.6,28.65],[11.88,28.65],[11.88,73.55],[11.88,82.1]]) walkTo(...p);
assert.equal(frame[20],4,"reachable pier after the on-foot shortcut");
assert(frame[18]>45);
tick(0,0,2);
assert.equal(frame[17],2,"actual controls complete the pickup and delivery");
const time=frame[18];
run(60,0,1); assert.equal(frame[18],time);
engine.reset(0); pickup();
walkTo(2.1,10.15); walkTo(2.1,-4.6); mount();
for(let i=0;i<550&&frame[27]<62;i++)tick(0,1);
assert(frame[27]>=62,"boulevard driving can reach the harbor");
run(120,0,0,1);
tick(0,0,2); assert.equal(frame[16],0,"leave the car before boarding");
for(const p of [[1.6,70.6],[11.88,70.6],[11.88,82.1]])walkTo(...p);
assert.equal(frame[20],4);
tick(0,0,2); assert.equal(frame[17],2,"mixed driving/walking path delivers using real inputs");
engine.reset(0); pickup(); run(5406);
assert.equal(frame[17],3); assert.equal(frame[18],0);
engine.reset(1); run(90); assert.equal(frame[17],4); assert.equal(frame[18],90);

engine.reset(1); mount();
const start=frame[27];
run(72,0,1);
assert(frame[27]>start+3 && frame[19]>18,"acceleration displaces the car");
const speed=frame[19];
run(18,0,0,1); assert(frame[19]<speed*.65);
const last=frame[27];
run(180,0,-1); assert(frame[27]<last-3,"reverse displaces the car backwards");
engine.reset(1); mount(); run(72,0,1);
const at60=spot();
engine.reset(1); mount(); run(144,0,1,0,step/2);
for(let i=0;i<2;i++) assert(Math.abs(spot()[i]-at60[i])<.06,"fixed stepping at 60/120Hz");
assert.deepEqual(view(...world,73728,18),scenery,"moving mesh never overwrites scenery");

engine.reset(1); mount();
const mailboxEvents=driver([3.9,18],1);
assert(mailboxEvents.includes(1),"mailbox contact: "+mailboxEvents);
assert(frame[19]>4,"light mailbox does not stop a car");
const mailRange=()=>rawMoving().slice(5*330*6,(5*330+150)*6);
const hitMail=mailRange();
run(18,0,0,1);
assert.notDeepEqual(mailRange(),hitMail,"mailbox visibly topples");

engine.reset(1); mount();
const treeEvents=driver([-5.1,19],2);
assert(treeEvents.includes(2),"tree contact: "+treeEvents);
assert(Math.hypot(frame[26]+5.1,frame[27]-19)>1.1,"car cannot pass through fixed trunk");
assert(frame[19]<16,"solid tree dissipates the impact");

engine.reset(1); mount();
const standing=ped(0);
const pedEvents=driver(()=>{const [x,z]=ped(0);return [x+.22,z+.22];},3,320);
assert(pedEvents.includes(3),"pedestrian contact: "+pedEvents+" at "+spot());
run(15,0,0,1);
assert(ped(0)[2]<standing[2]*.82,"a polygonal person visibly falls");
run(117,0,0,1);
assert(ped(0)[2]>standing[2]*.92,"the person gets up again");
engine.reset(1);
assert.equal(frame[22],0);
assert.deepEqual(rawMoving(),prior.subarray(0,rawMoving().length),"retry restores traffic, props and people");
assert.equal(worldSends,1);
console.log("Last Ferry: fixed stepping, mission, interaction, and three distinct collision classes passed.");

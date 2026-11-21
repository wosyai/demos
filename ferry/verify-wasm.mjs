import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const binary = new WebAssembly.Module(readFileSync(process.argv[2] ?? new URL("ferry.wasm", import.meta.url)));
assert.deepEqual(WebAssembly.Module.imports(binary).map(({ module, name }) => module+"."+name).sort(),
  ["ferry.frame", "ferry.moving", "ferry.world"]);
assert.deepEqual(WebAssembly.Module.exports(binary).map(({ name }) => name).sort(),
  ["_start", "cancel_action", "memory", "reset", "tick"]);

let engine, frame, world, moving, worldSends = 0;
const WORLD_FLOATS=8*4096*6;
const MOVING_FLOATS=24*256*6;
function view(pointer, count, max, stride) {
  assert(Number.isInteger(pointer) && pointer >= 0 && pointer % 4 === 0);
  assert(Number.isInteger(count) && count > 0 && count <= max && count % stride === 0);
  assert(pointer + count * 4 <= engine.memory.buffer.byteLength);
  return new Float32Array(engine.memory.buffer, pointer, count);
}

engine = new WebAssembly.Instance(binary, { ferry: {
  frame(p,n) { assert.equal(n,30); frame=view(p,n,30,1).slice(); assert(frame.every(Number.isFinite)); },
  world(p,n) { worldSends++; assert(n>120000); assert(view(p,n,WORLD_FLOATS,18).every(Number.isFinite)); world=[p,n]; },
  moving(p,n) { view(p,n,MOVING_FLOATS,18); moving=[p,n]; },
}}).exports;

const step = 1 / 60;
const tick = (x=0,z=0,flags=0,dt=step,aspect=1.65) => engine.tick(dt,x,z,flags,aspect);
const run = (n,x=0,z=0,flags=0,dt=step) => { for(let i=0;i<n;i++) tick(x,z,flags,dt); };
const spot = () => [frame[26],frame[27]];
const rawMoving = () => view(...moving,MOVING_FLOATS,18);
const clamp = (x,lo,hi) => Math.max(lo,Math.min(hi,x));

function walkTo(x,z) {
  for(let i=0;i<1450;i++) {
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
  for(const p of [[3.8,-4.6],[3.8,28.9],[-82,28.9],[-82,39.8]]) walkTo(...p);
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
  const vertices=rawMoving(), first=(7*330+(frame[16]===0?210:0)+4*150+i*210)*6;
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
const scenery=view(...world,WORLD_FLOATS,18).slice(), prior=rawMoving().slice(), projection=frame[0];
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
for(const p of [[-82,28.9],[3.8,28.9],[3.8,70.6],[11.88,70.6],[11.88,82.1]]) walkTo(...p);
assert.equal(frame[20],4,"reachable pier after the on-foot shortcut");
assert(frame[18]>55 && frame[18]<75,"crossing the expanded map costs real round time");
tick(0,0,2);
assert.equal(frame[17],2,"actual controls complete the pickup and delivery");
const time=frame[18];
run(60,0,1); assert.equal(frame[18],time);
function driveCourse(points) {
  for(const [x,z,radius,speed] of points) {
    let reached=false;
    for(let i=0;i<1700;i++) {
      const dx=x-frame[26], dz=z-frame[27], gap=Math.hypot(dx,dz);
      if(gap<radius){reached=true; break;}
      const angle=Math.atan2(dx,dz)-frame[28];
      const turn=Math.atan2(Math.sin(angle),Math.cos(angle));
      const desired=Math.min(speed,Math.max(1.8,speed-Math.abs(turn)*3.5));
      tick(clamp(turn*3.4,-1,1),clamp(.14+(desired-frame[19]/3.6)*.47,-.35,1),Math.abs(turn)>.95?1:0);
    }
    assert(reached,"Driving blocked at "+spot().join(",")+" going to "+x+","+z);
    assert.equal(frame[16],1);
  }
}
function parkAndExit() {
  run(105,0,0,1);
  tick(0,0,2);
  assert.equal(frame[16],0);
}

engine.reset(0);
mount();
driveCourse([[0,22,1.35,5.5],[-2.25,27.8,1.24,4.2],[-9.5,29.05,1.55,4.2],[-80,29.05,1.24,8.8]]);
parkAndExit();
walkTo(-82,39.8);
assert.equal(frame[20],3);
tick(0,0,2);
assert.equal(frame[17],1);
walkTo(-82,30.5);
mount();
driveCourse([[-102,29,1.4,7],[-107.85,32.5,1.28,4],[-108.4,52,1.33,5.7],[-106,57.15,1.2,4],
  [-100,58.5,1.25,4],[-7.5,58.6,1.8,7.4],[-2.2,61.2,1.5,4],[.4,68,1.5,3.8]]);
parkAndExit();
for(const p of [[3.9,67],[3.9,70.6],[11.88,70.6],[11.88,82.1]]) walkTo(...p);
assert.equal(frame[20],4);
tick(0,0,2);
assert.equal(frame[17],2,"wheel-driven western route and walking to board complete the mission");
assert(frame[18]>30,"no collision-induced crawl on the pickup loop");
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
assert.deepEqual(view(...world,WORLD_FLOATS,18),scenery,"moving mesh never overwrites scenery");

function trafficCenters() {
  const mesh=rawMoving(), start=330+(frame[16]===0?210:0), centers=[];
  for(let i=0;i<6;i++){
    let xmin=Infinity,xmax=-Infinity,zmin=Infinity,zmax=-Infinity;
    for(let q=(start+i*330)*6;q<(start+(i+1)*330)*6;q+=6){
      xmin=Math.min(xmin,mesh[q]); xmax=Math.max(xmax,mesh[q]);
      zmin=Math.min(zmin,mesh[q+2]); zmax=Math.max(zmax,mesh[q+2]);
    }
    centers.push([(xmin+xmax)/2,(zmin+zmax)/2]);
  }
  return centers;
}
function bodiesSeparated() {
  const mesh=rawMoving(), corner=114*6;
  const x=(mesh[0]+mesh[corner])*.5,z=(mesh[2]+mesh[corner+2])*.5;
  const frontX=mesh[6]-mesh[0],frontZ=mesh[2]-mesh[8];
  const unit=Math.hypot(frontX,frontZ);
  const sin=frontZ/unit,cos=frontX/unit;
  return trafficCenters().every(([tx,tz],i)=>{
    const west=i>=4;
    const dx=west?tz-z:x-tx,dz=west?x-tx:z-tz;
    const s=west?-cos:sin,c=west?sin:cos;
    const halfWidth=.94,halfLength=1.94;
    const crossX=halfWidth+halfWidth*Math.abs(c)+halfLength*Math.abs(s);
    const crossZ=halfLength+halfWidth*Math.abs(s)+halfLength*Math.abs(c);
    return Math.min(crossX-Math.abs(dx),crossZ-Math.abs(dz),
      crossX-Math.abs(dx*c-dz*s),crossZ-Math.abs(dx*s+dz*c))<.045;
  });
}
function lane(lane,throttle=1,flags=0) {
  const steer=clamp((lane-frame[26])*.62-frame[28]*2.22,-1,1);
  tick(steer,throttle,flags);
  assert(bodiesSeparated(),"neither car may step through the other car body");
}
engine.reset(1); mount();
for(let i=0;i<320;i++)lane(0);
assert.equal(frame[22],0,"narrow center-line near misses are not false collisions");
assert(frame[27]>43);
assert(trafficCenters().filter(([x])=>x<-35).length===2,"western district has its own moving traffic");
engine.reset(1); mount();
for(let i=0;i<270;i++)lane(-2);
assert.equal(frame[21],4,"head-on collision reported");
assert(frame[27]<14.5&&frame[19]<1,"sustained throttle cannot tunnel through a stopped car");
assert(frame[22]<=3,"sustained contact does not spam new hits");
const stop=frame[27];
for(let i=0;i<120;i++)lane(-2,-1);
assert(frame[27]<stop-4,"reversing separates the contact cleanly");
engine.reset(1); mount();
let contactFromRest=false, parkedZ=0;
for(let i=0;i<310;i++) {
  const wasStopped=frame[19]<.19 && frame[27]>4.4;
  const before=frame[22];
  const brake=frame[27]>4.4;
  const startZ=frame[27];
  lane(-2,brake?0:1,brake?1:0);
  if(wasStopped && frame[22]>before) {
    parkedZ=startZ;
    contactFromRest=frame[21]===4 && frame[19]>1;
  }
}
assert(contactFromRest,"approaching traffic visibly nudges a stopped player without overlap");
assert(frame[19]<.1 && frame[27]<parkedZ-.07 && frame[27]>parkedZ-.48,"bounded impulse does not creep forever");
engine.reset(1); mount();
for(let i=0;i<170;i++)lane(i>=150?-1.8:0,.66);
for(let i=0;i<80;i++)lane(-1.8,.66);
assert.equal(frame[21],4,"oblique approach collides without overlapping");
const oblique=spot();
for(let i=0;i<65;i++)lane(0,-.7);
assert(Math.hypot(frame[26]-oblique[0],frame[27]-oblique[1])>1.7,"oblique contact can be escaped");

engine.reset(1); mount();
const mailboxEvents=driver([3.9,18],1);
assert(mailboxEvents.includes(1),"mailbox contact: "+mailboxEvents);
assert(frame[19]>4,"light mailbox does not stop a car");
const mailRange=()=>rawMoving().slice(7*330*6,(7*330+150)*6);
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
const reset=rawMoving();
const shadowFloatCount=7*8*3*6;
assert.deepEqual(reset.subarray(0,-shadowFloatCount),prior.subarray(0,reset.length-shadowFloatCount),
  "retry restores traffic, props and people");
assert.deepEqual(reset.subarray(-shadowFloatCount),prior.subarray(-shadowFloatCount),
  "retry also restores the full list of shadows");
assert.equal(worldSends,1);
console.log("Last Ferry: fixed stepping, expanded mission, reciprocal swept vehicle contact, and all four collision classes passed.");

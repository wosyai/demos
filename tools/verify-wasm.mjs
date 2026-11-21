import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import assert from 'node:assert/strict';

const path = process.argv[2];
const file = process.argv[3] === '--binary'
  ? path : JSON.parse(readFileSync(path, 'utf8')).executable;
const binary = new WebAssembly.Module(readFileSync(file));
const imports = WebAssembly.Module.imports(binary);
const graphics = ['frame', 'mesh', 'outline', 'water'];
assert.deepEqual(imports.filter((item) => item.module === 'showcase').map((item) => item.name).sort(), graphics);
for (const item of imports) {
  assert.equal(item.kind, 'function');
  assert(item.module === 'showcase' ||
    (item.module === 'wasi_snapshot_preview1' && item.name === 'proc_exit'));
}

let engine;
let frame;
let mesh;
let water;
let outline;
function view(pointer, size) {
  assert(Number.isInteger(pointer) && pointer >= 0 && pointer % 4 === 0);
  assert(pointer + size * 4 <= engine.memory.buffer.byteLength);
  const data = new Float32Array(engine.memory.buffer, pointer, size);
  for (const component of data) assert(Number.isFinite(component));
  return data;
}
function layer(pointer, count, stride, maximum) {
  assert(Number.isInteger(count) && count >= 0 && count <= maximum && count % stride === 0);
  const data = view(pointer, count * 6);
  return { pointer, count, hash: createHash('sha256')
    .update(new Uint8Array(data.buffer, data.byteOffset, data.byteLength)).digest('hex') };
}
engine = new WebAssembly.Instance(binary, {
  showcase: {
    mesh(pointer, count) { mesh = layer(pointer, count, 3, 165888); },
    water(pointer, count) { water = layer(pointer, count, 3, 6); },
    outline(pointer, count) { outline = layer(pointer, count, 2, 24); },
    frame(pointer, hit) { frame = { values: Array.from(view(pointer, 25)), hit }; },
  },
  wasi_snapshot_preview1: { proc_exit(code) { assert.fail('Wosy exited: ' + code); } },
}).exports;

const { _start, generate, rebuild, edit, pick, control, clear_controls, look, reset_camera, tick, edit_view, select_material, cycle_material, place_selected, memory } = engine;
assert(memory instanceof WebAssembly.Memory);
for (const fn of [_start, generate, rebuild, edit, pick, control, clear_controls, look, reset_camera, tick, edit_view, select_material, cycle_material, place_selected]) {
  assert.equal(typeof fn, 'function');
}
_start();
generate(42);
assert(mesh.count > 0);
assert.equal(water.count, 6);
const original = mesh;
generate(42);
rebuild();
assert.deepEqual(mesh, original, 'seed did not reproduce mesh in the same storage');

tick(0, 1, 0);
assert.equal(frame.hit, -1);
assert.equal(outline.count, 0);
tick(0, 1, 1);
const priorView = frame.values.slice(0, 16);
look(45, -12);
tick(0, 1, 1);
assert.notDeepEqual(frame.values.slice(0, 16), priorView, 'look did not update projection');
assert.deepEqual(mesh, original, 'camera input should not affect mesh');
assert.equal(frame.values[24], 2);
select_material(6);
cycle_material(1);
tick(0, 1, 1);
assert.equal(frame.values[24], 1, 'hotbar should wrap forward');
cycle_material(-1);
select_material(0);
tick(0, 1, 1);
assert.equal(frame.values[24], 6, 'hotbar should wrap backward and ignore invalid selection');

assert.equal(pick(-4, 18, -4, -1, 0, 0), -1);
const hit = pick(12.5, 18, 12.5, 0, -1, 0);
assert(hit >= 0, 'terrain under center camera');
const x = hit & 31, y = (hit >>> 5) & 15, z = (hit >>> 9) & 31;
assert(x >= 0 && x < 24 && y >= 0 && y < 16 && z >= 0 && z < 24);
edit(x, y, z, 0);
rebuild();
assert.notEqual(mesh.hash, original.hash, 'block edit did not change mesh');
assert.equal(mesh.pointer, original.pointer, 'block edit relocated mesh storage');

for (let y = 0; y < 16; y++) {
  for (let z = 0; z < 24; z++) {
    for (let x = 0; x < 24; x++) edit(x, y, z, 0);
  }
}
for (let z = 10; z < 23; z++) {
  for (let x = 8; x < 18; x++) edit(x, 2, z, 3);
}
for (let y = 3; y <= 8; y++) {
  for (let x = 8; x < 18; x++) edit(x, y, 15, 3);
}
rebuild();
reset_camera();
look(0.72664234 / 0.0034, -0.21 / 0.0034);
tick(0, 1, 1);
const ground = frame.values[17];
const zStart = frame.values[18];
assert.equal(frame.values[22], 0);
assert.equal(frame.values[23], 1);
assert(frame.hit >= 0 && outline.count === 24, 'wall must be selectable');
control(0, 1);
tick(0.25, 1, 1);
assert(frame.values[18] < zStart && zStart - frame.values[18] <= 0.30,
  'a slow frame should advance toward the wall within the cap');
for (let i = 0; i < 10; i++) tick(0.05, 1, 1);
clear_controls();
assert(Math.abs(frame.values[18] - 16.30) < 0.012, 'solid wall must stop the player at contact');
assert(Math.abs(frame.values[17] - ground) < 0.003 && frame.values[23] === 1, 'walk stays grounded');
const blockedMesh = mesh.hash;
assert.equal(place_selected(), -3, 'cannot place a block intersecting the player');
assert.equal(mesh.hash, blockedMesh);

control(4, 1);
tick(0.04, 1, 1);
assert(frame.values[17] > ground && frame.values[23] === 0, 'jump should rise once from the ground');
for (let i = 0; i < 36; i++) tick(0.04, 1, 1);
assert(Math.abs(frame.values[17] - ground) < 0.003 && frame.values[23] === 1,
  'gravity should land; held jump must not trigger a second jump');
control(4, 0);
control(1, 1);
for (let i = 0; i < 6; i++) tick(0.05, 1, 1);
assert(frame.values[18] > 17.30, "back up outside the placement voxel");
control(1, 0);
select_material(5);
tick(0, 1, 1);
assert.equal(frame.values[24], 5);
assert.equal(place_selected(), 1, 'placing in free air next to the wall should work');
assert.notEqual(mesh.hash, blockedMesh);
assert.equal(edit_view(0), 1, 'removal should reach the newly placed block');
assert.equal(mesh.hash, blockedMesh);

control(7, 1);
control(7, 1);
tick(0, 1, 1);
assert.equal(frame.values[22], 1, 'repeated down must not toggle flight twice');
control(7, 0);
control(4, 1);
tick(0.04, 1, 1);
assert(frame.values[17] > ground, 'flight must rise with jump input');
control(4, 0);
control(7, 1);
control(7, 0);
tick(0, 1, 1);
assert.equal(frame.values[22], 0);

for (let z = 10; z < 23; z++) {
  for (let x = 8; x < 18; x++) edit(x, 2, z, 0);
}
for (let y = 3; y <= 8; y++) {
  for (let x = 8; x < 18; x++) edit(x, y, 15, 0);
}
edit(23, 2, 0, 1);
reset_camera();
tick(0, 1, 1);
assert.deepEqual(frame.values.slice(16, 19).map(x => Math.round(x * 100)), [2350, 462, 50]);
assert.equal(frame.values[23], 1);
edit(23, 2, 0, 0);
rebuild();
reset_camera();
tick(0, 1, 1);
assert.equal(mesh.count, 0);
assert.equal(frame.values[17], 10);
assert.equal(frame.values[22], 1, 'an empty world must use a stable flight spawn');
assert.equal(frame.values[23], 0);
console.log('Verified deterministic terrain, geometry, walking, jump and landing, solid walls, block editing, flight and respawn.');

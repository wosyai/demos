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
    frame(pointer, hit) { frame = { values: Array.from(view(pointer, 22)), hit }; },
  },
  wasi_snapshot_preview1: { proc_exit(code) { assert.fail('Wosy exited: ' + code); } },
}).exports;

const { _start, generate, rebuild, edit, pick, control, clear_controls, look, reset_camera, tick, edit_view, memory } = engine;
assert(memory instanceof WebAssembly.Memory);
for (const fn of [_start, generate, rebuild, edit, pick, control, clear_controls, look, reset_camera, tick, edit_view]) {
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
const intro = frame.values.slice();
look(45, -12);
tick(0, 1, 0);
assert.notDeepEqual(frame.values.slice(0, 16), intro.slice(0, 16), 'look did not update projection');
reset_camera();
tick(0, 1, 1);
const eye = frame.values.slice(16, 19);
control(0, 1);
tick(0.05, 1, 1);
const moved = frame.values.slice(16, 19);
assert.notDeepEqual(moved, eye, 'movement did not update camera');
clear_controls();
tick(0.05, 1, 1);
assert.deepEqual(frame.values.slice(16, 19), moved, 'release did not stop movement');
assert.deepEqual(mesh, original, 'camera input should not affect mesh');
control(0, 1);
tick(0.25, 1, 1);
const delta = Math.hypot(...frame.values.slice(16, 19).map((value, i) => value - moved[i]));
assert(delta > 0 && delta <= 0.43, 'a slow frame must advance movement with a cap');
clear_controls();
reset_camera();
tick(0, 1, 1);
assert(frame.hit >= 0, 'initial view should target the island in seed 42');
assert.equal(outline.count, 24);
const beforeViewEdit = mesh.hash;
assert.equal(edit_view(0), 1, 'center-target remove did not edit the island');
assert.notEqual(mesh.hash, beforeViewEdit, 'center-target edit must upload changed geometry');
generate(42);
assert.deepEqual(mesh, original);

assert.equal(pick(-4, 18, -4, -1, 0, 0), -1);
const hit = pick(12.5, 18, 12.5, 0, -1, 0);
assert(hit >= 0, 'terrain under center camera');
const x = hit & 31, y = (hit >>> 5) & 15, z = (hit >>> 9) & 31;
assert(x >= 0 && x < 24 && y >= 0 && y < 16 && z >= 0 && z < 24);
edit(x, y, z, 0);
rebuild();
assert.notEqual(mesh.hash, original.hash, 'block edit did not change mesh');
assert.equal(mesh.pointer, original.pointer, 'block edit relocated mesh storage');
console.log('Verified deterministic world, finite geometry, persistent mesh, camera input, picking and block editing.');

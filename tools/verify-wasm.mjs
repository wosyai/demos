import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import assert from 'node:assert/strict';

const path = process.argv[2];
const file = process.argv[3] === '--binary'
  ? path : JSON.parse(readFileSync(path, 'utf8')).executable;
const binary = new WebAssembly.Module(readFileSync(file));
const imports = WebAssembly.Module.imports(binary);
const graphics = ['atlas', 'frame', 'mesh', 'outline', 'water'];
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
let atlasCount = 0;
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
    atlas(pointer, width, height) {
      assert.equal(width, 128);
      assert.equal(height, 16);
      const bytes = new Uint8Array(engine.memory.buffer, pointer, width * height * 4);
      const tileHashes = [];
      for (let tile = 0; tile < 8; tile++) {
        const tileBytes = [];
        for (let y = 0; y < height; y++) {
          for (let x = 0; x < 16; x++) {
            const i = (y * width + tile * 16 + x) * 4;
            assert.equal(bytes[i + 3], 255);
            tileBytes.push(...bytes.subarray(i, i + 3));
          }
        }
        assert(new Set(tileBytes).size > 8, 'block tile must have texture');
        tileHashes.push(createHash('sha256').update(Uint8Array.from(tileBytes)).digest('hex'));
      }
      assert.equal(new Set(tileHashes).size, 8, 'surface material tiles must be distinct');
      atlasCount++;
    },
    mesh(pointer, count) {
      mesh = layer(pointer, count, 3, 165888);
      const data = view(pointer, count * 6);
      for (let i = 0; i < data.length; i += 6) {
        assert(data[i + 3] > 0 && data[i + 3] < 1, 'baked atlas U outside bounds');
        assert(data[i + 4] > 0 && data[i + 4] < 1, 'baked atlas V outside bounds');
        assert(data[i + 5] > 0 && data[i + 5] <= 1, 'baked light outside bounds');
      }
    },
    water(pointer, count) { water = layer(pointer, count, 3, 6); },
    outline(pointer, count) { outline = layer(pointer, count, 2, 24); },
    frame(pointer, hit) { frame = { values: Array.from(view(pointer, 25)), hit }; },
  },
  wasi_snapshot_preview1: { proc_exit(code) { assert.fail('Wosy exited: ' + code); } },
}).exports;

const { _start, generate, rebuild, edit, pick, control, clear_controls, look, reset_camera, tick, edit_view, select_material, cycle_material, place_selected, seed_begin, seed_code_unit, seed_end, default_seed, pulse_control, edit_control, memory } = engine;
assert(memory instanceof WebAssembly.Memory);
for (const fn of [_start, generate, rebuild, edit, pick, control, clear_controls, look, reset_camera, tick, edit_view, select_material, cycle_material, place_selected, seed_begin, seed_code_unit, seed_end, default_seed, pulse_control, edit_control]) {
  assert.equal(typeof fn, 'function');
}
_start();
function seed(text, trim = 0) {
  seed_begin(trim);
  for (let i = 0; i < text.length; i++) {
    if (seed_code_unit(text.charCodeAt(i)) === 0) {
      assert.equal(seed_code_unit(52), 0, 'rejection must stay sticky until the next session');
      break;
    }
  }
  return seed_end();
}
assert.equal(default_seed(), 471);
for (const [text, expect] of [
  ['0', 0n], ['-0', 0n], ['00042', 42n], ['0'.repeat(5000) + '42', 42n],
  ['2147483647', 2147483647n], ['-2147483648', -2147483648n],
]) assert.equal(seed(text), expect, JSON.stringify(text.slice(-15)));
for (const invalid of ['', '-', '+1', '1e2', '2147483648', '-2147483649',
  '１２３', '1\n', ' 42 ', '1 2', '1234.5', '😊']) {
  assert.equal(seed(invalid), 2147483648n, JSON.stringify(invalid));
}
for (const [text, expect] of [
  ['\u00a0 -0012\ufeff\u2028', -12n], ['\r\n 18 \u3000', 18n],
  ['- 42', 2147483648n], ['\u0085' + '42', 2147483648n],
  ['4\u20002', 2147483648n], ['\u180e' + '42', 2147483648n], ['  ', 2147483648n],
]) assert.equal(seed(text, 1), expect, JSON.stringify(text));
generate(42);
assert(mesh.count > 0);
assert.equal(water.count, 0, 'inland setup should not render an ocean');
assert.equal(atlasCount, 1);
const original = mesh;
generate(42);
rebuild();
assert.deepEqual(mesh, original, 'seed did not reproduce mesh in the same storage');
assert.equal(atlasCount, 1, 'reseed must not regenerate the material atlas');
generate(471);
const firstSeed = mesh.hash;
generate(722);
assert.notEqual(mesh.hash, firstSeed, 'seeds separated by 251 must not produce identical terrain');
generate(42);
assert.deepEqual(mesh, original, 'the initial seed still reproduces the same world');

tick(0, 1, 0);
assert.equal(frame.hit, -1);
assert.equal(outline.count, 0);
const preview = frame.values.slice(0, 19);
tick(0, 1, 1);
assert.deepEqual(frame.values.slice(0, 19), preview, 'starting play must not snap away from the eye-level preview');
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
look(0.72664234 / 0.0034, -0.10 / 0.0034);
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

const pulsedFrom = frame.values[18];
pulse_control(1);
pulse_control(1);
tick(0, 1, 1);
assert.equal(frame.values[18], pulsedFrom);
tick(NaN, 1, 1);
assert.equal(frame.values[18], pulsedFrom);
tick(0.04, 1, 0);
tick(0, 1, 1);
assert.equal(frame.values[18], pulsedFrom);
tick(0.04, 1, 1);
const singlePulse = frame.values[18];
assert(singlePulse > pulsedFrom && singlePulse - pulsedFrom <= 0.20);
tick(0.04, 1, 1);
assert.equal(frame.values[18], singlePulse, 'pulse should expire after one active advancing tick');
control(1, 1);
pulse_control(1);
tick(0.04, 1, 1);
const duringHeld = frame.values[18];
tick(0.04, 1, 1);
assert(frame.values[18] > duringHeld, 'pulse expiry must not release still-held movement');
control(1, 0);
pulse_control(4);
clear_controls();
tick(0.04, 1, 1);
assert.equal(frame.values[17], ground, 'reset must discard pending jump');
pulse_control(4);
tick(0, 1, 1);
assert.equal(frame.values[17], ground, 'jump pulse waits for a positive active tick');
tick(0.04, 1, 1);
assert(frame.values[17] > ground && frame.values[23] === 0, 'one isolated jump pulse leaves the ground');
for (let i = 0; i < 36; i++) tick(0.04, 1, 1);
assert(Math.abs(frame.values[17] - ground) < 0.003 && frame.values[23] === 1, 'jump pulse lands without repeating');
pulse_control(7);
pulse_control(7);
tick(0, 1, 1);
assert.equal(frame.values[22], 0, 'two discrete flight taps should cancel before next tick');
pulse_control(7);
tick(0, 1, 1);
assert.equal(frame.values[22], 1, 'discrete flight change should not require time advancement');
pulse_control(7);
tick(0, 1, 1);
assert.equal(frame.values[22], 0);

control(7, 1);
control(7, 1);
pulse_control(7);
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

for (let y = 3; y <= 8; y++) {
  for (let x = 8; x < 18; x++) edit(x, y, 15, 0);
}
edit(12, 4, 10, 3);
rebuild();
reset_camera();
look(0.72664234 / 0.0034, -0.10 / 0.0034);
tick(0, 1, 1);
const [sx, sy, sz] = frame.values.slice(16, 19);
const aimedZ = () => {
  const target = pick(sx, sy, sz, 0, 0, -1);
  return target < 0 ? -1 : (target >>> 9) & 31;
};
assert.equal(aimedZ(), 10, 'generic ray should still see distant blocks');
assert.equal(frame.hit, -1, 'first-person editing ray must not target a block beyond reach');
assert.equal(edit_control(0, 2), -1, 'long-range edits must fail');
for (const z of [13, 14, 15]) edit(12, 4, z, 3);
rebuild();
tick(0, 1, 1);
assert.equal(aimedZ(), 15);
assert.equal(edit_control(0, 1), 1, 'holding break edits immediately');
assert.equal(aimedZ(), 14);
assert.equal(edit_control(0, 1), 0, 'duplicate press may not edit twice');
tick(0, 1, 1);
tick(NaN, 1, 1);
for (let i = 0; i < 6; i++) tick(0.06, 1, 0);
assert.equal(aimedZ(), 14, 'paused or invalid ticks must not advance held edits');
for (let i = 0; i < 3; i++) tick(0.06, 1, 1);
assert.equal(aimedZ(), 14, 'held edit must wait out the initial interval');
for (let i = 0; i < 2; i++) tick(0.06, 1, 1);
assert.equal(aimedZ(), 13, 'held edit advances to the next targeted block');
assert.equal(edit_control(0, 0), 0);
for (let i = 0; i < 8; i++) tick(0.06, 1, 1);
assert.equal(aimedZ(), 13, 'releasing the action must stop the repeat');
select_material(4);
assert.equal(edit_control(1, 2), 1, 'place one selected block in the face-adjacent cell');
assert.equal(aimedZ(), 14);
edit(12, 4, 14, 0);
edit(12, 4, 13, 0);
edit(12, 4, 10, 0);
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
console.log('Verified deterministic terrain, geometry, walking, jump and landing, solid walls, first-person break/build reach and repeat, flight and respawn.');

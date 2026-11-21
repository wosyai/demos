import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import assert from 'node:assert/strict';

const path = process.argv[2];
const file = process.argv[3] === '--binary'
  ? path : JSON.parse(readFileSync(path, 'utf8')).executable;
const binary = new WebAssembly.Module(readFileSync(file));
const imports = WebAssembly.Module.imports(binary);
const graphics = ['aim', 'atlas', 'frame', 'mesh', 'outline', 'player', 'water'];
assert.deepEqual(imports.filter((item) => item.module === 'showcase').map((item) => item.name).sort(), graphics);
for (const item of imports) {
  assert.equal(item.kind, 'function');
  assert(item.module === 'showcase' ||
    (item.module === 'wasi_snapshot_preview1' && item.name === 'proc_exit'));
}

let engine;
let frame, missionFlameFloor = 1;
let mesh;
let water;
let outline;
let avatar = {count:0}, avatarUploads = 0, aim = [0, 0];
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
        const light = data[i + 5];
        assert(light > 0 && (light <= 1 || Math.abs(light - 1.18) < .001 || Math.abs(light - 1.85) < .001),
          'baked light outside ordinary light or beacon signal bounds');
      }
    },
    water(pointer, count) { water = layer(pointer, count, 3, 1944); },
    outline(pointer, count) { outline = layer(pointer, count, 2, 24); },
    player(pointer, count) { avatar = layer(pointer, count, 3, 576); avatarUploads++; },
    aim(x, y) {
      assert(Number.isFinite(x) && Math.abs(x) <= .941);
      assert(Number.isFinite(y) && Math.abs(y) <= .941);
      aim = [x, y];
    },
    frame(pointer, hit) {
      frame = { values: Array.from(view(pointer, 29)), hit };
      if (frame.values[25] === 1 && frame.values[26] < missionFlameFloor) missionFlameFloor = frame.values[26];
    },
  },
  wasi_snapshot_preview1: { proc_exit(code) { assert.fail('Wosy exited: ' + code); } },
}).exports;

const { _start, generate, rebuild, edit, pick, control, clear_controls, look, reset_camera, tick, edit_view, select_material, cycle_material, place_selected, seed_begin, seed_code_unit, seed_end, default_seed, pulse_control, edit_control, cycle_camera, start_beacon, leave_beacon, memory } = engine;
assert(memory instanceof WebAssembly.Memory);
for (const fn of [_start, generate, rebuild, edit, pick, control, clear_controls, look, reset_camera, tick, edit_view, select_material, cycle_material, place_selected, seed_begin, seed_code_unit, seed_end, default_seed, pulse_control, edit_control, cycle_camera, start_beacon, leave_beacon]) {
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
assert.equal(water.count, 1944, 'one continuous sea surface surrounds the island');
const initialSea = water;
assert.equal((pick(12.5, 15, 0.5, 0, -1, 0) >>> 5) & 15, 0, 'shore bed should emerge from the sea');
assert.equal((pick(12.5, 15, 1.5, 0, -1, 0) >>> 5) & 15, 1, 'shore should have a shallow intermediate step');
assert.equal((pick(12.5, 15, 2.5, 0, -1, 0) >>> 5) & 15, 2, 'first dry step should emerge above the water');
tick(0.06, 1, 0);
assert.deepEqual(water, initialSea, 'pause should preserve wave phase');
tick(0, 1, 1);
assert.deepEqual(water, initialSea, 'zero-time ticks should preserve wave phase');
tick(0.06, 1, 1);
assert.notEqual(water.hash, initialSea.hash, 'positive play time should advance visible waves');
assert.equal(water.pointer, initialSea.pointer, 'sea should reuse geometry storage');
assert.equal(atlasCount, 1);
const original = mesh;
generate(42);
rebuild();
assert.deepEqual(mesh, original, 'seed did not reproduce mesh in the same storage');
assert.deepEqual(water, initialSea, 'regenerating should reset wave phase deterministically');
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
function renderedSeaAt(x, z) {
  const data = view(water.pointer, 1944 * 6);
  const col = Math.min(15, Math.floor((x + 20) / 4));
  const row = Math.min(15, Math.floor((z + 20) / 4));
  const cell = ((row + 1) * 18 + col + 1) * 36;
  const u = (x - data[cell]) / 4, v = (z - data[cell + 2]) / 4;
  const a = data[cell + 1], c = data[cell + 7], b = data[cell + 13], d = data[cell + 19];
  return u + v <= 1 ? a * (1 - u - v) + b * u + c * v : d * (u + v - 1) + b * (1 - v) + c * (1 - u);
}
for (let z = 16; z <= 23; z++) edit(12, Math.max(0, Math.min(2, 19 - z)), z, 3);
rebuild();
reset_camera();
look(0.72664234 / 0.0034, -0.10 / 0.0034);
tick(0, 1, 1);
const startZ = frame.values[18];
control(1, 1);
tick(0.04, 1, 1);
const dryStride = frame.values[18] - startZ;
assert(dryStride > 0.18 && dryStride < 0.20);
for (let i = 0; i < 18 && frame.values[18] < 18.30; i++) tick(0.04, 1, 1);
const shallowZ = frame.values[18];
assert(shallowZ >= 18.30 && shallowZ < 18.50);
control(1, 0);
for (let i = 0; i < 20; i++) tick(0.04, 1, 1);
assert(Math.abs(frame.values[17] - 3.62) < 0.005 && frame.values[23] === 1,
  'shallow water rests on the visible seafloor instead of sinking through it');
assert(renderedSeaAt(frame.values[16], shallowZ) > 2.20, 'the shallow collision is under the visible sea');
control(1, 1);
tick(0.04, 1, 1);
const shallowStride = frame.values[18] - shallowZ;
assert(shallowStride > 0.13 && shallowStride < dryStride - 0.01, 'shallow water slows wading less than the open sea');
for (let i = 0; i < 160 && frame.values[18] < 26; i++) tick(0.06, 1, 1);
assert(frame.values[18] >= 26 && frame.values[22] === 0, 'walk off the beach into deep water without needing flight');
control(1, 0);
for (let i = 0; i < 70; i++) tick(0.04, 1, 1);
const seaGap = () => frame.values[17] - renderedSeaAt(frame.values[16], frame.values[18]);
const floatingGap = seaGap();
assert(floatingGap >= 0.30 && floatingGap <= 0.72, 'buoyancy should settle with the eye just above the rendered wave');
assert.equal(frame.values[23], 0, 'floating must not be considered solid ground');
const floatingZ = frame.values[18];
control(1, 1);
tick(0.04, 1, 1);
control(1, 0);
const swimStride = frame.values[18] - floatingZ;
assert(swimStride > 0.08 && swimStride < dryStride * 0.8, 'deep water must resist motion more than dry land');
control(4, 1);
for (let i = 0; i < 44; i++) tick(0.04, 1, 1);
control(4, 0);
assert(seaGap() > floatingGap + 0.12, 'swim-up input should increase lift while immersed');
control(0, 1);
for (let i = 0; i < 60 && frame.values[18] > 22.5; i++) tick(0.04, 1, 1);
control(0, 0);
assert(frame.values[18] <= 22.5 && frame.values[22] === 0, 'swim back onto the shallow shoreline without applying creative flight');
control(0, 1);
for (let i = 0; i < 70 && frame.values[18] > 19.31; i++) tick(0.04, 1, 1);
assert(Math.abs(frame.values[18] - 19.3) < 0.025, 'the submerged step should block a swimmer who does not climb');
control(4, 1);
for (let i = 0; i < 30 && frame.values[18] > 18.65; i++) tick(0.04, 1, 1);
control(4, 0);
control(0, 0);
assert(frame.values[18] <= 18.65 && frame.values[18] > 18.25, 'a fresh swim stroke should clear the shoreline sill');
for (let i = 0; i < 35; i++) tick(0.04, 1, 1);
assert(Math.abs(frame.values[17] - 3.62) < 0.005 && frame.values[23] === 1, 'the player can stand on the shallow sill');
control(0, 1);
control(4, 1);
for (let i = 0; i < 35 && frame.values[18] > 17.65; i++) tick(0.04, 1, 1);
control(0, 0);
for (let i = 0; i < 40; i++) tick(0.04, 1, 1);
control(4, 0);
assert(frame.values[18] <= 17.65 && frame.values[17] - 1.62 > renderedSeaAt(frame.values[16], frame.values[18]),
  'swimming up and jumping should enable dry egress, not only oscillation in the water');
assert(Math.abs(frame.values[17] - 4.62) < 0.005 && frame.values[23] === 1,
  'reaching shore lands once without automatic jump repetition while holding Jump');
pulse_control(7);
control(1, 1);
for (let i = 0; i < 45 && frame.values[18] < 24.5; i++) tick(0.04, 1, 1);
control(1, 0);
control(5, 1);
for (let i = 0; i < 22 && frame.values[17] > 2.15; i++) tick(0.04, 1, 1);
control(5, 0);
assert(frame.values[17] < renderedSeaAt(frame.values[16], frame.values[18]) && frame.values[18] > 24.5);
const flyingZ = frame.values[18];
control(1, 1);
tick(0.04, 1, 1);
control(1, 0);
assert.equal(frame.values[22], 1);
assert(Math.abs(frame.values[18] - flyingZ - dryStride) < 0.001, 'creative flight ignores water resistance');

console.log('Verified deterministic terrain, geometry, walking, jump and landing, solid walls, first-person break/build reach and repeat, flight, respawn, and sea physics.');

generate(42);
reset_camera();
look(0.72664234 / 0.0034, -0.10 / 0.0034);
tick(0, 1, 1);
const eye = frame.values.slice(16, 19);
const [ix, iy, iz] = eye.map(Math.floor);
assert(ix > 4 && iy > 1 && iz >= 6 && iz < 19, 'fixture uses the central terrain spawn');
for (let z = iz - 5; z <= iz + 4; z++) {
  for (let x = ix - 2; x <= ix + 2; x++) {
    for (let y = iy; y <= iy + 2; y++) edit(x, y, z, 0);
  }
}
edit(ix, iy, iz - 3, 3);
tick(0, 1, 1);
const aimTarget = frame.hit;
assert(aimTarget >= 0 && (aimTarget >>> 9 & 31) === iz - 3);
assert.equal(avatar.count, 0);
assert.equal(cycle_camera(), 1);
tick(0, 1, 1);
const shoulder = frame.values.slice(16, 19);
const cameraDistance = (position) => Math.hypot(...position.map((value, i) => value - eye[i]));
assert(cameraDistance(shoulder) > 3.5, 'clear third-person camera sits behind the player');
assert(shoulder[0] > eye[0] && shoulder[2] > eye[2], 'third person uses a shoulder offset');
assert.equal(frame.hit, aimTarget, 'changing perspective preserves player-eye target');
assert.equal(avatar.count, 288, 'six body parts, hat, and pack produce original Wosy geometry');
assert(aim[0] < 0 && aim[1] < 0);
const aimPoint = [eye[0], eye[1], iz - 2];
const project = (k) => frame.values[12 + k] +
  aimPoint[0] * frame.values[k] + aimPoint[1] * frame.values[4 + k] + aimPoint[2] * frame.values[8 + k];
assert(Math.abs(aim[0] - project(0) / project(3)) < .003, 'third-person reticle follows the actual edited surface');
assert(Math.abs(aim[1] - project(1) / project(3)) < .003);
const aimSquare = aim[0], submitted = avatarUploads;
tick(0, .65, 1);
assert(Math.abs(aim[0]) > Math.abs(aimSquare), 'portrait reticle accounts for viewport aspect');
assert.equal(avatarUploads, submitted, 'the unchanged avatar is not submitted again');
const grazing = [ix + 1, Math.floor(eye[1] + .18 * 1.45 + .04), iz + 1];
assert.equal(edit(...grazing, 3), 1, 'grazing-wall fixture starts clear');
tick(0, .35, 1);
assert(cameraDistance(frame.values.slice(16, 19)) > 3.65, 'narrow frustum clears wall outside central boom');
tick(0, 2.8, 1);
assert(cameraDistance(frame.values.slice(16, 19)) < 2.0, 'wide near-plane corner retracts before grazing side wall');
assert.equal(frame.hit, aimTarget, 'aspect changes camera clearance, not the player target');
assert.equal(edit(...grazing, 0), 1);
const obstruction = eye.map((value, i) => Math.floor(value + (shoulder[i] - value) * .46));
assert(edit(...obstruction, 3) === 1);
tick(0, 1, 1);
assert(cameraDistance(frame.values.slice(16, 19)) < 2.2, 'voxel behind player retracts camera');
assert.equal(frame.hit, aimTarget, 'camera obstruction is not an edit target');
assert.equal(edit_control(0, 2), 1, 'third-person controls break the outlined block');
tick(0, 1, 1);
assert.notEqual(frame.hit, aimTarget);
assert.equal(cycle_camera(), 0);
tick(0, 1, 1);
assert.deepEqual(frame.values.slice(16, 19), eye, 'first-person pose returns to player eye');
assert.deepEqual(aim, [0, 0]);
assert.equal(avatar.count, 0, 'first person clears the player geometry');
assert.equal(cycle_camera(), 1);
tick(0, 1, 0);
assert.equal(avatar.count, 0, 'menu does not render avatar');
assert.deepEqual(aim, [0, 0]);
tick(0, 1, 1);
assert.notDeepEqual(frame.values.slice(16, 19), eye, 'play retains the selected perspective');
assert.equal(cycle_camera(), 0);
edit(...obstruction, 0);
pulse_control(7);
control(4, 1);
tick(.05, 1, 1);
control(4, 0);
const raisedEye = frame.values.slice(16,19);
assert(raisedEye[1] > iy + .83 && raisedEye[1] < iy + 1, 'elevated test ray passes below a ceiling');
edit(ix, iy, iz - 3, 3);
edit(ix, iy + 1, iz - 1, 3);
tick(0, 1, 1);
const underCeiling = frame.hit;
assert.equal(underCeiling, aimTarget, 'player-eye ray sees the original block beneath the overhang');
assert.equal(cycle_camera(), 1);
tick(0, 1, 1);
assert.equal(frame.hit, underCeiling, 'fallback retains the visible player-eye edit target');
assert.deepEqual(frame.values.slice(16,19), raisedEye, 'terrain occlusion retracts camera to the player eye');
assert.deepEqual(aim, [0, 0], 'the original target stays visible at the centered reticle');
assert.equal(avatar.count, 0, 'the avatar does not obscure a retracted camera');
assert.equal(edit_control(0, 2), 1, 'the retracted camera shows the target being edited');
tick(0, 1, 1);
assert.notDeepEqual(frame.values.slice(16,19), raisedEye, 'chase view returns once the target is no longer occluded');
assert.equal(cycle_camera(), 0);
console.log('Verified exact Wosy chase camera, obstructed terrain, player mesh, projected reticle and player-origin editing.');


const coords = () => frame.values.slice(16, 19);
const phase = () => frame.values[25];
const missionHUD = () => frame.values.slice(25);
const steps = (count, seconds = .05, playing = 1) => {
  for (let i = 0; i < count; i++) tick(seconds, 1, playing);
};
function moveUntil(axis, index, goal, sign, cap = 80) {
  control(axis, 1);
  for (let i = 0; i < cap && (goal - coords()[index]) * sign > 0 && phase() === 1; i++) tick(.05, 1, 1);
  control(axis, 0);
}
function moveOn(axis, index, goal, sign, message, cap = 80) {
  moveUntil(axis, index, goal, sign, cap);
  assert((goal - coords()[index]) * sign <= .01, message + ': ' + coords());
}
function jumpNorth(goal, message) {
  control(4, 1);
  moveOn(0, 2, goal, -1, message, 28);
  control(4, 0);
  steps(14);
}

function aimNorthAt(y, z) {
  const [, eyeY, eyeZ] = coords();
  const pitch = Math.atan2(y - eyeY, eyeZ - z);
  look(0, (frame.values[19] - pitch) / .0034);
  tick(0, 1, 1);
}
function enterLighthouse() {
  moveUntil(0, 2, 5.6, -1, 40);
  jumpNorth(4.55, 'jump up one deck to the lighthouse entry');
  moveOn(0, 2, 3.98, -1, 'carry the lantern through the lighthouse door');
  assert.equal(phase(), 2, 'success requires physical arrival at the dry lighthouse');
}

generate(726);
edit(12, 14, 16, 5);
select_material(4);
rebuild();
const editedSandbox = mesh;
assert(start_beacon() > 0);
tick(0, 1, 1);
const freshMission = mesh, freshWater = water, spawn = coords();
assert.deepEqual(missionHUD(), [1, 1, 0, 7]);
assert.deepEqual([spawn[0], spawn[2]], [11.5, 21.5]);
assert.equal(edit(11, 4, 21, 0), -4, 'raw edit cannot bypass the mission rules');
assert.deepEqual(mesh, freshMission);
assert(frame.values[23] === 1 && spawn[1] > 6.6, 'mission spawns on dry starting deck');
const lanternColor = () => view(mesh.pointer, mesh.count * 6).filter((c, i) => i % 6 === 5 && c > 1);
assert(lanternColor().length > 0 && lanternColor().every(c => Math.abs(c - 1.18) < .001),
  'the lighthouse emits a distinct warm position marker before the run is won');
steps(70, .06, 0);
assert.deepEqual(missionHUD(), [1, 1, 0, 7], 'preview or pause must not advance the tide or flame');
assert.deepEqual(water, freshWater);
pulse_control(7);
control(7, 1);
tick(.05, 1, 1);
control(7, 0);
assert.equal(frame.values[22], 0, 'sticky or pulsed flight inputs cannot fly in Beacon Run');
select_material(3);
cycle_material(1);
tick(0, 1, 1);
assert.equal(frame.values[24], 5, 'mission stock is one material, regardless of sandbox keys');

moveOn(0, 2, 16.5, -1, 'south end of center bridge corridor');
aimNorthAt(4, 14.5);
assert(frame.hit >= 0 && (frame.hit & 31) === 11 && ((frame.hit >>> 9) & 31) === 14 &&
  (frame.hit >>> 14) === 3, 'the first bridge piling is aimable from the dry starting shore');
assert.equal(place_selected(), 1);
tick(0, 1, 1);
assert.equal(frame.values[28], 6, 'placing a beam consumes one wood');
assert.equal(edit_view(0), 1);
tick(0, 1, 1);
assert.equal(frame.values[28], 7, 'breaking a placed beam recovers its piece of wood');
assert.equal(edit_view(0), -4, 'the authored piling cannot be broken');

for (const piling of [14, 12, 10]) {
  aimNorthAt(4, piling + .5);
  assert.equal(place_selected(), 1, 'extend the dry surface above piling ' + piling);
  aimNorthAt(4.5, piling + 1);
  assert.equal(place_selected(), 1, 'place adjacent wood in the next unbridged cell');
  moveOn(0, 2, piling + .55, -1, 'walk the completed portion of the bridge');
}
aimNorthAt(4.45, 8.97);
assert.equal(place_selected(), 1, 'join the remaining open cell to the far rock bank');
tick(0, 1, 1);
assert.equal(frame.values[28], 0, 'full dry bridge uses exactly the visible wood stock');
moveOn(0, 2, 6.50, -1, 'cross all seven cells of the player-built bridge');
enterLighthouse();
assert.equal(frame.values[26], 1, 'the complete bridge keeps the flame dry');

function westStride(wait, finish = false) {
  start_beacon();
  missionFlameFloor = 1;
  tick(0, 1, 1);
  const surfaceLow = renderedSeaAt(4.5, 14.5);
  if (wait) steps(wait, .06);
  assert.equal(phase(), 1, 'harbor remains safe even at high tide');
  moveOn(2, 0, 4.66, -1, 'west route access');
  moveOn(0, 2, 14.2, -1, 'west cut shelf');
  steps(8);
  const before = coords();
  const surface = renderedSeaAt(before[0], before[2]);
  if (wait >= 275) assert(surface > surfaceLow + 1.4, 'high tide actually reaches the route, not just the HUD');
  if (!wait) assert(surface < 3.08, 'the cut is initially mostly dry');
  control(0, 1);
  tick(.05, 1, 1);
  control(0, 0);
  const stride = before[2] - coords()[2];
  if (finish) {
    aimNorthAt(3.5, 12.99);
    assert(frame.hit >= 0 && ((frame.hit >>> 9) & 31) === 12 && ((frame.hit >>> 5) & 15) === 3);
    assert.equal(edit_view(0), 1, 'break the bottom plug from the marked route');
    aimNorthAt(4.5, 12.99);
    assert(frame.hit >= 0 && ((frame.hit >>> 9) & 31) === 12 && ((frame.hit >>> 5) & 15) === 4);
    assert.equal(edit_view(0), 1, 'open player-height clearance through the tidal shortcut');
    moveOn(0, 2, 10.65, -1, 'walk through the broken sand gate', 33);
    assert.equal(frame.values[28], 7, 'digging sand does not change bridge stock');
    if (wait) assert(missionFlameFloor < .97 && frame.values[25] === 1, 'the flooded cut may briefly soak the flame without ending the run');
    moveUntil(0, 2, 9.1, -1, 14);
    jumpNorth(8.44, 'leave the low cut onto the north shelf');
    jumpNorth(6.65, 'step from the shelf onto the dry headland');
    moveOn(3, 0, 11.42, 1, 'reach lighthouse from the tidal cut');
    enterLighthouse();
    assert.equal(frame.values[26], 1, 'the flame fully recovers on dry land');
  }
  return stride;
}
const earlyCut = westStride(0, true), lateCut = westStride(280);
assert(earlyCut > .20 && lateCut < earlyCut * .80 && lateCut > .07,
  'walking the same cut is swift early and loses time in the rising sea');
westStride(130, true);

start_beacon();
tick(0, 1, 1);
moveOn(3, 0, 13.35, 1, 'choose open channel instead of wood pilings');
moveOn(0, 2, 12.6, -1, 'enter deep open water without holding Jump');
steps(170);
assert.equal(phase(), 3, 'leaving the lantern immersed in deep water extinguishes the run');
assert.equal(frame.values[26], 0);
const knownFailure = [coords(), water, mesh, missionHUD()];
control(0, 1);
steps(90);
control(0, 0);
assert.deepEqual([coords(), water, mesh, missionHUD()], knownFailure, 'finished run freezes terrain, clock-driven water and motion');

start_beacon();
tick(0, 1, 1);
moveOn(3, 0, 13.35, 1, 'travel to open water for the Swim Up stress case');
moveOn(0, 2, 12.6, -1, 'enter open water');
control(4, 1);
steps(250, .05);
control(4, 0);
assert.equal(phase(), 3, 'a single held Swim Up cannot keep the carried flame dry indefinitely');

start_beacon();
tick(0, 1, 1);
assert.deepEqual(coords(), spawn);
assert.deepEqual(mesh, freshMission);
assert.deepEqual(water, freshWater);
assert.deepEqual(missionHUD(), [1, 1, 0, 7], 'retry restores tide, lamp, wood, terrain and spawn');

moveOn(3, 0, 20.40, 1, 'east ridge entrance');
moveUntil(0, 2, 14.30, -1, 70);
assert(Math.abs(coords()[2] - 15.3) < .05, 'first ridge rise blocks walking');
jumpNorth(13.80, 'jump the first ridge rise');
moveUntil(0, 2, 12.30, -1, 40);
assert(Math.abs(coords()[2] - 13.3) < .05, 'second ridge rise blocks walking');
jumpNorth(11.80, 'jump the second ridge rise');
moveOn(0, 2, 6.75, -1, 'come off the ridge onto the north headland, clear of the lighthouse ramp');
moveOn(2, 0, 11.66, -1, 'line up with the lighthouse door');
enterLighthouse();
assert(lanternColor().length > 0 && lanternColor().every(c => Math.abs(c - 1.85) < .001),
  'the finished lighthouse shows the brighter lit signal');
assert(Math.abs(coords()[1] - 7.62) < .02 && frame.values[23] === 1);
assert(leave_beacon() > 0);
tick(0, 1, 1);
assert.equal(phase(), 0);
assert.deepEqual(mesh, editedSandbox, 'return to sandbox retains exact prior user edits');
assert.equal(frame.values[24], 4);
pulse_control(7);
tick(0, 1, 1);
assert.equal(frame.values[22], 1, 'sandbox flight is restored after the mission');
console.log('Verified Beacon Run high-tide route tradeoff, wet loss, retry, wood bridge editing, dry ridge victory, lit beacon and retained sandbox.');

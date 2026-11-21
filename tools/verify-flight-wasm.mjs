import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';

const file = process.argv[2] ?? new URL('../flight/flight.wasm', import.meta.url);
const module = new WebAssembly.Module(readFileSync(file));
const expected = ['aircraft', 'frame', 'record', 'world'];
const imports = WebAssembly.Module.imports(module);
assert.deepEqual(imports.filter(entry => entry.module === 'flight').map(entry => entry.name).sort(), expected);
assert(imports.every(({ module, name, kind }) => kind === 'function' &&
  (module === 'flight' || (module === 'wasi_snapshot_preview1' && name === 'proc_exit'))));

let engine;
let scene;
let sceneUpdates = 0;
let sceneryRange;
let aircraft;
let aircraftSize = 0;
let frame;
let records = [];
function floats(pointer, length) {
  assert(Number.isInteger(pointer) && pointer >= 0 && pointer % 4 === 0);
  assert(Number.isInteger(length) && length >= 0 && length <= 1_000_000);
  const buffer = engine.memory.buffer;
  assert(pointer + length * 4 <= buffer.byteLength);
  const value = new Float32Array(buffer, pointer, length);
  assert(value.every(Number.isFinite));
  return value;
}
function mesh(pointer, length) {
  assert(length > 0 && length % 18 === 0, 'expected interleaved position/RGB triangles');
  const view = floats(pointer, length);
  let color = 0;
  for (let i = 3; i < length; i += 6) {
    for (let j = 0; j < 3; j++) assert(view[i + j] >= 0 && view[i + j] <= 1.25,
      'lighting may boost color above one, but vertex colors must remain bounded');
    color |= Number(view[i] || view[i + 1] || view[i + 2]) > 0 ? 1 : 0;
  }
  assert(color, 'mesh should contain visible color');
  return createHash('sha256').update(new Uint8Array(view.buffer, view.byteOffset, view.byteLength)).digest('hex');
}
engine = new WebAssembly.Instance(module, {
  flight: {
    world(pointer, length) { scene = mesh(pointer, length); sceneryRange = [pointer, length]; sceneUpdates++; },
    aircraft(pointer, length) {
      aircraft = mesh(pointer, length);
      aircraftSize = length;
      if (sceneryRange) {
        const [staticPointer, staticLength] = sceneryRange;
        assert(pointer + length * 4 <= staticPointer || staticPointer + staticLength * 4 <= pointer,
          'retained static scenery must not share its buffer with moving geometry');
      }
    },
    frame(pointer, length) { frame = Array.from(floats(pointer, length)); },
    record(pointer, length) {
      assert(Number.isInteger(length) && length > 0 && length <= 500_000);
      const buffer = engine.memory.buffer;
      assert(pointer >= 0 && pointer + length <= buffer.byteLength);
      records.push(new Uint8Array(buffer, pointer, length).slice());
    },
  },
  wasi_snapshot_preview1: { proc_exit(code) { assert.fail(`Wosy exited with ${code}`); } },
}).exports;
assert(engine.memory instanceof WebAssembly.Memory);
for (const fn of ['_start', 'reset', 'tick', 'ghost_begin', 'ghost_byte', 'ghost_end']) assert.equal(typeof engine[fn], 'function');
engine._start();

function drive(course, input, aspect) {
  aircraft = frame = null;
  records = [];
  engine.reset(course);
  for (let i = 0; i < 90; i++) engine.tick(1 / 60, i < 20 ? 0 : input, aspect);
  assert(scene && aircraft && frame, 'reset and tick must provide all three render layers');
  assert.equal(mesh(...sceneryRange), scene, 'moving geometry must leave static scenery bytes intact');
  assert(frame.length >= 28 && frame[16] === course);
  assert(frame[17] > 0, 'the simulated clock must advance');
  assert(frame[18] >= 0 && frame[19] >= 0 && frame[21] > 0);
  assert([0, 1, 2].includes(frame[22]));
  assert(frame.slice(0, 16).some(value => value !== 0));
  return { scene, aircraft, frame };
}
const farm = drive(0, 0, 16 / 9);
const farmUpdates = sceneUpdates;
assert.deepEqual(drive(0, 0, 16 / 9), farm, 'identical controls and reset should replay identically');
assert.equal(sceneUpdates, farmUpdates, 'same-course retry must reuse the static mesh');
const banking = drive(0, 1, 16 / 9);
assert.notDeepEqual(banking.frame.slice(0, 16), farm.frame.slice(0, 16), 'banking changes the Wosy chase camera');
const portrait = drive(0, 0, 9 / 16);
assert.notDeepEqual(portrait.frame.slice(0, 16), farm.frame.slice(0, 16), 'aspect changes Wosy projection');
assert.deepEqual(portrait.frame.slice(16), farm.frame.slice(16), 'aspect cannot tilt the flight model');
const paris = drive(1, 0, 16 / 9);
assert.notEqual(paris.scene, farm.scene, 'the courses must have distinct terrain and scenery');
assert.notEqual(paris.aircraft, farm.aircraft, 'each course needs its own aircraft geometry');
assert.equal(records.length, 0, 'opening seconds should not record a course completion');

const traces = JSON.parse(readFileSync(new URL('../flight/test/reference-controls.json', import.meta.url), 'utf8'));
assert.deepEqual(traces.map(({ course, shortcut }) => [course, Number(shortcut)]).sort(), [[0, 0], [0, 1], [1, 0], [1, 1]]);
for (const { course, shortcut, controls } of traces) {
  engine.reset(1 - course);
  engine.reset(course);
  records = [];
  engine.tick(0, 0, 16 / 9);
  assert.equal(frame[23], 0);
  let previous = 0;
  let steps = 0;
  const route = [...controls, [controls.at(-1)[0], 15]];
  for (const [mask, count] of route) {
    assert(Number.isInteger(mask) && mask >= 0 && mask <= 63);
    assert(Number.isInteger(count) && count > 0 && count <= 7200);
    for (let i = 0; i < count && frame[22] === 0; i++) {
      engine.tick(1 / 30, mask, 16 / 9);
      steps++;
      assert(frame[20] >= previous && frame[20] - previous <= 1, 'gates must advance in order');
      previous = frame[20];
    }
    if (frame[22] !== 0) break;
  }
  assert.equal(frame[22], 1, `expected a clean landing: course=${course} shortcut=${shortcut} gates=${frame[20]} ticks=${steps}`);
  assert.equal(frame[20], frame[21]);
  assert.equal(frame[25], Number(shortcut));
  assert(frame[23] > 0 && frame[24] > frame[20] * 100);
  assert.equal(records.length, 1);
  const packet = records[0];
  const elapsed = frame[23];

  function receive(bytes) {
    engine.ghost_begin();
    for (const byte of bytes) engine.ghost_byte(byte);
    engine.ghost_end();
    engine.tick(0, 0, 16 / 9);
  }
  engine.reset(1 - course);
  receive(packet);
  assert.equal(frame[23], 0, 'a race record cannot cross courses');
  engine.reset(course);
  receive(packet.subarray(0, packet.length - 1));
  assert.equal(frame[23], 0, 'truncated storage must not become a best time');
  const impossible = new Uint8Array(180 + 6);
  impossible.set([87, 70, 1, course, 180, 0]);
  receive(impossible);
  assert.equal(frame[23], 0, 'a well-formed packet without a legal finish must not set the best time');
  for (let i = 0; i < 60; i++) engine.tick(1 / 30, 1, 16 / 9);
  const soloSize = aircraftSize;
  const soloGates = frame[20];
  engine.reset(course);
  receive(packet);
  assert.equal(frame[23], elapsed, 'same-course record restores its exact time');
  for (let i = 0; i < 60; i++) engine.tick(1 / 30, 1, 16 / 9);
  assert.equal(frame[20], soloGates, 'gate cues must not be counted as a replay aircraft');
  assert(aircraftSize > soloSize, 'Wosy must emit the extra replay aircraft');

  if (course === 0 && Number(shortcut) === 0) {
    const expectedResult = [previous, 1, elapsed, Number(shortcut)];
    engine.reset(1 - course);
    engine.reset(course);
    engine.tick(0, 0, 16 / 9);
    for (const [mask, count] of route) {
      for (let i = 0; i < count * 2 && frame[22] === 0; i++) engine.tick(1 / 60, mask, 16 / 9);
      if (frame[22] !== 0) break;
    }
    assert.deepEqual([frame[20], frame[22], frame[23], frame[25]], expectedResult,
      'same fixed-step controls at 30 and 60 Hz rendering must produce the same gates, landing and replay time');
  }
}
console.log('Flying Low: exact WASM ABI, both route variants landed on both courses, deterministic steering, portrait projection, and saved ghost validation passed.');

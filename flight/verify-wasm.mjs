import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const module = new WebAssembly.Module(readFileSync(process.argv[2]));
assert.deepEqual(WebAssembly.Module.imports(module).map(({ module, name }) => `${module}.${name}`).sort(), [
    "flight.aircraft", "flight.frame", "flight.record", "flight.world",
]);

let engine;
let frame;
let world;
let aircraft;
let worldPointer;
let aircraftPointer;
let worldUploads = 0;
let packet;
function readFloats(pointer, length, stride, limit) {
    assert(Number.isInteger(pointer) && pointer >= 0 && pointer % 4 === 0);
    assert(Number.isInteger(length) && length > 0 && length <= limit && length % stride === 0);
    assert(pointer + length * 4 <= engine.memory.buffer.byteLength);
    const values = new Float32Array(engine.memory.buffer, pointer, length).slice();
    assert(values.every(Number.isFinite));
    return values;
}
engine = new WebAssembly.Instance(module, { flight: {
    world(pointer, length) {
        worldPointer = pointer;
        world = readFloats(pointer, length, 18, 196608);
        worldUploads += 1;
    },
    aircraft(pointer, length) {
        aircraftPointer = pointer;
        aircraft = readFloats(pointer, length, 18, 12288);
    },
    frame(pointer, length) {
        frame = readFloats(pointer, length, 1, 28);
        assert.equal(frame.length, 28);
    },
    record(pointer, length) {
        assert(length >= 186 && length <= 7206);
        assert(pointer >= 0 && pointer + length <= engine.memory.buffer.byteLength);
        packet = new Uint8Array(engine.memory.buffer, pointer, length).slice();
    },
} }).exports;
engine._start();

const tick = (mask = 0, dt = 1 / 30, aspect = 1.65) => engine.tick(dt, mask, aspect);
function load(data) {
    engine.ghost_begin();
    for (const octet of data) engine.ghost_byte(octet);
    engine.ghost_end();
}
function reset(course) {
    engine.reset(course);
    tick(0, 0);
    assert.equal(frame[16], course);
    assert.equal(frame[17], 0);
    assert.equal(frame[20], 0);
    assert.equal(frame[21], 11);
    assert.equal(frame[22], 0);
    assert(aircraft.length >= 1000);
    assert(world.length >= 10000);
}

reset(0);
const farmWorld = world;
assert(worldPointer + world.length * 4 <= aircraftPointer || aircraftPointer + aircraft.length * 4 <= worldPointer,
    "persistent static and streamed moving meshes have disjoint backing");
const farmAircraft = aircraft;
const startFrame = frame;
for (let i = 0; i < 108; i++) tick(16);
assert(frame[18] > startFrame[18], "throttle accelerates");
assert.equal(frame[20], 1, "first rural gate is reachable with throttle");
assert.deepEqual(new Float32Array(engine.memory.buffer, worldPointer, world.length), farmWorld,
    "moving frames never mutate static geometry needed on graphics restore");
const allForward = [frame, aircraft];
reset(0);
assert.equal(worldUploads, 1, "retrying the same course does not rebuild or reupload terrain");
for (let i = 0; i < 108; i++) tick(16);
assert.deepEqual([frame, aircraft], allForward, "fixed control replay is deterministic");

// At the neutral spawn, the plane's cloth and framing are axis aligned. Check
// that two positive-area triangle interiors never compete on the same plane.
function cross(a, b, p) {
    return (b[0] - a[0]) * (p[1] - a[1]) - (b[1] - a[1]) * (p[0] - a[0]);
}
function overlapArea(left, right) {
    let shape = left;
    const winding = Math.sign(cross(...right));
    for (let i = 0; i < 3 && shape.length; i++) {
        const a = right[i], b = right[(i + 1) % 3];
        const clipped = [];
        for (let j = 0; j < shape.length; j++) {
            const p = shape[j], q = shape[(j + 1) % shape.length];
            const dp = cross(a, b, p) * winding, dq = cross(a, b, q) * winding;
            if (dp >= 0) clipped.push(p);
            if ((dp < 0) !== (dq < 0)) {
                const t = dp / (dp - dq);
                clipped.push([p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t]);
            }
        }
        shape = clipped;
    }
    let doubledArea = 0;
    for (let i = 0; i < shape.length; i++) {
        const a = shape[i], b = shape[(i + 1) % shape.length];
        doubledArea += a[0] * b[1] - a[1] * b[0];
    }
    return Math.abs(doubledArea) / 2;
}
function assertNonOverlappingParisPanels(values) {
    // Two 72-vertex gate meshes precede the player; no ghost at the start.
    const triangles = [];
    for (let i = 144 * 6; i < values.length; i += 18) {
        const corners = [0, 6, 12].map((v) => Array.from(values.subarray(i + v, i + v + 3)));
        const axis = [0, 1, 2].find((n) => corners.every((p) => Math.abs(p[n] - corners[0][n]) < 0.00005));
        if (axis === undefined) continue;
        const plane = corners[0][axis];
        const projected = corners.map((p) => p.filter((_, n) => n !== axis));
        if (Math.abs(cross(...projected)) < 0.00001) continue;
        for (const previous of triangles) {
            if (previous.axis !== axis || Math.abs(previous.plane - plane) >= 0.00005) continue;
            assert(overlapArea(projected, previous.projected) < 0.00008,
                `overlapping aircraft triangles on axis ${axis} at ${plane}`);
        }
        triangles.push({ axis, plane, projected });
    }
    assert(triangles.length > 60, "the panel check covers the actual aircraft geometry");
}

reset(1);
assert.equal(worldUploads, 2, "changing course publishes new terrain");
assert.notDeepEqual(world, farmWorld, "courses draw different scenery");
assert.notDeepEqual(aircraft, farmAircraft, "courses draw different airplanes and gates");
assertNonOverlappingParisPanels(aircraft);
const parisPose = [frame, aircraft];
for (let i = 0; i < 4; i++) {
    tick(0, 0);
    assert.deepEqual([frame, aircraft], parisPose, "repeated presentation of a stationary pose is stable");
}
tick(0, 0, 0.55);
assert(frame[0] > startFrame[0] && frame[3] === 0, "portrait changes projection rather than the camera mode");
for (let i = 0; i < 140; i++) tick(16);
assert.equal(frame[20], 1, "first city gate is reachable with throttle");

reset(1);
const malformed = [
    [87, 70, 1, 1, 180, 0, ...Array(180).fill(0)],
    [87, 70, 2, 1, 180, 0, ...Array(180).fill(0)],
    [87, 70, 1, 0, 180, 0, ...Array(180).fill(0)],
    [87, 70, 1, 1, 181, 0, ...Array(180).fill(0)],
    [87, 70, 1, 1, 180, 0, ...Array(179).fill(0), 255],
];
for (const bytes of malformed) {
    load(bytes);
    tick(0, 0);
    assert.equal(frame[23], 0, "rejects corrupt, mismatched, or unfinished ghost runs");
}
assert.equal(packet, undefined, "never publishes a record before landing");
console.log("Flight WASM: ABI, two scenes, both first gates, fixed-step replay, and ghost envelope verified");

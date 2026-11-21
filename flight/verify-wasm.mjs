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
        frame = readFloats(pointer, length, 1, 31);
        assert.equal(frame.length, 31);
        assert(frame[28] >= -1 && frame[28] <= 1, "turn cue is bounded");
        assert([0, 1, 2, 3, 4].includes(frame[29]), "landing enum is recognized");
        assert(frame[30] === 0 || frame[30] === 1, "shortcut availability is Boolean");
    },
    record(pointer, length) {
        assert(length >= 186 && length <= 14406);
        assert(pointer >= 0 && pointer + length <= engine.memory.buffer.byteLength);
        packet = new Uint8Array(engine.memory.buffer, pointer, length).slice();
    },
} }).exports;
engine._start();
assert.equal(engine.input_version(), 1);

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
const hostAnalog = (bank, pitch, power = 0) => 64 | (power & 48) | ((bank & 255) << 8) | ((pitch & 255) << 16);
function headingAfter(input) {
    reset(0);
    for (let i = 0; i < 21; i++) tick(input);
    return frame[3];
}
const weakRight = headingAfter(hostAnalog(63, 0));
const digitalRight = headingAfter(2);
assert(weakRight > 0 && weakRight < digitalRight, "partial joystick motion banks proportionally");
assert.equal(headingAfter(hostAnalog(-127, 0) | 2), digitalRight, "keyboard wins on its own axis");
assert(headingAfter(hostAnalog(-127, 0)) < 0, "signed joystick left is preserved");

const route = JSON.parse(readFileSync(new URL("test/reference-controls.json", import.meta.url), "utf8"))
    .find(({ course, shortcut }) => course === 0 && !shortcut);
function analogEquivalent(mask) {
    const bank = Number((mask & 2) !== 0) - Number((mask & 1) !== 0);
    const pitch = Number((mask & 4) !== 0) - Number((mask & 8) !== 0);
    return hostAnalog(bank * 127, pitch * 127, mask);
}
function finishWith(convert, expectedVersion) {
    packet = undefined;
    reset(1);
    reset(0);
    assert.deepEqual(Array.from(frame.subarray(28)), [0, 0, 0]);
    let sawShortcut = false, sawLanding = false;
    for (const [mask, count] of route.controls) {
        for (let i = 0; i < count; i++) {
            tick(convert(mask));
            if (frame[20] === 6) sawShortcut ||= frame[30] === 1;
            else assert.equal(frame[30], 0, "shortcut offer is exclusive to that gate");
            if (frame[26] && frame[22] === 0) sawLanding ||= frame[29] > 0;
        }
    }
    for (let i = 0; i < 15 && frame[22] === 0; i++) tick(convert(route.controls.at(-1)[0]));
    assert.equal(frame[22], 1, "authored flight lands with the selected control style");
    assert(sawShortcut && sawLanding, "flight visits actual shortcut and landing guidance");
    assert(packet, "landing emits an authentic replay packet");
    assert.equal(packet[2], expectedVersion);
    assert.equal(packet.length, 6 + (packet[4] + packet[5] * 256) * expectedVersion);
    return { time: frame[17], data: packet };
}
const classic = finishWith((mask) => mask, 1);
const proportional = finishWith(analogEquivalent, 2);
assert.equal(classic.time, proportional.time, "full deflection retains the legacy route exactly");
for (const { time, data } of [classic, proportional]) {
    reset(1);
    reset(0);
    if (data[2] === 2) {
        const corrupt = data.slice();
        corrupt[7] |= 0xf0;
        load(corrupt);
        tick(0, 0);
        assert.equal(frame[23], 0, "v2 packet rejects an out-of-range canonical axis");
    }
    load(data);
    tick(0, 0);
    assert.equal(frame[23], time, "an authentic saved ghost survives either packet version");
}
// The tail is the player aircraft (farm: 582 XYZRGB vertices). A local
// wing corner should translate in world space but not shake against its own
// chase camera when the authoritative simulation has not stepped.
function playerWingCorner() {
    return Array.from(aircraft.subarray(aircraft.length - 582 * 6, aircraft.length - 582 * 6 + 3));
}
function screenPoint([x, y, z]) {
    const w = frame[3] * x + frame[7] * y + frame[11] * z + frame[15];
    return [
        (frame[0] * x + frame[4] * y + frame[8] * z + frame[12]) / w,
        (frame[1] * x + frame[5] * y + frame[9] * z + frame[13]) / w,
    ];
}
function distance(a, b) {
    return Math.hypot(...a.map((v, i) => v - b[i]));
}
for (const hz of [60, 90, 120]) {
    for (const steering of [0, 2]) {
        reset(1);
        reset(0);
        for (let i = 0; i < 26; i++) tick(steering);
        const fixedClock = frame[17];
        let wing = playerWingCorner();
        const relative = screenPoint(wing);
        for (let i = 1; i < hz / 30; i++) {
            tick(steering, 1 / hz);
            assert.equal(frame[17], fixedClock, "presentation never advances the simulation clock");
            const next = playerWingCorner();
            assert(distance(next, wing) > 0.08, `aircraft interpolates a substep at ${hz} Hz`);
            assert(distance(relative, screenPoint(next)) < 0.002,
                `camera and aircraft share the same presentation pose at ${hz} Hz while steering ${steering}`);
            wing = next;
        }
        const still = [frame, aircraft];
        tick(0, 0);
        assert.deepEqual([frame, aircraft], still, "zero elapsed time freezes the exact presented pose");
    }
}

reset(1);
reset(0);
let previousHeading = 0, wrapped = false;
for (let i = 0; i < 800 && !wrapped; i++) {
    tick(2, 1 / 120);
    const heading = Math.atan2(frame[3], frame[11]);
    const raw = heading - previousHeading;
    const signed = Math.atan2(Math.sin(raw), Math.cos(raw));
    assert(signed > -0.00001 && signed < 0.013, "held bank follows the short yaw arc through each subframe");
    if (previousHeading > 3 && heading < -3) wrapped = true;
    previousHeading = heading;
}
assert(wrapped, "the bank trace actually crosses the yaw wrap");

function catchUp(increments) {
    reset(1);
    reset(0);
    for (let i = 0; i < 12; i++) tick(2);
    for (const dt of increments) tick(2, dt);
    return { time: frame[17], point: playerWingCorner(), camera: screenPoint(playerWingCorner()) };
}
const afterHitch = catchUp([0.125]);
const afterFrames = catchUp(Array(15).fill(1 / 120));
assert.equal(afterHitch.time, afterFrames.time, "catch-up traverses the same authoritative steps");
assert(distance(afterHitch.point, afterFrames.point) < 0.001, "catch-up retains the last step's prior pose");
assert(distance(afterHitch.camera, afterFrames.camera) < 0.0001, "catch-up camera uses the same final substep");

console.log("Flight WASM: geometry, 60/90/120 Hz cadence, fixed-step controls, replays, and guidance verified");

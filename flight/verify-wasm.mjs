import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const module = new WebAssembly.Module(readFileSync(process.argv[2] ?? new URL("flight.wasm", import.meta.url)));
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
        frame = readFloats(pointer, length, 1, 32);
        assert.equal(frame.length, 32);
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
    assert.equal(frame[20], course === 0 ? 2 : 0);
    assert.equal(frame[21], 0);
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
assert.equal(frame[20], 2, "farm starts directly on the landing approach");
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
    // Recover aircraft-local axes from the same Y-rotated Paris chase matrix.
    const len = Math.hypot(frame[3], frame[11]);
    const sx = frame[3] / len, cz = frame[11] / len;
    const triangles = [];
    for (let i = 0; i < values.length; i += 18) {
        const corners = [0, 6, 12].map((v) => {
            const [x,y,z] = values.subarray(i + v, i + v + 3);
            return [cz*x-sx*z,y,sx*x+cz*z];
        });
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
assert.notDeepEqual(aircraft, farmAircraft, "courses draw different airplanes");
assertNonOverlappingParisPanels(aircraft);
const parisPose = [frame, aircraft];
for (let i = 0; i < 4; i++) {
    tick(0, 0);
    assert.deepEqual([frame, aircraft], parisPose, "repeated presentation of a stationary pose is stable");
}
tick(0, 0, 0.55);
assert(frame[0] > parisPose[0][0] && frame[3] === parisPose[0][3], "portrait changes projection rather than the camera mode");

reset(1);
const malformed = [
    [87, 70, 1, 1, 180, 0, ...Array(180).fill(0)],
    [87, 70, 2, 1, 180, 0, ...Array(360).fill(0)],
    [87, 70, 3, 0, 180, 0, ...Array(360).fill(0)],
    [87, 70, 3, 1, 181, 0, ...Array(360).fill(0)],
    [87, 70, 3, 1, 180, 0, ...Array(360).fill(0)],
    [87, 70, 3, 1, 180, 0, 64, 255, ...Array(358).fill(0)],
];
for (const bytes of malformed) {
    load(bytes);
    tick(0, 0);
    assert.equal(frame[23], 0, "rejects corrupt, mismatched, or unfinished ghost runs");
}
assert.equal(packet, undefined, "never publishes a record before landing");
const hostAnalog = (bank, pitch, power = 0) => 64 | (power & 176) | ((bank & 255) << 8) | ((pitch & 255) << 16);
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

// Play through the public input/projection ABI, with no exported test state or
// ability to teleport. The chase offset is documented by the authored camera.
function aircraftPose() {
    const angle = Math.atan2(frame[3], frame[11]);
    const hx = Math.sin(angle), hz = Math.cos(angle);
    const right = -frame[12] / (1.61 / 1.65);
    const y = frame[19], speed = frame[18];
    const forward = (-frame[15] - frame[7] * (y + 5.3)) / Math.hypot(frame[3], frame[11]) + 17.5;
    return {x: hx * forward + hz * right, y, z: hz * forward - hx * right, speed, angle};
}
const clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, v));
const raw = (v) => Math.round(clamp(v, -127, 127));
const difference = (a, b) => Math.atan2(Math.sin(a - b), Math.cos(a - b));
function pilot(p, bearing, height, slope, power) {
    const bank = raw(440 * difference(bearing, p.angle));
    const glide = Math.max(0, (15.5 - p.speed) * .82);
    const climb = (height - p.y) * 1.22 + slope * p.speed;
    const pitch = raw(127 * (climb + glide) / (.34 * p.speed));
    return hostAnalog(bank, pitch, power);
}
function pasture(mode) {
    reset(1); reset(0);
    packet = undefined;
    let rollout = false, rolloutTicks = 0, rolloutHeading = 0;
    for (let i = 0; i < 1400 && frame[22] === 0; i++) {
        const p = aircraftPose();
        if (frame[20] === 3) {
            rollout = true;
            rolloutHeading = Math.max(rolloutHeading, Math.abs(p.angle));
            rolloutTicks++;
            const rolling = mode === "overrun" ? 16 : mode === "side" ? (16 | 2) :
                mode === "steer" && rolloutTicks < 20 ? (32 | 2) : 32;
            tick(rolling);
        } else if (mode === "rough" && p.z > 151) {
            tick(8 | 32);
        } else {
            const height = mode === "rough" ? Math.max(5, 17.5 - .084*p.z) : 17.5 - .094*p.z;
            tick(pilot(p, 0, height, -.094, p.z > 115 ? 32 : 0));
        }
    }
    return {result: frame[22], rollout, rolloutHeading, time: frame[17], data: packet};
}
const goodFarm = pasture("stop");
assert.equal(goodFarm.result, 1, "farm requires a flare and a completed rollout");
assert(goodFarm.rollout && goodFarm.data);
assert.equal(pasture("overrun").result, 9, "a valid touchdown can still run out of pasture");
assert.equal(pasture("side").result, 11, "a lateral rollout exit has a different outcome");
const steeredFarm = pasture("steer");
assert.equal(steeredFarm.result, 1, "small ground corrections can still stop inside the strip");
assert(steeredFarm.rolloutHeading > .055 && steeredFarm.rolloutHeading < .21, "airborne bank becomes gentle rollout steering");
const rough = pasture("rough");
assert([6, 10].includes(rough.result) && !rough.rollout, "steep/fast touchdown never starts rollout");

function paris(mode) {
    reset(0); reset(1);
    packet = undefined;
    let sawClimbWarning = false, launched = false, landedMail = false, tried = false;
    for (let i = 0; i < 1900 && frame[22] === 0; i++) {
        const p = aircraftPose();
        const phase = frame[20], status = frame[21];
        sawClimbWarning ||= frame[30] === 1;
        if (phase === 0) {
            const detour = mode === "wide" || mode === "high";
            if (detour) {
                const bearing = Math.atan2(1, clamp((158-p.z)/(69-p.x), .26, .72));
                const target = mode === "high" ? 20 : 12.3;
                tick(pilot(p, bearing, target, 0, 0));
            } else {
                const slope = mode === "strike" || p.x >= 49 ? 0 : p.x > 24 ? .23 : 0;
                const height = mode === "strike" ? 7.8 : p.x < 24 ? 7.9 : Math.min(13.5, 7.9 + (p.x-24)*.23);
                tick(pilot(p, Math.atan2(67-p.x,190-p.z), height, slope, 0));
            }
        } else if (phase === 1) {
            if (mode === "high" || mode === "skew") {
                const expectation = mode === "high" ? 5 : 7;
                const heading = mode === "high" ? .9 : -.35;
                const input = pilot(p, heading, mode === "high" ? 20 : 12.3, 0, 32);
                if (frame[26] === expectation) {
                    assert.equal(frame[20], 1, "invalid release cannot count mail as delivered");
                    return {event: frame[26], launched: false};
                }
                if (!tried && status === expectation) {
                    const frozen = frame[17];
                    tick(input | 128, 0);
                    engine.cancel_drop();
                    tick(input, 0);
                    assert.equal(frame[17], frozen, "canceling a release cannot move simulation");
                    tick(input);
                    assert.equal(frame[26], 0, "canceled release cannot fire upon the next real step");
                    tick(input | 128, 0);
                    tick(input);
                    tried = true;
                } else tick(input);
            } else {
                const bearing = Math.atan2(109-p.x, 218-p.z);
                const input = pilot(p, bearing, 11.0, 0, 32);
                if (status === 9 && !tried) {
                    const frozen = frame[17];
                    tick(input | 128, 0);
                    assert.equal(frame[17], frozen, "a tap before a physics step queues exactly one release");
                    tick(input);
                    tried = true;
                } else tick(input);
            }
        } else if (phase === 5 || phase === 2) {
            launched ||= phase === 5;
            landedMail ||= phase === 2 && frame[31] === 1;
            // Align early and level before touchdown instead of chasing the strip center.
            const bearing = p.z >= 277 ? 0 : clamp(Math.atan2(125-p.x, Math.max(22, 298-p.z)), -.38, .38);
            const slope = p.z > 249 ? -.207 : 0;
            const height = Math.min(12.3, 1.0 + (305-p.z)*.207);
            tick(pilot(p, bearing, height, slope, 32));
        } else if (phase === 3) tick(32);
    }
    return {result: frame[22], route: frame[25], launched, landedMail,
        sawClimbWarning, time: frame[17], data: packet};
}
assert.equal(paris("strike").result, 8, "the low lane really hits the bridge without a climb");
assert.equal(paris("high").event, 5, "a high release is rejected");
assert.equal(paris("skew").event, 7, "a misaligned release is rejected");
const lowParis = paris("low");
assert.equal(lowParis.result, 1, "the cyan climb and mail delivery can succeed");
assert.equal(lowParis.route, 1);
assert(lowParis.launched && lowParis.landedMail && lowParis.sawClimbWarning && lowParis.data);
const wideParis = paris("wide");
assert.equal(wideParis.result, 1, "a wider route can deliver without clearing artificial gates");
assert.equal(wideParis.route, 2);
assert(wideParis.launched && wideParis.landedMail && wideParis.data);
for (const [course, { time, data }] of [[0,goodFarm], [1,lowParis], [1,wideParis]]) {
    reset(1-course); reset(course);
    assert.equal(data[2], 3);
    assert.equal(data.length, 6 + 2 * (data[4] + data[5] * 256));
    if (course === 1) {
        const withoutDrop = data.slice();
        for (let i = 6; i < withoutDrop.length; i += 2) withoutDrop[i] &= 127;
        load(withoutDrop);
        tick(0, 0);
        assert.equal(frame[23], 0, "the same trajectory cannot validate if the mail action is removed");
    }
    load(data);
    tick(0, 0);
    assert.equal(frame[23], time, "authentic mission replay retains the exact timer");
}
function visibleGhost(rejectedCandidate) {
    reset(1); reset(0);
    for (const oldVersion of [1, 2]) {
        const oldPacket = goodFarm.data.slice();
        oldPacket[2] = oldVersion;
        load(oldPacket);
        tick(0, 0);
        assert.equal(frame[23], 0, `mission engine refuses old format v${oldVersion}`);
    }
    load(goodFarm.data);
    tick(0, 0);
    assert.equal(frame[23], goodFarm.time);
    if (rejectedCandidate) {
        const truncated = goodFarm.data.slice(0, -2);
        const ticks = (truncated.length - 6)/2;
        truncated[4] = ticks & 255;
        truncated[5] = ticks >> 8;
        load(truncated);
        tick(0, 0);
        assert.equal(frame[23], goodFarm.time, "a shorter non-finish cannot replace an existing best");
    }
    let diverged = null;
    for (let i = 0; i < 160 && frame[22] === 0; i++) {
        tick(16 | 2);
        if (aircraft.length > farmAircraft.length) diverged = aircraft;
    }
    assert(diverged, "a restored mission ghost actually draws after the routes diverge");
    return diverged;
}
assert.deepEqual(visibleGhost(true), visibleGhost(false),
    "rejected candidate validation never mutates a previously restored ghost's mission state");

// Recheck that the plane and chase camera share the same presentation pose.
function playerWingCorner() {
    return Array.from(aircraft.subarray(aircraft.length - 6, aircraft.length - 3));
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

console.log("Flight WASM: geometry, 60/90/120 Hz cadence, fixed-step controls, both missions, failure diagnostics, and replays verified");

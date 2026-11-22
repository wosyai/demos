import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const wasm = new WebAssembly.Module(readFileSync(process.argv[2]));

for (const aspect of [.56, 1.67]) {
  let engine, hud, hit, sea, avatar = new Float32Array(), uploads = 0;
  engine = new WebAssembly.Instance(wasm, {
    showcase: {
      aim() {}, atlas() {}, mesh() {}, outline() {},
      water(pointer, count) { sea = { pointer, count }; },
      player(pointer, count) {
        uploads++;
        avatar = new Float32Array(engine.memory.buffer, pointer, count * 6).slice();
      },
      frame(pointer, target) {
        hit = target;
        hud = Array.from(new Float32Array(engine.memory.buffer, pointer, 35));
      },
    },
    wasi_snapshot_preview1: { proc_exit(code) { assert.fail('Wosy exited: ' + code); } },
  }).exports;
  engine._start();
  assert(engine.start_beacon() > 0);
  const tick = (dt = .05) => engine.tick(dt, aspect, 1);
  const walk = (button, axis, limit, sign) => {
    engine.control(button, 1);
    for (let i = 0; i < 80 && (limit - hud[axis]) * sign > 0 && hud[25] === 1; i++) tick();
    engine.control(button, 0);
    assert((limit - hud[axis]) * sign <= 0 && hud[25] === 1, 'ordinary beacon waypoint ' + limit);
  };
  const center = (box, axis) => {
    let lo = Infinity, hi = -Infinity;
    for (let n = 0; n < 36; n++) {
      const coordinate = avatar[(box * 36 + n) * 6 + axis];
      lo = Math.min(lo, coordinate);
      hi = Math.max(hi, coordinate);
    }
    return (lo + hi) / 2;
  };
  const renderedSea = (x, z) => {
    const width = Math.sqrt(sea.count / 6);
    const data = new Float32Array(engine.memory.buffer, sea.pointer, sea.count * 6);
    const row = Math.floor((z + 20) / 4) + 1, col = Math.floor((x + 20) / 4) + 1;
    const at = (row * width + col) * 36;
    const u = (x - data[at]) / 4, v = (z - data[at + 2]) / 4;
    const a = data[at + 1], b = data[at + 13], c = data[at + 7], d = data[at + 19];
    return u + v <= 1 ? a * (1 - u - v) + b * u + c * v : d * (u + v - 1) + b * (1 - v) + c * (1 - u);
  };
  tick(0);
  assert.equal(avatar.length, 0, 'normal first-person play does not draw a body');
  assert.equal(engine.cycle_camera(), 1);
  tick(0);
  assert.equal(avatar.length, 396 * 6);
  const dry = center(0, 2) - center(1, 2);
  assert(Math.abs(dry) < .02, 'dry standing torso is upright');
  assert.equal(engine.cycle_camera(), 0);
  tick(0);
  assert.equal(avatar.length, 0, 'switching back hides the visible body');

  walk(0, 18, 33.42, -1);
  walk(3, 16, 28.5, 1);
  walk(0, 18, 26.5, -1);
  assert.equal(hud[22], 0, 'Beacon does not fly');
  assert.equal(hud[23], 0, 'the avatar actually left dry support');
  const [x, y, z] = hud.slice(16, 19);
  assert(renderedSea(x, z) > y - 1.62 + .5, 'the same rendered sea measurably immerses the player');
  assert.equal(avatar.length, 0);

  assert.equal(engine.cycle_camera(), 1);
  tick(0);
  assert.equal(avatar.length, 396 * 6);
  const startZ = center(1, 2);
  let minArm = Infinity, maxArm = -Infinity, minLean = Infinity;
  engine.control(0, 1);
  for (let i = 0; i < 30; i++) {
    tick(.05);
    assert.equal(hud[25], 1, 'the swimming sample is real active play');
    assert.equal(avatar.length, 396 * 6, 'third person displays the articulated body during strokes');
    const arms = center(5, 2) - center(6, 2);
    minArm = Math.min(minArm, arms);
    maxArm = Math.max(maxArm, arms);
    minLean = Math.min(minLean, center(0, 2) - center(1, 2));
  }
  engine.control(0, 0);
  assert(center(1, 2) < startZ - 1.0, 'the stroke observations include actual movement through water');
  assert(minLean < -.12, 'the wet pose visibly pitches away from the upright dry body');
  assert(minArm < -.045 && maxArm > .045, 'both actual arm meshes alternate a full stroke');
  const finalPose = avatar.slice(), before = uploads;
  tick(0);
  assert.equal(uploads, before, 'zero-time reprojection does not rebuild identical avatar geometry');
  assert.deepEqual(avatar, finalPose);
  assert.equal(engine.cycle_camera(), 0);
  tick(0);
  assert.equal(avatar.length, 0, 'first person hides the wet body too');
  assert.equal(engine.cycle_camera(), 1);
  tick(0);
  assert.deepEqual(avatar, finalPose, 'restoring third person preserves the actual running stroke pose');
  const forward = startZ - center(1, 2);
  const lastWetLean = center(0, 2) - center(1, 2);
  assert(lastWetLean < -.12, 'the return begins in a visibly pitched swim pose');

  assert.equal(engine.cycle_camera(), 0);
  tick(0);
  let yaw = 0, eyePitch = -.1;
  const moveTo = (button, axis, limit) => {
    if (yaw !== 0) {
      engine.look(-yaw / .0034, 0);
      yaw = 0;
      tick(0);
    }
    engine.control(button, 1);
    for (let i = 0; i < 80 && hud[axis] <= limit; i++) {
      if (i % 8 === 0) engine.control(4, 1);
      if (i % 8 === 4) engine.control(4, 0);
      tick();
      assert.equal(hud[25], 1, 'the return stays in the same active Beacon Run');
      assert.equal(hud[22], 0, 'the player cannot fly to shore');
    }
    engine.control(4, 0);
    engine.control(button, 0);
    assert(hud[axis] > limit, 'the normal controls reach the stairway waypoint ' + limit);
  };
  const placeAgainstShore = (x, y) => {
    const dx = x + .55 - hud[16], dz = hud[18] - 30.01;
    const nextYaw = Math.atan2(dx, dz);
    const pitch = Math.atan2(y + .4 - hud[17], Math.hypot(dx, dz));
    engine.look((nextYaw - yaw) / .0034, (eyePitch - pitch) / .0034);
    eyePitch = pitch;
    yaw = nextYaw;
    tick(0);
    assert(hit >= 0, 'the normal reticle acquires a support voxel');
    assert.deepEqual([hit & 63, (hit >>> 6) & 15, (hit >>> 10) & 63, (hit >>> 16) & 7], [x, y, 30, 4],
      'the reticle targets the channel-facing shore face to place at z29');
    assert.equal(engine.edit_control(1, 2), 1, 'ordinary placement spends wood on an actual stair');
    tick(0);
  };
  const settle = () => {
    for (let i = 0; i < 15 && hud[23] === 0; i++) tick();
  };

  moveTo(1, 18, 28.4);
  const preStairStock = hud[28];
  placeAgainstShore(28, 2);
  assert.equal(hud[28], preStairStock - 1);
  placeAgainstShore(29, 3);
  assert.equal(hud[28], preStairStock - 2, 'the two return stairs consume two units from real stock');
  moveTo(1, 18, 29.3);
  settle();
  moveTo(3, 16, 29.35);
  settle();
  moveTo(1, 18, 31.5);
  settle();
  assert.equal(hud[23], 1, 'ordinary swimming, building and jumping reach solid shore');
  assert.equal(hud[28], preStairStock - 2, 'walking back does not refund placed wood');
  assert.equal(engine.cycle_camera(), 1);
  tick(0);
  assert.equal(avatar.length, 396 * 6, 'third-person body is visible on the return shore');
  assert(center(1, 2) > 31, 'the body returned to the harbor, not a channel sandbank');

  for (let i = 0; i < 8; i++) {
    tick();
    assert.equal(hud[23], 1, 'the player stays on solid shore while the pose settles');
  }
  const exitLean = center(0, 2) - center(1, 2);
  assert(Math.abs(exitLean - dry) < .02, 'standing on land restores the original upright torso');
  assert(Math.abs(center(5, 2) - center(6, 2)) < .02, 'both arms return to neutral');
  assert.equal(engine.cycle_camera(), 0);
  tick(0);
  const [shoreX, shoreEye, shoreZ] = hud.slice(16, 19);
  assert(shoreZ > 31 && renderedSea(shoreX, shoreZ) < shoreEye - 1.62, 'the returned first-person eye independently confirms genuinely dry feet');
  assert.equal(avatar.length, 0, 'the body remains hidden in first person on land');
  console.log(JSON.stringify({ aspect, dry, minLean, minArm, maxArm, forward, exitLean, shoreZ }));
}

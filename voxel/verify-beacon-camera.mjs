import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const wasm = new WebAssembly.Module(readFileSync(process.argv[2]));

for (const aspect of [.56, 1.67]) {
  let game, frame, hit, aim = [0, 0], avatar = 0;
  game = new WebAssembly.Instance(wasm, {
    showcase: {
      atlas() {}, mesh() {}, water() {}, outline() {},
      player(_, count) { avatar = count; },
      aim(x, y) { aim = [x, y]; },
      frame(pointer, target) {
        frame = Array.from(new Float32Array(game.memory.buffer, pointer, 35));
        hit = target;
      },
    },
    wasi_snapshot_preview1: { proc_exit(code) { assert.fail('Wosy exited: ' + code); } },
  }).exports;
  game._start();
  assert(game.start_beacon() > 0);
  const tick = (dt = .05) => game.tick(dt, aspect, 1);
  const move = (control, steps) => {
    game.control(control, 1);
    for (let i = 0; i < steps; i++) {
      tick();
      assert.equal(frame[25], 1);
      assert.equal(frame[23], 1);
    }
    game.control(control, 0);
  };
  const pose = () => frame.slice(16, 19);
  const hitCell = key => [key & 63, (key >>> 6) & 15, (key >>> 10) & 63];
  const project = ([x, y, z]) => {
    const clip = k => frame[k] * x + frame[4 + k] * y + frame[8 + k] * z + frame[12 + k];
    return [clip(0) / clip(3), clip(1) / clip(3)];
  };
  const close = (one, other, tolerance, message) => {
    assert(Math.hypot(...one.map((value, i) => value - other[i])) < tolerance, message);
  };

  tick(0);
  const pitch = -.46;
  game.look(-Math.PI / 2 / .0034, (frame[19] - pitch) / .0034);
  move(0, 8);
  const openEye = pose();
  assert(openEye[0] > 22.5 && openEye[0] < 22.7 && Math.abs(openEye[2] - 42.5) < .01);
  assert.equal(game.cycle_camera(), 1);
  tick(0);
  const openArm = pose()[0] - openEye[0];
  assert(openArm > 3.5, 'the actual western harbor clearing allows a long boom');
  assert.equal(avatar, 396);

  move(1, 17);
  const squeezed = pose();
  const groundTarget = hit;
  const squeezedAim = aim.slice();
  assert(squeezed[0] < 27.001, 'the camera stays on the player side of the authored hut wall');
  assert.equal(avatar, 0, 'the retracted body cannot obstruct the view');
  assert.equal(game.cycle_camera(), 0);
  tick(0);
  const squeezedEye = pose();
  assert(squeezedEye[0] > 26.55 && squeezedEye[0] < 26.74);
  assert(squeezed[0] - squeezedEye[0] < .47);
  assert.equal(hit, groundTarget, 'perspective does not change the actual player-eye target');
  assert.equal((hit >>> 16) & 7, 3, 'the reticle intersects the top of a real support voxel');
  const turf = hitCell(hit);
  assert(turf[0] < 27 && turf[1] === 4 && turf[2] === 42);
  assert.deepEqual(aim, [0, 0]);
  assert.equal(game.cycle_camera(), 1);
  tick(0);
  close(pose(), squeezed, .001, 'switching back near the wall recovers the stable squeezed pose');
  close(aim, squeezedAim, .001, 'switching back restores the same offset reticle');
  const groundX = squeezedEye[0] - (squeezedEye[1] - 5) / Math.tan(-pitch);
  close(aim, project([groundX, 5, squeezedEye[2]]), .012,
    'the portrait or landscape reticle overlays the actual ground contact');

  const wood = frame[28];
  assert.equal(game.edit_control(1, 2), 1, 'placement works through the actual squeezed third-person reticle');
  tick(0);
  assert.deepEqual(hitCell(hit), [turf[0], turf[1] + 1, turf[2]]);
  assert.equal(frame[28], wood - 1, 'real wood was spent');

  assert.equal(game.edit_control(0, 2), 1, 'the same third-person reticle breaks that plank');
  tick(0);
  assert.equal(frame[28], wood - 1, 'breaking the plank does not immediately refund wood');

  move(0, 17);
  const recoveryStart = pose()[0] - openEye[0];
  let lastArm = recoveryStart;
  for (let i = 0; i < 12; i++) {
    tick();
    const arm = pose()[0] - openEye[0];
    assert(arm >= lastArm - .002, 'at rest in the clearing the camera does not pull back and forth');
    lastArm = arm;
  }
  assert(lastArm > recoveryStart + .015 && Math.abs(lastArm - openArm) < .03,
    'the boom continues recovering smoothly after the retreat ends');
  assert.equal(avatar, 396, 'the complete articulated avatar becomes visible again');
  assert.equal(game.cycle_camera(), 0);
  tick(0);
  close(pose(), openEye, .002, 'camera recovery never moves the actual player');
  assert.deepEqual(aim, [0, 0]);
  console.log(JSON.stringify({ aspect, openArm, squeezedArm: squeezed[0] - squeezedEye[0], recoveryStart, recovered: lastArm }));
}

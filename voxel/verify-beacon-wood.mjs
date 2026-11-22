import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';

const module = new WebAssembly.Module(readFileSync(process.argv[2]));
for (const aspect of [.56, 1.67]) {
  let engine, hud, target;
  const changed = [];
  const hashes = new Map(), counts = new Map();
  engine = new WebAssembly.Instance(module, {
    showcase: {
      aim() {}, atlas() {}, outline() {}, player() {}, water() {},
      mesh(pointer, count, chunk) {
        changed.push(chunk);
        counts.set(chunk, count);
        const bytes = new Uint8Array(engine.memory.buffer, pointer, count * 6 * 4);
        hashes.set(chunk, createHash('sha256').update(bytes).digest('hex'));
      },
      frame(pointer, hit) {
        hud = Array.from(new Float32Array(engine.memory.buffer, pointer, 30));
        target = hit;
      },
    },
    wasi_snapshot_preview1: { proc_exit(code) { assert.fail('Wosy exited: ' + code); } },
  }).exports;

  engine._start();
  assert(engine.start_beacon() > 0);
  const tick = () => engine.tick(0, aspect, 1);
  const hitCell = (hit) => [hit % 64, Math.floor(hit / 64) % 16, Math.floor(hit / 1024) % 64];
  tick();
  assert.deepEqual(hud.slice(25, 30), [1, 1, 0, 12, 0]);
  const aimNorthAt = (y, z) => {
    const pitch = Math.atan2(y - hud[17], hud[18] - z);
    engine.look(0, (hud[19] - pitch) / .0034);
    tick();
  };
  aimNorthAt(5, 40.5);
  assert.deepEqual(hitCell(target), [24, 4, 40]);
  assert.equal(Math.floor(target / 65536), 3, 'aim at the top of the authored ground');

  const before = [hashes.get(14), hashes.get(13)];
  changed.length = 0;
  assert.equal(engine.place_selected(), 1, 'wood can be placed away from the bridge');
  assert.deepEqual(changed, [14, 13], 'only the dirty owner and seam neighbor are rebuilt');
  assert.notEqual(hashes.get(14), before[0], 'owner geometry bytes actually changed');
  tick();
  assert.equal(hud[28], 11);
  assert.deepEqual(hitCell(target), [24, 5, 40]);

  changed.length = 0;
  assert.equal(engine.edit_view(0), 1, 'ordinary reticle mining leaves loose wood');
  assert.deepEqual(changed, [14, 13]);
  const loose = [hashes.get(14), hashes.get(13)];
  assert.notEqual(loose[0], before[0], 'the loose item adds real owner-chunk geometry');
  assert.equal(loose[1], before[1], 'no loose geometry was added in the neighbor');
  tick();
  assert.equal(hud[28], 11, 'breaking does not credit wood before pickup');
  assert.deepEqual(hitCell(target), [24, 4, 40]);

  changed.length = 0;
  assert.equal(engine.place_selected(), -5, 'cannot bury uncollected wood');
  assert.equal(engine.edit_view(0), -4, 'the authored ground underneath remains protected');
  assert.deepEqual(changed, [], 'rejected edits do not rebuild chunks');
  for (let i = 0; i < 4; i++) engine.tick(.05, aspect, 1);
  assert.equal(hud[28], 11, 'active time alone cannot collect distant wood');
  assert.deepEqual(changed, []);
  assert.deepEqual([hashes.get(14), hashes.get(13)], loose);

  const forwardTo = (z) => {
    engine.control(0, 1);
    for (let i = 0; i < 150 && hud[18] > z && hud[25] === 1; i++) engine.tick(.05, aspect, 1);
    engine.control(0, 0);
    assert(hud[18] <= z && hud[25] === 1, 'reach normal route waypoint ' + z);
  };
  forwardTo(41.15);
  assert.equal(hud[28], 12, 'reaching the visible item recovers exactly one wood');
  assert.deepEqual(changed, [14], 'pickup changes only the item owner chunk');
  assert.deepEqual([hashes.get(14), hashes.get(13)], before, 'both edited streams restore exactly');
  for (let i = 0; i < 4; i++) engine.tick(.05, aspect, 1);
  assert.equal(hud[28], 12, 'standing by the collected spot cannot collect it twice');
  assert.deepEqual(changed, [14]);

  forwardTo(30.52);
  for (const piling of [28, 26, 24, 22, 20, 18]) {
    aimNorthAt(4, piling + .50);
    assert.equal(engine.place_selected(), 1);
    aimNorthAt(4.5, piling + 1);
    assert.equal(engine.place_selected(), 1);
    forwardTo(piling + .55);
  }
  forwardTo(16.48);
  assert.equal(hud[29], 1, 'light the first watchfire by reaching its shore');
  const dx = 22.5 - hud[16], dz = hud[18] - 15.5;
  const yaw = Math.atan2(dx, dz);
  const pitch = Math.atan2(5.5 - hud[17], Math.hypot(dx, dz));
  engine.look(yaw / .0034, (hud[19] - pitch) / .0034);
  tick();
  assert.deepEqual(hitCell(target), [22, 5, 15], 'target the wooden watchfire support, not the light');
  const watchfireBefore = hashes.get(5), woodBefore = hud[28];
  changed.length = 0;
  assert.equal(engine.edit_view(0), -4, 'authored watchfire supports cannot be harvested');
  assert.deepEqual(changed, []);
  tick();
  assert.equal(hud[28], woodBefore);
  assert.equal(hashes.get(5), watchfireBefore);
  assert.deepEqual(hitCell(target), [22, 5, 15]);

  engine.look(-yaw / .0034, hud[19] / .0034);
  tick();
  const harbor = [12, 13, 14, 15];
  assert(harbor.every((id) => counts.get(id) > 0));
  changed.length = 0;
  forwardTo(11.5);
  assert.deepEqual(changed, harbor, 'north movement retires only the far harbor row');
  assert(harbor.every((id) => counts.get(id) === 0), 'retirement uploads an empty callback for each old slot');
  const caveZ = hud[18];
  assert(caveZ >= 10.8 && caveZ <= 11.5, 'reach the middle of the cave entrance lane');
  assert.deepEqual(hitCell(engine.pick(34.5, 6.25, caveZ, 0, 1, 0)), [34, 8, Math.floor(caveZ)],
    'the real terrain contains a continuous overhead rock layer');
  assert.deepEqual(hitCell(engine.pick(34.5, 6.25, caveZ, 0, -1, 0)), [34, 4, Math.floor(caveZ)],
    'the real terrain leaves a clear three-voxel passage above its floor');

  const coastTraverse = (control, limit, sign) => {
    const visited = new Set();
    engine.control(control, 1);
    for (let i = 0; i < 120 && (limit - hud[16]) * sign > 0; i++) {
      engine.tick(.05, aspect, 1);
      assert.equal(hud[25], 1, 'traversal is inside normal active play');
      assert.equal(hud[26], 1, 'the roofed coastal route keeps the flame dry');
      assert.equal(hud[29], 1, 'exploring the cave does not alter mission requirements');
      assert(Math.abs(hud[17] - 6.62) < .03 && Math.abs(hud[18] - caveZ) < .015,
        'ordinary movement crosses at walking height without entering a side wall');
      if (hud[16] >= 30 && hud[16] < 39) visited.add(Math.floor(hud[16]));
    }
    engine.control(control, 0);
    assert((limit - hud[16]) * sign <= 0, 'walk out of the opposite cave mouth');
    assert.deepEqual([...visited].sort((a, b) => a - b), [30, 31, 32, 33, 34, 35, 36, 37, 38]);
  };
  const west = [0, 4, 8];
  assert(west.every((id) => counts.get(id) > 0), 'west terrain starts resident');
  const westBefore = west.map((id) => hashes.get(id));
  changed.length = 0;
  coastTraverse(3, 40.1, 1);
  assert.deepEqual(changed, west);
  assert(west.every((id) => counts.get(id) === 0));
  changed.length = 0;
  engine.tick(.05, aspect, 1);
  assert.deepEqual(changed, [], 'stationary positive ticks do not publish terrain');
  coastTraverse(2, 28.8, -1);
  assert.deepEqual(changed, west, 'ordinary return reloads only the entering west column');
  assert(west.every((id) => counts.get(id) > 0));
  assert.deepEqual(west.map((id) => hashes.get(id)), westBefore, 'reload restores the real previous mesh bytes');
  assert(harbor.every((id) => counts.get(id) === 0), 'reload does not bring unrelated retired chunks back');
}

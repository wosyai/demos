import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';

const module = new WebAssembly.Module(readFileSync(process.argv[2]));
for (const aspect of [.56, 1.67]) {
  let engine, hud, target;
  const changed = [];
  const hashes = new Map();
  engine = new WebAssembly.Instance(module, {
    showcase: {
      aim() {}, atlas() {}, outline() {}, player() {}, water() {},
      mesh(pointer, count, chunk) {
        changed.push(chunk);
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
  assert.equal(engine.edit_view(0), 1, 'ordinary reticle mining recovers the same wood');
  assert.deepEqual(changed, [14, 13]);
  assert.deepEqual([hashes.get(14), hashes.get(13)], before, 'both edited chunk streams restore exactly');
  tick();
  assert.equal(hud[28], 12);
  assert.deepEqual(hitCell(target), [24, 4, 40]);

  changed.length = 0;
  assert.equal(engine.edit_view(0), -4, 'the authored ground underneath remains protected');
  assert.deepEqual(changed, [], 'rejected edits do not rebuild chunks');
  tick();
  assert.deepEqual(hud.slice(25, 30), [1, 1, 0, 12, 0], 'no loss, duplication, or progression change');

  const forwardTo = (z) => {
    engine.control(0, 1);
    for (let i = 0; i < 150 && hud[18] > z && hud[25] === 1; i++) engine.tick(.05, aspect, 1);
    engine.control(0, 0);
    assert(hud[18] <= z && hud[25] === 1, 'reach normal route waypoint ' + z);
  };
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
}

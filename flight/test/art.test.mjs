import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

const executable = process.env.FLIGHT_WASM || new URL("../flight.wasm", import.meta.url);
const close = (a, b, tolerance = .0002) => Math.abs(a - b) <= tolerance;

async function art() {
  let engine, world, plane;
  const readMesh = (pointer, length) => {
    assert(Number.isInteger(pointer) && pointer >= 0 && pointer % 4 === 0);
    assert(Number.isInteger(length) && length > 0 && length % 18 === 0);
    return new Float32Array(engine.memory.buffer, pointer, length).slice();
  };
  const module = new WebAssembly.Module(await readFile(executable));
  engine = new WebAssembly.Instance(module, {
    flight: {
      world(pointer, length) { world = readMesh(pointer, length); },
      aircraft(pointer, length) { plane = readMesh(pointer, length); },
      frame() {},
      record() {},
    },
    wasi_snapshot_preview1: { proc_exit(code) { assert.fail("Wosy art exited: " + code); } },
  }).exports;
  engine._start();
  return {
    sample(course) { engine.reset(course); engine.tick(0, 0, 1.4); return { world, plane }; },
  };
}

function vertices(mesh, [r, g, b]) {
  const result = [];
  for (let at = 0; at < mesh.length; at += 6) {
    if (close(mesh[at+3], r) && close(mesh[at+4], g) && close(mesh[at+5], b)) {
      result.push([mesh[at], mesh[at+1], mesh[at+2]]);
    }
  }
  return result;
}

function point(mesh, target) {
  for (let at = 0; at < mesh.length; at += 6) {
    if (target.every((value, i) => close(mesh[at+i], value))) return true;
  }
  return false;
}

test("Paris scenery includes four tapered feet, an arch apex, separate decks, and a coherent spire", async () => {
  const {world} = (await art()).sample(1);
  assert(world.length <= 32768 * 6, "tower leaves the world within the allocated mesh");
  for (const x of [206, 250]) {
    for (const z of [337, 381]) assert(point(world, [x, 2.35, z]), "separate splayed footing");
  }
  assert(point(world, [205, .08, 336]), "plaza begins on the dry bank beyond the promenade");
  assert(!point(world, [206, 2.35, 262]), "no old footing in the river");
  assert(point(world, [228, 19, 373.49]), "open arch rises at the center of the south face");
  assert(point(world, [212.9, 23.35, 343.9]), "first observation deck");
  assert(point(world, [219.93, 42.45, 350.93]), "second observation deck");
  assert(point(world, [228, 84, 359]), "mast reaches the original height");
});

test("Wright Flyer has thirteen striped cells and a navy canton; Paris has two Brazilian flag marks", async () => {
  const demo = await art();
  const farm = demo.sample(0).plane;
  assert(farm.length <= 2048 * 6);
  const red = vertices(farm, [.94, .18, .18]);
  const ivory = vertices(farm, [.94, .95, .95]);
  const canton = vertices(farm, [.095, .24, .64]);
  assert.equal(red.length, 7 * 6);
  assert.equal(ivory.length, 6 * 6);
  assert.equal(canton.length, 6);
  assert.equal(vertices(farm, [.97, .97, .9]).length, 9 * 6);
  assert(close(red[0][1], ivory[0][1]) && close(red[0][1], canton[0][1]), "canton and stripes share the partitioned cloth");
  assert(vertices(farm, [.97, .97, .9])[0][1] - red[0][1] > .018, "stars are safely above their blue canton");
  const paris = demo.sample(1).plane;
  assert(paris.length <= 2048 * 6);
  const green = vertices(paris, [.035, .59, .25]);
  const gold = vertices(paris, [1, .84, .12]);
  const blue = vertices(paris, [.028, .248, .63]);
  assert.equal(green.length, 12);
  assert.equal(gold.length, 12);
  assert.equal(blue.length, 2 * 16 * 3);
  assert.equal(vertices(paris, [.98, .96, .83]).length, 2 * 3 * 6);
  for (let flag = 0; flag < 2; flag++) {
    assert(gold[flag*6][1] - green[flag*6][1] > .018, "gold marking is not coplanar with the base");
    assert(blue[flag*48][1] - gold[flag*6][1] > .018, "blue disk is not coplanar with the diamond");
  }
});

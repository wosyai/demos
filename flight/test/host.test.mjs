import test from "node:test";
import assert from "node:assert/strict";
import { bootFlight, makeControls, memoryRange, replayStore } from "../host.mjs";

class Hub {
  constructor() { this.listeners = new Map(); }
  addEventListener(name, callback) {
    if (!this.listeners.has(name)) this.listeners.set(name, []);
    this.listeners.get(name).push(callback);
  }
  events(name, source = {}) {
    const value = { target: this, button: 0, repeat: false, prevented: false,
      preventDefault() { this.prevented = true; }, ...source };
    for (const listener of this.listeners.get(name) || []) listener(value);
    return value;
  }
}

function graphicsFixture() {
  const draws = [], uploads = [];
  const gl = {
    ARRAY_BUFFER: 34962, FLOAT: 5126, TRIANGLES: 4,
    STATIC_DRAW: 35044, DYNAMIC_DRAW: 35048,
    VERTEX_SHADER: 35633, FRAGMENT_SHADER: 35632, COLOR_BUFFER_BIT: 16384, DEPTH_BUFFER_BIT: 256,
    createShader: () => ({}), createProgram: () => ({}), createVertexArray: () => ({}), createBuffer: () => ({}),
    getShaderParameter: () => true, getProgramParameter: () => true,
    getUniformLocation: (_, name) => name,
    drawArrays: (...args) => draws.push(args),
    bufferData: (_, values, usage) => uploads.push([values.length, usage]),
  };
  for (const name of "shaderSource compileShader attachShader linkProgram deleteShader enableVertexAttribArray vertexAttribPointer bindVertexArray bindBuffer viewport clearColor clear disable enable useProgram uniform3fv uniform1f uniformMatrix4fv".split(" ")) gl[name] = () => {};
  return { gl, draws, uploads };
}

function mock({ noGraphics = false, badMesh = false, initialLost = false, exitAtStart = false } = {}) {
  const doc = new Hub(), win = new Hub(), nodes = new Map(), raf = new Map(), data = new Map();
  const g = graphicsFixture(), called = { reset: [], tick: [], replay: [], begin: 0 };
  const wasmExports = new WebAssembly.Memory({initial: 1});
  let index = 0, shouldComplete = false, current = 0, imported, distance = 122, completedGates = 3, landing = false;
  function element(name, dataset = {}) {
    const node = new Hub();
    const captures = new Set(), classes = new Set();
    Object.assign(node, {
      dataset, id: name, hidden: false, disabled: false, textContent: "", captures, classes,
      classList: { toggle(key, enabled) { if (enabled) classes.add(key); else classes.delete(key); } },
      focus() { doc.activeElement = this; },
      setPointerCapture(id) { captures.add(id); },
      hasPointerCapture(id) { return captures.has(id); },
      releasePointerCapture(id) { captures.delete(id); this.events("lostpointercapture", {pointerId: id}); },
    });
    nodes.set(name, node);
    return node;
  }
  const courses = [element("farm", {course: "0"}), element("paris", {course: "1"})];
  const controls = ["left", "right", "climb", "dive", "power", "brake"].map((value) => element(value, {action: value}));
  for (const name of "game view menu hud engine problem keys touch summary summary-title summary-detail summary-kicker again choose callout flight-cue time gates speed altitude best restart pause track".split(" ")) element(name);
  const canvas = nodes.get("view");
  Object.assign(canvas, { clientWidth: 820, clientHeight: 420, getContext: () => noGraphics ? null : g.gl });
  Object.assign(doc, { hidden: false, getElementById: (name) => nodes.get(name),
    querySelectorAll: (selector) => selector === "[data-course]" ? courses : controls });
  Object.assign(win, {
    devicePixelRatio: 3,
    localStorage: { setItem: (key, value) => data.set(key, value), getItem: (key) => data.get(key) },
    fetch: async () => {
      if (initialLost) canvas.events("webglcontextlost");
      return {ok: true, arrayBuffer: async () => new ArrayBuffer(0)};
    },
    WebAssembly: { async instantiate(_bytes, imports) {
      imported = imports.flight;
      return {instance: {exports: {
        memory: wasmExports, _start() { if (exitAtStart) imports.wasi_snapshot_preview1.proc_exit(9); },
        reset(course) {
          current = course;
          called.reset.push(course);
          imported.world(0, badMesh ? 16 : 18);
        },
        ghost_begin() { called.begin++; },
        ghost_byte(byte) { called.replay.push(byte); },
        ghost_end() { called.replay.push(-1); },
        tick(dt, mask, aspect) {
          called.tick.push([dt, mask, aspect]);
          imported.aircraft(128, 18);
          const frame = new Float32Array(wasmExports.buffer, 256, 28);
          frame.set([1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1, current,12.125,31,22,completedGates,8,shouldComplete ? 1 : 0,12.125,250,0,landing ? 1 : 0,distance]);
          imported.frame(256, 28);
          if (shouldComplete) {
            new Uint8Array(wasmExports.buffer, 512, 3).set([3,4,255]);
            imported.record(512, 3);
          }
        },
      }}};
    }},
    requestAnimationFrame(callback) { raf.set(++index, callback); return index; },
    cancelAnimationFrame(id) { raf.delete(id); },
  });
  const host = bootFlight(win, doc);
  return { ...host, ...g, doc, win, nodes, data, courses, canvas, called, raf,
    complete(value = true) { shouldComplete = value; },
    cue(values) { ({distance, completedGates, landing} = values); },
    frame(t) {
      const entry = raf.entries().next().value;
      assert.ok(entry, "a frame is pending");
      raf.delete(entry[0]);
      entry[1](t);
    } };
}

test("shared actions remain held while one key or pointer is released", () => {
  const controls = makeControls();
  controls.keys.set("ArrowLeft", 1);
  controls.keys.set("KeyA", 1);
  controls.pointers.set(11, 4);
  controls.pointers.set(12, 16);
  assert.equal(controls.mask, 21);
  controls.keys.delete("KeyA");
  controls.pointers.delete(11);
  assert.equal(controls.mask, 17);
  controls.clear();
  assert.equal(controls.mask, 0);
});
test("range guards validate alignment, memory bound, and current WebAssembly buffer", () => {
  const memory = new WebAssembly.Memory({initial: 1});
  memoryRange(memory, 4, 1, Float32Array)[0] = 81;
  memory.grow(1);
  assert.equal(memoryRange(memory, 4, 1, Float32Array)[0], 81);
  assert.throws(() => memoryRange(memory, 1, 1, Float32Array));
  assert.throws(() => memoryRange(memory, 131072, 1, Float32Array));
  assert.throws(() => memoryRange(memory, 4, Infinity, Float32Array));
});
test("opaque replay preserves binary bytes per course and degrades when storage is unavailable", () => {
  const data = new Map();
  const store = replayStore(() => ({getItem: data.get.bind(data), setItem: data.set.bind(data)}));
  store.save(1, Uint8Array.of(0, 65, 255));
  assert.equal(store.load(0), null);
  assert.deepEqual(Array.from(store.load(1), (value) => value.charCodeAt(0)), [0,65,255]);
  const unavailable = replayStore(() => { throw new Error("private"); });
  unavailable.save(1, Uint8Array.of(3));
  assert.equal(unavailable.load(1), null);
});
test("boots to course selection, selects Paris, forwards concurrent desktop and touch controls", async () => {
  const sim = mock();
  await sim.ready;
  assert.deepEqual(sim.called.reset, [0]);
  assert.equal(sim.courses[1].disabled, false);
  sim.courses[1].events("click");
  assert.deepEqual(sim.called.reset, [0,1]);
  assert.equal(sim.nodes.get("track").textContent, "Seine Sprint");
  const key = sim.win.events("keydown", {code: "KeyS"});
  assert.equal(key.prevented, true);
  assert.equal(sim.nodes.get("left").events("pointerdown", {pointerId: 5}).prevented, true);
  sim.nodes.get("power").events("pointerdown", {pointerId: 6});
  sim.frame(16);
  assert.equal(sim.called.tick.at(-1)[1], 21);
  sim.win.events("pointercancel", {pointerId: 5});
  sim.frame(32);
  assert.equal(sim.called.tick.at(-1)[1], 20);
  sim.win.events("blur");
  assert.equal(sim.nodes.get("power").captures.size, 0);

  assert.equal(sim.win.events("keydown", {code: "KeyS", repeat: true}).prevented, true);
  sim.frame(4000);
  assert.deepEqual(sim.called.tick.at(-1), [0,0,820/420]);
  sim.win.events("keydown", {code: "KeyS"});
  sim.frame(4016);
  assert.equal(sim.called.tick.at(-1)[1], 4);

  assert.equal(sim.canvas.width, 1640);
  assert.equal(sim.uploads.filter(([,usage]) => usage === sim.gl.STATIC_DRAW).length, 1);
  assert.ok(sim.draws.length > 3);
});
test("reports a result, stores only the active course, restores replay on retry and handles pause", async () => {
  const sim = mock();
  await sim.ready;
  sim.courses[1].events("click");
  sim.complete();
  sim.frame(16);
  assert.equal(sim.nodes.get("summary").hidden, false);
  assert.equal(sim.nodes.get("summary-title").textContent, "Run complete");
  assert.match(sim.nodes.get("summary-detail").textContent, /250 points/);
  assert.equal(sim.nodes.get("touch").hidden, true);
  assert.equal(sim.data.size, 1);
  assert.ok(sim.data.has("wosy-flying-low/v1/1"));
  sim.complete(false);
  sim.nodes.get("again").events("click");
  assert.deepEqual(sim.called.replay, [3,4,255,-1]);
  sim.win.events("keydown", {code: "Escape"});
  assert.equal(sim.nodes.get("summary-title").textContent, "Flight paused");
  const pauseCount = sim.called.tick.length;
  sim.frame(32);
  assert.equal(sim.called.tick.length, pauseCount);
  sim.nodes.get("again").events("click");
  sim.frame(50);
  assert.equal(sim.called.tick.length, pauseCount + 1);
  assert.equal(sim.nodes.get("summary").hidden, true);
});
test("context recovery redraws without resetting an active run", async () => {
  const sim = mock();
  await sim.ready;
  sim.courses[0].events("click");
  sim.frame(16);
  const oldDraws = sim.draws.length;
  assert.equal(sim.canvas.events("webglcontextlost").prevented, true);
  assert.equal(sim.raf.size, 0);
  sim.canvas.events("webglcontextrestored");
  sim.frame(50);
  assert.equal(sim.called.reset.length, 2);
  assert.ok(sim.draws.length > oldDraws);
  assert.equal(sim.called.tick.at(-1)[0], 0);
});
test("context recovery during initial download boots a preview", async () => {
  const sim = mock({initialLost: true});
  await sim.ready;
  assert.deepEqual(sim.called.reset, []);
  sim.canvas.events("webglcontextrestored");
  assert.deepEqual(sim.called.reset, [0]);
  assert.equal(sim.courses[0].disabled, false);
});
test("unsupported graphics or invalid WebAssembly mesh shows a useful error and disables courses", async () => {
  const noGraphics = mock({noGraphics: true});
  await noGraphics.ready;
  assert.match(noGraphics.nodes.get("problem").textContent, /WebGL 2/);
  assert.equal(noGraphics.courses[0].disabled, true);
  const bad = mock({badMesh: true});
  await bad.ready;
  assert.match(bad.nodes.get("problem").textContent, /restart/);

  assert.equal(bad.courses[0].disabled, true);
  const exited = mock({exitAtStart: true});
  await exited.ready;
  assert.match(exited.nodes.get("problem").textContent, /load the game/);
  assert.equal(exited.courses[0].disabled, true);
});

test("changing distance stays visual; live text updates only for gate or landing progress", async () => {
  const sim = mock();
  await sim.ready;
  sim.courses[0].events("click");
  const live = sim.nodes.get("flight-cue");
  sim.frame(10);
  assert.equal(live.textContent, "Gates cleared: 3 of 8.");
  sim.cue({distance: 45, completedGates: 3, landing: false});
  sim.frame(150);
  assert.match(sim.nodes.get("callout").textContent, /45 m/);
  assert.equal(live.textContent, "Gates cleared: 3 of 8.");
  sim.cue({distance: 1, completedGates: 8, landing: true});
  sim.frame(250);
  assert.equal(live.textContent, "Land in the marked strip.");
});

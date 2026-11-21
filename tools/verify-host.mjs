import assert from 'node:assert/strict';

function deferred() {
  let resolve;
  const promise = new Promise((done) => { resolve = done; });
  return { promise, resolve };
}

class Element {
  constructor() {
    this.handlers = new Map();
    this.classList = { add() {}, remove() {}, toggle() {} };
    this.clientWidth = 800;
    this.clientHeight = 400;
    this.value = '471';
  }

  addEventListener(name, fn) { this.handlers.set(name, fn); }
  dispatch(name, values = {}) {
    this.handlers.get(name)?.({ preventDefault() {}, ...values });
  }

  replaceChildren(...children) { this.textContent = children.at(-1).trim(); }
  focus() {}
}

async function loadHost(caseId, startsLost = false) {
  const nodes = new Map();
  const node = (id) => {
    if (!nodes.has(id)) nodes.set(id, new Element());
    return nodes.get(id);
  };
  const counters = { programs: 0, uploads: [], starts: 0, generations: 0, edits: [], controls: [], clears: 0, lockRequests: 0, lockExits: 0 };
  const canv = node('scene');
  const doc = new Element();
  const fetchResponse = deferred();
  const frames = new Map();
  const memory = new WebAssembly.Memory({ initial: 1 });
  let lost = startsLost;
  let frameId = 0;
  const gl = new Proxy({}, {
    get(_, name) {
      if (name === 'isContextLost') return () => lost;
      if (name === 'getProgramParameter' || name === 'getShaderParameter') return () => !lost;
      if (name === 'createProgram') return () => { assert(!lost); counters.programs++; return {}; };
      if (name === 'bufferData') return (_, data) => { assert(!lost); counters.uploads.push([...data]); };
      if (name.startsWith('create')) return () => { assert(!lost); return {}; };
      if (/^[A-Z_]+$/.test(name)) return 1;
      return () => {};
    },
  });
  canv.getContext = () => gl;
  canv.requestPointerLock = () => { counters.lockRequests++; };
  const controls = ['enter', 'apply-seed', 'random-seed'].map(node);
  for (const button of controls) button.disabled = true;
  const status = node('engine-status');
  status.textContent = 'Carregando motor';
  node('error').hidden = true;
  Object.assign(doc, {
    getElementById: node,
    querySelector: node,
    querySelectorAll: () => [],
    createElement: node,
    createTextNode: (text) => text,
    exitPointerLock() {
      counters.lockExits++;
      doc.pointerLockElement = null;
      doc.dispatch('pointerlockchange');
    },
  });
  Object.assign(globalThis, {
    document: doc,
    window: new Element(),
    HTMLInputElement: class extends Element {},
    matchMedia: () => ({ matches: false }),
    localStorage: { getItem() {}, setItem() {} },
    devicePixelRatio: 1,
    fetch(url) {
      assert(url.pathname.endsWith('/voxel/engine.wasm'));
      return fetchResponse.promise;
    },
    requestAnimationFrame(fn) { frames.set(++frameId, fn); return frameId; },
    cancelAnimationFrame(id) { frames.delete(id); },
    setTimeout: () => 1,
    clearTimeout: () => {},
  });
  WebAssembly.instantiate = async (_, { showcase }) => {
    const instanceExports = {
      memory,
      _start() { counters.starts++; },
      control(action, active) { counters.controls.push([action, active]); },
      clear_controls() { counters.clears++; },
      generate() {
        counters.generations++;
        showcase.water(0, 6);
        showcase.mesh(256, 3);
      },
      look() {},
      tick() { showcase.frame(512, -1); },
      edit_view(material) {
        counters.edits.push(material);
        new Float32Array(memory.buffer, 256, 18).fill(0.25);
        showcase.mesh(256, 3);
        return 1;
      },
    };
    return { instance: { exports: instanceExports } };
  };
  await import(new URL(`../voxel/main.js?host-test=${caseId}`, import.meta.url));
  const lostEvent = () => {
    lost = true;
    let prevented = false;
    canv.dispatch('webglcontextlost', { preventDefault() { prevented = true; } });
    assert(prevented, 'restoration must be enabled on context loss');
  };
  const restoredEvent = () => {
    lost = false;
    canv.dispatch('webglcontextrestored');
  };
  const resolveFetch = async (response = { ok: true, arrayBuffer: async () => new ArrayBuffer(0) }) => {
    fetchResponse.resolve(response);
    await new Promise((done) => setImmediate(done));
  };
  const grantLock = () => {
    doc.pointerLockElement = canv;
    doc.dispatch('pointerlockchange');
  };
  return { node, doc, counters, status, controls, frames, memory, lostEvent, restoredEvent, resolveFetch, grantLock };
}

function disabled(host, state) {
  for (const button of host.controls) assert.equal(button.disabled, state);
}

const pending = await loadHost('lost-pending');
pending.lostEvent();
await pending.resolveFetch();
disabled(pending, true);
assert.equal(pending.status.textContent, 'Recuperando gráficos');
assert.equal(pending.counters.starts, 1);
assert.equal(pending.counters.uploads.length, 0);
assert.equal(pending.frames.size, 0);
pending.restoredEvent();
disabled(pending, false);
assert.equal(pending.status.textContent, 'Wosy · motor ativo');
assert.equal(pending.counters.uploads.length, 2, 'restore needs both engine geometry buffers');
assert.equal(pending.frames.size, 1);
pending.node('enter').dispatch('click');
pending.doc.dispatch('keydown', { code: 'KeyW' });
assert.deepEqual(pending.counters.controls, [[0, 1]]);
pending.node('place').dispatch('click');
const editedMesh = Array(18).fill(0.25);
assert.deepEqual(pending.counters.edits, [2]);
assert.deepEqual(pending.counters.uploads.at(-1), editedMesh);
pending.lostEvent();
new Float32Array(pending.memory.buffer, 256, 18).fill(0);
disabled(pending, true);
assert.equal(pending.frames.size, 0);
assert.equal(pending.counters.clears, 1, 'held movement must clear on loss');
assert.equal(pending.counters.lockRequests, 1);
pending.grantLock();
assert.equal(pending.counters.lockExits, 1, 'late lock granted during loss must be released');
assert.equal(pending.doc.pointerLockElement, null);
const uploadsBeforeRestore = pending.counters.uploads.length;
pending.restoredEvent();
assert.equal(pending.counters.generations, 1, 'restore must not regenerate the island');
assert.deepEqual(pending.counters.edits, [2], 'restore must not repeat the edit');
assert.equal(pending.counters.uploads.length, uploadsBeforeRestore + 2);
assert.deepEqual(pending.counters.uploads[uploadsBeforeRestore], editedMesh, 'restore must upload retained edited geometry');
pending.node('enter').dispatch('click');
pending.doc.dispatch('keydown', { code: 'KeyW' });
assert.deepEqual(pending.counters.controls, [[0, 1], [0, 1]]);
assert.equal(pending.counters.lockRequests, 2);
pending.grantLock();
assert.equal(pending.counters.lockExits, 1, 'lock granted during play must be kept');
assert.equal(pending.doc.pointerLockElement, pending.node('scene'));

const early = await loadHost('restored-pending');
early.lostEvent();
early.restoredEvent();
disabled(early, true);
assert.equal(early.status.textContent, 'Carregando motor');
assert.equal(early.frames.size, 0);
await early.resolveFetch();
disabled(early, false);
assert.equal(early.counters.programs, 4, 'two graphics programs per context');
assert.equal(early.frames.size, 1);

const initiallyLost = await loadHost('already-lost', true);
await initiallyLost.resolveFetch();
disabled(initiallyLost, true);
assert.equal(initiallyLost.counters.programs, 0);
assert.equal(initiallyLost.counters.starts, 1);
initiallyLost.restoredEvent();
disabled(initiallyLost, false);
assert.equal(initiallyLost.counters.programs, 2);
assert.equal(initiallyLost.frames.size, 1);

const failed = await loadHost('fetch-error-lost');
failed.lostEvent();
const warn = console.warn;
try {
  console.warn = () => {};
  await failed.resolveFetch({ ok: false, status: 404 });
} finally {
  console.warn = warn;
}
failed.restoredEvent();
disabled(failed, true);
assert.equal(failed.status.textContent, 'Motor indisponível');
assert.equal(failed.node('error').hidden, false);
assert.equal(failed.frames.size, 0);

console.log('Verified host boot across WebGL loss/restoration, edited mesh retention and movement reset.');

const get = (id) => document.getElementById(id);
const shell = get("game");
const canvas = get("scene");
const enter = get("enter");
const seedInput = get("seed");
const applySeed = get("apply-seed");
const randomSeed = get("random-seed");
const status = get("engine-status");
const error = get("error");
const notice = get("notice");
const reticle = document.querySelector(".reticle");
const coarse = matchMedia("(pointer: coarse)");
const movementState = get("player-state");
const jumpTouch = get("jump-touch");
const descendTouch = get("descend-touch");
const flightTouch = get("flight-touch");
const materials = Array.from(document.querySelectorAll("[data-material]"));

const gl = canvas.getContext("webgl2", { alpha: false, antialias: true });
const fogColor = [0.65, 0.78, 0.72];
const keyActions = new Map([
  ["KeyW",0], ["ArrowUp",0], ["KeyS",1], ["ArrowDown",1],
  ["KeyA",2], ["ArrowLeft",2], ["KeyD",3], ["ArrowRight",3],
  ["Space",4], ["KeyC",5], ["ShiftLeft",6], ["ShiftRight",6], ["KeyF",7],
]);
const pressed = new Set();
const dpad = new Map();
const downActions = new Set();
const pulsedActions = new Set();
const layers = {
  mesh: { data: null, count: 0, version: 0 },
  water: { data: null, count: 0, version: 0 },
  outline: { data: null, count: 0, version: 0 },
};

let engine, memory, gpu, playing = false, loaded = false, failed = false, contextLost = false;
let pointerLook = null, toastTimer = 0, previous = 0, raf = 0;
let displayedMaterial, displayedFlight, displayedGrounded;

const vertex = `#version 300 es
layout(location=0) in vec3 position;
layout(location=1) in vec3 color;
uniform mat4 projection;
out vec3 rgb;
out vec3 point;
void main() {
  rgb=color;
  point=position;
  gl_Position=projection*vec4(position,1.0);
}`;
const fragment = `#version 300 es
precision highp float;
in vec3 rgb;
in vec3 point;
uniform vec3 eye;
uniform vec3 fog;
uniform float time;
uniform int pass;
out vec4 pixel;
void main() {
  vec3 col=rgb;
  if (pass==1) {
    vec2 p=point.xz;
    float wave=sin(0.34*p.x+0.23*p.y+1.05*time);
    float crest=sin(0.61*p.x-0.37*p.y-0.76*time+0.48*wave);
    float strip=smoothstep(0.85,1.0,crest)*0.08;
    float ray=smoothstep(0.38,0.93,normalize(point-eye).z)*0.14;
    col=vec3(0.19,0.49,0.49)+vec3(0.03,0.11,0.10)*wave+vec3(0.86,0.95,0.68)*(strip+ray);
  } else if (pass==0) {
    vec3 normal=normalize(cross(dFdx(point),dFdy(point)));
    float sun=max(dot(normal,normalize(vec3(-0.38,0.84,0.39))),0.0);
    col=rgb*(0.77+0.25*sun)+vec3(0.06,0.053,0.035)*sun;
  }
  float haze=clamp((distance(eye,point)-23.0)/110.0,0.0,1.0);
  pixel=vec4(mix(col,fog,pow(haze,1.08)*0.94),1.0);
}`;
const skyVertex = `#version 300 es
out vec2 uv;
void main() {
  vec2 p=vec2((gl_VertexID << 1)&2, gl_VertexID&2);
  uv=p;
  gl_Position=vec4(p*2.0-1.0,0.0,1.0);
}`;
const skyFragment = `#version 300 es
precision mediump float;
in vec2 uv;
uniform float aspect;
uniform float pitch;
uniform vec3 fog;
out vec4 pixel;
void main() {
  float horizon=0.44-pitch*0.96;
  float height=clamp((uv.y-horizon)/max(0.2,1.0-horizon),0.0,1.0);
  vec3 col=mix(fog,vec3(0.33,0.60,0.69),pow(height,0.62));
  vec2 pt=(uv-vec2(0.79,0.74-pitch*0.50))*vec2(aspect,1.0);
  float sun=length(pt);
  col=mix(col,vec3(0.98,0.89,0.66),0.39*exp(-sun*5.9));
  col=mix(col,vec3(1.0,0.94,0.75),1.0-smoothstep(0.039,0.043,sun));
  pixel=vec4(col,1.0);
}`;

function makeProgram(vs, fs) {
  function shader(kind, src) {
    const result = gl.createShader(kind);
    gl.shaderSource(result, src);
    gl.compileShader(result);
    if (!gl.getShaderParameter(result, gl.COMPILE_STATUS)) {
      throw new Error(gl.getShaderInfoLog(result) || "Shader WebGL inválido.");
    }
    return result;
  }
  const vert = shader(gl.VERTEX_SHADER, vs), frag = shader(gl.FRAGMENT_SHADER, fs);
  const result = gl.createProgram();
  gl.attachShader(result, vert);
  gl.attachShader(result, frag);
  gl.linkProgram(result);
  gl.deleteShader(vert);
  gl.deleteShader(frag);
  if (!gl.getProgramParameter(result, gl.LINK_STATUS)) {
    throw new Error(gl.getProgramInfoLog(result) || "Programa WebGL inválido.");
  }
  return result;
}

function geometry(values, usage) {
  const vao = gl.createVertexArray(), buffer = gl.createBuffer();
  gl.bindVertexArray(vao);
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
  if (values) gl.bufferData(gl.ARRAY_BUFFER, values, usage);
  gl.enableVertexAttribArray(0);
  gl.enableVertexAttribArray(1);
  gl.vertexAttribPointer(0, 3, gl.FLOAT, false, 24, 0);
  gl.vertexAttribPointer(1, 3, gl.FLOAT, false, 24, 12);
  gl.bindVertexArray(null);
  return { vao, buffer };
}

function newGraphics() {
  const world = makeProgram(vertex, fragment), sky = makeProgram(skyVertex, skyFragment);
  const locations = (program, names) => Object.fromEntries(names.map((name) => [name, gl.getUniformLocation(program, name)]));
  gpu = {
    world, sky, skyVao: gl.createVertexArray(),
    mesh: geometry(layers.mesh.data, gl.DYNAMIC_DRAW),
    water: geometry(layers.water.data, gl.STATIC_DRAW),
    outline: geometry(layers.outline.data, gl.DYNAMIC_DRAW),
    main: locations(world, ["projection", "eye", "fog", "time", "pass"]),
    background: locations(sky, ["aspect", "pitch", "fog"]),
  };
}

function memoryFloats(pointer, length) {
  if (!memory || !Number.isInteger(pointer) || pointer < 0 || (pointer & 3) ||
      !Number.isSafeInteger(length) || length < 0 || pointer + length * 4 > memory.buffer.byteLength) {
    throw new Error("O motor enviou dados inválidos.");
  }
  return new Float32Array(memory.buffer, pointer, length);
}

function bindLayer(name, stride) {
  return (pointer, count) => {
    if (!Number.isInteger(count) || count < 0 || count % stride !== 0) {
      throw new Error("O motor enviou uma malha inválida.");
    }
    const layer = layers[name];
    layer.data = count === 0 ? null : memoryFloats(pointer, count * 6).slice();
    layer.count = count;
    layer.version++;
    if (count === 0 || !gpu || contextLost) return;
    gl.bindBuffer(gl.ARRAY_BUFFER, gpu[name].buffer);
    gl.bufferData(gl.ARRAY_BUFFER, layer.data, name === "water" ? gl.STATIC_DRAW : gl.DYNAMIC_DRAW);
  };
}

function setStatus(text, kind = "") {
  status.className = `status ${kind}`;
  status.replaceChildren(document.createElement("i"), document.createTextNode(` ${text}`));
}

function refreshAvailability() {
  const ready = !failed && loaded && !contextLost && Boolean(gpu);
  enter.disabled = applySeed.disabled = randomSeed.disabled = !ready;
  if (failed) return;
  if (contextLost) setStatus("Recuperando gráficos");
  else if (!ready) setStatus("Carregando motor");
  else {
    setStatus("Wosy · motor ativo", "ready");
    startLoop();
  }
}

function loseGraphics() {
  const wasLost = contextLost;
  contextLost = true;
  gpu = null;
  if (!wasLost) {
    stopPlaying();
    if (document.pointerLockElement === canvas) document.exitPointerLock();
    if (raf) cancelAnimationFrame(raf);
    raf = 0; previous = 0;
  }
  refreshAvailability();
}

function prepareGraphics() {
  if (!gl.isContextLost()) {
    try { newGraphics(); }
    catch (e) { if (!gl.isContextLost()) throw e; }
  }
  if (gl.isContextLost()) loseGraphics();
  else {
    contextLost = false;
    refreshAvailability();
  }
}

function fail(message, detail) {
  if (detail) console.warn("Ilha de Bolso:", detail);
  failed = true;
  loaded = false;
  stopPlaying();
  if (document.pointerLockElement === canvas) document.exitPointerLock();
  enter.disabled = applySeed.disabled = randomSeed.disabled = true;
  setStatus("Motor indisponível", "failed");
  error.textContent = message;
  error.hidden = false;
}

function toast(message) {
  notice.textContent = message;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { notice.textContent = ""; }, 2800);
}

function generate(seed) {
  const previousMesh = layers.mesh.version, previousWater = layers.water.version;
  if (loaded) clearInputs();
  engine.generate(seed);
  if (previousMesh === layers.mesh.version || previousWater === layers.water.version) {
    throw new Error("O motor não enviou a malha da nova ilha.");
  }
  try { localStorage.setItem("wosy-voxel-seed", String(seed)); } catch {}
  seedInput.value = String(seed);
}

async function boot() {
  if (!gl) {
    fail("Este navegador não disponibilizou WebGL 2. Tente ativar a aceleração gráfica ou abrir em outro navegador.");
    return;
  }
  try {
    prepareGraphics();
    const response = await fetch(new URL("./engine.wasm?v=creative-1", import.meta.url));
    if (!response.ok) throw new Error(`Motor não encontrado (HTTP ${response.status}).`);
    const bytes = await response.arrayBuffer();
    const api = {
      showcase: {
        mesh: bindLayer("mesh", 3),
        water: bindLayer("water", 3),
        outline: bindLayer("outline", 2),
        frame: present,
      },
      wasi_snapshot_preview1: {
        proc_exit(code) { throw new WebAssembly.RuntimeError(`Wosy encerrou com código ${code}.`); },
      },
    };
    const { instance } = await WebAssembly.instantiate(bytes, api);
    if (failed) return;
    engine = instance.exports;
    memory = engine.memory;
    if (!(memory instanceof WebAssembly.Memory) || ["_start", "generate", "control", "clear_controls", "look", "tick", "edit_view", "select_material", "cycle_material", "place_selected"].some((name) => typeof engine[name] !== "function")) {
      throw new Error("O binário WebAssembly não oferece a interface esperada.");
    }
    if (gl.isContextLost()) loseGraphics();
    engine._start();
    let seed = 471;
    try { const stored = readSeed(localStorage.getItem("wosy-voxel-seed")); if (stored !== null) seed = stored; } catch {}
    generate(seed);
    loaded = true;
    if (gl.isContextLost()) loseGraphics();
    else refreshAvailability();
  } catch (e) {
    fail("Não foi possível iniciar o motor Wosy. Recarregue a página para tentar novamente.", e);
  }
}

function renderControls(flight, grounded, material) {
  if (displayedMaterial !== material) {
    displayedMaterial = material;
    for (const button of materials) {
      button.setAttribute("aria-pressed", String(Number(button.dataset.material) === material));
    }
  }
  if (displayedFlight === flight && displayedGrounded === grounded) return;
  displayedFlight = flight;
  displayedGrounded = grounded;
  movementState.textContent = flight ? "Voando" : grounded ? "A pé" : "No ar";
  jumpTouch.textContent = flight ? "Subir" : "Pular";
  descendTouch.hidden = !flight;
  flightTouch.textContent = flight ? "Parar voo" : "Voar";
  flightTouch.setAttribute("aria-pressed", String(flight));
}

function present(pointer, hit) {
  if (!gpu || contextLost || document.hidden) return;
  const data = memoryFloats(pointer, 25);
  if (playing) renderControls(data[22] === 1, data[23] === 1, data[24]);
  reticle.classList.toggle("target", hit >= 0);

  gl.disable(gl.DEPTH_TEST);
  gl.disable(gl.CULL_FACE);
  gl.clear(gl.DEPTH_BUFFER_BIT);
  gl.useProgram(gpu.sky);
  gl.uniform1f(gpu.background.aspect, data[20]);
  gl.uniform1f(gpu.background.pitch, data[19]);
  gl.uniform3fv(gpu.background.fog, fogColor);
  gl.bindVertexArray(gpu.skyVao);
  gl.drawArrays(gl.TRIANGLES,0,3);

  gl.enable(gl.DEPTH_TEST);
  gl.useProgram(gpu.world);
  gl.uniformMatrix4fv(gpu.main.projection, false, data.subarray(0, 16));
  gl.uniform3f(gpu.main.eye, data[16], data[17], data[18]);
  gl.uniform3fv(gpu.main.fog, fogColor);
  gl.uniform1f(gpu.main.time, data[21]);
  if (layers.water.count > 0) {
    gl.uniform1i(gpu.main.pass, 1);
    gl.bindVertexArray(gpu.water.vao);
    gl.drawArrays(gl.TRIANGLES, 0, layers.water.count);
  }
  if (layers.mesh.count > 0) {
    gl.uniform1i(gpu.main.pass, 0);
    gl.bindVertexArray(gpu.mesh.vao);
    gl.drawArrays(gl.TRIANGLES, 0, layers.mesh.count);
  }
  if (hit >= 0 && layers.outline.count > 0) {
    gl.uniform1i(gpu.main.pass, 2);
    gl.bindVertexArray(gpu.outline.vao);
    gl.drawArrays(gl.LINES, 0, layers.outline.count);
  }
}

function frame(now) {
  raf = 0;
  if (!loaded || !gpu || contextLost || document.hidden) { previous = 0; return; }
  const dt = previous ? (now - previous) / 1000 : 0;
  previous = now;
  const ratio = Math.min(devicePixelRatio || 1, 1.65);
  const w = Math.max(1, Math.round(canvas.clientWidth * ratio));
  const h = Math.max(1, Math.round(canvas.clientHeight * ratio));
  if (w !== canvas.width || h !== canvas.height) { canvas.width = w; canvas.height = h; }
  gl.viewport(0, 0, w, h);
  try {
    engine.tick(dt, w / h, playing ? 1 : 0);
    if (dt > 0) {
      for (const action of pulsedActions) {
        pulsedActions.delete(action);
        syncAction(action);
      }
    }
  } catch (e) { fail("O motor Wosy não conseguiu atualizar a imagem.", e); }
  startLoop();
}

function startLoop() {
  if (loaded && !raf && !contextLost && !document.hidden) raf = requestAnimationFrame(frame);
}

function syncAction(action) {
  if (!loaded || !playing || contextLost) return;
  const active = pulsedActions.has(action) || [...pressed].some((key) => keyActions.get(key) === action) ||
    [...dpad.values()].some((button) => keyActions.get(button.dataset.move) === action);
  if (active === downActions.has(action)) return;
  if (active) downActions.add(action);
  else downActions.delete(action);
  try { engine.control(action, active ? 1 : 0); }
  catch (e) { fail("O motor Wosy não conseguiu receber um comando.", e); }
}

function clearInputs() {
  pressed.clear();
  dpad.clear();
  downActions.clear();
  pulsedActions.clear();
  pointerLook = null;
  if (loaded) {
    try { engine.clear_controls(); }
    catch (e) { fail("O motor Wosy não conseguiu liberar os controles.", e); }
  }
}

function look(dx, dy) {
  if (!playing || !loaded || contextLost) return;
  try { engine.look(dx, dy); }
  catch (e) { fail("O motor Wosy não conseguiu mover a câmera.", e); }
}

function selectMaterial(material, cycle = false) {
  if (!playing || !loaded || contextLost) return;
  try {
    if (cycle) engine.cycle_material(material);
    else engine.select_material(material);
  } catch (e) { fail("O motor Wosy não conseguiu selecionar o material.", e); }
}

function edit(place) {
  if (!playing || !loaded || contextLost) return;
  try {
    const result = place ? engine.place_selected() : engine.edit_view(0);
    if (result === -1) toast("Aponte a mira para um bloco.");
    if (result === -2) toast("Aqui é o limite da ilha.");
    if (result === -3) toast("Esse bloco ficaria no seu caminho.");
  } catch (e) { fail("O motor Wosy não conseguiu atualizar a ilha.", e); }
}

function requestLook() {
  if (coarse.matches || typeof canvas.requestPointerLock !== "function") return;
  try { canvas.requestPointerLock()?.catch(() => toast("Arraste a cena para olhar.")); }
  catch { toast("Arraste a cena para olhar."); }
}

function startPlaying() {
  if (!loaded || contextLost) return;
  playing = true;
  shell.classList.add("playing");
  canvas.focus({ preventScroll: true });
  requestLook();
}

function stopPlaying() {
  playing = false;
  clearInputs();
  shell.classList.remove("playing");
}

function readSeed(value) {
  if (typeof value !== "string" || !/^-?[0-9]+$/.test(value)) return null;
  const seed = Number(value);
  return Number.isInteger(seed) && seed >= -2147483648 && seed <= 2147483647 ? seed : null;
}

function changeSeed(seed) {
  if (!engine || !loaded || contextLost) return;
  if (seed === null) { toast("Use um inteiro entre −2.147.483.648 e 2.147.483.647."); return; }
  try { generate(seed); toast(`Nova ilha · semente ${seed}`); }
  catch (e) { fail("O motor Wosy não conseguiu gerar esta ilha.", e); }
}

enter.addEventListener("click", startPlaying);
get("pause").addEventListener("click", () => {
  if (document.pointerLockElement === canvas) document.exitPointerLock();
  stopPlaying();
  enter.focus({ preventScroll: true });
});
get("seed-form").addEventListener("submit", (e) => { e.preventDefault(); changeSeed(readSeed(seedInput.value.trim())); });
randomSeed.addEventListener("click", () => changeSeed(crypto.getRandomValues(new Int32Array(1))[0]));
get("fullscreen").addEventListener("click", async () => {
  try {
    if (document.fullscreenElement) await document.exitFullscreen();
    else if (shell.requestFullscreen) await shell.requestFullscreen();
    else toast("Tela cheia não disponível neste navegador.");
  } catch { toast("Tela cheia não disponível neste navegador."); }
});

document.addEventListener("keydown", (e) => {
  if (!playing || e.target instanceof HTMLInputElement) return;
  if (e.code === "Space" && e.target?.nodeName === "BUTTON") return;
  const action = keyActions.get(e.code);
  if (action !== undefined) {
    pressed.add(e.code);
    syncAction(action);
    e.preventDefault();
  }
  if (e.code === "Escape") stopPlaying();
  if (e.code === "KeyQ" && !e.repeat) edit(false);
  if (e.code === "KeyE" && !e.repeat) edit(true);
  const slot = /^(?:Digit|Numpad)([1-6])$/.exec(e.code);
  if (slot && !e.repeat) {
    selectMaterial(Number(slot[1]));
    e.preventDefault();
  }
});
document.addEventListener("keyup", (e) => {
  if (pressed.delete(e.code)) syncAction(keyActions.get(e.code));
});
window.addEventListener("blur", clearInputs);
document.addEventListener("visibilitychange", () => {
  if (document.hidden) clearInputs();
  else startLoop();
});
document.addEventListener("pointerlockchange", () => {
  if (document.pointerLockElement === canvas) {
    if (!playing) document.exitPointerLock();
    return;
  }
  if (!playing) return;
  const fullscreenButton = document.activeElement === get("fullscreen");
  if (!fullscreenButton) stopPlaying();
});
document.addEventListener("pointerlockerror", () => toast("Arraste a cena para olhar."));
document.addEventListener("mousemove", (e) => {
  if (playing && document.pointerLockElement === canvas) look(e.movementX, e.movementY);
});
canvas.addEventListener("contextmenu", (e) => e.preventDefault());
canvas.addEventListener("pointerdown", (e) => {
  if (!playing || !loaded) return;
  canvas.focus({ preventScroll: true });
  if (e.pointerType !== "touch" &&
      (document.pointerLockElement === canvas || e.button === 2)) {
    if (e.button === 0 || e.button === 2) edit(e.button === 2);
    return;
  }
  if (e.pointerType !== "touch" && e.button !== 0) return;
  if (pointerLook || dpad.has(e.pointerId)) return;
  pointerLook = { id: e.pointerId, x: e.clientX, y: e.clientY };
  canvas.setPointerCapture(e.pointerId);
});
canvas.addEventListener("pointermove", (e) => {
  if (pointerLook?.id !== e.pointerId || document.pointerLockElement === canvas) return;
  look(e.clientX - pointerLook.x, e.clientY - pointerLook.y);
  if (pointerLook) { pointerLook.x = e.clientX; pointerLook.y = e.clientY; }
});
for (const event of ["pointerup","pointercancel","lostpointercapture"]) {
  canvas.addEventListener(event, (e) => {
    if (pointerLook?.id === e.pointerId) pointerLook = null;
  });
}
for (const btn of document.querySelectorAll("[data-move]")) {
  const action = keyActions.get(btn.dataset.move);
  btn.addEventListener("click", (e) => {
    if (e.detail !== 0 || !playing || !loaded || contextLost) return;
    pulsedActions.add(action);
    syncAction(action);
  });
  btn.addEventListener("pointerdown", (e) => {
    if (!playing || e.pointerId === pointerLook?.id || dpad.has(e.pointerId)) return;
    e.preventDefault();
    dpad.set(e.pointerId, btn);
    btn.setPointerCapture(e.pointerId);
    syncAction(action);
  });
  for (const event of ["pointerup","pointercancel","lostpointercapture"]) {
    btn.addEventListener(event, (e) => {
      if (dpad.get(e.pointerId) !== btn) return;
      dpad.delete(e.pointerId);
      syncAction(action);
    });
  }
}
for (const button of materials) {
  button.addEventListener("click", () => selectMaterial(Number(button.dataset.material)));
}
flightTouch.addEventListener("click", () => {
  if (!playing || !loaded || contextLost || downActions.has(7)) return;
  try { engine.control(7, 1); engine.control(7, 0); }
  catch (e) { fail("O motor Wosy não conseguiu alternar o voo.", e); }
});
document.addEventListener("wheel", (e) => {
  if (!playing || !loaded || contextLost || e.ctrlKey || e.deltaY === 0 ||
      (e.target !== canvas && document.pointerLockElement !== canvas &&
        !e.target?.closest?.(".hotbar"))) return;
  selectMaterial(Math.sign(e.deltaY), true);
  e.preventDefault();
}, { passive: false });
get("remove").addEventListener("click", () => edit(false));
get("place").addEventListener("click", () => edit(true));
canvas.addEventListener("webglcontextlost", (e) => {
  e.preventDefault();
  loseGraphics();
  if (!failed) toast("O navegador pausou os gráficos.");
});
canvas.addEventListener("webglcontextrestored", () => {
  if (failed) return;
  try { prepareGraphics(); }
  catch (e) { fail("Não foi possível restaurar os gráficos. Recarregue a página.", e); }
});
boot();

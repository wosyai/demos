# Wosy demos

Playable examples built with the [Wosy language](https://github.com/wosyai/lang).

## Flying Low

A third-person flight game with two short fictional courses inspired by early aviation. In **Barnstorm Run**, the Wright Flyer banks around farm buildings and lines up for a landing. In **Seine Sprint**, Santos-Dumont’s plane races along the Paris riverfront. Choose a faster or more forgiving line, finish on the landing strip, and chase a ghost of your best flight.

The game runs in English in a WebGL 2 browser on desktop or mobile. A Wosy WebAssembly engine owns flight dynamics, courses, the chase camera, scoring, and the replay. The browser handles input, drawing to the screen, and saving replay data on the device.

See the [Flying Low build guide](flight/BUILD.md). The complete route and replay tests run with `node tools/verify-flight-wasm.mjs`.

## Pocket Island

Start on foot in a seeded voxel landscape or switch to creative flight. Jump, break blocks, and build with six materials and original pixel textures. Terrain, texture pixels and face UVs, collision, movement, targeting, and edit timing run in Wosy compiled to WebAssembly. The browser host handles input and submits the mesh to WebGL 2, without a 3D framework.

- Desktop: WASD or arrows to move, Space to jump, and F to toggle flight. In flight, Space and C rise and descend. Select with 1–6 or the wheel, and use Q/E to remove/place. With mouse capture, left/right click also break/place; hold either action to repeat. Drag to look when capture is unavailable.
- Touch: drag the left joystick to move and the world on the right to look. Use the larger jump, flight, and editing buttons with your other thumb. Pick a building material from the hotbar. To set a seed manually, pause and open World options.

This is an experimental demo, not a claim that all game logic is statically verified.

## Build Pocket Island locally

Use the Wosy compiler revision in `tools/wosy-revision`, LLVM/Clang/LLD 18.1.8, Python 3 and Node. The build links the exact WebAssembly exports and checks the actual browser ABI and a deterministic world before updating the published binary.

```sh
WOSY=/path/to/wosy bash ./build.sh
python3 -m http.server 8000
```

Open `http://localhost:8000/voxel/` with a WebGL 2-capable browser. The site is static and does not require a backend. The engine and browser-host smoke tests can run without a GPU:

```sh
node tools/verify-wasm.mjs voxel/engine.wasm --binary
node tools/verify-host.mjs
```

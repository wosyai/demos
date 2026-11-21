# Wosy demos

Playable examples built with the [Wosy language](https://github.com/wosyai/lang).

## Last Ferry

Pick up a tape at a coastal drive-in and reach the last ferry before it leaves.
Drive a longer boulevard around traffic, take an alley, or get out and cut
through on foot. Try the district without a time limit in **Free roam**.
The town and its moving objects are full 3D; Wosy runs the vehicle, traffic,
pedestrians, collisions, and mission. See the [build guide](ferry/BUILD.md).

## Flying Low

A third-person game with two early-aviation missions. In **Pasture Landing**, bring the Wright Flyer down gently and stop before the short field ends. In **Paris Air Mail**, take the low cyan approach over the bridge or the wider amber detour, release the pouch over its target, then land. Fly again against a ghost of your best completed mission.

Flying Low runs in English on desktop and mobile in a WebGL 2 browser. Wosy owns flight dynamics, the chase camera, mission geometry and outcome, scoring, and replay. The browser handles input, drawing, and storing replays on the device.

See the [build guide](flight/BUILD.md). Verify both missions and replay behavior with `node tools/verify-flight-wasm.mjs`.

## Pocket Island

Explore a seeded island in **Creative**, or carry a flame to the lighthouse in **Beacon Run**. Take the longer dry ridge, build across the channel, or risk a shortcut through the tidal cut. Waves affect buoyancy and drag, and the tide can submerge the flame. Your creative terrain is restored when you leave the mission.

Wosy owns terrain, texture pixels, collisions, water geometry and swimming, camera and editable targets, and all mission rules. The browser only handles input and submits the meshes to WebGL 2.

- Desktop: WASD or arrows to move, Space to jump or swim up, V to switch perspective, and F to toggle creative flight. In flight, Space and C rise and descend. Select with 1–6 or the wheel, and use Q/E to remove/place. With mouse capture, left/right click also break/place; hold either action to repeat. Drag to look when capture is unavailable.
- Touch: drag the left joystick to move and the world on the right to look. Use the jump, view, and editing buttons with your other thumb. Flight is available in Creative. Pick a building material from the hotbar. To set a seed manually, pause and open World options.

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

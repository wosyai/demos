# Wosy demos

Playable examples built with the [Wosy language](https://github.com/wosyai/lang).

## Voxel island

Explore a seeded island, remove or place blocks, and generate a new world. Terrain, meshes, input state, camera, picking, and edits run in Wosy compiled to WebAssembly. The browser host handles input and submits the mesh to WebGL 2, without a 3D framework.

- Desktop: WASD or arrows to move, Space/C to rise/descend, and Q/E to remove/place. With mouse capture, left/right click also remove/place. Drag to look when mouse capture is unavailable.
- Touch: use the on-screen movement controls, drag to look, and use the remove/place buttons.

This is an experimental demo, not a claim that all game logic is statically verified.

## Build locally

Use the Wosy compiler revision in `tools/wosy-revision`, LLVM/Clang/LLD 18.1.8, Python 3 and Node. The build links the exact WebAssembly exports and checks the actual browser ABI and a deterministic world before updating the published binary.

```sh
WOSY=/path/to/wosy bash ./build.sh
python3 -m http.server 8000
```

Open `http://localhost:8000/voxel/` with a WebGL 2-capable browser. The site is static and does not require a backend. To run the smoke tests against the checked-in artifact, run `node tools/verify-wasm.mjs voxel/engine.wasm --binary`.

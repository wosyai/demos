# Building Last Ferry

Build with Wosy revision `7c80c31f97ea35c80b7344f23337dedfcbaa9776`,
LLVM/Clang/LLD 18.1.8, Python 3, and Node. No npm packages are required.

```sh
cd ferry
WOSY=/path/to/wosy
"$WOSY" build app
node verify-wasm.mjs .wosy/artifacts/app/dev/main/main
node --test test/host.test.mjs
cp .wosy/artifacts/app/dev/main/main ferry.wasm
```

Set `CLANG` and `WASM_LD` if LLVM 18 is not on your PATH.
Serve the repository as static files and open `/ferry/` in a WebGL 2 browser.

Wosy produces the two XYZRGB batches and perspective projection, and owns the
fixed-step simulation, foot and car movement, traffic, collision responses,
objective state, and the one-shot action consumed by the next step. Browser
code forwards analog and digital input, displays status, and submits batches
to WebGL. The lobby illustration is not a gameplay capture or a world asset.
All world objects with volume are modeled in 3D, not stacked sprites.

## Browser ABI

- Imports from `ferry`: `world(ptr, floats)`, `moving(ptr, floats)`,
  `frame(ptr, floats)`. Both mesh batches use six floats per vertex (XYZRGB),
  with three vertices per triangle. World geometry can be reused across resets.
- Exports: `_start()`, `reset(mode)`, `tick(dt, steer, drive, controls, aspect)`,
  `cancel_action()`, and memory. Reset mode 0 is the timed mission and mode 1
  is free roam. Axes range from -1 to 1; positive steer means right and
  positive drive means forward. Control bit 0 holds brake or sprint; bit 1
  queues the contextual action. Cancel it on lifecycle interruption.
- Frame length 30: view-projection [0–15], walking/driving [16], mission
  state [17], seconds [18], speed [19], action cue [20], latest contact and
  sequence [21–22], target range and position [23–25], player position
  [26–27], heading [28], signed turn cue [29].

## Lobby art

`art/lobby.webp` is an original illustration generated with the built-in image
tool and encoded as a 1536 × 1024 WebP. Generation prompt:

> Use case: stylized-concept. Create one wide 1536×1024 or widescreen landscape original game title-menu illustration for Last Ferry (no words in the image). A late-1980s waterfront district at blue hour: a glowing Art Deco drive-in marquee without any readable text, a boxy immaculate cream coupe with a restrained teal side accent, stylized asphalt lane markings, a couple of palm silhouettes and, beyond them, a small warmly lit ferry on the teal canal. Keep the car and main lights on the right third, with the central focal elements kept within the middle 70% vertically for responsive wide crops. The entire left 45% should be quiet dark deep navy negative space and faint pavement for an HTML title set later, with no high-contrast details there. Art direction: intentionally designed angular low-poly shapes with tactile, restrained pixel dithering, navy and dusty rose with small pools of amber and cyan, strong readable silhouette and cohesive dusk atmosphere. One connected illustration, no framing border. Neither a gameplay screenshot nor an imitation of an existing game cover. No letters, logos, watermarks, real vehicle brands, characters, guns, violence, or UI.

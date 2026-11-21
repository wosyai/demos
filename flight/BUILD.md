# Building Flying Low
From the demos checkout, with Wosy compiler revision
`8aecd0acc799d9c705a1fcfdb760af463bed4936`:

```sh
cd flight
WOSY=/path/to/wosy
"$WOSY" build app
node verify-wasm.mjs .wosy/artifacts/app/dev/main/main
cp .wosy/artifacts/app/dev/main/main flight.wasm
```

Set `CLANG` and `WASM_LD` if LLVM 18 is not on your PATH. There are no npm
dependencies. The browser, native headers and JS do not participate in
flight physics, camera placement, route progress, or replay simulation.

The WebAssembly host imports module `flight`: `world` and `aircraft` receive
packed XYZRGB triangles, `frame` receives a 28-float projection/HUD buffer,
and `record` receives an opaque binary replay. The host supplies elapsed real
time, an input bitmask and viewport aspect. Pointers are byte offsets into
exported WebAssembly memory; reacquire typed views after memory growth.
`world` is stable until a different course is selected, so the host can
re-upload it on graphics context recovery. `aircraft` and `frame` are stable
until the next `tick`. Persist any `record` bytes before another callback
can replace them.

A replay consists of the magic bytes `WF`, one version byte, one course byte,
an unsigned little-endian 16-bit step count, and one six-bit control mask per
step. The engine admits at most 7,200 steps (four minutes at 30 Hz). It replays
candidate records in a separate simulation lane before setting a best time
and requires a legal landing on exactly the final control step.

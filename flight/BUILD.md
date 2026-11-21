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
packed XYZRGB triangles, `frame` receives a 31-float projection/HUD buffer,
and `record` receives an opaque binary replay. The host supplies elapsed real
time, an input bitmask and viewport aspect. Pointers are byte offsets into
exported WebAssembly memory; reacquire typed views after memory growth.
`world` is stable until a different course is selected, so the host can
re-upload it on graphics context recovery. `aircraft` and `frame` are stable
until the next `tick`. Persist any `record` bytes before another callback
can replace them.

In the frame, the appended fields are a signed normalized turn cue at [28],
the landing instruction enum (0 none, 1 line up, 2 slow down, 3 ease descent,
4 aligned) at [29], and shortcut availability at [30]. Older fields retain
their positions. The host asks for proportional input support via
`input_version() == 1`. Set bit 6 in the tick input and put the signed
bank and pitch bytes at bits 8–15 and 16–23. Keyboard direction on an axis
takes precedence, and the engine quantizes effective axis motion to ±7.

A replay consists of the magic bytes `WF`, one version byte, one course byte,
an unsigned little-endian 16-bit step count, and one canonical control per
step. Version 1 retains the original one-byte digital mask. A run with
proportional input uses version 2, with each step taking two bytes in
little-endian order. The same canonical control feeds both live and playback
physics. The engine admits at most 7,200 steps (four minutes at 30 Hz) and
14,406 bytes, replays candidate records in a separate simulation lane, and
requires a legal landing on exactly the final control step.

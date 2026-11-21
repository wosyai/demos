# Building Flying Low
From the demos checkout, with Wosy compiler revision
`8aecd0acc799d9c705a1fcfdb760af463bed4936`:

```sh
cd flight
WOSY=/path/to/wosy
"$WOSY" build app
node verify-wasm.mjs .wosy/artifacts/app/dev/main/main
node --test test/host.test.mjs
cp .wosy/artifacts/app/dev/main/main flight.wasm
```

Set `CLANG` and `WASM_LD` if LLVM 18 is not on your PATH. There are no npm
dependencies. The browser handles input, presentation, and storage. Flight
physics, scenery, camera, mail trajectory, landings, and replays run in Wosy.

## Host ABI

The WebAssembly host imports module `flight`: `world` and `aircraft` receive
packed XYZRGB triangles, `frame` receives a 32-float projection/HUD buffer,
and `record` receives an opaque binary replay. The host supplies elapsed real
time, an input bitmask, and viewport aspect. Pointers are byte offsets into
exported memory; reacquire typed views after growth. `world` is stable until a
different mission is selected. `aircraft` and `frame` are stable until the next
`tick`. Persist any `record` bytes before another callback can replace them.

The frame keeps the projection in [0–15], mission in [16], elapsed seconds,
speed and altitude in [17–19], terminal status in [22], best time in [23],
and score in [24]. Mission-specific fields are:

| Index | Meaning |
| --- | --- |
| 20 | Phase: 0 cross the Seine, 1 approach drop, 2 landing approach, 3 rollout, 5 falling pouch |
| 21 | Drop window: 0 inactive, 5 high, 6 low, 7 misaligned, 8 not yet over target, 9 release |
| 22 | End: 0 active, 1 complete, 2 obstacle, 3 bounds/time, 4 outside strip, 5 alignment, 6 speed, 7 mail not delivered, 8 bridge, 9 overrun, 10 descent, 11 lateral exit |
| 25–26 | Route (0 none, 1 low, 2 wide) and last rejected release reason |
| 27–28 | Distance to target (or rollout remaining) and signed normalized turn cue |
| 29–31 | Landing instruction (1 align, 2 slow down, 3 ease descent, 4 ready), climb warning, mail delivered |

Input uses bits 0–5 for left, right, climb, dive, power, brake. For proportional
controls, set bit 6 and put signed bank and pitch bytes at bits 8–15 and 16–23.
Keyboard steering takes precedence on its axis. Wosy quantizes effective
axes to ±7. Bit 7 is a one-shot mail release; the browser sends it for one
`tick`, and the engine consumes it on the next fixed simulation step.
`cancel_drop()` clears a not-yet-consumed release when input is interrupted
without changing the simulation clock or undoing a pouch already launched.

Mission replay format uses magic bytes `WF`, version byte 3, mission byte, a
little-endian 16-bit step count, then one little-endian canonical control word
per step. Release is included in its original step. Only legally completed
missions on the final step are admitted, up to 7,200 steps and 14,406 bytes.
The former race rules used versions 1 and 2 with different storage; the
browser leaves those save keys untouched.

Touchdown and rollout use the same strip limits used to draw the markings.
Steering during rollout is slower than airborne banking. The Eiffel Tower
uses tapered leg, platform, lattice, and arch collision envelopes rather
than an invisible solid box; these approximate the drawn ironwork.

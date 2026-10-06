# Actual archive room profiling — bounded measurement brief

Profile the current shipping GameRoot/SceneRouter/player-owned S02 room at
1920x1080, Low internal scale.75 and Medium1.0, in three fixed cold hero/cold
roof/warm hero cases.Default45 warm-up frames and at least1.2 seconds per case, default180 measured frames,
allow60..600; warm-up15..180 frames. Current software run explicitly uses60
measured/20 warm-up frames with the same1.2-second minimum. VSync and Engine max FPS disabled only inside this CLI fixture.
Keep shader/material/art identities and quality budgets unchanged. Warm state
uses the original quiet projection, not new acquisition/save events. Preserve each completed case immediately, so later interruption does not erase
measurements. Retain complete logs, raw per-frame counters, non-measured post-run screenshots and
protected physical primary/backup save hashes in a fresh private cache-free copy.

Measure real process-frame wall intervals, Performance main/physics seconds
converted to ms, RenderingServer render setup and viewport CPU/GPU ms with
viewport timing enabled, draw calls/rendered primitives and texture/buffer/video/
engine static bytes. Report min/median/nearest-rank p95/max separately; never
sum overlapping monitors into an invented complete frame time. Renderer GPU
numbers describe the identified device; on llvmpipe they are software Vulkan
timings. Zero may mean unavailable. Engine static allocation is not process RSS;
rendered primitives include render passes and are not unique authored triangles.
The raw `main_process_ms` label is the engine TIME_PROCESS complete-frame
readout, not isolated script/gameplay CPU. Do not compare it with the7–8ms
main-gameplay CPU envelope or describe it as an independent CPU profiler.
Some monitors can lag by up to a second; the warm-up and raw data are retained.

A successful tooling receipt means valid measurements/source/slots, not GTX1060
or1080p60 acceptance. Technical Baseline's16.67ms frame,12–14ms GPU/7–8ms CPU,
geometry/memory envelopes and minimum three full release profiler-assisted runs
remain unchanged. These three static instrumented views do not count as full
release runs. Identify actual engine, renderer, device/vendor/API/window/internal
scale and software classification. The native-display entry is for an actual
Linux physical display/GPU, independently reviewed later; it never infers target
approval from a device name. Windows physical/save isolation remains unverified.

Current run uses the authenticated TCP-Xvfb/llvmpipe runner. Future Linux
physical-display invocation from the repository root:

```sh
python -B tools/profile_archive_room.py --godot /absolute/godot --native-display --samples 180 --output docs/production/evidence/archive_reconstruction/room-profile-physical-1
```

Keep a new output directory per run. The runner rejects non-Linux hosts before
launch, since XDG save isolation has not been verified there. The first default
180-frame software run reached the250-second outer bound after two captured
views; its full failure is preserved, not promoted as a performance result.
The supervised checkpoint coordinator can overlap instrumented wall timing;
these are current-environment measurements, not isolated laboratory benchmarks.
No fixture is loaded by production scenes/autoloads. Actual current scene art,
puzzle controls, owned save/scene/audio behavior and global defaults stay fixed.
After the measured stage checkpoint, continue bounded rug/room polish within
the active session. Full room/gallery/authored audio/target hardware/VS1 remain
open; no S03/bulk acceptance.

Primary units/API references: Godot RenderingServer and Performance official
documentation, with actual4.7.2 CLI reflection confirming these methods/enums:
https://docs.godotengine.org/en/stable/classes/class_renderingserver.html
https://docs.godotengine.org/en/stable/classes/class_performance.html

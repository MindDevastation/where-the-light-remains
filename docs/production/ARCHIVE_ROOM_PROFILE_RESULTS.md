# Current 1080p archive room measurements

Instrumented actual GameRoot/SceneRouter S02 room, Godot4.7.2, Forward+,
llvmpipe LLVM20.1.2 software Vulkan. Low internal scale.75, Medium1.0, window
1920x1080, VSync/frame cap off; three fixed views each,60 measured frames after
at least20 frames/1.2 seconds warm-up.360 actual frame samples total. Data:
room-profile-2, protected primary/backup unchanged, cache-free import/startup,
clean Godot completion and six inspected1080p screenshots. Each completed
case is immediately preserved. Four early entry guards reject non-Linux hosts
and invalid frame bounds before any engine launch/output creation.

| Preset | View | Wall median ms | Wall p95 ms | Renderer GPU median ms | Calls |
|---|---|---:|---:|---:|---:|
| low | cold_hero | 348.15 | 377.23 | 337.20 | 49 |
| low | cold_roof | 587.20 | 690.50 | 573.38 | 24 |
| low | warm_hero | 345.37 | 386.22 | 332.45 | 51 |
| medium | cold_hero | 538.54 | 584.52 | 521.69 | 49 |
| medium | cold_roof | 879.34 | 997.48 | 865.65 | 24 |
| medium | warm_hero | 562.84 | 689.84 | 550.09 | 51 |

These are **software** device timings, not GTX1060 or1080p60 measurements.
GPU timestamps describe llvmpipe work executed on CPU. Concurrent supervised
checkpoint collection can affect wall jitter; this is not an isolated laboratory
benchmark. The first default180-frame software run reached its250-second outer
bound after two images; preserved room-profile-1 failure is not accepted timing.

Raw `main_process_ms` means engine TIME_PROCESS, the complete-process-frame
monitor, not isolated script/gameplay CPU. Do not compare it with the baseline
7–8ms main-gameplay CPU envelope, or add it to renderer timing. Render setup/
viewport CPU/GPU/physics/wall are separate readouts with different scope. Some
monitors can lag. Rendered primitives31850..46112 are pass counters, not unique
authored triangle counts. Six views have zero visible shadow lights; no shadow
or quality budget was raised. Low texture monitor68677632 bytes / renderer video
104971808 maximum; Medium98792448 /145109024 maximum. Texture/video monitors
include render allocations, not only asset textures; engine static allocation
is not process RSS. Identical art/renderer shape at different internal scales
is retained in the screenshots.

Linux physical-display entry: tools/profile_archive_room.py --native-display,
with independently configured actual Godot/GPU. Unsupported hosts are blocked
because private XDG save isolation has not been verified there. Physical target
status remains NOT_ACCEPTED and full release profiler-run count0; these three
static cases do not satisfy the minimum three full profiler-assisted release
runs. See ARCHIVE_ROOM_PROFILING.md for command, units and limitations.

All prior accepted game/tool source identities compare unchanged against the
bookcase stage; additions are unbound CLI profiling fixtures and helper only.
Existing282 regression assertions are reused by those exact dependency hashes;
no claim that those commands were repeated for this tooling-only addition.
No new art/LFS/material/controller/default changes. Next: the bounded original
cloth rug brief, then continued room/tooling work within the active session.
Full gallery/authored audio/target hardware/ARCH/VS1/S03 remain open.

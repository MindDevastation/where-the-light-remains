# T019 gate/channel component evidence — 2026-10-04

**PASS for the isolated shared components**, accepted source
`d757a084c0773c9108f4d1fcbb95eb60bebf3dfd` on
`feature/04-archive-gameplay/archive-route-presentation`.
This continues the unfinished T019 patch. It does not repeat accepted S01/S02
tests, certify a recreated gameplay world, or close the full T019 integration.
See `../../SESSION_RECOVERY_2026-10-04_14-53.md` for the source-loss boundary.

## Actual clean-source result

`validated/clean_results.json`: **7 commands PASS**, 163 materialized source files
unchanged in both the working checkout and initially cache-free test copy,
temporary directory removed successfully. Each command has an immutable complete
stdout/stderr log and a receipt containing exit status, byte count, SHA-256 and
actual protected-file hashes. All seven log payloads were independently compared
to their receipts; no streamed partial log is used as acceptance.

| New check | Actual evidence/result |
| --- | --- |
| Clean import of new source | `clean_import.complete.log`, exit 0; no Godot errors/warnings |
| Headless component behavior | `headless_route.complete.log`: 147 assertions PASS |
| Authenticated TCP X11/Vulkan Forward+ behavior | `graphics_route.complete.log`: same 147 assertions PASS |
| Actual Low active route, effects off | `active_low.png/json`: all 17/17 route samples visible, dormant routes 0/17 |
| Actual Low completion/next route | `completed_low.png/json`: warm previous and blue next route both 17/17, other three 0/17 |
| Medium active route | `active_medium.png/json`: active route 17/17, other four 0/17 |
| All five restored completed, Low | `all_completed_low.png/json`: every warm route 17/17 |

All four 1920×1080 images were visually inspected. Russian wing labels are
readable, active/warm geometry remains clear, dormant barriers stay closed and
restored open barriers are absent. These are **engineering graybox views**,
not final Archive art or screenshots of the absent newer ArchiveMain.

Each command used independent userdata with real, valid v1 primary and backup
JSON files containing different immutable checkpoint IDs. Their bytes and the
default settings file remained unchanged. Only the review's separately named
fixture preferences file was written. GameState, dirty flag, InputManager mode/
revision and progression events remain unchanged by component operations.

The physical fixture instantiates the actual accepted first-person capsule and
the same shared gate resource five times. Dormant/unlocked states stop its feet
approximately 0.471 m before each barrier; open/completed states allow passage to
5.520 m beyond the gate plane. All remain floor-supported. A 45-degree gate also
blocks/clears correctly. Time scale 8 accelerates this engineering fixture and
is not a player movement-timing or performance measurement.

Further cases: instant restored fresh instance without opening/audio hooks;
cancelled opening/pulse with no stale event; idempotent same-state assignment;
explicit completion pulse; detach/reparent ownership; missing/queued/replaced
bindings and invalid states; frozen candidate colliders for router ray queries;
synchronous opening receiver's later state; forward and reverse pulses using
offset/yaw/scale-transformed mesh bounds with exact endpoints.

## Scope and retained failures

Godot 4.7.2, X11 and CPU Vulkan llvmpipe were used. Low review applies the actual
Low renderer scale 0.75 with effects/shadows off; authored glow and volumetrics
are confirmed disabled. No physical target GPU/FPS, Windows, final mesh/SFX,
shipping cinematic, complete VS1 or whole-game acceptance is claimed.
The established Xvfb TCP + MIT-MAGIC-COOKIE path remains enabled; harmless
interface-enumeration/XF86 keysym warnings are preserved in raw Xvfb output.

`initial/` retains the development failures. The restored older Godot executable
was truncated to 99,869,184 bytes and segfaulted even for `--version`; its ZIP was
also incomplete. The official pinned ZIP was downloaded again and checked against
SHA-256 `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`;
the restored executable is 146,414,384 bytes and reports the expected version.
This was dependency corruption, not an AF_UNIX or renderer restriction.

The first test scene had an inferred-Variant boolean parse error; the graphical
runner reached its own timeout and cleaned up its own Godot/Xvfb processes. The
typed boolean fix is included in accepted source. An initial headless wrapper's
uncaught timeout did not preserve its captured output; it is not acceptance.
The final runner captures complete outputs even on timeout and records cleanup.
No old/foreign process was terminated during reconnection.

## Remaining integration and reproduction

The missing newer ArchiveMain/Boot/fragment code and its original S02 evidence
have not been restored or replaced by this isolated proof. Connecting these
components to that controller and testing its actual route remains open.
`GATE-VS1` remains open; S03 has not started. Original materialized files in both
older worktrees remain exact and their Git status remains clean.

Run just this new feature's clean proof:

```sh
python3 tools/check_archive_route.py --godot /absolute/path/to/Godot \
  --graphics-prefix /absolute/path/to/graphics --output /new/empty/evidence/path
```

View the isolated fixture on a native Linux display:

```sh
python3 tools/run_route_review.py --godot /absolute/path/to/Godot --view completed_low
```

`--screenshot /new/file.png` captures and exits. This tool does not grant story
progress or select a shipping stage. Source selection deliberately leaves heavy
art/promised LFS objects absent; it never treats sparse absence as deletion.

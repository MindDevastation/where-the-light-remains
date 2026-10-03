# SaveGame DTO evidence — 2026-10-03 UTC

Accepted source `2006a7691f0b05d506e8ea2f58be799ec7a9e026`; identities in
`manifest.json`. Fresh archive of committed game/tools, no initial `.godot`,
actual editor import; 188 tracked files unchanged after checks. Fourteen existing
LFS payload identities verified; eleven runtime copies reused from the hydrated
worktree/cache. No new binary upload or independent retrieval claim.

| Gate | Actual evidence |
| --- | --- |
| JSON format | `clean_import_tests.log`: fresh/partial/complete full-precision JSON round trips, StringName normalization, fractional and maximum safe integer values PASS |
| Validation | Same log: required/unknown fields, versions, stage/checkpoint syntax, canonical fragment prefix, duplicate achievements, completion, malformed world/milestone types, Objects/Resources/vectors, nonfinite/unsafe numbers, depth/nodes/UTF-8 size and cycles rejected PASS |
| State transfer | Same log: deep-copy isolation, validated all-or-nothing GameState apply, new-game reset, invalid capture before recursive copy, original state restored PASS |
| Integrity | Same log: production save/backup/settings hashes, dirty flag, events, input, pause and audio unchanged PASS; DTO performs no IO |
| Existing shell | Same log: read-only debug inspection and pause/fade/nested settings paths PASS |
| Player / input | `player_input.log`: six actual Archive traversals, wall/ray/race/controller and twenty input mode/focus/pause combinations PASS |
| Graphics / startup | `graphical_engine.log`: authenticated Xvfb TCP + MIT-MAGIC-COOKIE, Godot X11/Vulkan Forward+, production root/eight autoloads/safe-exit dispatch PASS |

All accepted commands exit zero. Superseded development failures exposed JSON
integral-number normalization and engine decimal-float boundary rounding; both
were corrected before this clean acceptance. The fixture has its own timeout
and explicit failed-decode guard. No stalled development process remains.

Full stage/checkpoint registry and each world's domain validation belong to the
future scene router/controllers. No canonical puzzle counts/angles/solutions were
invented. Atomic IO/backup/recovery, App error handling and Boot/Continue are
subsequent features. Existing SaveManager still has scaffold IO behavior.

Integration: PR #37 merged as `753f306b6e5fb6f80092833de5325b67e5ef1e31`; tree `b582eafda66fbf71f649ee715d43acb48706742a` matches the accepted feature. `epic_engine.log` confirms merged graphical startup. GitHub reported MERGEABLE/CLEAN and no configured CI checks; no CI execution is claimed.

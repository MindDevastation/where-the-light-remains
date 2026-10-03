# Logical saves

## Typed DTO implementation brief — 2026-10-03 UTC

Read authority: technical save contract, QA recovery checklist, narrative/finding
order, current GameState/SaveManager scaffold and successful settings/pause evidence.
Keep exactly eight autoloads; use the established TCP X11/Forward+ path.

First independently reviewable slice: a typed `SaveGame` Resource v1 and validated
deep-copy GameState capture/apply. Disk IO and App exit behavior remain the next
feature. No SceneTree, resources, transforms, scene paths, hidden poem letters,
settings or invented puzzle solution values enter the DTO.

Fields: `save_version`, `stage_id`, `checkpoint_id`, `collected_fragments`,
`world_states`, `milestones`, `achievement_ids`, `game_completed`. Stage IDs retain
the existing `s00_prologue` naming contract; validate S00–S15 prefix/identifier
syntax only. The future router must validate actual registered full stage IDs and
checkpoint/spawn IDs before use. No guessed sixteen-entry scene-path registry.

Technical fragment IDs map to canonical found order: `star`, `hearth`, `echo`,
`sprout`, `feather`, `bell`, `sun_glint`, `double_moon`, `constellation`,
`clear_crystal`. A collected list is a prefix of this order, without duplicates.
These are code identifiers, not player-facing labels/final numbering. Completion
requires an S15 stage and all ten fragments; no optional achievement gates it.

World namespaces hold only bounded JSON primitives/dictionaries/arrays; world
controllers will validate exact domain states when their canonical parameters are
available. No ring angles/state counts or finale solve data are invented here.
Milestones are identifier→bool; achievement IDs are unique identifiers, initially
empty with no automatic awards. Defaults represent a fresh S00 logical state.

Reject wrong/missing/unknown fields, invalid identifiers/order, nonfinite/unsafe
JSON numbers, Objects/Resources/vectors, excessive depth/nodes/text/serialized size.
JSON-only copies normalize StringName keys/values to strings and exact integral
JSON numbers to integers (fractional finite values remain floats). Integers are
limited to the exact JSON double range ±(2^53−1). Schema v1 is the first
disk schema: unsupported versions return an explicit error; no predecessor
migration is invented. Future-version data must not be treated as corruption.

Acceptance: default/partial/complete and actual JSON round trips; corrupt/type/
version/order/depth/size/resource cases; deep-copy isolation and all-or-nothing
GameState apply; production settings/save hashes unchanged; clean source import,
previous input/player/settings/pause/debug/startup paths and graphical smoke.
Acceptance PASS on source `2006a7691f0b05d506e8ea2f58be799ec7a9e026`.
Actual output and identities: `evidence/save_dto/README.md`. Fresh editor import,
DTO and GameState isolation/type/order/size/cycle checks, prior player/input/pause/
read-only inspector and authenticated TCP X11/Forward+ startup pass. All 188
tracked game/tools files in the clean fixture remain identical after checks;
existing fourteen LFS payload identities verified, eleven runtime copies reused.

`GameState.capture_save()` returns a validated isolated snapshot or null;
`apply_save()` validates a full copy before changing any logical state. Neither
method writes files, marks dirty, emits gameplay events, routes scenes or applies
settings. Integral JSON values normalize to integers, including the exact maximum
safe integer 9007199254740991; fractional values retain their numeric value.
The numeric bound is derived from an integer constant because this engine's
decimal float literal parsing otherwise rounds that boundary down by one.

Atomic write/backup/recovery and safe-exit failure handling remain the next slice;
Boot/Continue/world-domain validation follows routing. No disk-persistence PASS
is implied by this DTO acceptance.

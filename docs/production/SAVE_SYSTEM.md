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

## Atomic persistence brief — 2026-10-03 UTC

Read the accepted DTO, settings and pause evidence and technical/QA save contract.
Implement bounded UTF-8 JSON reads, primary/backup results without state mutation,
same-directory temp write/flush/validated readback/backup/replace, and dirty flush
that clears only after success. Preserve the last valid primary as backup; first
save creates a valid backup too. Corrupt primary may recover from a valid backup,
but future schemas and actual IO permission errors must not be bypassed. Both
invalid files are preserved and reported as an explicit new-game decision for
the future Boot UI. No automatic deletion, reset, startup apply or v0 migration.

App must quit only after successful flush. Failed exit remains alive and presents
a Russian retry/stay dialog; native close uses the same path. InputManager owns
modal pause/capture. Tests use unique fixture directories and injected replacement
failures, plus actual IO failure and graphical dialog/startup regressions. Existing
production files and eight-autoload contract remain intact.

This uses Godot flush and same-directory rename with verified bytes, not a claim
of platform-independent power-loss durability or multi-process save locking.
Windows rename/physical-close certification remains target-runtime validation.
Acceptance PASS on source `dd3068e8dabc07b71b17c128c21ddda86b33c186`;
actual output and identities in `evidence/atomic_save/README.md`. Clean import,
199 unchanged tracked files, real file/backup/corruption/schema/UTF-8/error/dirty
tests, actual GUI retry/stay and real X11 close on failed and successful save,
prior shell/player/input/DTO/debug and graphical startup PASS.

### API and failure semantics

- `read_save()` returns `error`, isolated `data`, `source` (`primary`, `backup`,
  `none`), per-file errors and `needs_new_game`; it never applies/repairs state.
  Missing or corrupt primary may use valid backup. Future schema or IO obstacle
  stops fallback. Both invalid files remain untouched and signal the future Boot
  UI to offer an explicit New Game decision; that UI/reset operation is not here.
- `write_save(saved)` validates a copy, prepares/flushed/readback-checks a new
  same-directory primary temp, atomically updates backup from the last valid
  primary, then replaces primary. First save also creates a valid backup. Backup
  recovery never copies corrupt primary over the valid backup. Existing unknown
  schemas in either file and real IO errors block writes; both corrupt files
  cannot be silently overwritten. Only this operation's exact temps are removed.
- `flush_if_dirty()` returns Error and clears dirty only after a successful write;
  clean flush performs no IO. GameState capture/apply still do not mark dirty.
  Future checkpoint/collection owners explicitly call `mark_dirty()`.
- App disables automatic native quit and routes window close through the same
  flush. Failure emits local `exit_failed`, keeps the app/state alive, cancels an
  active fade and opens Russian retry/stay choices. Stay/Esc restores only modal
  ownership; existing pause and later locks survive. Removed modal releases its
  own pause. Successful dirty exit and native close commit before quitting.

Read limits apply before parsing; malformed/overlong/surrogate/out-of-range UTF-8
is rejected before string conversion. Fixture directories are unique. Real App
success tests use guarded fresh `XDG_DATA_HOME`; production user data/settings are
unchanged. Graphical input is injected through Godot, while window-close requests
are actual `WM_DELETE_WINDOW` messages. Eight autoloads remain unchanged.

Boot/Continue, explicit corrupt-save New Game UI/overwrite policy, sequential
migrations when a real next schema exists, registered stage/checkpoint/world
validation, authored checkpoint triggers and target Windows/hardware acceptance
remain later work. No invented stage paths or puzzle parameters were added.

# S00 / S01 / S02 authored audio slice

Status: twelve-source edit/export manifest and source measurements completed;
authored derivatives/bindings remain unfinished.
Continue from the existing accepted AudioDirector and fragment duck integration.
Do not rebuild their foundation or start S03 while GATE-VS1 is open.

## Available inputs

Authority: `docs/design/AUDIO_BASELINE.md`,
`assets/audio/music/MUSIC_RUNTIME_POLICY.md`, `MUSIC_INDEX.md`,
`assets/audio/README.md` and the latest owner recovery instructions.

Exact twelve-file hashes and ffprobe headers are sealed in
`evidence/audio_director/slice-input-inventory-1/results.json`: 314,574,978 source
bytes, all stereo 48 kHz 16-bit PCM. Durations range from 79.84 to 178.40 seconds.
There are currently zero runtime music derivatives under `game/audio/`.
Ambience/SFX folders contain their planned README contracts without media.
FFmpeg/ffprobe are available for the next controlled processing block.

| Stage | Canonical source intent | Runtime ownership |
| --- | --- | --- |
| S00 | Sparse Awakening vol.2; supplemental Sparse Awakening | Scripted near-silence, then only the approved seed/first motif note; no shared rotation |
| S01 | Archive Awakening; five Group A shared sources | Unique first; finite shared shuffle outside authored locks |
| S02 | Cold to Warm; three Group B shared sources | Unique first; cold/warm semantic editing and interaction feedback require the authored slice pass |

Source paths, group roles, channels, durations and hashes are available in the
inventory. Their presence/title does not prove motif identity, loop suitability,
instrumental content, approved loudness, provenance or final mix quality.

## Exact next block

The manifest is now `audio/slice_edit_manifest.json`. Ten S01/S02 rows use full
source intervals as finite **review candidates**, with 20 ms / 250 ms edge
fades; no loops or invented separated stems. Both S00 intervals remain unset:
the actual first note/common four-note motif has not been selected by listening.
The exporter rejects them before writing files.

`evidence/audio_director/slice-analysis-1/` seals measurements of all twelve
unchanged masters: integrated -17.3 to -13.7 LUFS, true peak -4.2 to -2.7 dBTP,
LRA 5.2–16.5 LU, no full-scale PCM samples. These are measured source properties,
not final mix targets or musical acceptance. Five source/output safety guards
pass; see `audio/README.md` for reproducible commands.

The first finite review derivative, `mus_s01_archive_awakening_v01`, now passes
compressed format/decode/duration/true-peak/source protection in
`evidence/audio_director/s01-unique-review-1/`: 129.72 s, 2,369,745 bytes,
-15.9 LUFS / 8.0 LU LRA / -3.1 dBTP, no gain adjustment. Seven export guards pass.
It remains unbound; Godot technical validation is recorded below and musical
acceptance remains pending.

The S02 unique review derivative now also passes in `s02-unique-review-1/`: 127.96 s, 2,168,261 bytes, -16.5 LUFS / 9.1 LU LRA / -3.6 dBTP; no gain adjustment. Eight boundary guards include timeout diagnostics.

Both exact unique OGGs now pass private cache-free Godot 4.7.2 import and 30
real decoder/mixer assertions: score signal, owned duck, two-decoder crossfade,
finite end/silence and unchanged protected saves. The exact main entry's 17
checks and normal startup also pass. See `unique-godot-review-2/`.
`unique-godot-review-1/` retains the initial test-array typing error and bounded
process termination; typed constants fix it. No shipping registry binding was
added, and the private imported files/caches were removed after validation.

The first Group A shared cue, `mus_s01_activation_sequence_v01`, now passes
finite Vorbis export/decode and ten source/output/receipt guards in
`s01-activation-review-1/`. Verification refuses tampered media and overwriting
a previous immutable receipt.

`mus_s01_archive_fragment_v01` also passes finite review export/decode in
`s01-fragment-review-1/`, with eleven guards. Unfinished encoder files now live
outside Git; verification rejects any leftover intermediate inside evidence.

All ten finite S01/S02 exports now pass. Their complete private cache-free Godot
import/mixer run passes 93 actual pool assertions plus the 30 unique-cue checks,
17 main-entry checks and normal startup. Every OGG produces actual captured
PCM, unique-first/group/no-immediate-repeat selection and two-decoder bounds
pass, protected physical save hashes stay unchanged. See
`evidence/audio_director/full-pools-godot-review-1/`; no runtime warnings/errors.
`audio/REVIEW_INDEX.md` links the exact accepted technical candidates and the
two original S00 sources. No shipping music binding was added.

The first Muted Pulse verification failed with a truncated 3/5 command trace;
its diagnostics remain in `s02-muted-pulse-review-1/`. The accepted rerun is
`s02-muted-pulse-review-2/`. Commands now persist cumulative memory/final trace;
12 guards include stale-file replacement, altered media and immutable receipts.
Late owned test-fixture residue was removed and all test/encoder temporary
media moved outside Git. The source-preserving cleanup/publication recheck is
recorded, rather than treating the first clean-status abort as a PASS.

The independent S00 semantic hook is implemented: the actual spark becoming
visible dispatches `spark_first_note` once through AudioDirector, with no local
player or source fallback. S00 profiles force silent entry and finite seeds.
Unbound shipping, pause/resume, continuous S01 handoff and quiet completed
restore pass in `prologue-spark-hook-1/`: 29 prologue + 59 playlist + 18 route +
17 exact-entry assertions and normal startup, initially cache-free, no errors.
Actual synthetic PCM at the spark now passes in `prologue-pcm-2/`: 41 event /
PCM / lifetime checks plus 152 affected mixer/playlist/route/prologue/entry
checks. Pre-spark/paused/finite-tail/locked/removed/quiet-load output is zero;
the seed is audible only after the actual spark. Revision-guarded cancellation
prevents a removed scene's deferred cue while retaining foreign silence/newer
intent/route leases. The initial ALWAYS-ancestor pause failure is preserved in
`prologue-pcm-1/`; the explicit paused-tree guard fixes it. No fixture is music.
Next independent tool work supports source audition/edit proposals; acceptance
still requires an actual listening selection, not measurement or a source title.
The tool now exists as `tools/audio_audition.py`. The primary source's 0–8 s
opening proposal in `s00-opening-audition-1/` passes finite compressed decode,
four bounded command traces, seven protection guards and unchanged original
master/manifest hashes. It has null note/motif identity and explicit pending
listening status; neither seed manifest interval was changed. Next independent
block produced the alternate opening proposal in `s00-alternate-opening-audition-2/`:
-18.2 LUFS / -4.0 dBTP, gain 0, four complete commands and eleven guards. Both
openings are linked in REVIEW_INDEX.md, still with null note/motif identity.
Alternate family 1 is excluded because its final receipt remained RUNNING after
CLI completion; the preserved diagnosis and atomic/read-back receipt fix precede
the accepted new family. Only actual listening/edit selection can select a seed.
The exact final S00 event/PCM source additionally passes its 41 checks with
physically existing read-only primary/backup fixtures in
`prologue-pcm-protected-saves-1/`; both SHA values remain unchanged, cache-free
import passes, and there are no runtime errors/warnings. No speaker check or
musical approval is implied. The actual next task is now the listening/edit
selection below, without repeating completed technical exports or event tests.

Authored next step: select the actual S00 first-note interval and common four-note Archive
identity by listening/editing the supplied sources, then export only that seed
and checkpoint. Review all ten finite candidates for instrumental/no-phoneme
content, approved palette, cadence/tail, motif consistency and actual scene mix.
Those checks are pending; byte/header/mixer proof does not establish them.
Do not bind unaccepted full takes to shipping scenes or infer motif identity
across generated tracks. Ambience/SFX/art/target-GPU requirements remain open.

Then produce one bounded derivative family at a time using canonical
`mus_s##_name_v##` names. Perform the source edit, loop/stem, loudness and
compression passes required by `assets/audio/README.md` before runtime import.
Do not invent an unspecified LUFS target, release provenance or a silent
substitute asset and mark it accepted. Header/hash/decode checks and mixer tests
are technical proof; listening/loop/seam/motif/mix acceptance remains separate.

After approved derivatives exist, bind explicit MusicCue/MusicStage resources
through the existing registry. S00 begins scoreless and requests its seed only
at the authored spark event. Ordinary S01/S02 semantic states request Director
intents; they never start global players directly. The existing fragment modal
owns a -4 dB text duck and releases it on Continue/restore/removal. Preserve
owned silence, safe-exit shutdown, transactional route cancellation and quiet
checkpoint restoration.

Validate each family with initially cache-free import, actual registered-world
load/progression/resume, captured mixer output and a bounded native slice run.
Commit and publish immediately after each accepted block; never accumulate all
twelve derivatives before a checkpoint.

## Remaining acceptance

The full gift/VS1 is not accepted by the Director foundation or the graybox.
Authored observatory/room art, selected ambience/SFX, motif/stem editing,
shipping score bindings, final source/credit metadata and physical target-GPU
profiling remain open. Missing dependent inputs pause their own task only.
No target-hardware PASS or later shipping world is implied by policy fixtures.

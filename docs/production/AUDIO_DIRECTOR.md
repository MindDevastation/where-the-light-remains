# AudioDirector implementation

## Brief — 2026-10-03 UTC

Authority read first: AUDIO_BASELINE, AUDIO_BUSES and its accepted real-mixer
evidence, AUDIO_PROVENANCE, source-master MUSIC_RUNTIME_POLICY / MUSIC_INDEX,
technical routing order, accepted SceneRouter and shell/Settings contracts.
Base main: `2914ec0a0a01a7f4b9a34d89768774451267c68c` (PR #42).
Feature: `feature/02-state-saves/audio-director`, parent `epic/02-state-saves`.

Implement the existing autoload's music foundation: exactly two Music_Main
players, finite authored cue/stage resources, unique-first group shuffle without
immediate repeats, deterministic semantic overrides, token-owned silence and
music ducking. Parent Master/Music/SFX preference gains remain SettingsManager's.
Music_Main and Music_Stems child mutes cover full score silence while Ambience,
UI and SFX remain independent. Ducking changes only score child gains and restores
their prior values. Pause/focus do not rewrite authored semantic state or locks.

Stage intent must be transactional. Prepare semantic target before fade-out while
retaining actual outgoing playback; commit after the last route acceptance guard.
Cancel restores the old metadata without rewinding/restarting the old cue. A later
semantic/silence request supersedes the lease and cancels the unaccepted route;
its newer owner survives rollback. Old playlist selection stays held during the
lease so it cannot start a long cue before a known scene transition.

Silence requests receive independent tokens and monotonic deadlines. Releasing
one token cannot release another; paused SceneTree still advances deadlines.
Silence stops pending/current score. Expiry alone does not replay a pre-silence
cue or create a second swell; only a later explicit intent may resume. S14's
authored phrase controller will request its approved 4–6 seconds, then the S15
controller owns its authored chain. No final narrative timing is manufactured.

S00 and S06/S12–S15 default to scripted ownership, conservatively disallowing
automatic shared rotation. Scenes can bind deterministic cues to semantic state.
S06 egg-pickup state is silent; S07 reflection excludes the source-title
`Wooden Hall Puzzle v2`. Vocal cues are rejected before S15 and unless both the
actual GameState completion flag and explicit authored final-wide-shot signal
allow them. No shipping registry or WAV derivative is invented.

Crossfades use bounded linear gains and at most two playing cues. A request during
a crossfade replaces one pending intent; it starts after that bounded fade instead
of introducing a third player or stale tween callback. Silence always cancels it.
Very short finite cues cap a fade to available outgoing/incoming material.
Calm playlist and ordinary stage defaults preserve approved 6s/2s timings.

Acceptance requires actual generated PCM through Godot's mixer: unique/bag/override
selection, overlap/gain/latest-request behavior, nested silence with real zero
Music_Main/Stems output, independent SFX/Ambience/UI, duck/preferences restore,
vocal gates and no automatic post-silence replay. Real router cancellation must
retain old stream/playback progress; later silence ownership and native failed
close must remain safe. Required import, affected shell/router/Settings regression
and authenticated TCP X11/Vulkan Forward+ checks use the confirmed local toolchain.
No old environment preflight is repeated.

Status: implementation in progress; no completed feature acceptance yet.

## Recovery mixer acceptance — 2026-10-04 UTC

The current Archive working branch already contains the dual-player director
and MusicCue/MusicStage resources from its published reconstruction checkpoint;
they were inspected in place and not rebuilt. No earlier AudioDirector feature
acceptance receipt is present. Work continues on
`feature/04-archive-gameplay/checkpoints-2026-10-04` under the owner's recovery
policy; main remains unchanged.

`evidence/audio_director/mixer-validation-1/results.json` passes clean-copy import
and 29 assertions with generated in-memory PCM through Godot's actual Dummy
driver mixer. Actual Music-parent peaks: baseline 0.08912, nested -6 dB duck
0.04467, remaining -4 dB duck 0.05623, nested/expired silence zero, explicit
semantic resume 0.08912. SFX/Ambience/UI continue around 0.09997 during silence.
Timed tokens expire while paused, remain latched against an automatic second
swell and preserve pre-existing child mutes. Ducks restore exact child gains;
parent preference gains and both protected save hashes remain unchanged.

This accepts the bounded mixer/lock component only, without a speaker check or
shipping music bindings. Next: unique/bag selection, bounded crossfade queue,
vocal/semantic guards and actual transactional router cancellation. Runtime
OGG/stem exports, authored scene events and target-hardware audio/art remain open.

## Playlist / crossfade component acceptance

`playlist-validation-1` retains a cold-mixer first-position assertion failure.
The fixture now waits for actual playback advancement with a one-second deadline.
`playlist-validation-2` passes its 56 assertions but retains five teardown-leak
warnings. The verbose diagnostic identifies AudioStreamWAV/AudioStreamPlaybackWAV
references following rapid test vocal revocations. A bounded 0.2-second audio
thread drain after fixture stop resolves teardown. `playlist-validation-3` passes
56 playlist and 29 mixer assertions with no runtime errors or warnings, preserving
both protected slot hashes. Production Director source is unchanged in this block.

Actual PCM players prove unique-first finite rotation, no immediate repeat,
exclusions/single-cue exhaustion, two-player overlap with bounded gains, latest
queued intent and complete fade/queue cancellation by owned silence. A stage
lease retains advancing playback and rollback restores metadata without restart.
Scripted S00 never rotates shared tracks, S07 reflection rejects the forbidden
source title, and S15 voice needs both actual completion and explicit wide shot;
revoking either stops playback. Later-stage IDs here are isolated audio-policy
fixtures; no later shipping world, narrative or timing has been implemented.
Next: actual SceneRouter fade/rollback and successful/failed App exit with playback.

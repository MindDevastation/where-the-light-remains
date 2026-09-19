# Music Runtime Policy

## Core model

`Stage = GroupSharedPool + StageUniqueCue`

Normal exploration stages play their unique cue first, then rotate the group's `shared/` pool using a shuffle bag. No immediate repeats. The stage unique cue may re-enter later rotation with higher weight.

This playlist model is an **approved override** layered on top of the master AUDIO_PLAN; authored silence and semantic substates always win.

## Transition timing

- within-playlist calm crossfade: typically `4–7 s`
- stage-to-stage baseline: `1–3 s`
- authored musical morph: `3–6 s`
- active/chase transition: `1.5–3 s`
- calm ambience-only breathing gap: usually `3–10 s` when scene timing allows

Do not start a long cue immediately before a known solved/cinematic transition.

## Stage ownership

A: S00, S01, S10, S11  
B: S02, S03  
C: S04, S06  
D: S05, S07  
E: S08, S09, S12, S13, S14, S15

## Mandatory stage overrides

### S00 Prologue
`scripted_only: true`, `shared_pool_enabled: false`.

The prologue must remain almost scoreless and reveal only the seed/first note of the Archive motif. Group A shared tracks cannot rotate here.

### S06 Egg
Deterministic state machine: `egg_stealth → egg_pickup_silence → boss_wake → egg_chase → rescue → comedic_beat`. Group C shuffle is disabled while event states own playback.

### S07 Seriousness / Smile
Group D remains the parent style family, but the active cue `Wooden Hall Puzzle v2` is excluded from the quiet reflection state. Prefer `Controlled Tails`, `Quiet Corridor in Dusk`, near-silence and authored puzzle layers.

### S12–S15 Finale
Critical narrative states are deterministic; shared Group E rotation may run only outside authored locks.

- S12: `Quiet Pages, Steady Light` owns poem reading.
- S13: `Final Quiet of the Archive` owns acrostic reveal with authored silence.
- S14: `Silent Piano`; on `Я люблю тебя`, music goes to zero for approximately **4–6 s**. No second swell.
- S15: preferred authored chain `Pre-dawn Hush → Quiet Hope → Starlit Motif → optional Glass and Wind / natural ambience`. Group E shuffle must not interrupt it.

## Suggested data shape

```yaml
group: A|B|C|D|E
unique_track: path
supplemental_tracks: []
shared_pool_enabled: true
playlist_exclusions: []
unique_first: true
unique_rotation_weight: 2.0
shared_rotation_weight: 1.0
silence_min_seconds: 3
silence_max_seconds: 10
playlist_crossfade_seconds: 6
stage_transition_crossfade_seconds: 2
scripted_only: false
```

`AudioDirector` owns selection, dual-player crossfades, snapshots, ducking and silence locks. Scenes request semantic states; they never directly own the global music players.

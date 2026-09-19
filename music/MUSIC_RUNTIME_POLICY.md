# Music Runtime Policy

## Core model
`Stage = GroupSharedPool + UniqueCue`

Every stage belongs to exactly one group. The exact same `shared/` pool is available to every stage inside that group. Each stage also owns a `unique/` cue that establishes its identity.

## Normal exploration playback
1. Play the stage unique cue first unless a scripted silence/event owns the opening.
2. Then build a shuffle bag from the stage group's `shared/` directory.
3. Do not repeat a shared track until the current bag is exhausted.
4. Never allow immediate repetition across bag boundaries.
5. After one full shared-pool cycle, the stage unique cue may re-enter rotation with a higher weight than one shared cue.
6. Supplemental tracks are stage-local and only enter rotation when explicitly enabled.

Recommended weights after the guaranteed first unique play:
- shared cue: `1.0`
- stage unique cue: `2.0`
- supplemental cue: `0.5–1.0`

## Silence and transitions
Calm exploration:
- ambience-only gap: random `3–10 s` when scene timing allows;
- crossfade: `4–7 s`;
- avoid starting a fresh long track immediately before a known puzzle resolution or cinematic lock.

Active states:
- crossfade: `1.5–3 s`;
- no random ambience gap during chase or momentum-critical sequences.

Canonical Audio Direction silence always overrides playlist behavior.

## Suggested AudioDirector states
General: `exploration`, `puzzle`, `solved`, `cinematic`, `silence`.

S06: `egg_stealth`, `egg_pickup_silence`, `boss_wake`, `egg_chase`, `rescue`.

Finale: `poem`, `acrostic`, `confession_pre`, `confession_silence`, `pre_dawn`, `dawn`, `morning`, `final_wide`.

## Scripted overrides
### Stage 6 — Egg
`Group C calm pool → Curious Sneaking Groove → mandatory egg-pickup silence → The Great Dodging Dash → rescue transition`.
Shared Group C music must not restart during the chase.

### Stage 12 — Poem
Group E remains the parent group, but `Quiet Pages, Steady Light` owns the poem state. Fade toward silence at the end.

### Stage 13 — Acrostic
`Final Quiet of the Archive` owns the stage. Preserve the planned silence after the full acrostic.

### Stage 14 — Confession
`Silent Piano` owns the stage. On `Я люблю тебя`, force music to zero and hold **4–6 seconds of complete music silence**. Shuffle playback cannot resume inside this window.

### Stage 15 — Dawn
Preferred deterministic chain: `Pre-dawn Hush → Quiet Hope → Starlit Motif → optional Glass and Wind / ambience tail`.
`Starlit Motif` is the formal unique cue. Group E shared tracks must not interrupt the authored dawn chain.

## Future data shape
```yaml
group: A|B|C|D|E
unique_track: path
supplemental_tracks: []
unique_first: true
unique_rotation_weight: 2.0
shared_rotation_weight: 1.0
silence_min_seconds: 3
silence_max_seconds: 10
crossfade_seconds: 6
scripted_only: false
```

`AudioDirector` owns all playlist selection, crossfades and silence locks. Scene scripts request music states; they do not directly own music players.

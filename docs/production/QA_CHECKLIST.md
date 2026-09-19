# QA / release acceptance checklist

Canonical acceptance baseline derived from the master Project Bible.

## Progression

- [ ] Fresh New Game reaches Stage 15 without console intervention.
- [ ] No mandatory action can soft-lock the run.
- [ ] Required route remains readable; new tester is rarely directionless for >10–15 s.
- [ ] All 10 fragments are obtainable in canonical found order while final order remains hidden until Stage 13.
- [ ] Optional secrets never gate progression or alter the canonical ending.

## Save / recovery

- [ ] Fragment checkpoints restore stable solved state.
- [ ] Memory I/III restart safely after crash where specified.
- [ ] Egg runtime rewind never performs a disk load on each hazard.
- [ ] Final puzzle preserves solved pairs after restart.
- [ ] Poem/acrostic/confession milestones do not force replay of the final puzzle.
- [ ] Corrupt primary save falls back to backup; both corrupt results in explicit New Game choice.
- [ ] `game_completed` is persisted before credits.

## Egg memory

- [ ] No HP/death loop.
- [ ] Stealth → pickup silence → boss wake → chase → rescue sequencing is deterministic.
- [ ] Collapse, poison and snake warnings are visually readable independent of audio.
- [ ] Achievement `Ничего не трогала` is granted once on mandatory completion.

## Finale / tone

- [ ] Hidden acrostic letters are not exposed before Stage 13.
- [ ] Stage 14 displays `Я люблю тебя` without response/reciprocity UI.
- [ ] 4–6 s music silence after confession is preserved.
- [ ] No new romantic demand/text is added in Stage 15.
- [ ] Epilogue does not depict or imply the heroine's decision.
- [ ] Stage 14→15 has no visible loading cut/fade-to-black.
- [ ] `Continue` only advances the authored sequence.

## Audio

- [ ] AudioDirector is sole owner of cross-scene music/ambience transitions.
- [ ] No duplicate music starts after pause/resume or stage restore.
- [ ] Mandatory silence map survives playlist rotation.
- [ ] Stage 0 never enters normal Group A shuffle.
- [ ] Stage 7 excludes overly active shared cues during quiet state.
- [ ] Stage 6 and Stages 12–15 respect deterministic scripted ownership.
- [ ] Music/SFX sliders work; all mandatory cues remain understandable with music muted.

## Accessibility / controls

- [ ] Mandatory puzzles use discrete/snap states rather than precision manipulation.
- [ ] No mandatory precision platforming.
- [ ] FOV, mouse sensitivity and invert-Y persist separately from save data.
- [ ] Pause/focus loss restores mouse capture and audio state safely.
- [ ] Hints can escalate without author assistance.

## Performance

Test Medium at 1920×1080 on GTX 1060-class reference and Low fallback.

- [ ] Typical frame remains within 16.67 ms budget for 60 FPS.
- [ ] Worst-case Hub/finale, Egg chase, Epilogue, Wing V and Memory I are profiled.
- [ ] Sustained GPU/CPU overruns are investigated rather than hidden by average FPS.
- [ ] VRAM/RAM returns after unloading memory scenes.
- [ ] Egg hazards/rewind do not hitch >25 ms under normal target conditions.
- [ ] Gameplay clues remain visible on Low with volumetrics/SSR/decor reduced.

## Release

- [ ] Minimum three complete blocker-free runs before RC.
- [ ] Build ≤5 GB.
- [ ] Bootstrap/install flow is understandable and SHA-256 verification works when implemented.
- [ ] External assets have source/license/provenance recorded.
- [ ] Debug stage/save/audio/performance tools are disabled in release build.

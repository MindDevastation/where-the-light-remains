# Narrative canon — implementation baseline

## Core rules

- One canonical ending.
- Ten mandatory fragments; optional secrets never gate the ending.
- Every fragment owns: sigil, poem couplet, direct feeling phrase and hidden acrostic letter.
- Hidden letters and 1–10 final numbering are never shown before Stage 13.
- Final acrostic resolves to **«Я люблю тебя»**.
- No yes/no prompt, reciprocity mechanic, relationship-state system or implied required response.
- Memory III represents a **possible** future meeting, never a promise or mutually decided future.
- Epilogue never depicts the heroine's reaction/decision after the confession.

## Final sigil order

1. Hearth → Я
2. Star → Л
3. Sprout → Ю
4. Echo → Б
5. Bell → Л
6. Feather → Ю
7. Double Moon → Т
8. Sun Glint → Е
9. Clear Crystal → Б
10. Constellation → Я

Finding order remains deliberately scrambled: `2,1,4,3,6,5,8,7,10,9`.

## Stage map

### S00 — Prologue / The Last Spark
Realtime night cinematic. Dormant observatory, first spark, main door opens, camera enters and hands control to the first-person player without a separate loading cut.

### S01 — Awakening the Archive
Player finds/installs the starting lens; Archive core wakes. Only Wing I route becomes readable/active.

### S02 — Wing I / Warmth & Light
Exact mechanic baseline: three concentric optical rings → emitter/star alignment → five-position focus wheel → Hearth activation. Fragment order: Star then Hearth.

### S03 — Wing II / Life & Voice
Central waveform projector; three local resonators with three states; short/medium/long sample logic; three impulse rings; sprout/life reveal. Fragment order: Echo then Sprout.

### S04 — Memory I / First Meeting
Compact stylized raid-memory space. Two-rune cooperative stabilization is mandatory. No combat system. The moment was ordinary at the time; no destiny/romance swell.

### S05 — Wing III / Laughter & Lightness
Kinetic mobile; three counterweights with discrete states; brake/stoppers; Feather and Bells. Fragment order: Feather then Bell.

### S06 — Memory II / The Egg
Linear stealth → egg pickup → deliberate pause → boss wake → scripted chase with readable collapse/poison/snake hazards → ledge/rescue. No HP/death loop. Runtime checkpoints rewind locally. Achievement flag `Ничего не трогала` is granted once on mandatory completion.

### S07 — Wing IV / Seriousness & Smile
Frosted memory glass; replay shutter; four symbol discs × three states; Double Moon puzzle with discrete orientations. Fragment order: Sun Glint then Double Moon. This is intentionally the quietest post-action wing.

### S08 — Wing V / Sincerity & Admiration
Constellation table with four observers/sectors and eight stars/lines; crystal task with three filters × three states and frosted target/screen. Future Record shows `Не создана`. Fragment order: Constellation then Crystal.

### S09 — Memory III / What Hasn't Happened Yet
No puzzle/fail state. One readable path. Fantasy/archive imagery gradually dissolves into a neutral real-world path/bridge/park analogue. Two figures may progress in parallel, but the scene expresses possibility only. Final state stays unresolved.

### S10 — Return to Observatory
Fully restored hub; final table unfolds; ten sigils are present in found/free arrangement.

### S11 — Order of Light
Five paired nodes and ten sigil sockets. Pair order is solved without exposing hidden letters. Pair logic: Hearth→Star, Sprout→Echo, Bell→Feather, Double Moon→Glint, Crystal→Constellation.

### S12 — Poem Assembly
All ten couplets become readable. No timer. Reading clarity dominates presentation.

### S13 — Acrostic Reveal
Initials are isolated/rearranged and reveal `Я Л Ю Б Л Ю Т Е Б Я`, then resolve to the phrase.

### S14 — Confession
Direct `Я люблю тебя`. Deliberate silence follows. A short author text may follow; it cannot ask for reciprocity. Continue only advances the scene.

### S15 — Dawn
Night → pre-dawn → dawn → morning. Camera exits through the same main entrance and reaches a calm exterior wide shot. `game_completed` is saved before credits. No new romantic copy and no depicted response from the heroine.

## Accessibility / navigation

Mandatory challenge is logic, observation, association and sequencing — not spatial memory. Avoid labyrinths. The player should normally understand where to go within roughly 10–15 seconds. Mandatory actions use forgiving discrete states/snap behavior; significant progress is never lost after a mistake.

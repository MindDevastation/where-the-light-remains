# Where the Light Remains — Project Summary

## Project identity

**Title:** Where the Light Remains  
**Format:** short atmospheric first-person narrative puzzle game  
**Platform:** Windows PC  
**Engine:** Godot 4.x / GDScript / Forward+  
**Main-path duration:** approximately 15–30 minutes  
**Performance target:** 1920×1080 / 60 FPS on GTX 1060-class hardware  
**Visual direction:** stylized realism; magical observatory / Archive of Light

## Core premise

The player restores a dark observatory-house wing by wing. Ten mandatory fragments are collected in a scrambled order. Each fragment owns a sigil, couplet and feeling phrase; the hidden acrostic order is revealed only near the end. The finale reconstructs the poem, reveals `Я люблю тебя`, presents the direct confession, then transitions into a quiet dawn epilogue.

There is one canonical ending. Secrets/achievements enrich the experience but never gate or improve the romantic outcome.

## Design rules

- Navigation stays simple/readable; mandatory challenge comes from logic, observation, association and sequencing.
- No mandatory precision platforming or spatial-memory maze design.
- Mistakes do not cause significant progress loss.
- No soft locks.
- Hints escalate from environmental to explicit.
- Mandatory sound information always has a visual equivalent.
- Tone is intimate and sincere, not coercive or grandiose.

## Stage map

| Stage | Name | Core function |
|---|---|---|
| 0 | The Last Spark | Dormant observatory, first spark, seamless entry |
| 1 | Awakening the Archive | Lens onboarding and hub activation |
| 2 | Warmth / Light | Optical rings + focus wheel; Star + Hearth |
| 3 | Life / Voice | Resonance/pulse; Echo + Sprout |
| 4 | First Meeting | Two-rune raid memory, no combat |
| 5 | Laughter / Lightness | Mobile/counterweights/bells; Feather + Bell |
| 6 | The Egg | Stealth → pickup → chase → rescue, no HP/death |
| 7 | Seriousness / Smile | Memory glass/discs + Double Moon |
| 8 | Sincerity / Admiration | Constellation + crystal + Future Record |
| 9 | What Hasn't Happened Yet | Possible future meeting; no promise/reciprocity |
| 10 | Return to Observatory | Restored hub and final table reveal |
| 11 | Order of Light | Five sigil pairs / true order |
| 12 | Poem Assembly | Full poem reading |
| 13 | Acrostic Reveal | Initials resolve to hidden phrase |
| 14 | Confession | Direct `Я люблю тебя`, no response mechanic |
| 15 | Dawn | Same observatory, dawn exit, game completion |

## Technical baseline

- Persistent `GameRoot` + replaceable `WorldSlot`.
- Archive is the primary connected scene; three memories are separate world scenes/chunks.
- Maximum 8 core autoload services.
- `SceneRouter` exclusively owns major world transitions.
- `AudioDirector` exclusively owns global music/ambience/stems/silence locks.
- Logical versioned save + backup; never serialize SceneTree.
- Medium is 1080p60 reference; Low reduces expensive visuals without removing clues.

## Assets / audio

Selected concept art and curated music source masters are now in `assets/`. `docs/production/ASSET_INDEX.md` defines their implementation role. Source WAV files are not shipping files; they require loop/stem/edit/mix/compression passes before runtime import.

Music normal-playback override: `GroupSharedPool + StageUniqueCue`; authored silence/event states always override shuffle playback.

## Current production state

**GO for implementation preflight and vertical-slice work.** Initial Godot project and core service scaffold exist under `game/`.

Open inputs: ambience/SFX package, exact audio provenance rows, runtime audio conversion, final avatar/model source, remaining personal secrets, credits/attribution, optional credits vocal decision and exact minimum CPU/RAM reference machine.

First playable milestone: `Hub → Wing I → fragment → save/load → return`, followed by profiler capture on target-class hardware.

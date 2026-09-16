# Where the Light Remains — Project Summary

## Project identity

**Title:** Where the Light Remains  
**Format:** short atmospheric first-person narrative puzzle game  
**Platform:** Windows PC  
**Engine target:** Godot 4.x  
**Main-path duration:** approximately 15–30 minutes  
**Performance target:** 1920×1080 / 60 FPS on GTX 1060-class hardware  
**Visual direction:** stylized realism; magical observatory / archive of light  
**Primary interaction:** explore → observe → understand → manipulate → restore → receive fragment → optional secret

## Core narrative premise

The player enters a dark observatory-house containing an **Archive of Light**. The Archive is restored wing by wing through calm, readable puzzles. Along the way the player finds ten mandatory fragments, each tied to a sigil, a couplet, and a short emotional statement.

The fragments are discovered in a scrambled order. Their hidden final order is only revealed near the end of the game. The final sequence reconstructs the poem, reveals a hidden acrostic, presents the confession, and then transitions into a quiet dawn epilogue.

The game has **one canonical ending**. Optional secrets and achievements enrich the experience but never gate the finale or create a “better” romantic outcome.

## Design principles

- Navigation must stay simple and readable.
- Mandatory difficulty comes from logic, association, observation, and sequencing rather than spatial orientation.
- The player should rarely wonder where to go for more than a few seconds.
- No mandatory precision platforming.
- No significant progress loss after mistakes.
- No soft-lock states.
- Hints escalate from environmental → visual → semantic → explicit.
- Mandatory audio puzzles always have visual equivalents.
- Romantic tone should stay intimate and sincere rather than grandiose or pressuring.

## Stage map

| Stage | Name | Function |
|---|---|---|
| 0 | Prologue — “The Last Spark” | Establish the observatory, darkness, and first light |
| 1 | Central Observatory — “Awakening the Archive” | Onboarding and hub activation |
| 2 | Wing I — “Warmth / Light” | First full puzzle wing; Star + Hearth fragments |
| 3 | Wing II — “Life / Voice” | Resonance and pulse puzzles; Echo + Sprout |
| 4 | Memory I — “First Meeting” | Stylized raid memory, quiet first recognition |
| 5 | Wing III — “Laughter / Lightness” | Balance and bell mechanics; Feather + Bell |
| 6 | Memory II — “The Egg” | Stealth → comic chase → scripted rescue |
| 7 | Wing IV — “Seriousness / Smile” | Quiet reflective puzzles; Sun Glint + Double Moon |
| 8 | Wing V — “Sincerity / Admiration” | Constellation/crystal-focused final wing |
| 9 | Memory III — “What Hasn’t Happened Yet” | A possible future meeting, framed without pressure |
| 10 | Return to the Observatory | Reassemble the completed Archive |
| 11 | Final Puzzle — “Order of Light” | Arrange the ten sigils into the true emotional order |
| 12 | Poem Assembly | Present the complete poem in a readable, calm sequence |
| 13 | Acrostic Reveal | Reveal the hidden message from the poem’s initials |
| 14 | Confession | Direct statement without response mechanics |
| 15 | Epilogue — “Dawn” | Emotional release and quiet closure |

## World structure

The primary location is one connected observatory-house with:

- a central observatory hub;
- five short wings;
- three separate memory sequences;
- a finale that returns to the hub;
- a dawn epilogue using the restored observatory/exterior.

The hub and architectural language are designed for heavy reuse. The three memories are more scripted and visually distinct but remain stylistically compatible.

## Visual language

Hero material family:

- aged brass / bronze;
- dark wood;
- pale stone;
- glass / frosted glass / crystal;
- paper;
- restrained textiles;
- selective living vegetation;
- warm archive light.

Shape language prioritizes circles, arcs, ellipses, rings, lenses, celestial diagrams, petals, frames, and soft architectural arches. Aggressive spikes, horror-gothic treatment, sci-fi neon, and visual clutter are intentionally avoided.

## Audio direction

Music is primarily instrumental. The score behaves as one evolving system rather than sixteen disconnected songs. Ambience and gameplay SFX carry strong spatial and feedback roles.

Important silence/near-silence moments are part of the design, especially:

- before the first spark;
- immediately after taking the egg;
- after the rescue/comedic beat;
- during Wing IV;
- around the future-memory key text;
- during poem reading;
- during the acrostic reveal;
- after the final confession;
- at the end of the dawn epilogue.

A vocal song, if used at all, is reserved for optional credits and is not part of the canonical ending.

## Technical baseline

Approved architecture direction:

- Godot 4.x;
- GDScript;
- Forward+ renderer;
- persistent `GameRoot` with replaceable `WorldSlot`;
- central Archive scene plus separate memory scenes;
- logical, versioned saves rather than SceneTree serialization;
- centralized scene routing, audio direction, settings, and input modes;
- discrete/scripted puzzle states instead of unstable physics;
- Medium preset as the 1080p60 reference target;
- separate Low preset that removes expensive visual features without reducing gameplay readability.

## Current production state

Already designed:

- story and complete stage flow 0–15;
- puzzle structure and fail/recovery rules;
- final text package and tone audit;
- Art Bible;
- Audio Direction / AUDIO_PLAN;
- Asset Manifest;
- Godot technical architecture;
- performance budget;
- QA plan;
- concept-art generation prompt package.

Still being prepared before implementation begins:

- selected concept art;
- final music tracks / stems;
- finalized SFX selections;
- character reference imagery and final avatar production source;
- remaining personal secret content;
- final third-party credits / attribution.

## Implementation hold

The repository is intentionally **not yet configured for Codex execution**. Implementation handoff will occur only after the selected visual and music packages have been uploaded and mapped to this design baseline.

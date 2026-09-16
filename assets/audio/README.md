# Audio Intake

This directory will contain the selected audio package for **Where the Light Remains**.

The approved audio direction is primarily instrumental. Music is treated as one evolving system across stages rather than sixteen unrelated tracks. Critical gameplay feedback must remain readable independently of music.

## Structure

```text
assets/audio/
├── music/
├── ambience/
└── sfx/
```

## Selection rules

Before implementation, selected files should be indexed with:

- source / generator / library;
- license or usage basis;
- stage(s);
- intended AudioDirector state;
- loop / one-shot / stem classification;
- BPM/key where relevant;
- loudness or gain notes after first integration pass;
- whether the file is canonical, candidate, or replacement-safe.

## Important design constraints

- mandatory audio puzzles always have visual equivalents;
- the Egg sequence needs distinct hazard telegraphs;
- deliberate silence/near-silence is part of the design;
- no second musical climax after the confession;
- optional vocal music, if retained, is credits-only and not part of the canonical ending.

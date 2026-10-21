# Godot project

Current working-branch scope is playable **S00 prologue → S01 Archive onboarding → S02 Wing I optics/Star/Hearth → return**, with implemented player/UI/pause/settings, eight core services, routing/progression and save/reload. Production art, authored audio and full visual acceptance remain incomplete. **GATE-VS1 OPEN; S03 gated.** See [`../docs/production/WORK_RECOVERY.md`](../docs/production/WORK_RECOVERY.md) for actual checkpoints, validation boundaries and next work.

Use Godot4.7.2 stable/Forward+. Materialize LFS payloads with `git lfs pull`, open `game/project.godot` and run its boot scene (F5), or use `godot --path game` from the repository root. Editor: `godot --editor --path game`. WASD/mouse/E/Esc provide movement/look/interaction/pause. Development IO checks use owned private saves; preserve existing primary/backup slots. Linux software-native evidence does not certify the Windows GTX1060-class1920×1080/60 target.

The project must follow `docs/design/TECHNICAL_BASELINE.md`, the master Project Bible and `docs/production/QA_CHECKLIST.md`. Concept art is reference-only; it does not define mechanics.

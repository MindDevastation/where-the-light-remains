# Wing I Hearth flame — bounded visual effect

Replaces the single graybox sphere at `Wing01/Room/Hearth/Flame` with three
original teardrop tongues. The effect uses Godot-native geometry: one 80-triangle
mesh shared by three lobes (240 visible triangles total), one existing shared
`m_archive_emissive_gold.tres`, no particles, transparency, new shaders,
lights, shadow passes, collision or audio nodes. No Blender/LFS payload is added.

`game/art/vfx/hearth_flame.gd` owns presentation only. ArchiveMain still owns
visibility through `hearth_collected`; the existing node path and root position
(0,.55,0), Hearth bowl/body/collider, emitter/beam/Star and save order remain.
The quiet silhouette fits the old +/- .22 m horizontal and .72 m height envelope.
Bounded slow sway uses scene delta and an explicit pausable process mode.
Hidden/cold state stops processing and resets all transforms; warm/quiet reload
starts at a reproducible pose. No activation burst or state signal is emitted.
Both Low and Medium use the same geometry/material, with no glow dependency.

Acceptance requires actual frame animation, pause/resume, hide/reactivation,
geometry/material/normal checks, unchanged gameplay/save state, current S02
controls/save/reload/return and entry regressions, plus inspected cold/warm player
captures on Low/Medium. First headless evidence retains the corrected envelope
and pause defects; subsequent families contain current proof.

This is bounded Flame presentation only. Final beam/Star art, ceiling/upper
structure, complete room/VS1, authored audio and physical target GPU remain open.

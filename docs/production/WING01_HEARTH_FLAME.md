# Wing I Hearth flame — bounded visual effect

Replaces the single graybox sphere at `Wing01/Room/Hearth/Flame` with three
original teardrop tongues. The effect uses Godot-native geometry: one 80-triangle
mesh saved in `hearth_flame_mesh.tres` and shared by three lobes (240 visible triangles total), one existing shared
`m_archive_emissive_gold.tres`, no particles, transparency, new shaders,
lights, shadow passes, collision or audio nodes. No Blender/LFS payload is added. Rebuild its immutable geometry using
`tools/create_hearth_flame_mesh.gd`; no mesh builder runs during scene entry.

`game/art/vfx/hearth_flame.gd` owns presentation only. ArchiveMain still owns
visibility through `hearth_collected`; the existing node path and root position
(0,.55,0), Hearth bowl/body/collider, emitter/beam/Star and save order remain.
The quiet silhouette fits the old +/- .22 m horizontal and .72 m height envelope.
Bounded slow sway uses scene delta and an explicit pausable process mode.
Hidden/cold state stops processing and resets all transforms; warm/quiet reload
starts from its reproducible hidden pose when visibility changes. No activation burst or state signal is emitted.
Both Low and Medium use the same geometry/material, with no glow dependency.

Acceptance requires actual frame animation, pause/resume, hide/reactivation,
geometry/material/normal checks, unchanged gameplay/save state, current S02
controls/save/reload/return and entry regressions, plus inspected cold/warm player
captures on Low/Medium. First headless evidence retains the corrected envelope
and pause defects; subsequent families contain current proof.

This is bounded Flame presentation only. Final beam/Star art, ceiling/upper
structure, complete room/VS1, authored audio and physical target GPU remain open.

## Threaded scene loading and cleanup

The actual GameRoot/SceneRouter route exposed an unreleased RefCounted warning
with script-level nested preloads, although direct scene instantiation passed.
Replacing only the mesh builder with a saved mesh did not clear the warning.
The final PackedScene declares mesh/material dependencies and all three visual
children explicitly; its script controls only transforms/visibility processing.
Current S02 route/cleanup passes without warnings. Baseline-scene comparison
and intermediate failing headless/native families are retained as evidence.

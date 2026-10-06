# Wing I beam and Star — bounded presentation brief

Status: implementation in progress after verified shipping roof integration.
Canon: NARRATIVE_CANON S02, REQUIRED_ASSET_TABLE S02-002/VFX-001/SIG Star.
Three discrete rings establish four sequential visible beam segments; Star is
collected first, then the five-position focus unlocks Hearth. Presentation does
not implement optical physics or change those controllers/save signals.

Preserve four existing segment NodePaths, positions, 90-degree axes, one-meter
lengths and root visibility. Keep the separate focus beam's authored pose,
two-meter scale and strength-driven X scale. Its immutable replacement uses
one shared core mesh and one surrounding halo mesh, both centered on local Y
with endpoints +/-0.5 m. Twelve radial sides, opaque core radius 0.017 m and
uncapped halo radius 0.050 m. At most 100 triangles / two surfaces per beam,
500 triangles / ten draw surfaces across the five owners. No collision,
particles, new lights/shadow casts, runtime mesh construction or global shader
time. These are ceilings; measure actual counts before acceptance.

A reusable MeshInstance3D root keeps the old Node3D visibility/scale contract.
Its explicit scene mesh/material dependencies avoid nested script preloads.
Two simple shared shaders expose per-instance color and intensity; the original
teal/blue hue and 1.4 intensity are defaults. Halo uses restrained additive alpha
and view-facing falloff. Only palette setup runs at ready/property change;
there is no per-frame beam script or shared material mutation. All quality
presets retain the core silhouette, independently of glow/SSR/volumetrics.

Star remains a Sprite3D at (0,1.72,-25.3), with the exact existing `star.svg`,
billboard/pixel scale and unshaded flag. A presentation-only pausable script
slowly breathes alpha 0.82..1 and scale 1..1.024 over roughly eight seconds.
Visibility still belongs to ArchiveMain's `star_collected` projection. Hidden
or ancestor-hidden state stops processing and restores a reproducible quiet
pose; reload has no activation burst, sound, progress/save signal or extra
sigil/number/letter. No texture or canonical text is changed.

Acceptance: actual static mesh arrays/bounds/normals and shared references;
all original emitter/beam endpoints and focus positions; sequential ring
visibility through real controls without changing states; isolated per-instance
palette changes without altering another beam/shared material; actual Star
animation/pause/hide/ancestor hide/reactivation and quiet state/dirty flag.
Run current housing, S02 save/reload/return and Boot regressions, cache-free
import/startup and inspect cold/partial/aligned/focus/warm player views on
Low/Medium. Measure transparent surfaces/calls/textures. No new Blender/LFS
payload; immutable Godot meshes have a checked-in code-native source generator.

This supplies bounded S02 beam/Star presentation only. Complete global beam
rollout, final room/gallery/lighting/VS1, authored audio, physical target GPU
and S03 remain open. Continue the next stage after its immediate checkpoint
within the owner's current 3–4 hour work window.

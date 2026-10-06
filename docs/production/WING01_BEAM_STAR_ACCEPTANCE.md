# Wing I beam and Star acceptance

The shipping room now uses two shared immutable ArrayMeshes for each authored
beam: 48 opaque core + 24 uncapped halo triangles, 72 per pair / 360 for all
five owners, two shared shader material surfaces per pair. Explicit scene
resource dependencies avoid nested script preload lifetime warnings. Color and
energy are per instance; no beam frame callback or shared material mutation.
Original four segment paths/poses/lengths and focus pose/strength scaling remain.
This is discrete controller presentation, with inherited spatial gaps intact.

Star keeps the exact canonical star.svg and Sprite3D pose/billboard/pixel size.
Its slow alpha/scale breathing is pausable, stops and resets when hidden through
itself or an ancestor, and adds no progress, save, sound or light side effects.

Evidence beam-star-headless-1 passes 50 mesh/controller/palette/Star lifetime
assertions + 19 current housing assertions + 17 Boot assertions and normal
startup. beam-star-s02-1 passes 60 actual controls/save/reload/return assertions:
146 assertions total, cache-free imports, no Godot WARNING/ERROR. Read-only
protected primary/backup slots remain byte-identical; physical S02 IO happens
only in its test-owned copy. All exact current game/tools hashes are sealed.

beam-star-native-1 supplies sixteen individually inspected actual 960x540
Forward+ Low/Medium software Vulkan views: cold/partial/aligned, close Star,
broad/adjusted focus and warm room/Hearth. Core cues work with glow/volumetrics
off, focus visibly narrows and the original warm room transition survives.
Observed calls 19..41, texture bytes Low 27648512 / Medium 35138048; these are
view-specific software counters, not GTX 1060 / 1080p60 acceptance. At most five
additional additive halo surfaces; no textures, particles, collisions or lights.
beam-star-authoring-1 records a real fresh static-mesh factory reproduction.

Both accepted roof source/export families and canonical Star texture retain
exact identities. No new Blender/GLB/LFS payload. Aggregate beam-star-acceptance-1
binds current source and evidence. Full room/gallery/lighting, global beam
rollout, authored audio, physical target GPU, ARCH/VS1 and S03 remain open.
Next: original bounded wall practicals, without new walking routes or global
lighting changes. Continue stages within the owner's current 3–4 hour window.

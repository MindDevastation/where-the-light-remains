# Wing I — bounded Hearth bowl and emitter housing

S02-004 requires a Hearth bowl with its existing warm activation; S02-002
requires a light emitter/star target using the shared beam system. This block
authors only the static bowl/stand and emitter housing. The canonical three
rings → emitter/star → five-position focus → Hearth order stays authoritative.
`wing01_hearth_emitter.json` records exact interfaces and bounded geometry.

Six pinned current room A/B/C images in `wing01_optics_v1.json` were retrieved
with Git identity/SHA-256 verification and inspected. They show layered warm
stone, brass optical fittings and contrasting dark hardware; their large orrery
does not replace the canonical puzzle. No faction marks, new sigils, globe
puzzle, book/gallery clutter or inferred gameplay are copied from these images.

Hearth origin remains the existing body center (-2.8,0.65,-24). A stepped Stone
pedestal extends to the floor; an original hollow brass vessel ends at Y=0.97
world. The old radius-0.6/height-0.65 collision and sibling Flame node are unchanged.
The mouth remains genuinely open with a recessed floor, rather than a top disk.
Emitter remains at (0,1.72,-20), rotation X=90 degrees. Local -Y is its optical
face, meeting the existing first beam at world Z=-20.2. Its shared brass/iron
housing surrounds a recessed shared clear-glass face. No new light/shader/state
or collision is introduced. Star, all beam nodes and control/grip paths stay intact.

One editable source, two separately exported identity GLBs and script-free art
wrappers. Same verified Blender 4.5.14 → Godot 4.7.2 axis/unit/material/UV policy;
the accepted optical geometry helpers provide closed loft solids and metric
UVs. Original ring/focus assets are not regenerated. Each part is capped at
2,000 triangles, with two/three existing material surfaces and no new textures.

Before acceptance: actual source reopen/cavity rays, exported/imported bounds,
UVs/normals/material identity, upload and independent LFS retrieval, actual
puzzle approaches/safe spawns/save/reload/return and inspected Low/Medium cold/
warm/close views. Physical target GPU and full VS1 remain separate gates.

Ceiling is a separate unresolved adaptation: current room references show a
high dome/arched structure, while the accepted playable footprint is 10 x 12 m
with 4 m wall art and higher safety guards. A generic stone barrel roof is not
implied by those references. No ceiling geometry or global budget is assigned
by this static hero-art block.

# Archive bookcase — original reusable room family brief

Use pinned Wing I v2 appearances for dark walnut shelving, closed archival
books and restrained navy/crimson cloth accents. Author a compact original
case against the existing side-wall panel family, without new windows, raised
platforms, stairs, walking gallery, copied symbols, legible text, dates or
numbers. Book spines have only simple existing brass bands; no puzzle clues.
This supplies ordinary room furniture, not full library/gallery/ARCH acceptance.

Metric source/export is one joined static mesh of individually closed solids,
wall-face origin, +Z toward room, +Y up. Bounds [-1.2,0,0]..[1.2,2.55,.42] m;
6500 triangle / six shared material-surface ceiling per case. Four intended
unit-scale instances at X +/-4.8, Z-17/-25, floor Y0, yaw +/-90. New geometry is
limited to .42 m perimeter strips and remains .8 m clear of the entrance/back
wall junctions. Existing center puzzle, checkpoint/grip approaches, corridor
and five route owners stay fixed. Godot wrapper owns one conservative matching
static box collision so the player cannot walk through a closed bookcase; actual
capsule probes must prove required paths remain clear and the new face stops.

Reuse Walnut/Brass/Leather/Navy/Crimson. Add the missing required MAT-009
Parchment/Paper as a single reusable rough opaque material with a warm neutral
base color and no new texture. No faux paper text, thin transparent pages,
new lights, scripts, signals, animations or runtime book randomisation. Books
vary deterministically in height/width and leather/cloth binding, with a closed
paper block; authored poses are immutable and contain no letters or symbols.

Before acceptance: reopen editable source, verify closed positive-volume
components, metric UVs, unit normals/tangents, identity transform/finite GLB,
exact reused material references and measured counts. Upload actual source/GLB
and independently retrieve/reopen/import/use from an initially empty LFS store.
Inspect actual Low/Medium entrance, side/close, hero, Star/Hearth and warm views;
measure calls/textures and confirm the paper master has no added texture. Run
actual shipping capsule/checkpoint/grip/side-wall checks, S02 controls/save/reload,
beam/Star and Boot. Accepted roof/lamp/source identities remain unchanged. No
target GPU/1080p60, authored audio, final room/gallery/VS1 or S03 acceptance.
Continue the next bounded stage after a verified stable checkpoint.

# VFX-007 bounded brief — 2026-10-07

Status: **IMPLEMENTATION BRIEF / AFTER VFX-006 STABLE**.
Current canonical VFX-007 requires one subtle inspect/highlight strategy for
stages1–11, explicitly not a cartoon outline. The current inventory marks it
MISSING; the accepted player already provides an actual ray-selected
InteractionTarget and `focus_changed`. This independent family needs no stair,
recess, full core, new clue, fragment carrier, audio or future-stage decision.

Authority: REQUIRED_ASSET_TABLE VFX-007; TECHNICAL_BASELINE interaction/input/
Low readability; NARRATIVE_CANON fixed S01 lens sequence and S02 discrete puzzle;
QA_CHECKLIST controls/clues with effects and music off. Current v2 S01 ca004,
S02 wi002 A/B/C and lighting guide supply restrained warm feedback only; they
do not authorize new interaction locations, hero shape or symbols.

## Fixed scope before implementation

- One native shader/material + world presentation listener; no new geometry,
  Blender source, bitmap, LFS payload, light, collider, narration or save flag.
- Existing geometry is used for a very low-alpha additive warm surface wash,
  without vertex expansion, silhouettes, screen-space outlines, flash or pulse.
  Material overlays live only on the selected current MeshInstance(s); original
  base materials and preexisting overlays are preserved/restored.
- Eight existing targets only: S01 panel cover, pickup lens, socket and lever
  handle; S02 outer/middle/inner ring and focus control. Map exact target paths
  to existing visual roots. Unit geometry/pivots/UV/normals/tangents/collision
  remain owned by accepted assets; their bytes must compare unchanged.
- Only the actual active player's current available ray focus enables the wash;
  focus loss, range/occlusion, pause/UI/disable, consumed target, quiet spawn,
  unload or node lifetime clears it. No additional interaction/event occurs.
- Visible on Low/Medium and with decorative effects disabled: this is subtle
  inspect feedback. The original Russian E prompt remains independently readable.
  No hint/glyph/route/hidden-letter information is added.
- No global viewport/shader/budget change. At most the one focused visual root
  gets an extra material pass; no shadow pass. Do not modify imported GLBs or
  accepted master materials.
- Require native import/startup, actual ray acquisition/clear/occlusion/consumed
  state tests, exact overlay/material restoration, pause/quiet reload and
  S01/S02 progression. Individually inspect Low/Medium paired on/off S01 and
  S02 captures and ensure the wash remains secondary to existing scene/text.
  Software renderer checks do not accept physical target GPU. Future stage
  adoption and complete style/gate remain PARTIAL.

Execute after dust publication with a separate bounded acceptance/checkpoint.

# ARCH-011 next-family layout dependency — 2026-10-06

After bounded ARCH-008 fanlight acceptance, ARCH-011 is the next MISSING
architectural row. This audit pauses that dependent family, not accepted art,
lighting, routing or publication. Owner's existing push authorization remains
valid. No reasoning escalation or new permission request is introduced.

| Source | Established requirement | Consequence |
| --- | --- | --- |
| docs/design/REQUIRED_ASSET_TABLE.md ARCH-011 | Short stairs/steps, stages1–9, two widths, no complex platforming | A functioning stair family needs a placement and a lower/upper walking level; neither is specified by this row |
| docs/production/S01_HUB_FLOOR.md / ACCEPTANCE | Original radius10 floor, collision planeY0, player feetY.004; no stairs/new walkway or puzzle redesign | Raising/cutting accepted Hub floor or disguising steps as coplanar skins changes its established scope |
| game/worlds/archive/wing01_room_floor.tscn / wing01_corridor_floor.tscn | Existing corridor/room tiles lie atY0 | No authored raised platform, stair landing or approved second elevation exists in S02 |
| game/core/player/player.gd / player.tscn | Capsule1.8m, floor snap.15, gravity/move_and_slide, no step-up/jump implementation | True risers cannot be declared traversable from art inspection; ramps/step handling require a separate collision/locomotion decision and physical tests |
| docs/production/S00_S15_EXTERIOR_INTERFACES.md / S00_APPROACH.md | Exterior uses floorY0 and fixed original S00 rail; ARCH-018 permits path | S00 path is already accepted and does not supply ARCH-011 stages1–9 placement; changing it is not a missing stairs fix |
| docs/production/THREE_D_PRODUCTION_PIPELINE.md §1 | Pause if modeling requires inventing important geometry/function | A concept stair silhouette cannot select the missing level layout |
| docs/production/ASTRA_WORKFLOW.md §§6–7 | Pause the dependent task when canonical decisions are missing; do not silently resolve contradictions | Preserve/publish completed window work, then obtain the missing layout decision |

Repository design search finds no further stairs/elevation brief beyond
ARCH-011 and the distinct ARCH-018 exterior path. Actual assembled/native views
confirm the existing flat Hub→corridor→optics route. Decorative pedestal steps
are accepted ARCH-010 geometry, not traversable ARCH-011 stairs. Authoring an
unused future-stage mesh or assigning it to a gallery would not close current
VS1 coverage and is not claimed as production completion.

Missing input: canonical stair location(s), lower/upper walking elevations and
the two intended widths, including whether a current S01/S02 layout may change
or the row should instead be deferred to a later stage and its VS1 dependency
explicitly revised. Any approved layout change needs a bounded brief covering
landing/collision, first-person traversal, interaction reach/LOS, route clues,
save/checkpoint spawns, Low/Medium native review and affected progression.

ARCH-011 remains MISSING; no assets or runtime layout changed by this audit.
Other missing families remain tracked rather than silently substituted for the
ordered architecture task. Full gallery/target hardware/VS1/S03 remain OPEN.

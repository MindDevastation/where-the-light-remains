# S00 flat entry approach and guard skins — bounded contract

Continues stable portal ddc34ee/receipt495581d without accepted art regeneration.
Canonical ARCH-018 explicitly permits steps/path. Preserve the actual original
flat path and existing floorY0, automatic railZ15→4,Y1.624; no authored steps,
new route, collision, player motion, camera/FOV, state/save/event/light change.
Same original v2 S00 p_001/p_004 A/B/C stone/timber/iron/brass language; sparse
plain paving, low stone guard plinth and dark iron balustrade, restrained brass
cap rings. No glowing line, clue marking, copied emblem, lantern or prop clutter.

| Existing owner | Original body/root | Visual envelope |
| --- | --- | --- |
| Prologue/Floor | (0,-.15,12), Box4x.3x8 | center-pivot paving; maxlocalY.156 (world6mm), X<=2/Z<=4 |
| LeftGuard/RightGuard | (+/-2.15,.6,12), Box.3x1.2x8.3 | one shared centered longitudinal master within original body |
| RearGuard | (0,.6,16.15), Box4.6x1.2x.3 | shorter crosswise centered master within original body |

Replace only the three old visual primitive definitions' four Mesh instances.
Floor/guard bodies/shapes/layers remain the authority; open bars do not create
new traversable gaps in the old containment boundary. Floor skins are at most
6mm above the unchanged collision plane, ending atZ8/16, inside same4m width;
no cumulative transforms, stairs or texture-only/concept promotion.
Three original GLBs, one editable s00_approach.blend, shared existing Stone/Iron/
Brass. Local limits: paving6000tri, each guard4000tri; three surfaces each. No
new material/shader/texture/global draw budget/LOD/collision/light strategy.

Required actual source/import manifold/metricUV/unit shading/pivot/material,
body containment, flat path height and physical rail/guard regression. Scoped
S00 clock/pause/persistence and S01 handoff; Low/Medium native views inspected;
all four new committed LFS payloads independently downloaded/reopened/imported/
used before acceptance. ARCH-018/012/complete exterior classifications must
retain incomplete future/Hub/corner scope, no full exterior/VS1/GPU/S03 promotion.

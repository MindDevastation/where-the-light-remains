# MAT-002 polished brass — bounded acceptance, 2026-10-07

Status: ACCEPTED for the required one reusable material master. Full hero
geometry, owner gallery, target GPU and GATE-VS1 remain OPEN. No S03 work.
Brief fixed before production: POLISHED_BRASS.md. Native interface baseline:
ARCHIVE_CORE_HERO_INTERFACE_AUDIT.md. Review: review/polished_brass.html.

One shared editable `game/art/materials/m_polished_brass.tres` uses three
original periodic1024-square albedo/+Y-normal/ORM PNGs. Editable generator:
`tools/generate_polished_brass_maps.py`, using the unchanged existing noise and
normal helpers. No concept pixels, third-party texture, shader or new 3D family.
Ordinary Git PNG/source publication; zero new LFS payloads. Numeric roughness
.212484–.282097, metallic.98, restrained normal scale.3. Import preserves native
compression, mipmaps and anisotropic filtering: HQ albedo/ORM and explicit
normal-map compression with +Y preserved. AO channel is white, reserved.

Only two shipping material overrides change: Hub/Astrolabe/OuterRing and
InnerRing. The exact previous scene is recovered by removing the new material
ext_resource, restoring both Metal overrides and load_steps102. All geometry,
UVs, transforms, collider, targets, routes, clock/state, lighting, saved DTO and
onboarding remain identical. Accepted lower housing keeps aged brass. The hidden
finale placeholder keeps its previous Metal. Original12 masters,20 material maps,
193 previous art/source identities and47 actual runtime GLB payloads are
preserved. Previous source reopen/acceptance is reused in its original scope;
this turn verifies identity/use, not a fresh Blender reopen or LFS upload.

| Final exact-source evidence | Fresh result |
| --- | --- |
| polished-readonly-2 | Clean import/startup;29 new material +29 pedestal +26 inspect assertions =84; protected primary/backup unchanged |
| polished-progression-2 |35 S00 prologue +122 actual S01 E/pause/awakening/checkpoint +60 S02 physical IO/quiet reload =217; owned private slots |
| polished-native-2 | Fresh deterministic regeneration: all3 PNGs and manifest byte-identical; cache-free import/startup; Low8 +Medium12 actual Forward+ captures; protected primary/backup and logical DTO/dirty unchanged |
| polished-acceptance-20261007 | Current source/evidence hash seal, preserved identities and two-override scene equivalence |

Total301 assertion executions in final scoped families; these are executions,
not301 unique new tests. The29 material assertions are new. Prior dust602,
inspect286 and fanlight712+72 remain historical accepted evidence, not fresh
executions counted in301. Earlier polished-readonly-1 fails strict warnings
because its source PNG loader used res:// as a loose image. The final test loads
source PNG bytes explicitly. Production material unchanged; no warning waiver.
polished-native-1/progression-1 are superseded by current exact-source families;
core-hero-audit remains the explicitly identified pre-material baseline only.

All20 final PNGs were individually inspected, not a contact-sheet-only review.
Shipping captures use actual GameRoot/player/HUD and unchanged shipping lights;
decoration is off and transforms/ray/overlay counts match within each pair.
Eight old/new pairs prove native material response on Low/Medium. This software
llvmpipe Vulkan/Forward+ run is not physical GTX1060/1080p60 evidence.

| Individually viewed final frames | Visual judgment |
| --- | --- |
| sleeping_polished/previous_low +medium (4) | Warm brass rim separates from previous cool/dull fill; geometry and sleeping room unchanged |
| oblique_polished/previous_low +medium (4) | Restrained warm highlights; silhouette/controls unchanged; current torus geometry remains visibly provisional |
| panel_polished/previous_low +medium (4) | Actual Panel ray/inspect wash and Cyrillic E prompt remain readable; ring highlights do not cover the control |
| awakened_polished/previous_low +medium (4) | Existing warm CoreLight produces stronger brass response; no new emission/light; pedestal/state unchanged |
| specimen_neutral_medium | Polished and aged masters visibly distinct; maintained smooth highlight versus aged micro-wear |
| specimen_warm_medium | Warm response retains brass hue, restrained micro-normal detail |
| specimen_cool_medium | Cool key response remains metallic, distinct from aged wear |
| specimen_tiles_medium | Actual4×4 UV repetition on isolated cards; no visible boundary seams; no atlas/trim claim |

Specimen lights/sky/primitives live only in the review test. They are not added
to the shipping world. No new global lighting or performance policy is set.
Low native aliasing and provisional hero silhouette are not falsely accepted
as finished style. This fulfills MAT-002's one-master requirement using the same
bounded material criteria as accepted MAT-001/003/004; future-stage adoption and
complete room composition stay separate. PROP-001/002/004 remain PARTIAL.

Delta-only inventory: MAT-002 MISSING→ACCEPTED;26 ACCEPTED/40 PARTIAL/11 MISSING
among77 VS1 rows,185 canonical rows retained. No completion percentage inferred.
ARCH-011 remainsMISSING/required_for_vs1 pending explicit owner A/B choice.
Architecture/backdrop/alcove, full hero, channels/carrier/emblems, remaining
materials/trims/decals/dressing/style, authored audio/mix and owner/physical-GPU
gates remain open. Full-game planning estimate25–30%, low confidence,3/16
playable stages remains unchanged. Next: constrained authored core/orbit/mount
production brief and restore usable private LFS upload before creating binaries;
independent native material slots remain eligible after their own bounded brief.

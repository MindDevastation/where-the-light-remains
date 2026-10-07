# S01 core — measured three-orbit production brief, 2026-10-07

MEASURED_PROPOSAL_NOT_AUTHORED. Contract: core_orbits_production_brief.json.
Evidence: evidence/archive_reconstruction/core-orbits-brief-20261007/results.json
and core_orbits_metric.png / .svg. The individually inspected drawing is a metric
projection of centre lines, not a production model or shipping native frame.
Existing source audit/interfaces and accepted lower pedestal remain unchanged.

| Orbit | Centre-line radius | Godot default YXZ Euler degrees | Source scale | Triangle ceiling |
| --- | --- | --- | --- | --- |
| Outer | 0.58 m | (55,0,25) | (1,1,1) | 1800 |
| Inner | 0.46 m | (-30,0,-20) | (1,1,1) | 1800 |
| Third | 0.34 m | (25,0,68) | (1,1,1) | 1800 |

All three share the existing world pivot (0,1.8,0). Preserve the outer/inner
orientations; apply physical dimensions in source rather than retaining legacy
inner node scaling. Rings are authored bevelled 14 mm radial ×28 mm wide straps,
2 mm bevel, with joins confined within20 mm of their centre line. No primitive
TorusMesh substitution qualifies as finished hero art. Use existing polished brass,
dark iron and aged brass masters, metric UV1024px/m, no extra material family,
light, icon, clue, control, collider, interaction or independent animation clock.
Total rings+mounts ceiling6000 triangles, mounts600, target≤3 masters/≤6 surfaces;
measure actual export rather than accepting these ceilings as measured counts.

A private headless Godot probe records the actual Basis.from_euler default YXZ.
The continuous-yaw distance lower bound encloses each control AABB in an annular
cylinder and subtracts20 mm support plus radius*pi/8192 Lipschitz allowance from
sampled circular centre lines. Bounds apply throughout the existing shared group
yaw, not only one pose. Minimum orbit-to-control gaps: Panel321 mm, Lens936 mm,
Socket109.5 mm, Lever292 mm. Radius0.58 is selected to retain≥100 mm at Socket;
larger silhouette is not automatically permitted. Conservative orbit bounds fit
inside the historical accepted world envelope x±.882265, y.969710–2.630290,
z±.688279. The proposed three-ring union is x±.545881, y1.284304–2.315696,
z±.426241. This proves bounded metric clearance, not gameplay ray visibility,
craftsmanship, style parity or material/performance acceptance.

Mount construction: centre spindle radius≤.055 m at worldY1.39–1.8; base collar
radius≤.19 m at Y1.39–1.44, inside the accepted .2 m axle footprint. Three upper
bridges start at the pivot and end at each circle's maximum-Y anchor; keep their
entire support aboveY1.78, including bevel/joins. No lower radial spokes through
the controls. Anchors before shared yaw, in world metres:

| Bridge | X | Y | Z |
| --- | --- | --- | --- |
| Outer | .149115 | 2.295474 | -.262050 |
| Inner | -.220232 | 2.067328 | .302711 |
| Third | .113767 | 2.119805 | -.019544 |

Conservative mount-to-control lower bounds: Panel305 mm, Lens405 mm, Socket155 mm,
Lever405 mm. The JSON contract's support envelope is mandatory for these bounds.
Preserve existing lower pedestal, panel/lens/socket/lever identities/transforms,
LightMarker/CoreLight, reach2.5 m, yaw.35 rad/s after existing two-second onset,
state/save semantics and S01→S02→Hub routes. No ARCH-011 choice or S03 scope.

Next authoring depends on authenticated GitHub credential helper supporting
private git-lfs upload in this environment and restored pinned Blender. Author
editable .blend and export sibling .glb through LFS; inspect actual bevels, seams,
tangents, material slots, triangle/draw budgets and correct applied unit scale.
Independently retrieve both payloads and reopen the source in a second clean
Blender process. Native Low/Medium neutral/current-light pairs and actual scene
old/new composition must establish crafted readability. Test E-ray targeting and
all four controls throughout yaw, pause/awakening, S01→S02→Hub, physical private
save/quiet reload and protected primary/backup state. These checks are required
before bounded runtime integration acceptance; the metric brief earns no inventory
acceptance, new shipping placement or new GLB evidence.

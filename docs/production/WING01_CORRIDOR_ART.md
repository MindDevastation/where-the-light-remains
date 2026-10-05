# Wing I corridor — bounded approved-kit presentation

The actual ArchiveMain now instances the previously accepted v2 structural kit:
four 4 m wall bays, two shared seam piers and one room entrance portal. This is
ordinary placement under `MODULAR_ARCHIVE_KIT.md`; module sources, export
pipeline, shared materials, dimensions, grid and budgets are unchanged.

| Part | Positions X/Y/Z, meters | Yaw | Scale |
| --- | --- | ---: | --- |
| Left wall bays | (-2, 0, -10), (-2, 0, -14) | 90° | 1 |
| Right wall bays | (2, 0, -10), (2, 0, -14) | 270° | 1 |
| Seam piers | (-2, 0, -12), (2, 0, -12) | 0° | 1 |
| Room portal | (0, 0, -15) | 0° | 1 |

The two graybox corridor wall meshes are hidden. Their original higher safety
colliders and existing floor remain; kit wrappers retain their approved solid
walls/piers and capsule-safe arch. The centerline still connects the real Wing I
gate to the existing room, without progression, interaction or save changes.

`evidence/archive_reconstruction/corridor-art-headless-1/` passes clean import,
39 new assertions using the actual 0.35 m radius / 1.8 m player capsule and
101 relevant Archive state/safe-spawn regressions. The player moves through the
portal into the room and back; a seam pier blocks lateral escape. All three
commands preserve two physically existing save fixtures exactly; no runtime
errors/warnings and the private cache-free copy is removed.

Visual corridor review is the next independent block. Full room/observatory
art, emitter/Hearth authoring, S00 note/motif selection, scene mix and physical
GTX 1060 profiling remain open. No full GATE-VS1 acceptance is implied.

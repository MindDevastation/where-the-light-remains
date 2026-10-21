# VFX-006: bounded current Archive dust — 2026-10-07

Native editable Godot scene/script/shader, two actual room volumes; no new DCC
family or LFS payload. Hub `(3,2,0)` and S02 `(1.8,2,−22)` use shared 25 mm
feathered billboards with instance-local motion. Counts12/36/48 per volume on
Low/Medium/High, slow .015–.04 m/s drift, 12 s lifetime, padded visibility AABB.
No own collider, light, shadow, glow, clue, audio, save flag or new stage.

Existing world stage owns visibility: S00 disabled; S01/S02 enabled. Tree/focus
pause freezes GPU speed; effects-off hides/stops decorative particles even
while paused, and unpause does not restart disabled effects. Quiet projection
does not emit a progression event. See ARCHIVE_DUST_MOTES.md for the fixed brief.

| Current evidence | Actual result |
| --- | --- |
| dust-readonly-1 | 385 assertions: new effect78,state101,route147,lighting59. Clean import and protected primary/backup unchanged. Runtime/test bytes checked for reuse at the acceptance seal; later review-script typing correction does not certify the failed native attempt. |
| dust-progression-2 | 217 assertions: S00 timeline35,S01 E/pause/awakening/save122,S02 Star→Hearth/retry/physical primary/backup/quiet load60. Owned private test save slots. |
| dust-native-2 | Clean import/startup; native Forward+ Low/Medium10 views each. All20 PNG individually inspected; logical DTO/dirty and protected physical slots unchanged. Actual on/off GPU rendering proof in10 frozen pairs. |
| dust-acceptance-20261007 | Current source/evidence seal; preserved prior art identities, runtime LFS pointer/payload proof; per-image judgments and explicit exclusions. |

Actual rendering changes61–134 pixels in current interior pairs at960×540,
<.03% of each image; S00 pairs are identical. This measures sparse rendered
decoration, not artistic merit or performance. Individually reviewed images
retain routes, controls, Star/Hearth and warm/cold composition; the effect is
secondary and adds no fog veil. Pale/cool Hub stone and unfinished upper/exterior/
hero/dressing remain visibly incomplete. Full v2 style is not accepted here.

This session executed602 scoped assertions, with no duplication from historical
fanlight712+72. Native software llvmpipe is not physical GTX1060/1080p60. No new
binary family was authored; previous source/export identities remain accepted
in their original scope.47 restored runtime GLBs were checked against committed
LFS SHA-256/size; this is restoration proof, not a new source reopen or hardware
result. Imported/root side effects from the recovery import were restored.

Excluded diagnostics: dust-native-1 failed due to a review-only GDScript type
inference error and timed out; corrected native-2 is current. dust-progression-1
used a nonexistent final test name, so its family is excluded; the full correct
three-test suite passed as dust-progression-2. Failed families stay diagnostic.

Only VFX-006 MISSING→PARTIAL; broader stages0–15 adoption and full composition
remain open.185 canonical rows unchanged; among77 VS1 rows25 ACCEPTED,
39 PARTIAL,13 MISSING. ARCH-011 still MISSING/required_for_vs1 pending owner
decision. Full GATE-VS1 and S03 remain gated, full-game estimate25–30% unchanged.

Next independent bounded family: VFX-007 subtle inspect wash tied to existing
player ray focus, fixed in ARCHIVE_INSPECT_GLOW.md. Continue from latest remote
receipt; current-session checkpoint journal is continuation_20261007.jsonl,
alongside the unchanged historical development.jsonl.

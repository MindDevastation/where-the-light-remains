# TRIM-002 — fixed measured source and first-use brief, 2026-10-07

Canonical MUST: one2K stone/ornament trim, reuse0–15, arches/pedestals/borders.
Current row MISSING; a tileable or micro-wear field alone cannot satisfy it.
Original carved stone profiles/joints/bead relief, restrained pale warm limestone
from current v2 material/kit references; no glyph, star, sign, clue or new mechanic.
Inspected current kit/core/material primary references; no pixels are copied.
S00 timber/iron/cobalt authority stays unchanged. This family is source-only
unless the exact measured carrier and scene checks below are completed.

One2048×2048 RGB albedo/+Y tangent normal/ORM set, original editable analytic
source plus fixed region JSON. One shared opaque matte StandardMaterial3D,
normal scale1, nonmetallic B0, white reserved AO R1, roughness G.76–.92.
No displacement, alpha, emission, custom shader or project-wide budget change.
Lengthwise U repeats every2m:2048/2=1024px/m, matching accepted1024 maps on
one-UV-unit-per-meter Archive kit. V never wraps across unrelated bands.

| Region | Allocated source rows | Active rows / normalized V | Physical width at1024px/m | Existing canonical metric source |
| --- | --- | --- | --- | --- |
| A arch_fillet | 0–255 | 96–159 / [.046875,.078125] | .0625m | ARCH-005 arch profile6→7 offset.12→.18, depth.20: actual.06m stone fillet |
| B arch_moulding | 256–767 | 352–671 / [.171875,.328125] | .3125m | ARCH-005 full developed surround profile.309432983m; existing .015m brass subsection remains separate |
| C pedestal_plinth | 768–1151 | 864–1055 / [.421875,.515625] | .1875m | PROP-001 accepted lower stone barrel localY−.694→−.53: actual.164m |
| D wall_border | 1152–1663 | 1216–1599 / [.59375,.78125] | .375m | ARCH-004 wall profile2→3: inset.075→.10, Y.135→.30, depth.178; developed.166883m, centre-crop at metric density |
| E floor_edge | 1664–2047 | 1728–1983 / [.84375,.96875] | .25m | ARCH-0061m floor module edge Y−.2→0: actual.2m, centre-crop at metric density |

Active row intervals are pixel-edge ranges [start,end), e.g A[96,160).
U[0,1] represents2m. Native specimens show4m lengths/two repeats and active
physical widths; UV derivatives must recover1024px/m in both axes. The first
real .06m fillet uses V=.0625±(.06*1024)/(2*2048), i.e [.0475,.0775].
Do not stretch its .06m face over the entire sheet or change geometry to fit it.

U seams are periodic analytic/seeded fields. Region active edges are clamped into
allocated padding:64px minimum,96px for A/B/C. Normal derivatives are authored
within each physical profile; guard pixels copy edge values, not neighboring
ornament. Planned review footprint≤16 source pixels, with native mip/repeat and
boundary checks; extremely distant atlas mixing remains a measured scene concern.
No atlas-wide V repetition. Hide real UV cuts at existing construction boundaries;
no seam across a visible uninterrupted fillet, continuous developed-length U at
spring/crown. Texture relief is limited to5mm and does not alter collision.

First integration target is the existing ARCH-005 RoomPortal under
ArchiveMain/Wing01/Corridor/Presentation (resolve exact wrapper from source),
world position(0,0,−15), module bounds[-2,0,−.2]→[2,4,.2], unchanged2.4m passage,
spring2m/apex3.6m and existing jamb/crown collisions. Scope: front6cm stone fillet
between profile6/7 only. Existing broad stone and brass retain their materials.
Source tools/create_archive_kit.py currently gives orthonormal tileable UVs;
one material override cannot implement strip UVs correctly. Use a sibling editable
UV-only Blender/GLB variant after usable private LFS upload is configured. Retain
every vertex/triangle/normal, object origin/transform, slot identity for retained
surfaces and wrapper collision/route. No blanket swap of all arches. Independently
retrieve/reopen source and payload, clean-import, native before/after, actual E/
pause/state/S01→S02/private save-reload tests before bounded shipping STABLE.

Current environment has no GH_TOKEN/GITHUB_TOKEN/GIT_ASKPASS or configured
credential.helper, no Blender executable and no private CLI LFS upload proof.
Connected Git Data fast-forward transport works for ordinary source/PNG/docs.
Do not extract historical secrets, put GLB in ordinary Git, modify accepted LFS
files or waive source reopen. Required owner setup, if unchanged: provide an
authenticated GitHub credential helper for this environment capable of git-lfs
upload to this repository. Permission is already granted; this is capability.
New3D work remains dependent, source/measurement work continues. No binary authored
before that path exists. If blocked, complete the three-orbit measured integration
brief from the existing hero audit instead of more unassigned material specimens.

Acceptance here requires exact regeneration of3 maps+manifest, profile masks/UV/
density/periodic-U/padding/normal and data-range checks, fresh minimal Godot import,
Low/Medium native neutral and exact current environment/moon lighting subsets,
native framebuffer profile and boundary/mip views, protected primary/backup slots,
and individual image review. These fixtures have no gameplay/autoload and are not
shipping/physical target-GPU acceptance. At most TRIM-002→PARTIAL after passing.
ARCH-011 owner A/B stays pending; floorY0, walk-only, GATE-VS1 OPEN/S03 blocked.

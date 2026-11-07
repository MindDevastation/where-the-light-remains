# First measured TRIM-002 integration — existing RoomPortal

Reviewable bounded contract, not an implemented/accepted UV variant. Dependencies:
authenticated private Git/LFS upload to this repository, pinned Blender/source
reopen and independently usable payload/import path. Native Git reads/Git Data
ordinary commits work; current environment has no configured credential helper,
GH_TOKEN/GITHUB_TOKEN/GIT_ASKPASS or Blender. No historical credential is used.
The missing owner step is configure an authenticated GitHub credential helper
supporting LFS upload in this execution environment; publication permission is
already granted. Blender is then restored from the pinned source handoff.

Actual target: ArchiveMain/Wing01/Corridor/Presentation/RoomPortal/Art at
world(0,0,−15); archive_arch_4m wrapper/GLB and create_archive_kit.py source.
Existing full module bounds[-2,0,−.2]→[2,4,.2], origin(0,0,0),2.4m passage,
springY2/apex3.6, floorY0/walk-only and all34 jamb/crown collision shapes remain.
The source has ten moulding sections; select only front+Z stone band6→7,
offset.12→.18/depth.20, physical width.06m. Leave the brass band and all other
stone/materials unchanged. Other RoomPortal/back/front module instances do not
receive a blanket material override.

Create sibling archive_arch_4m_trim_uv.blend and sm_archive_arch_4m_trim_uv.glb
through approved LFS, with exact existing geometry/object transform preserved.
Map that band using developed length on its .15m offset centre path, U=s/2m;
V=.0625+(offset−.15)*1024/2048 gives [.0475,.0775]. Continue U across jamb/spring/
crown; cut at existing construction boundaries only. No stretch-over-full-sheet,
new groove geometry or replacement primitive. Recompute UV-dependent tangents;
existing normals, vertices, indices/topology and retained material IDs stay exact.
Use one additional shared trim slot for the selected faces;≤3 surfaces and
unchanged≤4000 module triangle ceiling. Measure actual export/source budgets.

Use a sibling wrapper preserving the original collision/metadata byte-equivalent
sections; replace only this RoomPortal instance, retaining its node name/position
and route identity. Keep accepted source/export families intact. Independent
LFS source/payload/OID/size retrieval, second clean Blender reopen, GLB metric/
origin/UV/normal/tangent checks and cache-free Godot import are mandatory.

Before bounded runtime STABLE: native Low/Medium same-frame old/new corridor
portal/approach/reverse views and contrast/style inspection; actual player E/ray
for nearby gates/onboarding, pause, awakening/progression, S01→S02→Hub continuity,
private physical save/reload and protected readonly primary/backup. No warning
waiver, save schema/timer/light/collider/layout change. One first-use fillet does
not automatically close the complete canonical trim/VS1 scope. Archive stairs
remain dependent on the separate owner A/B choice; S03 stays gated.

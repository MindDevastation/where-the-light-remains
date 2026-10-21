# Archive practical lighting — bounded candidate contract, 2026-10-06

Continue from remotely accepted gate3d81acb/publication receipt228ae00. The
existing v2 lighting guide and S00 p001 / S01 ca004 / S02 wi002 references were
viewed; canonical split stage states and fixed routes override concept props,
stairs, extra windows, emblems and fixture counts. This scope addresses uniform
pale/cool fill using actual accepted art, not complete visual style approval.

Scene ambient energy .65→.22 and moon .7→.38, same blue palette/tonemap. S00
retains exactly its one accepted exterior lantern, original rail and door. Four
accepted unit lanterns mount on the inside faces of Hub Wall0L/0R/2R/3L at local
(0,.35,.175), world height2.75m; no collider or target is added. Their unchanged
local range3/energy1.25/specular.1/no-shadow wrapper is retained. Existing two
S02 lanterns, materials, source Blender/GLB families and RoomLight's existing
cold/hearth color tween remain unchanged.

The four interior fixtures are hidden only during existing PROLOGUE state and
projected visible at the existing S01 handoff. This prevents shadow-free light
leaking onto exterior side-wall backs and keeps S00's sole warm source intact.
Their visibility is read-only presentation from stage_id, not a new save flag.

One shadow-free CoreLight at(0,2.35,0),range5.5,specular.25 projects cold asleep
(.43,.65,1)/energy.30 and warm awakened(1,.68,.36)/energy1.8. The existing
seven-second awakening clock ramps only during seconds2..7; pause freezes it,
cancel restores durable presentation, quiet load assigns immediately. No new
timer/tween/save flag, route light/emblem or gameplay behavior is introduced.
Settings keeps clue lights on Low with existing shadows/effects controls.

Acceptance requires affected actual S00/S01/S02 state/progression/gate tests,
pause/cancel/quiet/reload and local-placement checks, cache-free import/startup,
protected physical saves and individually inspected native Low/Medium exterior,
Hub controls/asleep/awakening/awake and S02 cold/star/hearth/warm views. Record
renderer/device, draw/light counts and source identities. No added shadow pass;
fixed GTX1060/1080p60 budget remains, software llvmpipe does not certify it.
Upper infill/windows/backdrop, complete hero/channels/dressing/audio/gallery,
physical GPU and GATE-VS1 remain open; S03 remains blocked.

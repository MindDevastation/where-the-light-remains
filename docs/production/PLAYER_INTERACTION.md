# First-person player / interaction foundation

Epic: `epic/01-shell`; feature: `feature/01-shell/player-interaction`.
Status: **PASS for the bounded controller/interaction foundation, 2026-10-03 UTC**;
no gameplay puzzle or final UI art approval.

## Bounded implementation brief

Authority: `ASTRA_WORKFLOW.md`, `TECHNICAL_BASELINE.md`, `INPUT_MAP.md`,
`INPUT_FOCUS.md`, `NARRATIVE_CANON.md`, `REQUIRED_ASSET_TABLE.md`, existing
Archive/Wing I sample contracts and evidence. The accepted TCP/cookie X11 /
Vulkan Forward+ baseline is reused. Standing Extra High / highest available
request applies; no agent-side setting change is claimed.

Implement one persistent first-person CharacterBody3D, walk and look only;
InputManager owns capture/mode/pause. Physics movement consumes its gated,
normalized vector. Mouse look consumes unscaled `screen_relative` to avoid
resolution/stretch-dependent sensitivity, body yaw and clamped head pitch.
SettingsManager supplies FOV, sensitivity and invert-Y. No jump/sprint/crouch,
new keyboard actions, cutscene skip threshold or puzzle detents are introduced.

Initial **technical tuning values**, not final authored gameplay approval:
1.8 m total capsule, 0.35 m radius (reuse the proven Archive clearance probe),
feet origin, 1.62 m eye, 2.6 m/s walk, ±85 degree pitch and 2.5 m interaction
reach. Default sensitivity 0.5 maps to 0.002 radians per physical mouse pixel.
These bounded scene/controller parameters can be tuned after playable review;
the Archive contract and global visual/performance budgets remain unchanged.

Reserve the existing fixture layer 1 for solid world, layer 2 for selectable
areas, and layer 3 for this player. Walk collides with world; a ray tests both
world and selectable layers, excluding the player's own RID. The nearest solid
body blocks picking through a wall. Hit-from-inside is enabled so starting
inside a solid does not permit a through-wall action.

Only a collider's explicitly named `InteractionTarget` component can dispatch
an action. The reusable component checks availability and emits `interacted`
with the actor; world/puzzle logic stays local. Existing script-free Wing I
grips can receive a runtime component from their future controller without
changing the art carrier or inventing solve parameters. On E, the player queues
one non-echo request and rechecks range/occlusion/availability in the next
physics tick instead of acting on a stale target from the prior frame. Pause,
focus loss, mode change, deactivation and target deletion clear pending action.

GameRoot owns an inactive Player under PlayerContainer and an associated
minimal focus dot / Russian E prompt under UILayer. An empty world never
activates movement or capture. SceneRouter's later spawn pipeline will activate
the player; standalone CLI fixtures may do so explicitly. This does not make
the empty scaffold or carrier a playable story level.

Acceptance: real move_and_slide traversal through accepted Archive passages,
wall stopping, heading-relative walking, normalized diagonals, no stale movement
after pause/focus, look clamps/inversion/settings, physics ray occlusion/range,
single E/echo handling, target disable/delete race, Russian glyphs and actual
Forward+ screenshot. Repeat engine/input/debug and relevant art regressions.
Use fresh committed game source without a prior import cache; hash-verified
existing LFS payload copies are sufficient for code-only import isolation.

Source API references: [CharacterBody3D](https://docs.godotengine.org/en/stable/classes/class_characterbody3d.html),
[PhysicsRayQueryParameters3D](https://docs.godotengine.org/en/stable/classes/class_physicsrayqueryparameters3d.html),
[unscaled mouse motion](https://docs.godotengine.org/en/stable/classes/class_inputeventmousemotion.html).

## Actual acceptance

Committed source `908f480b6caeb81adff5a7df33fc439cfd2d94e7`: fresh game/tools
archive with no initial import cache, 14 existing LFS payloads verified against
HEAD pointers (runtime copies only), all 168 tracked files unchanged after tests.
Godot 4.7.2 clean import, six production-player Archive traversals at 0/90 degree
assembly yaws, wall stopping, normalized/heading-relative movement, look/setting
and pause/focus boundaries pass. Physics queries enforce reach/nearest blocker
and recheck E after target disable, deletion, movement or pause. Camera-inside
solid, disabled nearer target and queued collider cases pass.

Actual TCP/cookie X11/Vulkan Forward+ run passes the same controller tests and
selects/dispatches E through a temporary component on the existing Middle grip.
The existing script-free carrier, all art/materials/maps/LFS files and puzzle
solve parameters are unchanged. The real 1920×1080 focus-dot/Russian prompt PNG
was inspected; accepted Wing I review sky/key/fill lighting was reused after
the first preview exposed insufficient metal reflection. No final world art
or target GPU performance is certified.

Evidence: `evidence/player_interaction/README.md`. CLI scene:
`tests/player_interaction_smoke.tscn`, not a production world. GameRoot startup,
InputMap, InputManager and debug state/file integrity regressions also pass.
An initial inside-solid probe triggered capsule depenetration and moved the
camera out of the test box; placing the probe on the ray-only layer fixed its
setup and the corrected actual query passes. A concurrent graphical runner
attempt collided on Xvfb display 100; serial graphical checks pass. Use the
runner serially for these tests. These were harness issues, not missing runtime
capabilities.

Next shell work: SettingsManager persistence and Russian settings UI; pause/
transition UI and SceneRouter spawning remain their respective features.

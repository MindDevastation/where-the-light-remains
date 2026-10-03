# SceneRouter partial checkpoint — 2026-10-03 UTC

This is an unfinished feature checkpoint, not full acceptance or main integration.
`manifest.json` distinguishes clean contract source from the later prototype.

Contract logs: fresh import, actual registered threaded resource preload, isolated
StageDefinition copies, full stage/checkpoint/domain validation and offline nested
upright spawn PASS. The clean archive's 206 tracked files remain unchanged;
fourteen existing LFS identities verified, eleven runtime payloads reused.
Input/pause and authenticated TCP X11/Forward+ production startup PASS.

Latest prototype logs: editor import, actual Forward+ transition smoke and
production startup PASS. Initial replace/state/player/fade, overlaps, wrong
checkpoint, injected domain apply failure, later identical DISABLED ownership,
removed root and actual blocked capsule spawn checks pass. No production save or
settings write is performed. Full fresh-prototype regression/acceptance is open.

`physics_development.log` retains superseded failures and the successful fix.
PROCESS_MODE_DISABLED initially removed CollisionObject3D from physics space;
candidate collider disable modes now retain query presence while callbacks are
frozen, then restore their authored modes. A separate earlier freed-reference
typed-assignment bug was corrected with lifetime guards before prototype PASS.
These were implementation errors, not environment/capability blockers.

Resume requirements and remaining cases are listed in `SCENE_ROUTER.md`.
No shipping story worlds, solve parameters, target GPU or Windows acceptance.

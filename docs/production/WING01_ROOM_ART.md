# Wing I room — bounded side/back placement

This step reuses the accepted modular kit in the existing 10 x 12 m graybox
room. There is no new source mesh, export pipeline, shared material, lighting
budget, puzzle layout or progression rule. It is not full room art acceptance.

| Part | Positions X/Y/Z, meters | Yaw | Scale |
| --- | --- | ---: | ---: |
| Left 4 m wall bays | (-5, 0, -17/-21/-25) | 90° | 1 |
| Right 4 m wall bays | (5, 0, -17/-21/-25) | 270° | 1 |
| Back bays, 4/2/4 m | (-3/0/3, 0, -27) | 0° | 1 |
| Side/corner piers | (-5/5, 0, -15/-19/-23/-27) | 0° | 1 |
| Back seam piers | (-1/1, 0, -27) | 0° | 1 |

Exactly one pier owns each junction. Old side/back skins are hidden, while
their higher 5.5 m safety colliders remain. Front skins, room floor, ceiling,
emitter/Hearth authoring and other production variants remain unfinished.

`evidence/archive_reconstruction/room-wall-headless-1/` passes cache-free import,
19 actual shipping-capsule checks and 101 Archive state regressions. Both
Star/Hearth spawns and all four real grip approaches are unobstructed; kit
colliders stop escape at both sides and the back. Existing physical primary/
backup fixtures remain unchanged. Puzzle and five-route bindings are intact.

`room-wall-s02-regression-1/` separately passes 60 actual S02 assertions in
test-owned slots: real E/grip controls, ordered fragments, actual disk obstacle/
retry/primary/backup, quiet reload and grounded return through the corridor to
Hub. Both private projects are removed and logs contain no errors/warnings.

`room-wall-native-1/` passes cache-free import, Low/Medium Forward+ and unchanged
existing physical slot hashes. All six actual player images were inspected:
stone wall faces and the corner/junction are readable, and the existing cold
blue/warm Hearth lighting remains visibly distinct. The warm image applies
only the validated local quiet presentation projection, without changing
GameState/dirty state or saving; the separate 60-check suite verifies real
persisted progression. Private Godot/Xvfb/project resources close afterward.

Reproduce only this affected view family with
`tools/validate_corridor_presentation.py --scope room` and the documented Godot/
graphics-prefix arguments. Native graphics use software llvmpipe, not a target
GPU profile. This accepts only bounded side/back placement, not full VS1 art.
Next: room floor from approved unit tiles; test seams and puzzle approaches,
inspect the new surface under both existing lighting states. Front/ceiling,
full emitter/Hearth art, authored audio/mix and target GPU remain open.

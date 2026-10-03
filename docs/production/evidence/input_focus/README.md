# Input focus evidence — 2026-10-03 UTC

Implementation `c6aa035acbe8efdec725fe9621c34addd042c379`; additional native
held-key rearming assertion `2a47f5e32325a4d2745481c245e62de201214f53`.
`manifest.json` pins final code/test hashes; the implementation stayed unchanged
after the clean archive check. Feature follows normal feature → epic → main.

| Gate | Actual result / evidence |
| --- | --- |
| Authentication / permission / disk | PASS, MindDevastation, GitHub push permission, authenticated Git and origin LFS payload hash; `auth.log` |
| Environment recovery | Reused local verified packages/TCP cookie path. Local cached Godot executable returned 139 and cached ZIP SHA differed from the pinned release; fresh official ZIP matched `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`, version 4.7.2 ran. No renderer fallback or system apt used |
| Ordinary Git recovery | PASS, 264 missing HEAD blobs / 1,494,649,780 bytes hash/size verified, all 568 available, refs unchanged; `recovery.log` |
| Existing LFS restore | PASS, actual origin pull and producer fsck; `lfs_restore.log`; fourteen existing payloads/hash sizes in `payloads.json` |
| Minimum capability | PASS, actual X11 TCP authorization and engine Forward+ startup/eight services/safe exit; `capability.log` |
| Clean source/import | PASS, fresh `git archive c6aa035 game tools`, no initial `.godot`, verified producer runtime LFS payload copies; `clean_import_input.log`. 157 tracked files unchanged after import/tests |
| Input state boundaries | PASS, 20 mode/focus/pause combinations with synthetic Window signals; held/echo suppression, UI pointer route, diagonals, raw Esc/UI navigation, direct pause and recapture motion; `clean_import_input.log` |
| Native focus / capture | PASS, actual XSetInputFocus on authenticated Xvfb, queried native focus/mouse mode, UI/paused/DISABLED return; `clean_native.log` |
| Native return / echo | PASS, additional real focus return then injected W echo does not move; fresh press rearms; `native_echo.log` |
| Clean startup regression | PASS, GameRoot/eight autoloads/safe exit under X11/Vulkan Forward+; `clean_engine.log` |
| Previous feature paths | PASS, InputMap on clean archive; actual mixer routing/gain/mute in `initial_regression.log`; debug state/file integrity, Archive 15 capsule traversals and Wing I 40 poses / 48 rays in `regression.log` |

The native test changes real window focus; keyboard events remain injected
Godot events. Windows/native physical keyboard, target GPU and audible output
are not certified. The clean archive reused hash-verified producer LFS payloads;
it is an import/cache isolation check, not a new independent LFS download claim.
No new LFS binary, migration or history rewrite occurred.

Review corrected the first draft's UI motion interception before acceptance.
An old debug test fixture restored only mouse mode and retained GAMEPLAY even
though startup now uses UI; restoring through InputManager fixed the fixture,
with all state/file equality assertions preserved. No inspector behavior changed.
`initial_regression.log` retains that initial fixture failure and the preceding
successful mixer check; `regression.log` records the corrected final PASS.

Feature merged through PR #29 into Shell at
`836bfa1f5a8c2f8daae93bcd89993066bf9e93ae`.
The merged tree is exactly `76035d6f6f0de5d61bad5eb1c5668ba9f3c453d7`, equal
to the validated feature. `epic_smoke.log` records actual authenticated TCP
X11/Vulkan/Forward+ GameRoot/eight-autoload/safe-exit PASS on the merged epic.
GitHub reports MERGEABLE/CLEAN; no remote checks are configured, so no CI PASS
is claimed. A documentation-only checkpoint precedes normal main integration.

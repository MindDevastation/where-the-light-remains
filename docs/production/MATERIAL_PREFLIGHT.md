# Material library preflight

Status: **BLOCKED — graphical validation runtime unavailable** (2026-09-22).

Next feature: feature/03-art-foundation/material-library.
The approved baseline remains six shared families under game/art/materials/:
pale observatory stone, aged brass, polished/dark wood, frosted/memory glass,
crystal/glass and magical emissive light. The canonical asset table and the
approved Material sheet were inspected. No new material, shader strategy,
texture or production asset was invented or marked accepted in this preflight.

## Actual environment preparation

Godot 4.7.2 and Blender 4.5.14 are restored and their CLI tests pass.
System package installation is unavailable: apt update cannot change its
execution identity (setgroups/setegid/seteuid failures). The required Xvfb,
xauth and Mesa Vulkan packages were instead downloaded from the configured,
pinned Ubuntu Noble snapshot and extracted into a writable local prefix.
Archive sizes and SHA-256 were checked against the snapshot package metadata.
No root filesystem permissions or sandbox configuration were changed.

The package/version/checksum inventory is in
[evidence/material_graphics_packages_2026-09-22.json](evidence/material_graphics_packages_2026-09-22.json).

## Exact remaining blocker

With the local binaries and libraries configured, Xvfb reports:

    Cannot establish any listening sockets

Godot reports:

    ERROR: X11 Display is not available
    ERROR: Unable to create DisplayServer, all display drivers failed.

An isolated capability probe in an owned temporary directory fails at UNIX
socket creation:

    AF_UNIX capability BLOCKER: errno=1; Operation not permitted

Actual output:
[evidence/material_graphics_preflight_2026-09-22.log](evidence/material_graphics_preflight_2026-09-22.log).

This is a runtime capability dependency, not a missing material design decision.
An execution environment supporting local UNIX sockets and an X11 display is
required to resume this graphical validation. Do not disable access controls
or report graphical/visual PASS from headless tests. Further display retries
are paused until the execution capability changes.

The validated Blender/LFS fixture remains eligible for its independent
headless integration gate. No material feature has been merged or marked
complete. Representative target-hardware performance remains unmeasured.
High is sufficient for routine material baseline work; global material/shader
strategy and cross-stage modular architecture retain the separate escalation
requirements in ASTRA_WORKFLOW.md.

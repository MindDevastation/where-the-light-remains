# Archive channel trim v1 - source brief

The current ARCH-015/S01-005 route presentation still uses a plain BoxMesh. This bounded continuation adds an original native VFX skin to the existing reusable prefab: a bevelled luminous insert and two narrow dark-iron rails inside the original 0.18 by 0.03 by 4.7 m envelope. The original active/completed materials, five route placements and existing local Tween remain authoritative.

The measured baseline is `8dc7ffe618e0f95e802f310b714903d0ea21c39c`. The component script is preserved byte-for-byte. The luminous mesh keeps the original centre, height and longitudinal bounds, so its existing forward/reverse pulse endpoints remain the same. Rails are children of the visual node and inherit its authored transform and lifetime. No light, collider, input, clock, save field or global budget is added.

The source-native mesh format follows the accepted immutable ArrayMesh beam and Hearth VFX pattern. This is a new channel presentation source, not a conversion or publication of the blocked Archive central mechanism binaries. Text resources and existing shared material families are used. The per-channel candidate ceiling is 200 triangles; this does not change scene-level budgets.

The exact execution contract is `archive_channel_trim_v1.json`. Generation, import, actual native rendering and bounded state/pause/cancellation checks are pending. This brief is WIP, not an acceptance receipt. ARCH-015/S01-005 stay PARTIAL and the inventory remains unchanged. GATE-VS1 is OPEN; S03 remains blocked.

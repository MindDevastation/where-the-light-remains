# VFX-007 checkpoint — 2026-10-07

Status: WIP; inventory remains MISSING until the affected progression suite is clean.
Readonly actual-ray/effects/occlusion/material/lifetime tests passed26 assertions,
with dust regression78. Native inspect-native-2 passed import/startup and eight
individually inspected paired Low/Medium frames.

S01 progression executes122 assertions, but reports one RefCounted ObjectDB
leak at exit. The strict validator correctly fails; no warning waiver or accepted
progression claim. Isolation with the previous dust-only world removes the
warning. Disabling the focus listener or exit cleanup does not remove it; the
next diagnostic isolates preloaded material/shader construction.

inspect-diagnostic-* directories use deliberate private-copy mutations and are
DIAGNOSTIC ONLY, even where their technical result is PASS. They never certify
shipping hashes or acceptance. inspect-native-1/read-only-1 predate current
listener storage and the occlusion check. The current native/read-only-2 scope
is valid; failed progression families are excluded.

Last production STABLE is fa9006e02cfb0fecc2c68e208b0b0c7f8f2596e9.
Checkpoint publication is WIP, not a promotion of this material family.

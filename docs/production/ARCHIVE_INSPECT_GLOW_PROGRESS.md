# Historical inspect WIP checkpoint — b1a09ca

This document preserves the intermediate WIP diagnosis. It is superseded by
ARCHIVE_INSPECT_GLOW_ACCEPTANCE.md and inspect-acceptance-20261007/results.json.
Strict failed families remain diagnostics; no warning was waived.

The script default preload of an external material reproduced one RefCounted
exit leak, even with focus callbacks disabled. Private no-preload, constructed
StandardMaterial3D and previous-world isolation removed it. Merely switching the
external resource to StandardMaterial3D or adding a shutdown frame did not.
Final scene-serialized external material assignment passed the unchanged
original progression test. These observations identify a bounded workaround,
not an established engine-internal root cause.

All inspect-diagnostic-* copies deliberately mutate private files and never
certify shipping bytes. Final current families are readonly-4, progression-7
and native-4; earlier material/owner versions remain superseded diagnostics.

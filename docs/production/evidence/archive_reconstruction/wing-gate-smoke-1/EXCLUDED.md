# Excluded adapter revision

Recorded source predates the immutable SceneState reader correction. Nested PackedScene instantiation during Mesh._init exposed RefCounted exit leakage in actual threaded world reload/native capture. Earlier normal startup/capsule PASS does not accept the later changed adapter; current regression/native/LFS revision2 is required. Binary source/GLB unchanged. Historical receipts preserved.

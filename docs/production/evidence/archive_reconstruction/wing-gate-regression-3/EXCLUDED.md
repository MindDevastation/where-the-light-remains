# Excluded runtime binding adapter

All behavior assertions passed but threaded progression still leaked one RefCounted count0 at exit. Neither SceneState-only runtime reader nor Node child binding resolved it. Current import-only MeshInstance3D root revision4 removes runtime binding scripts and requires new native/LFS evidence. Do not infer precise engine-internal causation from these diagnostics.

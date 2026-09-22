extends SceneTree
## Verifies imported geometry and the authored wrapper; never used in gameplay.

var _meshes: Array[MeshInstance3D] = []


func _initialize() -> void:
    _run.call_deferred()


func _check(condition: bool, message: String) -> bool:
    if not condition:
        push_error("LFS_EXPORT FAIL: " + message)
        quit(1)
    return condition


func _inspect(node: Node) -> bool:
    if not _check(node.get_script() == null, "Art/wrapper must contain no gameplay script"):
        return false
    if node is MeshInstance3D:
        _meshes.append(node)
    for child in node.get_children():
        if not _inspect(child):
            return false
    return true


func _run() -> void:
    var scene: PackedScene = load("res://tests/fixtures/lfs_export_sample.tscn")
    if not _check(scene != null, "Wrapper failed to load"):
        return
    var wrapper: Node3D = scene.instantiate()
    root.add_child(wrapper)
    await process_frame
    if not _inspect(wrapper) or not _check(_meshes.size() == 1, "Expected one imported mesh"):
        return
    var instance: MeshInstance3D = _meshes[0]
    var mesh: Mesh = instance.mesh
    if not _check(mesh != null and mesh.get_surface_count() == 1, "Expected one surface"):
        return
    if not _check(instance.get_active_material(0) != null, "Missing material"):
        return
    var bounds: AABB = instance.global_transform * mesh.get_aabb()
    if not _check(bounds.position.is_equal_approx(Vector3(-0.5, 0.0, -0.5)) and bounds.size.is_equal_approx(Vector3.ONE), "Meter scale/Y-up/bottom pivot mismatch"):
        return
    var arrays: Array = mesh.surface_get_arrays(0)
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
    var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
    if not _check(vertices.size() > 0 and normals.size() == vertices.size() and uvs.size() == vertices.size(), "Missing normals/UVs"):
        return
    for index in vertices.size():
        var normal: Vector3 = (instance.global_basis * normals[index]).normalized()
        var point: Vector3 = instance.global_transform * vertices[index]
        if not _check(is_equal_approx(normals[index].length(), 1.0) and normal.dot(point - Vector3(0, 0.5, 0)) > 0.0, "Invalid/inward normal"):
            return
    wrapper.rotate_y(PI / 2.0)
    bounds = instance.global_transform * mesh.get_aabb()
    if not _check(wrapper.global_position.is_zero_approx() and bounds.position.is_equal_approx(Vector3(-0.5, 0, -0.5)) and bounds.size.is_equal_approx(Vector3.ONE), "Rotation displaced bottom-center pivot"):
        return
    wrapper.queue_free()
    await process_frame
    print("LFS_EXPORT PASS: GLB import; meters; Y-up; bottom-center pivot; normals; UV; one material; script-free wrapper")
    root.get_node("App").call("request_safe_exit")

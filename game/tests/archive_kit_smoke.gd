extends SceneTree
## CLI-only actual geometry/physics gate. Never attached to a production wrapper.

var contract: Dictionary
var triangles_by_module: Dictionary = {}
var surfaces_by_module: Dictionary = {}
var meshes: Array[MeshInstance3D] = []


func _initialize() -> void:
    _run.call_deferred()


func _check(condition: bool, message: String) -> bool:
    if not condition:
        push_error("ARCHIVE_KIT FAIL: " + message)
        quit(1)
    return condition


func _vec(values: Array) -> Vector3:
    return Vector3(values[0], values[1], values[2])


func _inspect(node: Node) -> bool:
    if not _check(node.get_script() == null, "Wrapper/art has a script: " + str(node.name)):
        return false
    if not _check(node is Node3D and not node is Area3D and not node is AnimationPlayer, "Unexpected art/physics node"):
        return false
    if node is MeshInstance3D:
        meshes.append(node)
    for child in node.get_children():
        if not _inspect(child):
            return false
    return true


func _module_path(id: String) -> String:
    return "res://worlds/archive/modules/archive_" + id + ".tscn"


func _geometry(module: Dictionary) -> bool:
    var id: String = module["id"]
    var packed: PackedScene = load(_module_path(id))
    if not _check(packed != null, "Missing wrapper " + id):
        return false
    var instance: Node3D = packed.instantiate()
    root.add_child(instance)
    await process_frame
    meshes.clear()
    if not _inspect(instance) or not _check(meshes.size() == 1 and instance.transform == Transform3D.IDENTITY, "One mesh and identity pivot required: " + id):
        return false
    var art: MeshInstance3D = meshes[0]
    var mesh: Mesh = art.mesh
    var expected_bounds := AABB(_vec(module["bounds_min"]), _vec(module["bounds_max"]) - _vec(module["bounds_min"]))
    var bounds: AABB = art.global_transform * mesh.get_aabb()
    if not _check(bounds.position.distance_to(expected_bounds.position) < 0.001 and bounds.size.distance_to(expected_bounds.size) < 0.001, "Meter axes/envelope mismatch: " + id):
        return false
    if not _check(mesh.get_surface_count() == module["materials"].size(), "Surface ceiling mismatch: " + id):
        return false
    var triangles := 0
    for surface in mesh.get_surface_count():
        var family: String = module["materials"][surface]
        var shared: Material = load(contract["materials"][family])
        if not _check(art.get_active_material(surface) == shared and mesh.surface_get_material(surface) == shared and not shared.resource_local_to_scene, "Embedded/duplicated material instead of shared resource: " + id):
            return false
        var arrays: Array = mesh.surface_get_arrays(surface)
        var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
        var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
        var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
        var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
        var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
        if not _check(vertices.size() > 0 and normals.size() == vertices.size() and uv.size() == vertices.size() and tangents.size() == 4 * vertices.size() and indices.size() % 3 == 0, "Missing geometry/normals/tangents/UV: " + id):
            return false
        triangles += int(indices.size() / 3)
        for index in vertices.size():
            var tangent := Vector3(tangents[index * 4], tangents[index * 4 + 1], tangents[index * 4 + 2])
            if not _check(vertices[index].is_finite() and uv[index].is_finite() and absf(normals[index].length() - 1) < .002 and absf(tangent.length() - 1) < .002 and absf(tangent.dot(normals[index])) < .003, "Invalid imported normals/tangents/UV: " + id):
                return false
        for triangle in int(indices.size() / 3):
            var a: int = indices[triangle * 3]
            var b: int = indices[triangle * 3 + 1]
            var c: int = indices[triangle * 3 + 2]
            var area: float = (vertices[b] - vertices[a]).cross(vertices[c] - vertices[a]).length() / 2
            var ab: Vector2 = uv[b] - uv[a]
            var ac: Vector2 = uv[c] - uv[a]
            var uv_area: float = absf(ab.x * ac.y - ab.y * ac.x) / 2
            if not _check(area > 0.0000000001 and absf(uv_area / area - 1) < .01, "Imported metric UV density/degenerate triangle: " + id):
                return false
    if not _check(triangles <= int(module["triangle_ceiling"]), "Triangle ceiling exceeded: " + id):
        return false
    triangles_by_module[id] = triangles
    surfaces_by_module[id] = mesh.get_surface_count()
    for anchor in module["anchors"]:
        var marker: Marker3D = instance.get_node(String(anchor).capitalize())
        if not _check(marker != null and marker.position.distance_to(_vec(module["anchors"][anchor])) < .001, "Anchor mismatch: " + id):
            return false
    var collision: StaticBody3D = instance.get_node("Collision")
    var expected_shapes := 34 if id == "arch_4m" else 1
    if not _check(collision.get_child_count() == expected_shapes and collision.collision_layer == 1, "Collider shape count/layer: " + id):
        return false
    if id == "arch_4m":
        for child in collision.get_children():
            var shape_node: CollisionShape3D = child
            if not _check(shape_node.shape is BoxShape3D if "Jamb" in child.name else shape_node.shape is ConvexPolygonShape3D, "Arch must use jamb boxes plus segmented convex crown"):
                return false
    for angle in [PI / 2, PI, PI * 1.5]:
        instance.rotation.y = angle
        bounds = art.global_transform * mesh.get_aabb()
        var rotated: AABB = Transform3D(Basis(Vector3.UP, angle), Vector3.ZERO) * expected_bounds
        if not _check(instance.global_position.is_zero_approx() and bounds.position.distance_to(rotated.position) < .001 and bounds.size.distance_to(rotated.size) < .001, "Yaw moved pivot/envelope: " + id):
            return false
    print("ARCHIVE_KIT_GEOMETRY PASS: ", id, "; triangles=", triangles, "; surfaces=", mesh.get_surface_count(), "; external materials; metric UVs; normals/tangents; bounds/pivots/anchors/yaws; script-free")
    instance.queue_free()
    await physics_frame
    await physics_frame
    return true


func _anchors(assembly: Node3D, replacement: bool) -> bool:
    var facade: Node3D = assembly.get_node("Facade")
    var names: Array = ["ShortLeft", "ShortRight", "Bay1", "Bay2"] if replacement else ["Bay0", "Bay1", "Bay2"]
    for index in names.size() - 1:
        var right: Marker3D = facade.get_node(names[index] + "/Right")
        var left: Marker3D = facade.get_node(names[index + 1] + "/Left")
        if not _check(right.global_position.distance_to(left.global_position) < .001, "Facade anchors have a gap"):
            return false
    var floors: Node3D = assembly.get_node("Floors")
    for z in 4:
        for x in 14:
            var index: int = z * 14 + x
            if x < 13:
                if not _check(floors.get_child(index).get_node("Right").global_position.distance_to(floors.get_child(index + 1).get_node("Left").global_position) < .001, "Floor X seam"):
                    return false
            if z < 3:
                if not _check(floors.get_child(index).get_node("Back").global_position.distance_to(floors.get_child(index + 14).get_node("Front").global_position) < .001, "Floor Z seam"):
                    return false
    return true


func _floor_rays(assembly: Node3D) -> bool:
    var exclude: Array[RID] = []
    for group in ["Facade", "Piers"]:
        for module in assembly.get_node(group).get_children():
            exclude.append(module.get_node("Collision").get_rid())
    var samples := 0
    for z in [-1.5, -1.0, -.5, .5, 1.0, 1.5]:
        for i in 27:
            var point: Vector3 = assembly.global_transform * Vector3(-6.5 + i * .5, .1, z)
            var query := PhysicsRayQueryParameters3D.create(point, point - Vector3.UP, 1, exclude)
            var hit: Dictionary = assembly.get_world_3d().direct_space_state.intersect_ray(query)
            if not _check(not hit.is_empty() and absf(hit["position"].y) < .001 and hit["normal"].dot(Vector3.UP) > .999, "Floor ray gap/height at " + str(point)):
                return false
            samples += 1
    print("ARCHIVE_KIT_FLOOR PASS: ", samples, " actual top/seam rays, continuous Y=0")
    return true


func _walk(assembly: Node3D, lane: float) -> bool:
    var body := CharacterBody3D.new()
    body.safe_margin = .001
    body.floor_snap_length = .03
    var shape_node := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.height = contract["sample"]["walk_probe"]["height_m"]
    capsule.radius = contract["sample"]["walk_probe"]["radius_m"]
    shape_node.shape = capsule
    shape_node.position.y = capsule.height / 2
    body.add_child(shape_node)
    root.add_child(body)
    body.global_position = assembly.global_transform * Vector3(lane, .003, -1.5)
    var travel: Vector3 = assembly.global_basis * Vector3(0, 0, 3)
    var minimum := 100.0
    var maximum := -100.0
    for tick in 61:
        await physics_frame
        body.velocity = travel + Vector3(0, -.1 if body.is_on_floor() else -4.0, 0)
        body.move_and_slide()
        minimum = minf(minimum, body.global_position.y)
        maximum = maxf(maximum, body.global_position.y)
        if not _check(absf(body.global_position.y) < .01, "Capsule floor discontinuity"):
            return false
    var position: Vector3 = assembly.global_transform.affine_inverse() * body.global_position
    if not _check(position.z >= 1.5 and absf(position.x - lane) < .01 and body.is_on_floor(), "Capsule stopped/drifted in arch lane " + str(lane) + ": " + str(position)):
        return false
    print("ARCHIVE_KIT_WALK PASS: yaw=", rad_to_deg(assembly.rotation.y), "; lane=", lane, "; final=", position, "; feet_y_range=", minimum, "..", maximum)
    body.queue_free()
    await physics_frame
    return true


func _blockers(assembly: Node3D) -> bool:
    var capsule := CapsuleShape3D.new()
    capsule.height = 1.8
    capsule.radius = .35
    for x in [-4.0, -2.0, -1.6, 1.6, 2.0, 4.0]:
        var query := PhysicsShapeQueryParameters3D.new()
        query.shape = capsule
        query.transform.origin = assembly.global_transform * Vector3(x, .92, -1.5)
        query.motion = assembly.global_basis * Vector3(0, 0, 3)
        var fractions: PackedFloat32Array = assembly.get_world_3d().direct_space_state.cast_motion(query)
        if not _check(fractions.size() == 2 and fractions[0] < .6, "Wall/jamb/pier failed to block capsule at " + str(x)):
            return false
    var start: Vector3 = assembly.global_transform * Vector3(0, 3.8, -1)
    var end: Vector3 = assembly.global_transform * Vector3(0, 3.8, 1)
    var hit: Dictionary = assembly.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start, end))
    if not _check(not hit.is_empty(), "Arch crown collision has a hole"):
        return false
    print("ARCHIVE_KIT_BLOCKERS PASS: six actual capsule sweeps + crown ray; aperture stays open")
    return true


func _run() -> void:
    var path: String = ProjectSettings.globalize_path("res://../docs/production/modular_archive_kit_v1.json")
    contract = JSON.parse_string(FileAccess.get_file_as_string(path))
    if not _check(not contract.is_empty() and contract["version"] == 1, "Approved contract unavailable"):
        return
    for module in contract["modules"]:
        if not await _geometry(module):
            return
    var packed: PackedScene = load("res://tests/fixtures/archive_kit_sample.tscn")
    var assembly: Node3D = packed.instantiate()
    root.add_child(assembly)
    await physics_frame
    await physics_frame
    var total := 56 * int(triangles_by_module["floor_1m"]) + 2 * int(triangles_by_module["wall_4m"]) + int(triangles_by_module["arch_4m"]) + 4 * int(triangles_by_module["pier_4m"])
    if not _check(assembly.get_node("Floors").get_child_count() == 56 and total <= 23568, "Primary assembly count/budget"):
        return
    for degrees in [0, 90, 180, 270]:
        assembly.rotation.y = deg_to_rad(degrees)
        await physics_frame
        await physics_frame
        if not _anchors(assembly, false) or not _floor_rays(assembly) or not _blockers(assembly):
            return
        for lane in [-.75, 0.0, .75]:
            if not await _walk(assembly, lane):
                return
    assembly.rotation.y = 0
    var old: Node = assembly.get_node("Facade/Bay0")
    old.get_parent().remove_child(old)
    old.free()
    for entry in contract["sample"]["replacement_test"]["with"]:
        var short_wall: Node3D = load(_module_path("wall_2m")).instantiate()
        short_wall.name = "ShortLeft" if entry["position"][0] == -5 else "ShortRight"
        assembly.get_node("Facade").add_child(short_wall)
        short_wall.position = _vec(entry["position"])
    await physics_frame
    await physics_frame
    if not _anchors(assembly, true) or not _floor_rays(assembly) or not _blockers(assembly):
        return
    for lane in [-.75, 0.0, .75]:
        if not await _walk(assembly, lane):
            return
    assembly.queue_free()
    await physics_frame
    await physics_frame
    var corner: Node3D = load("res://tests/fixtures/archive_kit_corner.tscn").instantiate()
    root.add_child(corner)
    await physics_frame
    await physics_frame
    if not _check(corner.get_node("Piers").get_child_count() == 1 and corner.get_node("Facade").get_child_count() == 2, "Corner needs one shared pier, two walls"):
        return
    for degrees in [0, 90, 180, 270]:
        corner.rotation.y = deg_to_rad(degrees)
        await physics_frame
        await physics_frame
        var a: Vector3 = corner.get_node("Facade/Bay0/Right").global_position
        var b: Vector3 = corner.get_node("Facade/Bay1/Right").global_position
        var junction: Vector3 = corner.get_node("Piers/Pier0/Junction").global_position
        if not _check(a.distance_to(b) < .001 and a.distance_to(junction) < .001, "Right-angle ownership/anchor gap"):
            return
        var query := PhysicsShapeQueryParameters3D.new()
        var capsule := CapsuleShape3D.new()
        capsule.height = 1.8
        capsule.radius = .35
        query.shape = capsule
        query.transform.origin = corner.global_transform * Vector3(.8, .92, -.8)
        query.motion = corner.global_basis * Vector3(-1.6, 0, 1.6)
        var exclude: Array[RID] = []
        for group in ["Floors", "Facade"]:
            for module in corner.get_node(group).get_children():
                exclude.append(module.get_node("Collision").get_rid())
        query.exclude = exclude
        var fractions: PackedFloat32Array = corner.get_world_3d().direct_space_state.cast_motion(query)
        if not _check(fractions[0] < .6, "Single corner pier fails actual diagonal capsule sweep"):
            return
    print("ARCHIVE_KIT_CORNER PASS: one pier owns actual right-angle join; anchors and isolated pier capsule sweeps pass at four yaws")
    print("ARCHIVE_KIT PASS: five imported modules; primary instances=63; triangles=", total, "; authored_surfaces=68; replacement_triangles=", total - int(triangles_by_module["wall_4m"]) + 2 * int(triangles_by_module["wall_2m"]), "; 15 real capsule traversals; floor continuity; blockers; yaws; material reuse; script-free")
    root.get_node("App").call("request_safe_exit")

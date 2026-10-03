extends SceneTree
## CLI asset contract check; does not implement a puzzle/controller.

var failures := 0
var rays := 0


func _initialize() -> void:
    _run.call_deferred()


func _check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error("WING01_SMOKE FAIL: " + message)


func _meshes(node: Node) -> Array[MeshInstance3D]:
    var result: Array[MeshInstance3D] = []
    if node is MeshInstance3D:
        result.append(node)
    for child in node.get_children():
        result.append_array(_meshes(child))
    return result


func _vector(data: Array) -> Vector3:
    return Vector3(data[0], data[1], data[2])


func _pick(assembly: Node3D, area: Area3D, mask: int = 2) -> void:
    var point := area.global_position
    var front := assembly.global_basis * Vector3(0, 0, -1)
    var query := PhysicsRayQueryParameters3D.create(point + front, point - front * .1, mask)
    query.collide_with_areas = true
    query.collide_with_bodies = mask != 2
    var hit := assembly.get_world_3d().direct_space_state.intersect_ray(query)
    _check(not hit.is_empty() and hit.get("collider") == area, "Actual grip selection: " + str(area.get_meta("component")))
    rays += 1


func _run() -> void:
    # The production JSON is outside the exportable project; this is a repository CLI test.
    var contract: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://") + "../docs/production/wing01_optics_v1.json"))
    _check(not contract.is_empty(), "Versioned repository contract")
    if failures:
        quit(1)
        return
    var packed: PackedScene = load("res://gameplay/puzzles/wing01/wing01_optics_sample.tscn")
    _check(packed != null, "Script-free carrier loads")
    if failures:
        quit(1)
        return
    var assembly: Node3D = packed.instantiate()
    root.add_child(assembly)
    var count := 0
    var surfaces := 0
    for part: Dictionary in contract.parts:
        var pivot: Node3D = assembly.get_node(str(part.id).capitalize())
        _check(pivot.position.is_equal_approx(_vector(part.joint)), "Joint placement: " + str(part.id))
        _check(pivot.scale.is_equal_approx(Vector3.ONE) and pivot.basis.is_equal_approx(Basis.IDENTITY), "Unit unrotated joint")
        _check(pivot.get_script() == null and assembly.get_script() == null, "No gameplay behavior in art carrier")
        var art: Node3D = pivot.get_node("Art")
        _check(art.transform.is_equal_approx(Transform3D.IDENTITY), "Export instance identity")
        var meshes := _meshes(art)
        _check(meshes.size() == 1, "One independently movable mesh per part")
        if meshes.size() != 1:
            continue
        var mesh := meshes[0].mesh
        var triangles := 0
        _check(meshes[0].transform.is_equal_approx(Transform3D.IDENTITY), "Imported mesh identity")
        _check(mesh.get_surface_count() == part.materials.size(), "Authored material surface count")
        for surface in mesh.get_surface_count():
            var material := mesh.surface_get_material(surface)
            _check(material != null and material == load(contract.materials[part.materials[surface]]), "Shared external material identity")
            var data := mesh.surface_get_arrays(surface)
            var positions: PackedVector3Array = data[Mesh.ARRAY_VERTEX]
            var normals: PackedVector3Array = data[Mesh.ARRAY_NORMAL]
            var uv: PackedVector2Array = data[Mesh.ARRAY_TEX_UV]
            var tangents: PackedFloat32Array = data[Mesh.ARRAY_TANGENT]
            var indices: PackedInt32Array = data[Mesh.ARRAY_INDEX]
            _check(positions.size() == normals.size() and positions.size() == uv.size() and tangents.size() == positions.size()*4, "Imported UV/normal/tangent arrays")
            _check(indices.size()%3 == 0, "Imported triangle indices")
            triangles += indices.size()/3
            for normal in normals:
                _check(absf(normal.length()-1)<.002, "Unit imported normal")
        _check(triangles <= part.triangle_ceiling, "Local triangle ceiling")
        count += triangles
        surfaces += mesh.get_surface_count()
        print("WING01_IMPORT PASS: ",part.id,"; triangles=",triangles,"; shared surfaces=",mesh.get_surface_count())
    _check(count == 8636 and surfaces == 16, "Actual approved source totals")
    for yaw in [0.0, PI/2]:
        assembly.rotation.y = yaw
        await physics_frame
        await physics_frame
        for part: Dictionary in contract.parts:
            if part.id == "frame":
                continue
            var pivot: Node3D = assembly.get_node(str(part.id).capitalize())
            var grip: Area3D = pivot.get_node("Grip")
            var original: Transform3D = pivot.transform
            var others := {}
            for child in assembly.get_children():
                if child is Node3D and child != pivot:
                    others[child.name] = child.global_transform
            var mesh := _meshes(pivot.get_node("Art"))[0]
            var witness: Vector3 = mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX][0]
            var poses: Array = contract.focus_test_degrees if part.id == "focus" else contract.ring_test_degrees
            var distinct := []
            for degrees: float in poses:
                pivot.rotation.z = deg_to_rad(degrees)
                await physics_frame
                await physics_frame
                var expected: Vector3 = assembly.to_global(_vector(part.joint) + Basis(Vector3.FORWARD, -deg_to_rad(degrees))*witness)
                _check(mesh.to_global(witness).distance_to(expected)<.0001, "Actual vertex rotates around intended +Z joint")
                _check(pivot.position.is_equal_approx(_vector(part.joint)), "No joint drift")
                for key in others:
                    _check(assembly.get_node(NodePath(key)).global_transform.is_equal_approx(others[key]), "Other parts stay fixed")
                _pick(assembly,grip)
                if degrees == 0:
                    _pick(assembly,grip,3)
                if part.id == "focus":
                    var position := mesh.to_global(witness)
                    for previous: Vector3 in distinct:
                        _check(position.distance_to(previous)>.025, "Five distinct physical focus poses")
                    distinct.append(position)
            pivot.transform = original
            print("WING01_ARTICULATION PASS: ",part.id,"; yaw=",yaw,"; independent poses=",poses.size())
        var query := PhysicsRayQueryParameters3D.create(assembly.to_global(Vector3(0,.3,-2)),assembly.to_global(Vector3(0,.3,2)),1)
        var hit := assembly.get_world_3d().direct_space_state.intersect_ray(query)
        _check(not hit.is_empty() and hit.get("collider") == assembly.get_node("Frame/Collision"), "Actual fixed blocking base")
        query = PhysicsRayQueryParameters3D.create(assembly.to_global(Vector3(0,2.9,-2)),assembly.to_global(Vector3(0,2.9,2)),1)
        _check(assembly.get_world_3d().direct_space_state.intersect_ray(query).is_empty(), "No render-derived whole-envelope collider")
    assembly.queue_free()
    await process_frame
    if failures == 0:
        print("WING01_SMOKE PASS: 8636 triangles / 16 shared surfaces; 40 independent poses; ",rays," actual Area rays; five focus stops; two assembly yaws; primitive blocking")
    quit(0 if failures == 0 else 1)

extends Node
## Imported hero housings, cavity rays and unchanged gameplay ownership in a private fixture.

var _checks := 0
var _failures: Array[String] = []

func _ready() -> void:
    get_tree().create_timer(35.0, true).timeout.connect(func() -> void:
        push_error("ARCHIVE_HEARTH_EMITTER FAIL: timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()

func _check(condition: bool, message: String) -> void:
    _checks += 1
    if not condition:
        _failures.append(message)
        push_error("ARCHIVE_HEARTH_EMITTER FAIL: " + message)

func _model(node: Node3D, low: Vector3, high: Vector3, families: Array[String], triangles: int) -> MeshInstance3D:
    _check(node.transform == Transform3D.IDENTITY and node.get_script() == null and node.find_children("*", "CollisionObject3D", true, false).is_empty(), "Script-free identity visual owns no new collision")
    var parts := node.find_children("*", "MeshInstance3D", true, false)
    _check(parts.size() == 1, "Housing contains exactly one imported mesh")
    if parts.size() != 1:
        return null
    var visual := parts[0] as MeshInstance3D
    var mesh: Mesh = visual.mesh
    var bounds: AABB = node.global_transform.affine_inverse() * visual.global_transform * mesh.get_aabb()
    _check(bounds.position.distance_to(low) < .001 and bounds.size.distance_to(high - low) < .001, "Actual imported meter envelope and pivot")
    var valid := mesh.get_surface_count() == families.size()
    var count := 0
    for s in mesh.get_surface_count():
        if s >= families.size():
            valid = false
            continue
        var material := load("res://art/materials/" + families[s] + ".tres") as Material
        valid = valid and visual.get_active_material(s) == material and mesh.surface_get_material(s) == material and not material.resource_local_to_scene
        var arrays: Array = mesh.surface_get_arrays(s)
        var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
        var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
        var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
        var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
        var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
        var attributes := vertices.size() > 0 and normals.size() == vertices.size() and uv.size() == vertices.size() and tangents.size() == 4 * vertices.size() and indices.size() % 3 == 0
        valid = valid and attributes
        count += int(indices.size() / 3)
        if not attributes:
            continue
        for i in vertices.size():
            var tangent := Vector3(tangents[i * 4], tangents[i * 4 + 1], tangents[i * 4 + 2])
            valid = valid and vertices[i].is_finite() and uv[i].is_finite() and absf(normals[i].length() - 1) < .002 and absf(tangent.length() - 1) < .002 and absf(tangent.dot(normals[i])) < .003
        for t in int(indices.size() / 3):
            var a := indices[t * 3]
            var b := indices[t * 3 + 1]
            var c := indices[t * 3 + 2]
            var area: float = (vertices[b] - vertices[a]).cross(vertices[c] - vertices[a]).length() / 2
            var ab: Vector2 = uv[b] - uv[a]
            var ac: Vector2 = uv[c] - uv[a]
            var uv_area := absf(ab.x * ac.y - ab.y * ac.x) / 2
            valid = valid and area > .0000000001 and absf(uv_area / area - 1) < .01
    _check(valid and count == triangles, "Exact triangles, shared materials, finite metric UVs and unit orthogonal normals/tangents")
    return visual

func _run() -> void:
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var world := preload("res://worlds/archive/archive_main.tscn").instantiate() as ArchiveMain
    add_child(world)
    var saved := SaveGame.new()
    saved.stage_id = ArchiveProgress.WING_ONE
    saved.milestones = {"archive_awakened": true, "wing_01_unlocked": true}
    var prepared := world.prepare_state(saved)
    _check(prepared["error"] == OK, "Existing S02 state prepares")
    _check(world.apply_stage_state(saved.stage_id, prepared["state"]) == OK, "Existing quiet restoration applies")
    await get_tree().physics_frame
    var room := world.get_node("Wing01/Room") as Node3D
    var hearth := room.get_node("Hearth") as StaticBody3D
    var bowl := hearth.get_node("Bowl") as Node3D
    var emitter := room.get_node("Emitter") as Node3D
    var housing := emitter.get_node("Housing") as Node3D
    var bowl_mesh := _model(bowl, Vector3(-.6, -.65, -.6), Vector3(.6, .32, .6), ["m_observatory_stone", "m_aged_brass"], 1208)
    var emitter_mesh := _model(housing, Vector3(-.24, -.2, -.24), Vector3(.24, .175, .24), ["m_aged_brass", "m_dark_iron", "m_clear_glass"], 1204)
    var solid := hearth.get_node("CollisionShape3D").shape as CylinderShape3D
    _check(hearth.position.is_equal_approx(Vector3(-2.8, .65, -24)) and hearth.collision_layer == 1 and hearth.collision_mask == 4 and solid != null and is_equal_approx(solid.radius, .6) and is_equal_approx(solid.height, .65), "Original Hearth body pose and primitive collision remain unchanged")
    _check(not (emitter is MeshInstance3D) and not (bowl is MeshInstance3D), "Old primitive skins are replaced by static authored visuals")
    _check(emitter.position.is_equal_approx(Vector3(0, 1.72, -20)) and is_equal_approx(emitter.rotation.x, PI / 2) and emitter.to_global(Vector3(0, -.2, 0)).distance_to(Vector3(0, 1.72, -20.2)) < .001, "Emitter optical face matches original axis and first beam start")
    var first := room.get_node("BeamSegments/Segment0") as Node3D
    _check(first.to_global(Vector3(0, .5, 0)).distance_to(emitter.to_global(Vector3(0, -.2, 0))) < .001 and room.get_node("Star").position.is_equal_approx(Vector3(0, 1.72, -25.3)), "Existing beam and Star positions stay intact")
    if bowl_mesh != null:
        # A temporary ray-only mesh shape verifies imported cavity geometry; never shipped collision.
        var ray_body := StaticBody3D.new()
        ray_body.collision_layer = 8
        ray_body.collision_mask = 0
        var ray_shape := CollisionShape3D.new()
        ray_shape.shape = bowl_mesh.mesh.create_trimesh_shape()
        ray_body.add_child(ray_shape)
        world.add_child(ray_body)
        ray_body.global_transform = bowl_mesh.global_transform
        await get_tree().physics_frame
        var space := world.get_world_3d().direct_space_state
        var query := PhysicsRayQueryParameters3D.create(hearth.global_position + Vector3(0, 1, 0), hearth.global_position + Vector3(0, -.3, 0), 8)
        var hit := space.intersect_ray(query)
        _check(not hit.is_empty() and hit["collider"] == ray_body and absf(hit["position"].y - .59) < .001 and hit["normal"].y > .9, "Imported bowl has a recessed floor below its open mouth")
        ray_body.queue_free()
    var player := preload("res://core/player/player.tscn").instantiate() as FirstPersonPlayer
    world.add_child(player)
    player.set_physics_process(false)
    await get_tree().physics_frame
    player.global_position = Vector3(-2.8, .02, -22.5)
    var blocked := player.move_and_collide(Vector3(0, 0, -2))
    _check(blocked != null and blocked.get_collider() == hearth, "Original Hearth collider stops the shipping capsule")
    var flame := hearth.get_node("Flame") as MeshInstance3D
    var flame_mesh := flame.mesh as SphereMesh
    _check(flame.position.is_equal_approx(Vector3(0, .55, 0)) and flame_mesh != null and is_equal_approx(flame_mesh.radius, .22) and is_equal_approx(flame_mesh.height, .72) and not flame.visible, "Cold housing does not replace or activate existing Flame")
    var completed := ArchiveProgress.fresh()
    completed["awakened"] = true
    completed["unlocked"][0] = true
    completed["unlocked"][1] = true
    completed["completed"][0] = true
    completed["light_restored"] = true
    completed["star_collected"] = true
    completed["hearth_collected"] = true
    _check(world.apply_stage_state(ArchiveProgress.WING_ONE, completed) == OK and flame.visible and bowl_mesh.is_visible_in_tree() and emitter_mesh.is_visible_in_tree(), "Warm quiet projection restores original Flame with both housings intact")
    _check(world.slice_bindings_valid() and GameState.capture_save().to_dict() == before and SaveManager.get("_dirty") == dirty, "Art preserves puzzle bindings, progression and dirty state")
    world.queue_free()
    await get_tree().process_frame
    if _failures.is_empty():
        print("ARCHIVE_HEARTH_EMITTER PASS: %d assertions" % _checks)
    get_tree().quit(0 if _failures.is_empty() else 1)

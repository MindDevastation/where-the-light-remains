extends Node
## Actual imported book geometry, conservative footprint and retained room routes.

var _checks := 0
var _failures: Array[String] = []

func _ready() -> void:
    _run.call_deferred()

func _check(value: bool, message: String) -> void:
    _checks += 1
    if not value:
        _failures.append(message)
        push_error("ARCHIVE_BOOKCASE FAIL: " + message)

func _run() -> void:
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var world := preload("res://worlds/archive/archive_main.tscn").instantiate() as ArchiveMain
    add_child(world)
    var player := preload("res://core/player/player.tscn").instantiate() as FirstPersonPlayer
    world.add_child(player)
    player.set_physics_process(false)
    var saved := SaveGame.new()
    saved.stage_id = ArchiveProgress.WING_ONE
    saved.milestones = {"archive_awakened":true,"wing_01_unlocked":true}
    var prepared := world.prepare_state(saved)
    _check(prepared["error"] == OK and world.apply_stage_state(saved.stage_id,prepared["state"]) == OK, "Quiet original S02 projection remains valid")
    await get_tree().physics_frame
    await get_tree().physics_frame
    var room := world.get_node("Wing01/Room") as Node3D
    var books := room.get_node("Books") as Node3D
    _check(books.get_child_count() == 4 and books.get_script() == null and books.scale == Vector3.ONE, "Exactly four static unit-scale cases")
    var shared: Mesh
    for side: String in ["Left","Right"]:
        var sign_x := -1.0 if side == "Left" else 1.0
        for index in 2:
            var owner := books.get_node(side+str(index)) as Node3D
            var z := -17.0 if index == 0 else -25.0
            _check(owner.global_position.is_equal_approx(Vector3(sign_x*4.8,0,z)) and owner.scale == Vector3.ONE, "Exact perimeter pose " + str(owner.name))
            _check((owner.global_basis*Vector3(0,0,1)).is_equal_approx(Vector3(-sign_x,0,0)), "Face points into room " + str(owner.name))
            _check(owner.get_script() == null and owner.find_children("*","Light3D",true,false).is_empty(), "No script/light " + str(owner.name))
            var wall := room.get_node("Presentation/Wall"+("L" if side == "Left" else "R")+str(index*2)) as Node3D
            _check(wall.to_local(owner.global_position).is_equal_approx(Vector3(0,0,.2)), "Flush existing side-panel support " + str(owner.name))
            var visuals := owner.get_node("Art").find_children("*","MeshInstance3D",true,false)
            _check(visuals.size() == 1, "One imported static visual " + str(owner.name))
            var visual := visuals[0] as MeshInstance3D
            if shared == null:
                shared = visual.mesh
            _check(visual.mesh == shared and visual.scale == Vector3.ONE and visual.position == Vector3.ZERO, "Shared identity imported resource " + str(owner.name))
            _check(shared.get_aabb().position.is_equal_approx(Vector3(-1.2,0,0)) and shared.get_aabb().end.is_equal_approx(Vector3(1.2,2.55,.42)), "Actual metric bounds " + str(owner.name))
            var body := owner.get_node("Collision") as StaticBody3D
            var shape := owner.get_node("Collision/Footprint") as CollisionShape3D
            _check(body.collision_layer == 1 and body.collision_mask == 1 and (shape.shape as BoxShape3D).size.is_equal_approx(Vector3(2.4,2.55,.42)) and shape.position.is_equal_approx(Vector3(0,1.275,.21)), "Conservative closed-case footprint " + str(owner.name))
            player.global_position = Vector3(sign_x*3.7,.02,z)
            var hit := player.move_and_collide(Vector3(sign_x*1.0,0,0))
            _check(hit != null and owner.is_ancestor_of(hit.get_collider()) and absf(player.global_position.x)<4.2, "Actual capsule stops at new case face " + str(owner.name))
        if side == "Left":
            player.global_position = Vector3(-3.7,.02,-16)
            var original_hit := player.move_and_collide(Vector3(0,0,-10))
            _check(original_hit != null and original_hit.get_collider() == room.get_node("Hearth"), "The first diagnostic lane crosses the inherited Hearth collider, not furniture")
        for direction in [-1.0,1.0]:
            # This retained perimeter lane clears both the old Hearth and the
            # new case face with the actual radius-.35 shipping capsule.
            var start := Vector3(sign_x*4.0,.02,-16 if direction<0 else -26)
            var motion := Vector3(0,0,direction*10)
            player.global_position = start
            var hit := player.move_and_collide(motion)
            _check(hit == null and player.global_position.is_equal_approx(start+motion), "Actual capsule keeps the side passage " + side + ", " + str(direction))
    var expected := [preload("res://art/materials/m_dark_walnut.tres"),preload("res://art/materials/m_aged_brass.tres"),preload("res://art/materials/m_aged_leather.tres"),preload("res://art/materials/m_archive_parchment.tres"),preload("res://art/materials/m_navy_textile.tres"),preload("res://art/materials/m_crimson_textile.tres")]
    _check(shared.get_surface_count() == 6, "Six shared material surfaces")
    var triangles := 0
    for s in shared.get_surface_count():
        _check(shared.surface_get_material(s) == expected[s], "Exact external material mapping " + str(s))
        var arrays := shared.surface_get_arrays(s)
        var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
        var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
        var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
        var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
        var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
        triangles += int(indices.size()/3)
        var valid := vertices.size() == normals.size() and vertices.size() == uv.size() and tangents.size() == vertices.size()*4
        for i in vertices.size():
            var tangent := Vector3(tangents[i*4],tangents[i*4+1],tangents[i*4+2])
            valid = valid and vertices[i].is_finite() and uv[i].is_finite() and absf(normals[i].length()-1)<.001 and absf(tangent.length()-1)<.001 and absf(tangent.dot(normals[i]))<.003
        for i in range(0,indices.size(),3):
            var a := indices[i]
            var b := indices[i+1]
            var c := indices[i+2]
            var area := (vertices[b]-vertices[a]).cross(vertices[c]-vertices[a]).length()/2
            var tex_area := absf((uv[b]-uv[a]).cross(uv[c]-uv[a]))/2
            valid = valid and area>.0000000001 and absf(tex_area/area-1)<.004
        _check(valid, "Actual finite metric arrays and unit shading " + str(s))
    _check(triangles == 4296 and triangles*4 <= 26000, "Measured 4296 triangles/case; 17184 all four")
    var paper := expected[3] as StandardMaterial3D
    _check(paper.albedo_texture == null and paper.roughness_texture == null and paper.normal_texture == null and paper.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and is_equal_approx(paper.roughness,.95), "Reusable MAT-009 opaque paper adds no texture")
    var space := world.get_world_3d().direct_space_state
    var positions: Array[Vector3] = []
    for name: String in ["Star","Hearth"]:
        positions.append((world.get_node("Spawns/"+name) as Node3D).global_position)
    for name: String in ["Outer","Middle","Inner","Focus"]:
        var grip := room.get_node("Rings/Carrier/"+name+"/Grip") as Node3D
        positions.append(Vector3(grip.global_position.x,.02,grip.global_position.z+1.5))
    for position: Vector3 in positions:
        var query := PhysicsShapeQueryParameters3D.new()
        query.shape = (player.get_node("CollisionShape3D") as CollisionShape3D).shape
        query.transform = Transform3D(Basis.IDENTITY,position+Vector3(0,.9,0))
        query.collision_mask = 1
        _check(space.intersect_shape(query,1).is_empty(), "Actual retained checkpoint/grip approach " + str(position))
    _check(world.slice_bindings_valid() and world.get_node("StageController").bindings_valid(), "All original S02/five route bindings remain")
    _check(GameState.capture_save().to_dict() == before and SaveManager.get("_dirty") == dirty, "Furniture does not mutate progression/dirty state")
    world.queue_free()
    await get_tree().process_frame
    if _failures.is_empty():
        print("ARCHIVE_BOOKCASE PASS: %d assertions; 4296 triangles/six shared surfaces per case; four actual capsule-safe perimeter footprints" % _checks)
    get_tree().quit(0 if _failures.is_empty() else 1)

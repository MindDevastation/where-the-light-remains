extends Node
## Imported geometry and actual shipping capsule in the isolated ceiling fixture.

var _checks := 0
var _failures: Array[String] = []

func _ready() -> void:
    _run.call_deferred()

func _check(condition: bool, message: String) -> void:
    _checks += 1
    if not condition:
        _failures.append(message)
        push_error("ARCHIVE_CEILING FAIL: " + message)

func _run() -> void:
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var world := preload("res://tests/fixtures/archive_ceiling_sample.tscn").instantiate() as ArchiveMain
    add_child(world)
    var player := preload("res://core/player/player.tscn").instantiate() as FirstPersonPlayer
    world.add_child(player)
    player.set_physics_process(false)
    var saved := SaveGame.new()
    saved.stage_id = ArchiveProgress.WING_ONE
    saved.milestones = {"archive_awakened": true, "wing_01_unlocked": true}
    var prepared := world.prepare_state(saved)
    _check(prepared["error"] == OK and world.apply_stage_state(saved.stage_id, prepared["state"]) == OK, "Existing S02 state accepts the isolated fixture")
    _check(world.get_node("StageController").open_wing(0, false) == OK, "Existing entrance gate opens quietly")
    await get_tree().physics_frame
    await get_tree().physics_frame
    var study := world.get_node("Wing01/Room/CeilingStudy") as Node3D
    _check(study.position.is_equal_approx(Vector3(0,4,-21)) and study.scale == Vector3.ONE, "Unscaled wall-top assembly origin")
    _check(study.get_child_count() == 3, "Two rib variants plus explicit transition")
    _check(study.find_children("*", "CollisionObject3D", true, false).is_empty(), "Study adds no collision")
    _check(study.find_children("*", "Light3D", true, false).is_empty(), "Study adds no lights")
    var shared := {
        "m_observatory_stone": preload("res://art/materials/m_observatory_stone.tres"),
        "m_dark_iron": preload("res://art/materials/m_dark_iron.tres"),
        "m_aged_brass": preload("res://art/materials/m_aged_brass.tres")
    }
    var total := 0
    for part: Node3D in study.get_children():
        _check(part.scale == Vector3.ONE and part.get_script() == null, "Identity scale and script-free wrapper " + str(part.name))
        var visual := part.get_node("Art").get_child(0) as MeshInstance3D
        _check(visual != null and visual.transform.is_equal_approx(Transform3D.IDENTITY), "Real imported mesh with identity pivot " + str(part.name))
        if visual == null:
            continue
        var box := visual.mesh.get_aabb()
        var bounds_ok := box.position.y >= -.00001 and box.end.y <= 5.64001
        _check(bounds_ok, "Imported geometry stays above wall top and inside its upper envelope " + str(part.name))
        var materials_ok := visual.mesh.get_surface_count() == 3
        var arrays_ok := true
        var triangles := 0
        for surface in visual.mesh.get_surface_count():
            var material := visual.get_active_material(surface)
            materials_ok = materials_ok and material in shared.values() and not material.resource_local_to_scene
            var arrays := visual.mesh.surface_get_arrays(surface)
            var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
            var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
            var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
            var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
            var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
            triangles += indices.size() / 3
            arrays_ok = arrays_ok and vertices.size() > 0 and normals.size() == vertices.size() and uv.size() == vertices.size() and tangents.size() == vertices.size()*4
            if tangents.size() != vertices.size()*4:
                continue
            for i in vertices.size():
                var tangent := Vector3(tangents[i*4],tangents[i*4+1],tangents[i*4+2])
                arrays_ok = arrays_ok and vertices[i].is_finite() and uv[i].is_finite() and absf(normals[i].length()-1)<.002 and absf(tangent.length()-1)<.002 and absf(tangent.dot(normals[i]))<.003
            for t in int(indices.size()/3):
                var a := indices[t*3]
                var b := indices[t*3+1]
                var c := indices[t*3+2]
                var area := (vertices[b]-vertices[a]).cross(vertices[c]-vertices[a]).length()/2
                var ab := uv[b]-uv[a]
                var ac := uv[c]-uv[a]
                var uv_area := absf(ab.x*ac.y-ab.y*ac.x)/2
                arrays_ok = arrays_ok and area > .0000000001 and absf(uv_area/area-1)<.01
        _check(materials_ok, "Exactly three existing shared opaque materials " + str(part.name))
        _check(arrays_ok, "Actual metric UVs, normals and tangents " + str(part.name))
        _check(triangles == (1688 if part.name == "Transition" else 2568), "Measured imported triangle count " + str(part.name))
        total += triangles
        _check(part.get_node("Crown").global_position.is_equal_approx(Vector3(0,9.5,-21)), "All crown connection markers meet " + str(part.name))
    _check(total == 6824, "Whole added sample measures 6824 triangles / nine surfaces")
    for pair in [["Rib10M", Vector3.LEFT*5], ["Rib12M", Vector3.BACK*6]]:
        var part: Node3D = study.get_node(pair[0])
        var foot := part.get_node("FootLeft") as Marker3D
        _check(foot.global_position.is_equal_approx(study.global_position+pair[1]), "Exact rotated wall-top connection " + str(part.name))
        _check(is_equal_approx(part.get_node("SpringLeft").global_position.y,5.5), "Exact spring height " + str(part.name))
    for x in [-.75,0.0,.75]:
        for direction in [-1.0,1.0]:
            player.global_position = Vector3(x,.02,-15-direction*1.5)
            var hit := player.move_and_collide(Vector3(0,0,direction*3))
            _check(hit == null, "Actual capsule crosses the entrance with study, lane/direction " + str(x) + "/" + str(direction))
    for corner in [Vector3(-4,.02,-16),Vector3(4,.02,-16),Vector3(-4,.02,-26),Vector3(4,.02,-26)]:
        player.global_position = corner
        var motion := Vector3(-signf(corner.x),0,1 if corner.z<-21 else -1)
        _check(player.move_and_collide(motion) == null, "Actual capsule clears room corner below infill " + str(corner))
    var feet: Array[Vector3] = []
    for checkpoint in ["Star","Hearth"]:
        feet.append((world.get_node("Spawns/"+checkpoint) as Node3D).global_position)
    for grip_name in ["Outer","Middle","Inner","Focus"]:
        var grip := world.get_node("Wing01/Room/Rings/Carrier/"+grip_name+"/Grip") as Node3D
        feet.append(Vector3(grip.global_position.x,.004,grip.global_position.z+1.5))
    for approach: Vector3 in feet:
        var query := PhysicsShapeQueryParameters3D.new()
        query.shape = player.get_node("CollisionShape3D").shape
        query.transform = Transform3D(Basis.IDENTITY,approach+Vector3(0,.9,0))
        query.collision_mask = 1
        _check(world.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty(), "Actual shipping capsule clears preserved checkpoint/grip approach " + str(approach))
    _check(world.slice_bindings_valid(), "Existing puzzle bindings remain valid in fixture")
    _check(GameState.capture_save().to_dict() == before and SaveManager.get("_dirty") == dirty, "Geometry/physics review preserves state and save dirty flag")
    world.queue_free()
    await get_tree().process_frame
    if _failures.is_empty():
        print("ARCHIVE_CEILING PASS: %d imported geometry/anchor/capsule/state assertions; 6824 added triangles / 9 surfaces" % _checks)
    get_tree().quit(0 if _failures.is_empty() else 1)

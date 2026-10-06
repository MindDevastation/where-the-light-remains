extends Node
## Actual imported roof rays, arrays, materials and preserved shipping capsule.

var _checks := 0
var _failures: Array[String] = []
var _world_scene: PackedScene = preload("res://tests/fixtures/archive_dome_sample.tscn")
var _dome_path: NodePath = ^"Wing01/Room/DomeCoverage"
var _marker := "ARCHIVE_DOME"

func _ready() -> void:
    _run.call_deferred()

func _check(condition: bool, message: String) -> void:
    _checks += 1
    if not condition:
        _failures.append(message)
        push_error(_marker + " FAIL: " + message)

func _inspect_world(_world: ArchiveMain, _dome: Node3D) -> void:
    pass

func _run() -> void:
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var world := _world_scene.instantiate() as ArchiveMain
    add_child(world)
    var player := preload("res://core/player/player.tscn").instantiate() as FirstPersonPlayer
    world.add_child(player)
    player.set_physics_process(false)
    var saved := SaveGame.new()
    saved.stage_id = ArchiveProgress.WING_ONE
    saved.milestones = {"archive_awakened": true, "wing_01_unlocked": true}
    var prepared := world.prepare_state(saved)
    _check(prepared["error"] == OK and world.apply_stage_state(saved.stage_id,prepared["state"]) == OK,
        "Existing S02 state accepts the isolated dome")
    _check(world.get_node("StageController").open_wing(0,false) == OK, "Original entrance gate opens quietly")
    await get_tree().physics_frame
    await get_tree().physics_frame
    var dome := world.get_node(_dome_path) as Node3D
    _inspect_world(world,dome)
    _check(dome.global_position.is_equal_approx(Vector3(0,4,-21)) and dome.scale == Vector3.ONE, "Unscaled wall-top pivot")
    _check(dome.get_node("Crown").global_position.is_equal_approx(Vector3(0,9.5,-21)), "Accepted crown connection")
    _check(dome.get_node("Spring").global_position.is_equal_approx(Vector3(0,5.5,-21)), "Accepted spring connection")
    for type_name in ["CollisionObject3D","Light3D","WorldEnvironment"]:
        _check(dome.find_children("*",type_name,true,false).is_empty(), "Dome adds no " + type_name)
    var shared := {
        "Frame": [preload("res://art/materials/m_dark_iron.tres"),preload("res://art/materials/m_aged_brass.tres")],
        "Glass": [preload("res://art/materials/m_clear_glass.tres")],
        "Sky": [preload("res://art/materials/m_archive_night_sky.tres")]
    }
    var counts := {"Frame":10944,"Glass":4608,"Sky":4608}
    var limits := {"Frame":AABB(Vector3(-5.13,1.37,-6.13),Vector3(10.26,4.26,12.26)),
        "Glass":AABB(Vector3(-5.12,1.5,-6.12),Vector3(10.24,4.12,12.24)),
        "Sky":AABB(Vector3(-5.47,1.48,-6.47),Vector3(10.94,4.52,12.94))}
    var trees: Dictionary = {}
    var total := 0
    for part_name: String in ["Frame","Glass","Sky"]:
        var part := dome.get_node(part_name) as Node3D
        var visual := part.get_node("Art").get_child(0) as MeshInstance3D
        _check(part.scale == Vector3.ONE and part.get_script() == null, "Static script-free wrapper " + part_name)
        _check(visual != null and visual.transform.is_equal_approx(Transform3D.IDENTITY), "Actual identity mesh " + part_name)
        if visual == null:
            continue
        _check((limits[part_name] as AABB).grow(.0001).encloses(visual.mesh.get_aabb()), "Actual bounded geometry " + part_name)
        _check(visual.cast_shadow == (GeometryInstance3D.SHADOW_CASTING_SETTING_ON if part_name == "Frame" else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF), "Explicit opaque-only shadow scope " + part_name)
        var materials_ok: bool = visual.mesh.get_surface_count() == shared[part_name].size()
        var arrays_ok := true
        var triangles := 0
        for surface in visual.mesh.get_surface_count():
            var material := visual.get_active_material(surface)
            materials_ok = materials_ok and material == shared[part_name][surface] and not material.resource_local_to_scene
            var arrays := visual.mesh.surface_get_arrays(surface)
            var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
            var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
            var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
            var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
            var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
            triangles += int(indices.size()/3)
            arrays_ok = arrays_ok and not vertices.is_empty() and normals.size() == vertices.size() and uv.size() == vertices.size() and tangents.size() == vertices.size()*4
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
                arrays_ok = arrays_ok and area>.0000000001 and absf(uv_area/area-1)<.01
        _check(materials_ok, "Exact external shared material mapping " + part_name)
        _check(arrays_ok, "Actual metric UVs and unit normals/tangents " + part_name)
        _check(triangles == counts[part_name], "Measured imported triangle count " + part_name)
        total += triangles
        trees[part_name] = visual.mesh.generate_triangle_mesh()
    _check(total == 20160, "20160 new triangles / four surfaces")
    var glass := shared["Glass"][0] as StandardMaterial3D
    _check(glass.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA and glass.cull_mode == BaseMaterial3D.CULL_BACK,
        "Single shared transparent shell with backface culling")
    var origin := Vector3(0,1.6,0)
    var directions: Array[Vector3] = [Vector3.UP]
    for height in [.25,.75,1.5]:
        for i in 16:
            var angle := (i+.5)*TAU/16
            directions.append(Vector3(cos(angle),height,sin(angle)))
    for direction: Vector3 in directions:
        var ray := direction.normalized()
        var front: Dictionary = (trees["Glass"] as TriangleMesh).intersect_ray(origin,ray)
        var back: Dictionary = (trees["Sky"] as TriangleMesh).intersect_ray(origin,ray)
        var covered := not front.is_empty() and not back.is_empty()
        if covered:
            covered = origin.distance_to(front["position"])+.12 < origin.distance_to(back["position"])
            covered = covered and (front["normal"] as Vector3).dot(ray)<0 and (back["normal"] as Vector3).dot(ray)<0
        _check(covered, "Actual imported interior roof ray, farther opaque sky " + str(direction))
    for lane in [-.75,0.0,.75]:
        for direction in [-1.0,1.0]:
            player.global_position = Vector3(lane,.02,-15-direction*1.5)
            _check(player.move_and_collide(Vector3(0,0,direction*3)) == null, "Shipping capsule entrance lane/direction " + str(lane) + "/" + str(direction))
    for corner in [Vector3(-4,.02,-16),Vector3(4,.02,-16),Vector3(-4,.02,-26),Vector3(4,.02,-26)]:
        player.global_position = corner
        var motion := Vector3(-signf(corner.x),0,1 if corner.z<-21 else -1)
        _check(player.move_and_collide(motion) == null, "Shipping capsule clears corner " + str(corner))
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
        _check(world.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty(), "Shipping capsule clears puzzle approach " + str(approach))
    _check(world.slice_bindings_valid(), "Original puzzle bindings remain valid")
    _check(GameState.capture_save().to_dict() == before and SaveManager.get("_dirty") == dirty, "Review preserves state/dirty flag")
    world.queue_free()
    await get_tree().process_frame
    if _failures.is_empty():
        print(_marker + " PASS: %d imported geometry/roof-ray/material/capsule/state assertions; 20160 new triangles / four surfaces" % _checks)
    get_tree().quit(0 if _failures.is_empty() else 1)

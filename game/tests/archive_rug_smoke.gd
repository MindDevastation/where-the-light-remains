extends Node
## Imported cloth bounds, measured floor separation and real capsule traversals.

var _checks := 0
var _failures: Array[String] = []

func _ready() -> void:
    _run.call_deferred()

func _check(value: bool, message: String) -> void:
    _checks += 1
    if not value:
        _failures.append(message)
        push_error("ARCHIVE_RUG FAIL: " + message)

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
    _check(prepared["error"] == OK and world.apply_stage_state(saved.stage_id,prepared["state"]) == OK, "Quiet original S02 projection")
    await get_tree().physics_frame
    await get_tree().physics_frame
    var room := world.get_node("Wing01/Room") as Node3D
    var rug := room.get_node("Rug") as Node3D
    _check(rug.global_position.is_equal_approx(Vector3(0,.010,-21.4)) and rug.scale == Vector3.ONE and rug.rotation == Vector3.ZERO, "Unit centered room placement")
    _check(rug.get_script() == null and rug.find_children("*","CollisionObject3D",true,false).is_empty() and rug.find_children("*","Light3D",true,false).is_empty(), "Cosmetic cloth has no collider, light or script")
    var visuals := rug.get_node("Art").find_children("*","MeshInstance3D",true,false)
    _check(visuals.size() == 1, "One actual imported static mesh")
    var visual := visuals[0] as MeshInstance3D
    var mesh := visual.mesh
    _check(visual.position == Vector3.ZERO and visual.scale == Vector3.ONE, "Identity imported visual")
    _check(mesh.get_aabb().position.is_equal_approx(Vector3(-1.3,-.004,-2)) and mesh.get_aabb().end.is_equal_approx(Vector3(1.3,.004,2)), "Actual 2.6 by 4m footprint, 8mm cloth thickness")
    var expected := [preload("res://art/materials/m_navy_textile.tres"),preload("res://art/materials/m_crimson_textile.tres")]
    _check(mesh.get_surface_count() == 2, "Two existing shared textile surfaces")
    var triangles := 0
    for s in mesh.get_surface_count():
        _check(mesh.surface_get_material(s) == expected[s], "Exact shared material identity " + str(s))
        var arrays := mesh.surface_get_arrays(s)
        var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
        var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
        var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
        var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
        var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
        triangles += int(indices.size()/3)
        var valid := vertices.size() == normals.size() and vertices.size() == uv.size() and tangents.size() == vertices.size()*4
        for i in vertices.size():
            var tangent := Vector3(tangents[i*4],tangents[i*4+1],tangents[i*4+2])
            valid = valid and vertices[i].is_finite() and normals[i].is_finite() and uv[i].is_finite() and absf(normals[i].length()-1)<.001 and absf(tangent.length()-1)<.001 and absf(tangent.dot(normals[i]))<.003
        for i in range(0,indices.size(),3):
            var a := indices[i]
            var b := indices[i+1]
            var c := indices[i+2]
            var area := (vertices[b]-vertices[a]).cross(vertices[c]-vertices[a]).length()/2
            var tex_area := absf((uv[b]-uv[a]).cross(uv[c]-uv[a]))/2
            valid = valid and area > .0000000001 and absf(tex_area/area-1)<.004
        _check(valid, "Finite nondegenerate arrays, unit shading and metric UVs " + str(s))
    _check(triangles == 44, "Measured 44 triangles")
    var tiles := room.get_node("TileFloor") as Node3D
    var tile_top := -INF
    for tile: MeshInstance3D in tiles.find_children("*","MeshInstance3D",true,false):
        tile_top = maxf(tile_top,(tile.global_transform * tile.mesh.get_aabb().end).y)
    var bottom := (visual.global_transform * mesh.get_aabb().position).y
    var top := (visual.global_transform * mesh.get_aabb().end).y
    _check(is_equal_approx(tile_top,0) and is_equal_approx(bottom-tile_top,.006) and is_equal_approx(top-tile_top,.014), "Measured 6mm tile gap and 14mm cosmetic top")
    var space := world.get_world_3d().direct_space_state
    var slab := room.get_node("RoomFloor") as StaticBody3D
    var excluded: Array[RID] = []
    for body: CollisionObject3D in world.find_children("*","CollisionObject3D",true,false):
        if body != slab:
            excluded.append(body.get_rid())
    for point in [Vector3(-.8,.1,-20),Vector3(.8,.1,-20),Vector3(-.8,.1,-22.8),Vector3(.8,.1,-22.8)]:
        var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(point,point-Vector3(0,.3,0),1,excluded))
        _check(not hit.is_empty() and hit["collider"] == slab and absf(hit["position"].y)<.0001, "Original floor remains under cloth " + str(point))
    for direction in [-1.0,1.0]:
        var start := Vector3(-2 if direction>0 else 2,.02,-20)
        var motion := Vector3(direction*4,0,0)
        player.global_position = start
        var hit := player.move_and_collide(motion)
        _check(hit == null and player.global_position.is_equal_approx(start+motion), "Actual capsule crosses both rug edges " + str(direction))
    for x in [-1.7,1.7]:
        for direction in [-1.0,1.0]:
            var start := Vector3(x,.02,-18.8 if direction<0 else -24)
            var motion := Vector3(0,0,direction*5.2)
            player.global_position = start
            var hit := player.move_and_collide(motion)
            _check(hit == null and player.global_position.is_equal_approx(start+motion), "Actual longitudinal passage beside the optical pedestal " + str(x) + ", " + str(direction))
    _check(world.slice_bindings_valid() and world.get_node("StageController").bindings_valid(), "Original puzzle and route bindings")
    _check(GameState.capture_save().to_dict() == before and SaveManager.get("_dirty") == dirty, "Decoration leaves progression and dirty state unchanged")
    world.queue_free()
    await get_tree().process_frame
    if _failures.is_empty():
        print("ARCHIVE_RUG PASS: %d assertions; actual floor gap and capsule paths; 44 imported triangles" % _checks)
    get_tree().quit(0 if _failures.is_empty() else 1)

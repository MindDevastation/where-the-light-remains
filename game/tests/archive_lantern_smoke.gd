extends Node
## Reopened-source GLB arrays, wall mounting, bounded light spheres and quiet state.

var _checks := 0
var _failures: Array[String] = []

func _ready() -> void:
    _run.call_deferred()

func _check(value: bool, message: String) -> void:
    _checks += 1
    if not value:
        _failures.append(message)
        push_error("ARCHIVE_LANTERN FAIL: " + message)

func _run() -> void:
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var world := preload("res://worlds/archive/archive_main.tscn").instantiate() as ArchiveMain
    add_child(world)
    var saved := SaveGame.new()
    saved.stage_id = ArchiveProgress.WING_ONE
    saved.milestones = {"archive_awakened":true,"wing_01_unlocked":true}
    var prepared := world.prepare_state(saved)
    _check(prepared["error"] == OK and world.apply_stage_state(saved.stage_id,prepared["state"]) == OK, "Original quiet S02 projection accepts local practicals")
    await get_tree().physics_frame
    var room := world.get_node("Wing01/Room") as Node3D
    var group := room.get_node("Practicals") as Node3D
    _check(group.get_child_count() == 2 and group.scale == Vector3.ONE and group.get_script() == null, "Exactly two static unit-scale practicals")
    var shared: Mesh
    for name: String in ["Left","Right"]:
        var sign_x := -1.0 if name == "Left" else 1.0
        var owner := group.get_node(name) as Node3D
        _check(owner.global_position.is_equal_approx(Vector3(sign_x*4.8,2.8,-21)) and owner.scale == Vector3.ONE, "Metric wall pose " + name)
        _check((owner.global_basis*Vector3(0,0,1)).is_equal_approx(Vector3(-sign_x,0,0)), "Fixture faces into room " + name)
        _check(owner.get_script() == null and owner.find_children("*","CollisionObject3D",true,false).is_empty(), "No script or collision " + name)
        var wall := room.get_node("Presentation/Wall"+("L1" if name == "Left" else "R1")) as Node3D
        _check(wall.to_local(owner.global_position).is_equal_approx(Vector3(0,2.8,.2)), "Mounting on existing side panel center and face " + name)
        var meshes := owner.get_node("Art").find_children("*","MeshInstance3D",true,false)
        _check(meshes.size() == 1, "One imported static mesh " + name)
        var visual := meshes[0] as MeshInstance3D
        _check(visual.scale == Vector3.ONE and visual.position == Vector3.ZERO and visual.mesh.get_surface_count() == 4, "Identity imported geometry and four surfaces " + name)
        if shared == null:
            shared = visual.mesh
        _check(visual.mesh == shared, "Both instances share one imported resource " + name)
        var bounds := visual.mesh.get_aabb()
        _check(bounds.position.is_equal_approx(Vector3(-.18,-.232,0)) and bounds.end.is_equal_approx(Vector3(.18,.314,.37)), "Measured actual GLB bounds " + name)
        _check(owner.global_position.y+bounds.position.y>2.48, "Bottom above shipping player head clearance " + name)
        var query := PhysicsRayQueryParameters3D.create(owner.to_global(Vector3(0,0,.2)),owner.to_global(Vector3(0,0,-.1)),1)
        var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
        _check(not hit.is_empty() and wall.is_ancestor_of(hit["collider"]) and (hit["position"] as Vector3).distance_to(owner.global_position)<.001, "Actual existing collision face supports wall mount " + name)
        var light := owner.get_node("Practical") as OmniLight3D
        _check(light.position == Vector3(0,0,.23) and is_equal_approx(light.omni_range,3) and is_equal_approx(light.light_energy,1.25), "Declared local range/energy budget " + name)
        _check(not light.shadow_enabled and is_equal_approx(light.light_specular,.1) and light.light_color == Color(1,.55,.24,1), "Warm practical with no shadow pass and restrained specular " + name)
        _check(light.global_position.distance_to(Vector3(0,2.8,-15))>light.omni_range and light.global_position.distance_to(Vector3(0,2.8,-6))>light.omni_range, "Light sphere excludes doorway and Hub " + name)
    var expected := [preload("res://art/materials/m_dark_iron.tres"),preload("res://art/materials/m_aged_brass.tres"),preload("res://art/materials/m_clear_glass.tres"),preload("res://art/materials/m_archive_emissive_gold.tres")]
    var total := 0
    for s in shared.get_surface_count():
        _check(shared.surface_get_material(s) == expected[s], "Exact shared external material mapping " + str(s))
        var arrays := shared.surface_get_arrays(s)
        var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
        var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
        var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
        var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
        var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
        total += int(indices.size()/3)
        var valid := vertices.size() == normals.size() and vertices.size() == uv.size() and tangents.size() == vertices.size()*4
        for i in vertices.size():
            valid = valid and vertices[i].is_finite() and normals[i].is_finite() and uv[i].is_finite() and absf(normals[i].length()-1)<.001
        for i in range(0,indices.size(),3):
            var a := indices[i]
            var b := indices[i+1]
            var c := indices[i+2]
            var area := (vertices[b]-vertices[a]).cross(vertices[c]-vertices[a]).length()/2
            var tex_area := absf((uv[b]-uv[a]).cross(uv[c]-uv[a]))/2
            valid = valid and area>.0000000001 and absf(tex_area/area-1)<.004
        _check(valid, "Actual finite imported arrays/nondegenerate metric UVs " + str(s))
    _check(total == 708 and total*2 <= 2400, "Measured 708 triangles per fixture, 1416 both")
    var main_light := room.get_node("RoomLight") as OmniLight3D
    _check(main_light.light_color == Color(.43,.65,1,1) and is_equal_approx(main_light.light_energy,2.5) and is_equal_approx(main_light.omni_range,9), "Original cold RoomLight unchanged")
    _check(world.slice_bindings_valid() and world.get_node("StageController").bindings_valid(), "Original S02 and five routes remain bound")
    _check(GameState.capture_save().to_dict() == before and SaveManager.get("_dirty") == dirty, "Presentation does not mutate state or dirty flag")
    world.queue_free()
    await get_tree().process_frame
    if _failures.is_empty():
        print("ARCHIVE_LANTERN PASS: %d assertions; 708 triangles/four reused surfaces each; two local shadow-free practicals" % _checks)
    get_tree().quit(0 if _failures.is_empty() else 1)

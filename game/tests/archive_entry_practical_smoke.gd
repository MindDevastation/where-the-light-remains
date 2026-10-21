extends Node

var _checks := 0
var _failures: Array[String] = []

func _ready() -> void:
    _run.call_deferred()

func _check(value: bool, message: String) -> void:
    _checks += 1
    if not value:
        _failures.append(message)
        push_error("ARCHIVE_ENTRY_PRACTICAL FAIL: " + message)

func _run() -> void:
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var world := preload("res://worlds/archive/archive_main.tscn").instantiate() as ArchiveMain
    add_child(world)
    await get_tree().physics_frame
    var wall := world.get_node("Hub/Wall3R") as StaticBody3D
    var fixture := wall.get_node("EntryPractical") as Node3D
    var shape := wall.get_node("CollisionShape3D").shape as BoxShape3D
    _check(shape.size.is_equal_approx(Vector3(2.258,4.8,.35)) and wall.position.is_equal_approx(Vector3(2.4139,2.4,8.1347)), "Unchanged existing wall contract")
    _check(fixture.position.is_equal_approx(Vector3(.72,.35,-.175)) and absf(fixture.rotation.y-PI)<.00001 and fixture.scale==Vector3.ONE and fixture.get_script()==null, "Exact fixed exterior face pivot")
    _check(fixture.find_children("*","CollisionObject3D",true,false).is_empty(), "No new player collider")
    var visual := fixture.find_children("*","MeshInstance3D",true,false)[0] as MeshInstance3D
    _check(visual.mesh.get_surface_count()==4, "Four original imported material surfaces")
    var materials := [preload("res://art/materials/m_dark_iron.tres"),preload("res://art/materials/m_aged_brass.tres"),preload("res://art/materials/m_clear_glass.tres"),preload("res://art/materials/m_archive_emissive_gold.tres")]
    var min_y := INF
    var max_z := -INF
    var face_valid := true
    var min_face_z := INF
    for surface in visual.mesh.get_surface_count():
        _check(visual.mesh.surface_get_material(surface)==materials[surface], "Original shared material identity "+str(surface))
        for point: Vector3 in visual.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
            var w := visual.global_transform*point
            var local := wall.to_local(w)
            min_y=minf(min_y,w.y)
            max_z=maxf(max_z,w.z)
            min_face_z=minf(min_face_z,-local.z-shape.size.z/2)
            face_valid=face_valid and absf(local.x)<shape.size.x/2 and absf(local.y)<shape.size.y/2 and local.z<=-.175+.00001
    _check(face_valid and absf(min_face_z)<.00001, "Actual source vertices fit the original wall face, backing touches face")
    _check(min_y>1.8 and max_z<9.275, "Actual fixture clears capsule height and entire sliding door sweep")
    var light := fixture.get_node("Practical") as OmniLight3D
    _check(light.light_color.is_equal_approx(Color(1,.55,.24,1)) and is_equal_approx(light.light_energy,1.25) and is_equal_approx(light.omni_range,3) and not light.shadow_enabled and is_equal_approx(light.light_specular,.1), "Original accepted warm shadow-free light contract")
    _check(light.global_position.distance_to(Vector3(0,.7,0))>light.omni_range+1 and light.global_position.z-light.omni_range>0, "Local light cannot reach core or Wing I")
    # The accepted exterior and original S02 family have three practicals.
    # Interior Hub fixtures are checked by archive_practical_lighting_smoke.
    var lights := fixture.find_children("*","OmniLight3D",true,false)
    lights.append_array(world.get_node("Wing01/Room/Practicals").find_children("*","OmniLight3D",true,false))
    var lanterns := 0
    for candidate in lights:
        if candidate.name=="Practical":
            lanterns+=1
    _check(lanterns==3, "One entry practical plus two retained Wing I practicals")
    _check(world.slice_bindings_valid() and GameState.capture_save().to_dict()==before and SaveManager.get("_dirty")==dirty, "Original bindings and read-only progression/dirty state")
    world.queue_free()
    await get_tree().process_frame
    if _failures.is_empty():
        print("ARCHIVE_ENTRY_PRACTICAL PASS: %d assertions; actual fixed face, vertex/door/capsule clearance, original materials and local warm light" % _checks)
    get_tree().quit(0 if _failures.is_empty() else 1)

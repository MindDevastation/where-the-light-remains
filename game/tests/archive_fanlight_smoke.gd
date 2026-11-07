extends Node
## Actual imported static header and every original rotated gate/ghost sweep.

var _checks := 0
var _failures: Array[String] = []

func _check(value: bool, message: String) -> void:
    _checks += 1
    if not value:
        _failures.append(message)
        push_error("ARCHIVE_FANLIGHT FAIL: "+message)

func _ready() -> void:
    get_tree().create_timer(25.0,true).timeout.connect(func() -> void:
        push_error("ARCHIVE_FANLIGHT timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()

func _run() -> void:
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var world := preload("res://worlds/archive/archive_main.tscn").instantiate() as ArchiveMain
    add_child(world)
    world.set_process(false)
    world.get_node("Prologue").set_process(false)
    await get_tree().physics_frame
    var shared: Mesh
    for i in range(1,6):
        var route := world.get_node("Routes/Wing%02d"%i) as Node3D
        var gate := route.get_node("Gate") as ArchiveGate
        var window := route.get_node("ArchedFanlight") as Node3D
        _check(window.position==gate.position and window.rotation==Vector3.ZERO and window.scale==Vector3.ONE, "Same fixed gate pivot/route transform "+str(i))
        _check(window.find_children("*","CollisionObject3D",true,false).is_empty() and window.find_children("*","Light3D",true,false).is_empty() and window.get_script()==null, "Static noninteractive/light-free header "+str(i))
        var visuals := window.find_children("*","MeshInstance3D",true,false)
        _check(visuals.size()==1, "Single original imported static mesh "+str(i))
        var visual := visuals[0] as MeshInstance3D
        if shared==null: shared=visual.mesh
        _check(visual.mesh==shared and visual.position==Vector3.ZERO and visual.scale==Vector3.ONE and visual.rotation==Vector3.ZERO, "Five exact unit shared resources "+str(i))
        var bounds := shared.get_aabb()
        _check(bounds.position.is_equal_approx(Vector3(-1.70,3.22,.176)) and bounds.end.is_equal_approx(Vector3(1.70,4.78,.276)), "Actual imported original header bounds "+str(i))
        _check(bounds.position.y>3.20+.019 and bounds.end.y<4.80-.019, "Passage and accepted drum/lintel gaps "+str(i))
        var body := gate.get_node("Barrier") as StaticBody3D
        var old := body.get_node("Mesh") as MeshInstance3D
        var old_max_z := body.position.z+old.position.z+old.mesh.get_aabb().end.z
        _check(bounds.position.z-old_max_z>.056, "Actual gate depth separated for entire upward sweep "+str(i))
        _check(gate.opening_height==3.3 and is_equal_approx(gate.opening_duration,.45) and gate.bindings_valid(), "Original opening contract/bindings "+str(i))
        _check(gate.apply_state(ArchiveGate.Status.OPEN,true)==OK, "Original live ghost starts "+str(i))
        await get_tree().physics_frame
        await get_tree().physics_frame
        var ghost := gate.get_node_or_null("OpeningVisual") as MeshInstance3D
        _check(ghost!=null and ghost.mesh==old.mesh and ghost.position.z+ghost.mesh.get_aabb().end.z<bounds.position.z-.056, "Live rotated opening ghost still separated "+str(i))
        var ray := PhysicsRayQueryParameters3D.create(gate.to_global(Vector3(0,1.6,.8)),gate.to_global(Vector3(0,1.6,-.8)),1)
        _check(world.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(), "Original capsule-height aperture remains open "+str(i))
        _check(gate.apply_state(ArchiveGate.Status.DORMANT,false)==OK and not gate.animation_running, "Quiet reset leaves static header and no replay "+str(i))
    var expected := [preload("res://art/materials/m_observatory_stone.tres"),preload("res://art/materials/m_dark_iron.tres"),preload("res://art/materials/m_aged_brass.tres"),preload("res://art/materials/m_clear_glass.tres")]
    _check(shared.get_surface_count()==4, "Exactly four existing material surfaces")
    var triangles := 0
    for s in shared.get_surface_count():
        _check(shared.surface_get_material(s)==expected[s], "Exact external material mapping "+str(s))
        var arrays := shared.surface_get_arrays(s)
        var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
        var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
        var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
        var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
        var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
        triangles+=int(indices.size()/3)
        var valid := vertices.size()==normals.size() and vertices.size()==uv.size() and tangents.size()==vertices.size()*4
        for i in vertices.size():
            valid=valid and vertices[i].is_finite() and normals[i].is_finite() and uv[i].is_finite() and absf(normals[i].length()-1)<.001
            var tangent := Vector3(tangents[i*4],tangents[i*4+1],tangents[i*4+2])
            valid=valid and tangent.is_finite() and absf(tangent.length()-1)<.001 and absf(tangent.dot(normals[i]))<.001
        for i in range(0,indices.size(),3):
            var a := indices[i]
            var b := indices[i+1]
            var d := indices[i+2]
            var area := (vertices[b]-vertices[a]).cross(vertices[d]-vertices[a]).length()/2
            var tex_area := absf((uv[b]-uv[a]).cross(uv[d]-uv[a]))/2
            valid=valid and area>.0000000001 and absf(tex_area/area-1)<.004
        _check(valid, "Finite unit shading/nondegenerate metric UV arrays "+str(s))
    _check(triangles==1560 and triangles*5<=17500, "Measured1560 triangles/shared master7800 five instances")
    _check(world.slice_bindings_valid() and world.get_node("StageController").bindings_valid(), "Original puzzles/five routes remain bound")
    _check(GameState.capture_save().to_dict()==before and SaveManager.get("_dirty")==dirty, "No progress/dirty side effect")
    world.queue_free()
    await get_tree().process_frame
    if _failures.is_empty():
        print("ARCHIVE_FANLIGHT PASS: %d assertions; original1560tri/four materials/five headers; actual metric arrays, rotated ghost/passages and quiet read-only projection"%_checks)
    get_tree().quit(0 if _failures.is_empty() else 1)

extends Node
## Actual shared beam arrays, controller visibility and pausable canonical Star.

var _checks := 0
var _failures: Array[String] = []

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _run.call_deferred()

func _check(value: bool, message: String) -> void:
    _checks += 1
    if not value:
        _failures.append(message)
        push_error("ARCHIVE_BEAM_STAR FAIL: " + message)

func _run() -> void:
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var world := preload("res://worlds/archive/archive_main.tscn").instantiate() as ArchiveMain
    add_child(world)
    var saved := SaveGame.new()
    saved.stage_id = ArchiveProgress.WING_ONE
    saved.milestones = {"archive_awakened":true,"wing_01_unlocked":true}
    var prepared := world.prepare_state(saved)
    _check(prepared["error"] == OK and world.apply_stage_state(saved.stage_id,prepared["state"]) == OK, "Quiet original S02 projection accepts presentation")
    var room := world.get_node("Wing01/Room") as Node3D
    var core := preload("res://art/vfx/archive_beam_core_mesh.tres")
    var halo := preload("res://art/vfx/archive_beam_halo_mesh.tres")
    var core_material := preload("res://art/materials/m_archive_beam_core.tres")
    var halo_material := preload("res://art/materials/m_archive_beam_halo.tres")
    for mesh: ArrayMesh in [core,halo]:
        var arrays := mesh.surface_get_arrays(0)
        var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
        var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
        var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
        var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
        var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
        var valid := vertices.size() == normals.size() and uv.size() == vertices.size() and tangents.size() == vertices.size()*4
        for i in vertices.size():
            valid = valid and vertices[i].is_finite() and normals[i].is_finite() and uv[i].is_finite() and absf(normals[i].length()-1)<.001
        for i in range(0,indices.size(),3):
            valid = valid and (vertices[indices[i+1]]-vertices[indices[i]]).cross(vertices[indices[i+2]]-vertices[indices[i]]).length()>.00000001
        _check(valid and mesh.get_surface_count() == 1, "Finite actual mesh arrays and nondegenerate triangles " + mesh.resource_path)
        _check(int(indices.size()/3) == (48 if mesh == core else 24), "Measured static triangle count " + mesh.resource_path)
        var radius := .017 if mesh == core else .05
        _check(mesh.get_aabb().is_equal_approx(AABB(Vector3(-radius,-.5,-radius),Vector3(2*radius,1,2*radius))), "Centered one-meter Y axis and exact silhouette bounds")
    var beams: Array[MeshInstance3D] = []
    for i in 4:
        beams.append(room.get_node("BeamSegments/Segment"+str(i)) as MeshInstance3D)
    beams.append(room.get_node("Focus/Beam") as MeshInstance3D)
    var z_positions := [-20.7,-21.8,-23.6,-24.7]
    for i in beams.size():
        var beam := beams[i]
        var shell := beam.get_node("Halo") as MeshInstance3D
        _check(beam.mesh == core and shell.mesh == halo and beam.material_override == core_material and shell.material_override == halo_material,
            "Shared immutable geometry/material resources at owner " + str(i))
        _check(beam.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and shell.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and not beam.is_processing(),
            "No shadow or frame-processing owner " + str(i))
        _check(beam.find_children("*","CollisionObject3D",true,false).is_empty() and beam.find_children("*","Light3D",true,false).is_empty(), "No physics/light ownership " + str(i))
        if i<4:
            _check(beam.position.is_equal_approx(Vector3(0,1.72,z_positions[i])) and is_equal_approx(beam.rotation.x,PI/2) and beam.scale == Vector3.ONE,
                "Original segment pose/length " + str(i))
    _check(beams[4].position.is_equal_approx(Vector3(-1.9,.8,-23.2)) and is_equal_approx(beams[4].scale.y,2), "Original authored two-meter focus beam")
    _check(beams[0].to_global(Vector3(0,.5,0)).distance_to(room.get_node("Emitter").to_global(Vector3(0,-.2,0)))<.001, "First beam still starts at actual emitter optical face")
    _check(beams[0].visible and not beams[1].visible and not beams[2].visible and not beams[3].visible and not beams[4].visible, "Cold state has only the initial segment")
    var rings := room.get_node("Rings") as LightRingPuzzle
    _check(rings.rotate_ring(0) == OK and beams[1].visible and not beams[2].visible, "Real outer-ring control reveals only its next segment")
    rings.rotate_ring(1)
    _check(not beams[2].visible, "Incorrect middle stop does not reveal the next segment")
    _check(rings.rotate_ring(1) == OK and beams[2].visible and not beams[3].visible, "Real middle-ring control reveals only its next segment")
    _check(rings.restore_completed(true) == OK and beams[3].visible, "Quiet complete projection reveals the final segment without acquisition")
    var focus := room.get_node("Focus") as LightFocusPuzzle
    _check(focus.restore_state(true,false) == OK and beams[4].visible, "Star-state projection enables original focus beam")
    var old_width := beams[4].scale.x
    _check(focus.cycle() == OK and beams[4].scale.x<old_width and is_equal_approx(beams[4].scale.y,2), "Real focus control narrows only the old X axis")
    var second_tint: Variant = beams[1].get_instance_shader_parameter("beam_tint")
    beams[0].set("beam_color",Color(.8,.3,.06,1))
    beams[0].set("beam_energy",.8)
    _check(beams[0].get_instance_shader_parameter("beam_tint") == Color(.8,.3,.06,1) and beams[0].get_node("Halo").get_instance_shader_parameter("beam_tint") == Color(.8,.3,.06,1),
        "Palette reaches only this core/halo instance")
    _check(beams[1].get_instance_shader_parameter("beam_tint") == second_tint and beams[0].material_override == beams[1].material_override,
        "Per-instance palette does not mutate another beam/shared material")
    var star := room.get_node("Star") as Sprite3D
    _check(star.texture == preload("res://art/sigils/star.svg") and is_equal_approx(star.pixel_size,.01) and star.billboard == BaseMaterial3D.BILLBOARD_ENABLED and not star.shaded,
        "Exact canonical texture, billboard and pixel size")
    _check(star.position.is_equal_approx(Vector3(0,1.72,-25.3)) and not star.visible and not star.is_processing(), "Cold Star preserves authored position and is dormant")
    var completed: Dictionary = prepared["state"].duplicate(true)
    completed["light_restored"] = true
    completed["star_collected"] = true
    _check(world.apply_stage_state(saved.stage_id,completed) == OK and star.visible and star.is_processing() and is_zero_approx(star.get("_phase")),
        "Archive projection alone reveals Star at its reproducible quiet pose")
    var rest_scale := star.scale
    var rest_color := star.modulate
    await get_tree().create_timer(.25,true).timeout
    _check(float(star.get("_phase"))>.1 and star.scale != rest_scale and star.modulate.a<rest_color.a, "Actual scene time animates the quiet sigil")
    _check(star.modulate.a>=.82 and star.modulate.a<=1 and star.scale.x>=1 and star.scale.x<=1.024, "Restrained alpha/scale envelope")
    get_tree().paused = true
    var phase: float = star.get("_phase")
    var paused_scale := star.scale
    var paused_color := star.modulate
    await get_tree().create_timer(.08,true).timeout
    _check(is_equal_approx(star.get("_phase"),phase) and star.scale == paused_scale and star.modulate == paused_color, "Pause freezes phase/pose without shader wall clock")
    get_tree().paused = false
    await get_tree().create_timer(.08,true).timeout
    _check(float(star.get("_phase"))>phase, "Unpause resumes local phase")
    room.visible = false
    _check(not star.is_processing() and is_zero_approx(star.get("_phase")) and star.scale == rest_scale and star.modulate == rest_color, "Ancestor hide resets and stops Star")
    room.visible = true
    _check(star.is_processing() and is_zero_approx(star.get("_phase")), "Ancestor reveal quietly restarts Star")
    star.visible = false
    _check(not star.is_processing() and star.scale == rest_scale and star.modulate == rest_color, "Hidden Star resets its quiet pose")
    for preset in ["Low","Medium"]:
        SettingsManager.graphics_preset = preset
        SettingsManager.apply_runtime(false)
        _check(beams[0].mesh == core and beams[0].material_override == core_material and star.texture == preload("res://art/sigils/star.svg"), "Core/canonical sigil independent of quality effects " + preset)
    _check(world.slice_bindings_valid() and GameState.capture_save().to_dict() == before and SaveManager.get("_dirty") == dirty,
        "Presentation/control review preserves global progression and dirty flag")
    world.queue_free()
    await get_tree().process_frame
    if _failures.is_empty():
        print("ARCHIVE_BEAM_STAR PASS: %d mesh/controller/palette/Star lifetime/state assertions; 72 triangles per beam pair" % _checks)
    get_tree().quit(0 if _failures.is_empty() else 1)

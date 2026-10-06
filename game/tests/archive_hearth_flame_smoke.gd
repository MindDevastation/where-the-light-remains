extends Node

var _checks := 0
var _failures: Array[String] = []

func _check(value: bool, message: String) -> void:
    _checks += 1
    if not value:
        _failures.append(message)
        push_error(message)

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _run.call_deferred()

func _run() -> void:
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var flame := preload("res://art/vfx/hearth_flame.tscn").instantiate() as Node3D
    flame.visible = false
    add_child(flame)
    _check(flame.get_child_count() == 3, "Three authored flame tongues")
    _check(not flame.is_processing() and is_zero_approx(flame.get("_phase")), "Cold effect is dormant")
    var gold := preload("res://art/materials/m_archive_emissive_gold.tres")
    var mesh := (flame.get_child(0) as MeshInstance3D).mesh
    var triangles := 0
    var geometry_valid := true
    var sharing_valid := true
    var envelope := AABB()
    for child: MeshInstance3D in flame.get_children():
        sharing_valid = sharing_valid and child.mesh == mesh and child.material_override == gold
        geometry_valid = geometry_valid and child.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        envelope = envelope.merge(child.transform * child.get_aabb())
        var arrays := child.mesh.surface_get_arrays(0)
        var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
        var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
        triangles += vertices.size() / 3
        geometry_valid = geometry_valid and vertices.size() == normals.size()
        for index in vertices.size():
            geometry_valid = geometry_valid and vertices[index].is_finite() and normals[index].is_finite() and absf(normals[index].length() - 1) < .001
        for index in range(0, vertices.size(), 3):
            geometry_valid = geometry_valid and (vertices[index + 1] - vertices[index]).cross(vertices[index + 2] - vertices[index]).length() > .000001
    _check(sharing_valid, "One mesh and existing shared gold material reused by all lobes")
    _check(triangles == 240 and geometry_valid, "240 nondegenerate triangles, finite unit normals and no shadow passes")
    _check(envelope.position.x >= -.22 and envelope.end.x <= .22 and envelope.position.z >= -.22 and envelope.end.z <= .22 and envelope.position.y >= -.361 and envelope.end.y <= .361, "Quiet silhouette fits original flame envelope")
    _check(flame.find_children("*", "CollisionObject3D", true, false).is_empty() and flame.find_children("*", "Light3D", true, false).is_empty() and flame.find_children("*", "AudioStreamPlayer", true, false).is_empty(), "No physics, light or audio ownership")
    var rest := (flame.get_child(0) as Node3D).transform
    flame.visible = true
    _check(flame.is_processing() and (flame.get_child(0) as Node3D).transform == rest, "Quiet visibility begins at reproducible pose")
    for frame in 8:
        await get_tree().process_frame
    _check(float(flame.get("_phase")) > 0 and (flame.get_child(0) as Node3D).transform != rest, "Actual scene frames animate the warm effect")
    get_tree().paused = true
    var paused_phase: float = flame.get("_phase")
    var paused_pose := (flame.get_child(0) as Node3D).transform
    for frame in 4:
        await get_tree().process_frame
    _check(is_equal_approx(flame.get("_phase"), paused_phase) and (flame.get_child(0) as Node3D).transform == paused_pose, "Game pause freezes effect without wall-clock shader motion")
    get_tree().paused = false
    for frame in 3:
        await get_tree().process_frame
    _check(float(flame.get("_phase")) > paused_phase, "Unpause resumes local phase")
    flame.visible = false
    _check(not flame.is_processing() and is_zero_approx(flame.get("_phase")) and (flame.get_child(0) as Node3D).transform == rest, "Cold projection resets pose and stops processing")
    for frame in 3:
        await get_tree().process_frame
    _check(is_zero_approx(flame.get("_phase")), "Hidden effect does not advance")
    flame.visible = true
    _check(flame.is_processing() and (flame.get_child(0) as Node3D).transform == rest, "Quiet warm reload has no activation burst")
    for preset in ["Low", "Medium"]:
        SettingsManager.graphics_preset = preset
        SettingsManager.apply_runtime(false)
        _check(flame.is_visible_in_tree() and (flame.get_child(0) as MeshInstance3D).material_override == gold, "%s retains emissive geometry without particles/glow dependency" % preset)
    flame.queue_free()
    await get_tree().process_frame
    _check(not is_instance_valid(flame) and GameState.capture_save().to_dict() == before and SaveManager.get("_dirty") == dirty, "Scene cleanup preserves gameplay/save state")
    if _failures.is_empty():
        print("ARCHIVE_HEARTH_FLAME PASS: %d assertions" % _checks)
    get_tree().quit(0 if _failures.is_empty() else 1)

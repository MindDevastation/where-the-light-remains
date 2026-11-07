extends Node
## Paired native kit and current carrier poses; no real input or save action.

var _output := ""
var _preset := "Low"
var _captures: Array[Dictionary] = []
var _checks := 0
var _failures := 0


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--review-output="): _output = argument.trim_prefix("--review-output=")
        if argument.begins_with("--review-preset="): _preset = argument.trim_prefix("--review-preset=")
    get_tree().create_timer(140.0, true).timeout.connect(func() -> void:
        push_error("ARCHIVE_DECAL_REVIEW timeout")
        get_tree().quit(1))
    _run.call_deferred()


func _check(value: bool, message: String) -> void:
    _checks += 1
    if not value:
        _failures += 1
        push_error("ARCHIVE_DECAL_REVIEW FAIL: " + message)


func _pair(name: String, decals: Array[Node], camera: Camera3D) -> void:
    for enabled: bool in [true, false]:
        for decal: Decal in decals: decal.visible = enabled
        for frame in 4: await get_tree().process_frame
        await RenderingServer.frame_post_draw
        var image := get_viewport().get_texture().get_image()
        var filename := "%s_%s_%s.png" % [name, "on" if enabled else "off", _preset.to_lower()]
        _check(image.get_size() == get_window().size and image.save_png(_output.path_join(filename)) == OK, "save original native framebuffer")
        _captures.append({"file": filename, "view": name, "enabled": enabled,
            "preset": _preset, "effects": SettingsManager.effects,
            "size": [image.get_width(), image.get_height()], "camera": str(camera.global_transform),
            "decal_count": decals.size(), "scope": "Neutral kit fixture or current S02 API/camera pose; no gameplay input/save/route execution"})
    for decal: Decal in decals: decal.show()


func _run() -> void:
    _check(not _output.is_empty() and _preset in ["Low", "Medium"], "bounded review arguments")
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    SettingsManager.graphics_preset = _preset
    SettingsManager.effects = false
    SettingsManager.apply_runtime(false)
    var fixture := Node3D.new()
    add_child(fixture)
    var light := DirectionalLight3D.new()
    fixture.add_child(light)
    light.rotation_degrees = Vector3(-55, -25, 0)
    var camera := Camera3D.new()
    fixture.add_child(camera)
    camera.position = Vector3(0, 3.8, 2.7)
    camera.look_at(Vector3.ZERO)
    camera.fov = 45
    camera.make_current()
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(.46, .39, .30)
    material.roughness = .78
    var kit: Array[Node] = []
    var names: Array[String] = ["scratches", "edge_wear", "dust", "soot"]
    for index in names.size():
        var mesh := MeshInstance3D.new()
        var plane := PlaneMesh.new()
        plane.size = Vector2(1.15, 1.15)
        mesh.mesh = plane
        mesh.material_override = material
        mesh.position = Vector3(-.67 if index % 2 == 0 else .67, 0, -.67 if index < 2 else .67)
        fixture.add_child(mesh)
        var decal := load("res://art/decals/archive_" + names[index] + ".tscn").instantiate() as Decal
        fixture.add_child(decal)
        decal.position = mesh.position
        decal.size = Vector3(.95, .03, .95)
        kit.append(decal)
    await _pair("neutral_kit", kit, camera)
    fixture.queue_free()
    await get_tree().process_frame
    var world := preload("res://worlds/archive/archive_main.tscn").instantiate() as ArchiveMain
    world.process_mode = Node.PROCESS_MODE_PAUSABLE
    add_child(world)
    var state := ArchiveProgress.fresh()
    state["awakened"] = true
    state["unlocked"][0] = true
    _check(world.apply_stage_state(ArchiveProgress.WING_ONE, state) == OK, "quiet existing cold S02 pose")
    camera = Camera3D.new()
    add_child(camera)
    camera.fov = 55
    camera.make_current()
    var decals := world.get_node("Wing01/Room/Hearth/Bowl").find_children("*", "Decal", true, false)
    _check(decals.size() == 2, "two shipping decal nodes")
    for frame in 4: await get_tree().process_frame
    get_tree().paused = true
    camera.position = Vector3(-1.7, 1.45, -22.85)
    camera.look_at(Vector3(-2.8, .62, -24))
    await _pair("hearth_close", decals, camera)
    for decal: Decal in decals: decal.hide()
    camera.fov = 45
    camera.position = Vector3(-2.1, 1.75, -23.3)
    camera.look_at(Vector3(-2.8, .59, -24))
    var soot: Array[Node] = [world.get_node("Wing01/Room/Hearth/Bowl/SurfaceDetail/InnerSoot")]
    await _pair("hearth_soot", soot, camera)
    for decal: Decal in decals: decal.hide()
    camera.fov = 50
    camera.position = Vector3(-1.95, .75, -23.05)
    camera.look_at(Vector3(-2.46, .11, -23.75))
    var dust: Array[Node] = [world.get_node("Wing01/Room/Hearth/Bowl/SurfaceDetail/PedestalDust")]
    await _pair("hearth_dust", dust, camera)
    camera.fov = 55
    camera.position = Vector3(-2.1, 1.62, -21.2)
    camera.look_at(Vector3(-2.8, .7, -24))
    await _pair("hearth_approach", decals, camera)
    get_tree().paused = false
    _check(GameState.capture_save().to_dict() == before and SaveManager.get("_dirty") == dirty, "native review preserves DTO/dirty")
    var receipt := {"status": "PASS_CAPTURE_ONLY" if _failures == 0 else "FAIL", "checks": _checks,
        "failures": _failures, "preset": _preset, "renderer": RenderingServer.get_current_rendering_method(),
        "device": RenderingServer.get_video_adapter_name(), "captures": _captures,
        "scope": "New four-mask kit and two static existing Hearth projections; software Vulkan, API/pose review only"}
    var file := FileAccess.open(_output.path_join("captures_" + _preset.to_lower() + ".json"), FileAccess.WRITE)
    file.store_string(JSON.stringify(receipt, "  ") + "\n")
    file.close()
    world.queue_free()
    await get_tree().process_frame
    print("ARCHIVE_DECAL_REVIEW %s: %d assertions; ten originals" % ["CAPTURED" if _failures == 0 else "FAIL", _checks])
    get_tree().quit(0 if _failures == 0 else 1)

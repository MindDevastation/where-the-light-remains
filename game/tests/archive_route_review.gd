extends Node3D
## Isolated graybox presentation review; does not route a shipping story stage.

const GATE := preload("res://worlds/archive/common/archive_gate.tscn")
const CHANNEL := preload("res://worlds/archive/common/archive_light_channel.tscn")

var _gates: Array[ArchiveGate] = []
var _channels: Array[ArchiveLightChannel] = []
var _camera: Camera3D
var _output := ""
var _metadata := ""
var _view := "active_low"
var _failure := false


func _check(value: bool, message: String) -> void:
    if not value:
        _failure = true
        push_error("ROUTE_REVIEW FAIL: " + message)


func _ready() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--output="): _output = arg.trim_prefix("--output=")
        if arg.begins_with("--metadata="): _metadata = arg.trim_prefix("--metadata=")
        if arg.begins_with("--view="): _view = arg.trim_prefix("--view=")
    _run.call_deferred()


func _material(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.85
    return mat


func _setup() -> WorldEnvironment:
    var floor := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(25, 0.2, 14)
    floor.mesh = box
    floor.material_override = _material(Color(0.055, 0.075, 0.10))
    floor.position = Vector3(0, -0.12, 2)
    add_child(floor)
    for i in 5:
        var gate := GATE.instantiate() as ArchiveGate
        gate.position.x = (i - 2) * 4.6
        gate.get_node("Label").text = ["Крыло I", "Крыло II", "Крыло III", "Крыло IV", "Крыло V"][i]
        add_child(gate)
        _gates.append(gate)
        var channel := CHANNEL.instantiate() as ArchiveLightChannel
        channel.position = gate.position + Vector3(0, 0, 2.8)
        add_child(channel)
        _channels.append(channel)
    var world := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.022, 0.035, 0.055)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.4, 0.5, 0.7)
    environment.ambient_light_energy = 0.8
    # Authored on; the actual Low/effects-off profile must remove these.
    environment.glow_enabled = true
    environment.volumetric_fog_enabled = true
    environment.volumetric_fog_density = 0.001
    world.environment = environment
    add_child(world)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-55, -25, 0)
    light.light_energy = 1.0
    light.shadow_enabled = true
    add_child(light)
    _camera = Camera3D.new()
    _camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    _camera.size = 16
    _camera.position = Vector3(0, 12, 15)
    add_child(_camera)
    _camera.look_at(Vector3(0, 0, 1.2))
    _camera.make_current()
    return world


func _run() -> void:
    _check(_view in ["active_low", "completed_low", "active_medium", "all_completed_low"], "known review state")
    var saved := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var original_files := [FileAccess.get_sha256(SaveManager.SAVE_PATH) if FileAccess.file_exists(SaveManager.SAVE_PATH) else "absent",
            FileAccess.get_sha256(SaveManager.BACKUP_PATH) if FileAccess.file_exists(SaveManager.BACKUP_PATH) else "absent"]
    var world := _setup()
    var preferences := SettingsManager.snapshot()
    var low := _view.ends_with("low")
    preferences["graphics_preset"] = "Low" if low else "Medium"
    preferences["effects"] = not low
    preferences["shadows"] = not low
    preferences["resolution"] = Vector2i(1920, 1080)
    _check(SettingsManager.apply_settings(preferences, "user://route-review-settings.cfg") == OK,
            "apply actual isolated renderer preferences")
    SettingsManager.apply_scene_graphics()
    if low:
        _check(not world.environment.glow_enabled and not world.environment.volumetric_fog_enabled and
                is_equal_approx(get_viewport().scaling_3d_scale, 0.75), "Low fallback independent of glow/volumetrics")
    if _view == "all_completed_low":
        for i in 5:
            _check(_gates[i].apply_state(ArchiveGate.Status.COMPLETED) == OK, "five completed gate restore")
            _check(_channels[i].apply_state(ArchiveLightChannel.Status.COMPLETED) == OK, "five warm route restore")
    else:
        var completed := _view == "completed_low"
        _check(_gates[0].apply_state(ArchiveGate.Status.COMPLETED if completed else ArchiveGate.Status.OPEN) == OK,
                "Wing I gate restored")
        _check(_channels[0].apply_state(ArchiveLightChannel.Status.COMPLETED if completed else ArchiveLightChannel.Status.ACTIVE) == OK,
                "Wing I route restored")
        if completed:
            _check(_gates[1].apply_state(ArchiveGate.Status.OPEN) == OK and
                    _channels[1].apply_state(ArchiveLightChannel.Status.ACTIVE) == OK, "only one new active route")
    for i in 8:
        await get_tree().process_frame
    if not _output.is_empty():
        await RenderingServer.frame_post_draw
        var image := get_viewport().get_texture().get_image()
        _check(image.get_size() == Vector2i(1920, 1080), "actual 1920x1080 framebuffer")
        _check(image.save_png(_output) == OK, "PNG capture")
        var samples := []
        for i in 5:
            var positions := []
            for n in range(2, 19):
                var point := _channels[i].global_transform * Vector3(0, 0.04, lerpf(-2.2, 2.2, float(n) / 20.0))
                var pixel := _camera.unproject_position(point)
                positions.append([pixel.x, pixel.y])
            samples.append({"index": i, "status": _channels[i].status, "positions": positions})
        if not _metadata.is_empty():
            var file := FileAccess.open(_metadata, FileAccess.WRITE)
            _check(file != null, "review metadata open")
            if file != null:
                file.store_string(JSON.stringify({"view": _view, "profile": SettingsManager.graphics_preset,
                        "effects": SettingsManager.effects, "glow": world.environment.glow_enabled,
                        "volumetrics": world.environment.volumetric_fog_enabled,
                        "render_scale": get_viewport().scaling_3d_scale, "samples": samples}, "  ") + "\n")
                file.close()
        var current_files := [FileAccess.get_sha256(SaveManager.SAVE_PATH) if FileAccess.file_exists(SaveManager.SAVE_PATH) else "absent",
                FileAccess.get_sha256(SaveManager.BACKUP_PATH) if FileAccess.file_exists(SaveManager.BACKUP_PATH) else "absent"]
        _check(saved == GameState.capture_save().to_dict() and dirty == SaveManager.get("_dirty") and
                current_files == original_files, "review leaves gameplay/slots unchanged")
        if not _failure:
            print("ROUTE_REVIEW PASS: ", _view, "; actual 1920x1080, scale=", get_viewport().scaling_3d_scale,
                    "; glow=", world.environment.glow_enabled, "; volumetrics=", world.environment.volumetric_fog_enabled)
        get_tree().quit(1 if _failure else 0)

extends Node
## Preferences only; logical SaveGame and semantic audio remain separate owners.

const SETTINGS_PATH := "user://settings.cfg"
const FORMAT_VERSION := 1
const MAX_FILE_BYTES := 65536
const RESOLUTIONS: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]
const PRESETS: Array[String] = ["Low", "Medium", "High"]
const EFFECT_FLAGS: Array[String] = ["glow_enabled", "ssao_enabled", "ssil_enabled", "ssr_enabled", "volumetric_fog_enabled"]
const DEFAULTS := {
    "master_volume": 1.0, "music_volume": 0.8, "sfx_volume": 0.9,
    "mouse_sensitivity": 0.5, "invert_y": false, "fov": 75.0,
    "resolution": Vector2i(1280, 720), "fullscreen": false,
    "graphics_preset": "Medium", "shadows": true, "effects": true,
}

var master_volume := 1.0
var music_volume := 0.8
var sfx_volume := 0.9
var mouse_sensitivity := 0.5
var invert_y := false
var fov := 75.0
var resolution := Vector2i(1280, 720)
var fullscreen := false
var graphics_preset := "Medium"
var shadows := true
var effects := true
var last_error: Error = OK
var _environments: Dictionary = {}
var _lights: Dictionary = {}
var _graphics_queued := false


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    last_error = load_settings()
    if last_error != OK and last_error != ERR_FILE_NOT_FOUND:
        push_warning("Не удалось загрузить настройки. Файл сохранен без изменений. Код: %d" % last_error)
    apply_runtime(not _has_display_override())
    get_tree().node_added.connect(_on_node_changed)
    get_tree().node_removed.connect(_on_node_changed)
    get_window().size_changed.connect(_apply_viewport)
    _notify_changed.call_deferred()


func snapshot() -> Dictionary:
    var values := {}
    for key in DEFAULTS:
        values[key] = get(key)
    return values


func validate(values: Dictionary) -> Dictionary:
    var result := DEFAULTS.duplicate()
    for key in DEFAULTS:
        if not values.has(key):
            continue
        var value: Variant = values[key]
        if typeof(DEFAULTS[key]) == TYPE_FLOAT:
            if typeof(value) not in [TYPE_FLOAT, TYPE_INT] or not is_finite(float(value)):
                return {}
            var lower := 0.1 if key == "mouse_sensitivity" else (50.0 if key == "fov" else 0.0)
            var upper := 2.0 if key == "mouse_sensitivity" else (110.0 if key == "fov" else 1.0)
            result[key] = clampf(float(value), lower, upper)
        else:
            if typeof(value) != typeof(DEFAULTS[key]):
                return {}
            result[key] = value
    if result["resolution"] not in RESOLUTIONS or result["graphics_preset"] not in PRESETS:
        return {}
    return result


func load_settings(path: String = SETTINGS_PATH) -> Error:
    if not FileAccess.file_exists(path):
        return ERR_FILE_NOT_FOUND
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return FileAccess.get_open_error()
    var length := file.get_length()
    file.close()
    if length > MAX_FILE_BYTES:
        return ERR_INVALID_DATA
    var config := ConfigFile.new()
    var error := config.load(path)
    if error != OK:
        return error
    var version: Variant = config.get_value("metadata", "version", 0)
    if typeof(version) != TYPE_INT or version != FORMAT_VERSION:
        return ERR_INVALID_DATA
    var values := {}
    for key in DEFAULTS:
        values[key] = config.get_value("settings", key, DEFAULTS[key])
    values = validate(values)
    if values.is_empty():
        return ERR_INVALID_DATA
    _assign(values)
    if is_inside_tree():
        apply_runtime(false)
        _notify_changed()
    return OK


func apply_settings(values: Dictionary, path: String = SETTINGS_PATH) -> Error:
    var validated := validate(values)
    if validated.is_empty():
        last_error = ERR_INVALID_DATA
        return last_error
    last_error = _write_values(validated, path)
    if last_error != OK:
        return last_error
    _assign(validated)
    apply_runtime()
    _notify_changed()
    return OK


func save_settings(path: String = SETTINGS_PATH) -> Error:
    return apply_settings(snapshot(), path)


func _write_values(values: Dictionary, path: String) -> Error:
    var config := ConfigFile.new()
    config.set_value("metadata", "version", FORMAT_VERSION)
    for key in values:
        config.set_value("settings", key, values[key])
    var temporary := path + ".tmp-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
    var file := FileAccess.open(temporary, FileAccess.WRITE)
    if file == null:
        return FileAccess.get_open_error()
    file.store_string(config.encode_to_text())
    file.flush()
    var error := file.get_error()
    file.close()
    if error == OK:
        error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path))
    if error != OK:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
    return error


func _assign(values: Dictionary) -> void:
    for key in DEFAULTS:
        set(key, values[key])


func apply_runtime(apply_display: bool = true) -> void:
    for entry in [[&"Master", master_volume], [&"Music", music_volume], [&"SFX", sfx_volume]]:
        var index := AudioServer.get_bus_index(entry[0])
        if index >= 0:
            var volume: float = entry[1]
            AudioServer.set_bus_volume_linear(index, maxf(volume, 0.000001))
            AudioServer.set_bus_mute(index, is_zero_approx(volume))
    if apply_display and DisplayServer.get_name() != "headless":
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
        if not fullscreen:
            get_window().size = resolution
    _apply_viewport()
    apply_scene_graphics()


func _apply_viewport() -> void:
    if not is_inside_tree():
        return
    var viewport := get_tree().root
    var profile := PRESETS.find(graphics_preset)
    var scale := 0.75 if profile == 0 else 1.0
    var native_fullscreen := DisplayServer.get_name() != "headless" and DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
    if native_fullscreen and viewport.size.y > 0:
        scale *= minf(1.0, float(resolution.y) / viewport.size.y)
    viewport.scaling_3d_scale = scale
    viewport.msaa_3d = Viewport.MSAA_2X if profile == 2 else Viewport.MSAA_DISABLED
    viewport.positional_shadow_atlas_size = ([512, 2048, 4096][profile] if shadows else 0)


func _on_node_changed(node: Node) -> void:
    if node is WorldEnvironment or node is Light3D:
        if not _graphics_queued:
            _graphics_queued = true
            apply_scene_graphics.call_deferred()


func apply_scene_graphics() -> void:
    if not is_inside_tree():
        return
    _graphics_queued = false
    for cache in [_environments, _lights]:
        for id in cache.keys():
            if cache[id][0].get_ref() == null:
                cache.erase(id)
    for node in get_tree().root.find_children("*", "WorldEnvironment", true, false):
        var world := node as WorldEnvironment
        if world.environment == null:
            continue
        var id := world.get_instance_id()
        if not _environments.has(id) or world.environment != _environments[id][2]:
            var authored := world.environment
            var runtime := authored.duplicate() as Environment
            _environments[id] = [weakref(world), authored, runtime]
            world.environment = runtime
        var original: Environment = _environments[id][1]
        for flag in EFFECT_FLAGS:
            world.environment.set(flag, effects and bool(original.get(flag)))
    for node in get_tree().root.find_children("*", "Light3D", true, false):
        var light := node as Light3D
        var id := light.get_instance_id()
        if not _lights.has(id):
            _lights[id] = [weakref(light), light.shadow_enabled]
        light.shadow_enabled = shadows and _lights[id][1]


func _has_display_override() -> bool:
    # Godot consumes its display flags before exposing command-line arguments.
    # Launchers forward this explicit user flag instead of platform argv hacks.
    return OS.get_cmdline_user_args().has("--preserve-display")


func _notify_changed() -> void:
    if is_inside_tree():
        var events := get_tree().root.get_node_or_null("EventBus")
        if events != null:
            events.settings_changed.emit()

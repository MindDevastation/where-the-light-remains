extends SceneTree
## CLI-only startup check. Never attached to a production scene or autoload.

const EXPECTED_AUTOLOADS: Array[String] = [
    "App", "AudioDirector", "EventBus", "GameState", "InputManager",
    "SaveManager", "SceneRouter", "SettingsManager",
]

var _startup_stage: StringName = &""


func _initialize() -> void:
    _run.call_deferred()


func _require(condition: bool, message: String) -> bool:
    if not condition:
        push_error("ENGINE_PREFLIGHT FAIL: " + message)
        quit(1)
    return condition


func _on_stage_changed(stage_id: StringName) -> void:
    _startup_stage = stage_id


func _run() -> void:
    print("ENGINE_PREFLIGHT runtime: ", JSON.stringify({
        "executable": OS.get_executable_path(),
        "version": Engine.get_version_info(),
        "csharp": OS.has_feature("C#"),
        "platform": OS.get_name(),
        "display": DisplayServer.get_name(),
        "renderer": RenderingServer.get_current_rendering_method(),
        "driver": RenderingServer.get_current_rendering_driver_name(),
    }))

    var configured_autoloads: Array[String] = []
    for property in ProjectSettings.get_property_list():
        var setting_name: String = property["name"]
        if setting_name.begins_with("autoload/"):
            configured_autoloads.append(setting_name.trim_prefix("autoload/"))
    configured_autoloads.sort()
    if not _require(configured_autoloads == EXPECTED_AUTOLOADS, "Expected exactly 8 baseline autoloads"):
        return
    for service_name in EXPECTED_AUTOLOADS:
        var service: Node = root.get_node_or_null(NodePath(service_name))
        if not _require(service != null, "Autoload was not instantiated: " + service_name):
            return
        var script: Script = service.get_script()
        if not _require(script != null and script.can_instantiate(), "Invalid autoload script: " + service_name):
            return

    var baseline: Dictionary = {
        "display/window/size/viewport_width": 1920,
        "display/window/size/viewport_height": 1080,
        "physics/common/physics_ticks_per_second": 60,
        "rendering/renderer/rendering_method": "forward_plus",
    }
    for setting_name in baseline:
        if not _require(ProjectSettings.get_setting(setting_name) == baseline[setting_name], "Baseline mismatch: " + setting_name):
            return

    root.get_node("EventBus").connect("stage_changed", _on_stage_changed)
    var main_scene: String = ProjectSettings.get_setting("application/run/main_scene", "")
    if not _require(not main_scene.is_empty() and ResourceLoader.exists(main_scene), "Missing main scene"):
        return
    if not _require(change_scene_to_file(main_scene) == OK, "Main scene failed to load"):
        return
    await process_frame
    await process_frame
    if not _require(current_scene != null and current_scene.name == &"GameRoot", "GameRoot was not created"):
        return
    for node_name in ["PlayerContainer", "UILayer", "TransitionLayer", "WorldSlot"]:
        if not _require(current_scene.has_node(NodePath(node_name)), "Missing GameRoot child: " + node_name):
            return
    if not _require(root.get_node("SceneRouter").get("_world_slot") == current_scene.get_node("WorldSlot"), "GameRoot did not bind WorldSlot"):
        return
    if not _require(_startup_stage == root.get_node("GameState").get("current_stage_id"), "Startup stage event was not emitted"):
        return

    # Let the real scene and services process beyond the first startup frame.
    await create_timer(1.0).timeout
    if not _require(is_instance_valid(current_scene) and current_scene.is_inside_tree(), "Main scene stopped during smoke test"):
        return
    print("ENGINE_PREFLIGHT PASS: GameRoot ready; 8 autoloads; baseline settings; requesting App safe exit")
    root.get_node("App").call("request_safe_exit")

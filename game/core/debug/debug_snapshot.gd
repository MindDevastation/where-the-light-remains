extends RefCounted
## Read-only inspection. Never calls save, routing, audio or gameplay setters.

const MAX_SAVE_BYTES := 262144


static func inspect_save(path: String) -> Dictionary:
    var result := {"path": path, "status": "missing", "bytes": 0}
    if not FileAccess.file_exists(path):
        return result
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        result["status"] = "unreadable"
        result["error"] = FileAccess.get_open_error()
        return result
    result["bytes"] = file.get_length()
    if file.get_length() > MAX_SAVE_BYTES:
        result["status"] = "too_large"
        file.close()
        return result
    var parser := JSON.new()
    var error := parser.parse(file.get_as_text())
    file.close()
    if error != OK:
        result["status"] = "invalid_json"
        result["error_line"] = parser.get_error_line()
    else:
        # A JSON preview is not SaveManager's future schema validation/load.
        result["status"] = "json_preview"
        result["data"] = parser.data
    return result


static func capture(game_root: Node) -> Dictionary:
    var root := game_root.get_tree().root
    var state := root.get_node("GameState")
    var save := root.get_node("SaveManager")
    var director := root.get_node("AudioDirector")
    var fragments: Dictionary = state.get("collected_fragments")
    var worlds: Array[Dictionary] = []
    for child in game_root.get_node("WorldSlot").get_children():
        worlds.append({"name": String(child.name), "type": child.get_class(), "scene": child.scene_file_path})
    var buses: Array[Dictionary] = []
    for index in AudioServer.bus_count:
        buses.append({
            "name": String(AudioServer.get_bus_name(index)),
            "send": String(AudioServer.get_bus_send(index)) if index > 0 else "output",
            "db": AudioServer.get_bus_volume_db(index),
            "mute": AudioServer.is_bus_mute(index),
            "solo": AudioServer.is_bus_solo(index),
        })
    var current_scene := game_root.get_tree().current_scene
    return {
        "stage": String(state.get("current_stage_id")),
        "fragments": fragments.duplicate(true),
        "completed": state.get("game_completed"),
        "save_dirty": save.get("_dirty"),
        "primary": inspect_save(save.get("SAVE_PATH")),
        "backup": inspect_save(save.get("BACKUP_PATH")),
        "audio_stage": String(director.get("current_stage")),
        "audio_state": String(director.get("current_state")),
        "buses": buses,
        "scene": current_scene.scene_file_path if current_scene != null else "",
        "worlds": worlds,
        "paused": game_root.get_tree().paused,
        "input_mode": root.get_node("InputManager").get("mode"),
        "fps": Engine.get_frames_per_second(),
        "process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
        "physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
        "nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
        "draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
    }

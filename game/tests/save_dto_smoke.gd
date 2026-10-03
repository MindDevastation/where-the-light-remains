extends Node
## CLI-only typed logical data and transactional state tests. No disk writes.

var _failures: Array[String] = []
var _events := 0


func _ready() -> void:
    _run.call_deferred()


func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
        push_error("SAVE_DTO FAIL: " + message)


func _files() -> Dictionary:
    var hashes := {}
    for path in [SettingsManager.SETTINGS_PATH, SaveManager.SAVE_PATH, SaveManager.BACKUP_PATH]:
        hashes[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"
    return hashes


func _invalid(values: Dictionary, label: String, expected: Error = ERR_INVALID_DATA) -> void:
    var result := SaveGame.decode(values)
    _check(result["error"] == expected and result["data"] == null, "Invalid " + label + " accepted or misclassified")


func _run() -> void:
    print("SAVE_DTO runtime: ", Engine.get_version_info()["string"])
    var original := GameState.capture_save()
    _check(original != null, "Initial GameState invalid")
    var files := _files()
    var settings := SettingsManager.snapshot()
    var mode := InputManager.mode
    var dirty: bool = SaveManager.get("_dirty")
    var audio := [AudioDirector.current_stage, AudioDirector.current_state]
    EventBus.stage_changed.connect(func(_id: StringName) -> void: _events += 1)
    EventBus.checkpoint_reached.connect(func(_id: StringName) -> void: _events += 1)
    EventBus.fragment_collected.connect(func(_id: StringName) -> void: _events += 1)
    var fresh := SaveGame.new()
    var baseline := fresh.to_dict()
    _check(SaveGame.decode(baseline)["error"] == OK and fresh.stage_id == &"s00_prologue", "Default v1 state")
    var partial := SaveGame.new()
    partial.stage_id = &"s02_warmth_light"
    partial.checkpoint_id = &"fixture_checkpoint"
    partial.collected_fragments = [&"star", &"hearth"]
    partial.world_states = {&"fixture": {&"flags": [true, false, null], &"counter": 3, &"fraction": .1, &"safe_integer": 9007199254740991, &"state": &"idle", &"nested": {&"enabled": false}}}
    partial.milestones = {&"fixture_seen": true}
    partial.achievement_ids = [&"fixture_optional"]
    var complete := partial.copy_validated()
    complete.stage_id = &"s15_dawn"
    complete.collected_fragments = SaveGame.FOUND_ORDER.duplicate()
    complete.game_completed = true
    for sample in [fresh, partial, complete]:
        var parser := JSON.new()
        _check(parser.parse(JSON.stringify(sample.to_dict(), "", true, true)) == OK, "Actual JSON parse")
        var result := SaveGame.decode(parser.data)
        _check(result["error"] == OK and result["data"].to_dict() == sample.to_dict(), "Actual JSON round trip")
    _check(complete.to_dict()["achievement_ids"] == ["fixture_optional"], "Completion altered optional flags")
    var extracted := partial.to_dict()
    extracted["world_states"]["fixture"]["flags"][0] = false
    _check(partial.world_states["fixture"]["flags"][0], "Dictionary exposes DTO mutable state")
    var copied := partial.copy_validated()
    copied.world_states["fixture"]["nested"]["enabled"] = true
    _check(not partial.world_states["fixture"]["nested"]["enabled"], "DTO copy shares nested state")
    print("SAVE_DTO checked: fresh/partial/complete JSON round trips, StringName normalization, optional flags and nested copy isolation")

    for missing in SaveGame.FIELDS:
        var value := baseline.duplicate(true)
        value.erase(missing)
        _invalid(value, "missing " + missing)
    var unknown := baseline.duplicate(true)
    unknown["scene_path"] = "res://a_scene.tscn"
    _invalid(unknown, "unknown scene path field")
    for version in [0, -1, true, "1", 1.5, NAN, INF]:
        var value := baseline.duplicate(true)
        value["save_version"] = version
        _invalid(value, "version " + str(version))
    var future := {"save_version": 2, "future_fields": []}
    _invalid(future, "future schema protection", ERR_UNAVAILABLE)
    for pair in [["stage_id", "s16_future"], ["stage_id", "s99_unknown"], ["stage_id", "res://world.tscn"], ["stage_id", 0], ["checkpoint_id", "../spawn"], ["checkpoint_id", "x".repeat(97)], ["game_completed", 1], ["collected_fragments", ["hearth"]], ["collected_fragments", ["star", "star"]], ["collected_fragments", ["unknown"]], ["world_states", []], ["world_states", {"fixture": 3}], ["milestones", {"seen": 1}], ["achievement_ids", ["same", "same"]], ["achievement_ids", ["res://actor"]]]:
        var value := baseline.duplicate(true)
        value[pair[0]] = pair[1]
        _invalid(value, pair[0] + " type/domain")
    var bad_completion := baseline.duplicate(true)
    bad_completion["game_completed"] = true
    _invalid(bad_completion, "premature completion")
    var complete_without_fragments := complete.to_dict()
    complete_without_fragments["collected_fragments"] = []
    _invalid(complete_without_fragments, "incomplete fragment completion")
    var object := Node.new()
    for hostile in [object, Resource.new(), Vector3.ZERO, Color.WHITE, PackedByteArray([1]), NAN, INF, 9007199254740992, "x".repeat(513)]:
        var value := baseline.duplicate(true)
        value["world_states"] = {"fixture": {"value": hostile}}
        _invalid(value, "non-JSON/unsafe value")
    object.free()
    var deep: Dictionary = {"value": true}
    for i in 12:
        deep = {"nested": deep}
    var excessive := baseline.duplicate(true)
    excessive["world_states"] = {"fixture": deep}
    _invalid(excessive, "excessive depth")
    excessive["world_states"] = {"fixture": {"items": range(5000)}}
    _invalid(excessive, "excessive nodes")
    var large_text := []
    for i in 800:
        large_text.append("я".repeat(512))
    excessive["world_states"] = {"fixture": {"items": large_text}}
    _invalid(excessive, "serialized UTF-8 byte limit")
    var cyclic := {}
    cyclic["self"] = cyclic
    excessive["world_states"] = {"fixture": cyclic}
    _invalid(excessive, "cyclic dictionary")
    cyclic.clear()
    print("SAVE_DTO checked: required/unknown fields, supported/future schema, identifiers/types/found order/completion, objects/resources/vectors, nonfinite/unsafe numbers, depth/nodes/UTF-8 size and cycles")

    _check(GameState.apply_save(partial) == OK, "Partial state apply")
    var stable := GameState.capture_save().to_dict()
    partial.world_states["fixture"]["flags"][0] = false
    _check(GameState.world_states["fixture"]["flags"][0], "Apply shares input DTO")
    var snapshot := GameState.capture_save()
    snapshot.world_states["fixture"]["flags"][1] = true
    _check(not GameState.world_states["fixture"]["flags"][1], "Capture shares GameState")
    var invalid_dto := SaveGame.new()
    invalid_dto.collected_fragments = [&"hearth"]
    _check(GameState.apply_save(invalid_dto) == ERR_INVALID_DATA and GameState.capture_save().to_dict() == stable, "Invalid apply partially mutated state")
    _check(GameState.apply_save(null) == ERR_INVALID_DATA, "Null apply accepted")
    GameState.world_states = {"fixture": {"value": Resource.new()}}
    _check(GameState.capture_save() == null, "Capture accepted Resource")
    cyclic["self"] = cyclic
    GameState.world_states = {"fixture": cyclic}
    _check(GameState.capture_save() == null, "Capture recursively copied cyclic state before validation")
    cyclic.clear()
    _check(GameState.apply_save(complete) == OK and GameState.game_completed, "Complete state apply")
    GameState.reset_for_new_game()
    _check(GameState.capture_save().to_dict() == baseline, "New Game reset did not clear new logical fields")
    _check(GameState.apply_save(original) == OK, "Original state restore")
    _check(_files() == files and SettingsManager.snapshot() == settings, "DTO/state altered production files/settings")
    _check(InputManager.mode == mode and not get_tree().paused and SaveManager.get("_dirty") == dirty and [AudioDirector.current_stage, AudioDirector.current_state] == audio and _events == 0, "Capture/apply caused routing/input/audio/dirty/event side effects")
    print("SAVE_DTO checked: transactional GameState apply/capture, invalid-state preservation, reset and production file/service integrity")
    if _failures.is_empty():
        print("SAVE_DTO PASS: typed v1 logical state, strict bounded validation, JSON round trips and isolated transactional capture/apply")
    get_tree().quit(0 if _failures.is_empty() else 1)

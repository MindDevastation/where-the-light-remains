extends Node
## Explicit destructive-choice semantics, with prior bytes durably preserved.

class FixtureWriter extends "res://autoload/save_manager.gd":
    var directory := ""
    var fail_primary := false
    func _primary_path() -> String:
        return directory.path_join("save.json")
    func _backup_path() -> String:
        return directory.path_join("backup.json")
    func _replace_file(temporary: String, destination: String) -> Error:
        return ERR_FILE_CANT_WRITE if fail_primary and destination == _primary_path() else super._replace_file(temporary, destination)

var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
    get_tree().create_timer(20.0, true).timeout.connect(func() -> void: get_tree().quit(1))
    _run.call_deferred()


func _check(condition: bool, message: String) -> void:
    _checks += 1
    if not condition:
        _failures.append(message)
        push_error("NEW_GAME_SAVE FAIL: " + message)


func _store(path: String, text: String) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    _check(file != null, "Test-owned file writable")
    if file != null:
        file.store_string(text)
        file.close()


func _hashes(writer: FixtureWriter) -> Array[String]:
    return [FileAccess.get_sha256(writer._primary_path()), FileAccess.get_sha256(writer._backup_path())]


func _run() -> void:
    var original_state := GameState.capture_save().to_dict()
    var original_dirty: bool = SaveManager.get("_dirty")
    var production := [FileAccess.get_sha256(SaveManager.SAVE_PATH), FileAccess.get_sha256(SaveManager.BACKUP_PATH)]
    var writer := FixtureWriter.new()
    add_child(writer)
    var fresh := SaveGame.new()
    for scenario in ["valid", "corrupt", "missing", "rollback", "future", "directory"]:
        writer.directory = "user://new_game_tests/" + scenario
        _check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(writer.directory)) == OK, "Isolated scenario directory")
        if scenario in ["valid", "rollback"]:
            var old := SaveGame.new()
            old.stage_id = &"s01_observatory"
            old.checkpoint_id = &"old_progress"
            _store(writer._primary_path(), JSON.stringify(old.to_dict()))
            old.checkpoint_id = &"older_progress"
            _store(writer._backup_path(), JSON.stringify(old.to_dict()))
        if scenario == "corrupt":
            _store(writer._primary_path(), "{broken primary\n")
            _store(writer._backup_path(), "broken backup\n")
        if scenario == "future":
            var future := fresh.to_dict()
            future["save_version"] = 99
            _store(writer._primary_path(), JSON.stringify(future))
        if scenario == "directory":
            _check(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(writer._primary_path())) == OK, "Physical directory IO obstacle")
        var before := _hashes(writer)
        _check(writer.write_new_game(fresh)["error"] == ERR_UNAUTHORIZED and _hashes(writer) == before, "No unconfirmed reset or file mutation")
        var bad := fresh.copy_validated()
        bad.stage_id = &"s01_observatory"
        _check(writer.write_new_game(bad, true)["error"] == ERR_INVALID_DATA, "New Game rejects non-fresh logical payload")
        writer.fail_primary = scenario == "rollback"
        var result := writer.write_new_game(fresh, true)
        if scenario in ["future", "directory"]:
            _check(result["error"] != OK and result["history"].is_empty() and _hashes(writer) == before, "Future schema or actual IO obstacle stays protected")
        else:
            _check(not result["history"].is_empty(), "Explicit choice creates a history receipt")
            if scenario == "rollback":
                _check(result["error"] == ERR_FILE_CANT_WRITE and result["rollback_error"] == OK and _hashes(writer) == before, "Partial replacement restores both original slots byte-for-byte")
            else:
                _check(result["error"] == OK and writer.read_save()["data"].to_dict() == fresh.to_dict(), "Confirmed choice writes fresh typed primary")
                _check(writer._read_file(writer._backup_path())["data"].to_dict() == fresh.to_dict(), "New backup belongs to the same fresh game")
            if scenario != "missing":
                _check([FileAccess.get_sha256(result["history"].path_join("primary.json")), FileAccess.get_sha256(result["history"].path_join("backup.json"))] == before, "Both original valid/corrupt files retained exactly in history")
            _check(FileAccess.file_exists(result["history"].path_join("manifest.json")), "History manifest remains available")
        for file in DirAccess.get_files_at(writer.directory):
            _check(not file.contains(".tmp_"), "No temporary slot garbage after transaction")
    _check(GameState.capture_save().to_dict() == original_state and SaveManager.get("_dirty") == original_dirty, "Disk-only operation never applies state or clears dirty globals")
    _check([FileAccess.get_sha256(SaveManager.SAVE_PATH), FileAccess.get_sha256(SaveManager.BACKUP_PATH)] == production, "Production slot bytes untouched by isolated fixtures")
    writer.queue_free()
    if _failures.is_empty():
        print("NEW_GAME_SAVE PASS: ", _checks, " assertions; explicit choice, exact history, corrupt/missing reset, rollback and future/IO protection")
    get_tree().quit(0 if _failures.is_empty() else 1)

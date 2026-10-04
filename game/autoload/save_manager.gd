extends Node

const SAVE_PATH := "user://savegame.json"
const BACKUP_PATH := "user://savegame.backup.json"
var _dirty := false
var _writing := false

func mark_dirty() -> void:
    _dirty = true

func flush_if_dirty() -> Error:
    if not _dirty:
        return OK
    var saved := GameState.capture_save()
    if saved == null:
        return ERR_INVALID_DATA
    var error := write_save(saved)
    if error == OK:
        _dirty = false
    return error


func _primary_path() -> String:
    return SAVE_PATH


func _backup_path() -> String:
    return BACKUP_PATH


func read_save() -> Dictionary:
    # Reading never applies, repairs, writes or clears dirty state.
    var primary := _read_file(_primary_path())
    var backup := _read_file(_backup_path())
    var result := {"error": primary["error"], "data": null, "source": "none",
        "primary_error": primary["error"], "backup_error": backup["error"],
        "needs_new_game": false}
    if primary["error"] == OK:
        result.merge({"error": OK, "data": primary["data"], "source": "primary"}, true)
    elif _recoverable(primary["error"]):
        if backup["error"] == OK:
            result.merge({"error": OK, "data": backup["data"], "source": "backup"}, true)
        else:
            result["error"] = backup["error"] if not _recoverable(backup["error"]) else ERR_INVALID_DATA
            result["needs_new_game"] = _recoverable(backup["error"])
    return result


func write_save(saved: SaveGame) -> Error:
    if _writing:
        return ERR_BUSY
    if saved == null:
        return ERR_INVALID_DATA
    var validated := saved.copy_validated()
    if validated == null:
        return ERR_INVALID_DATA
    var primary_path := _primary_path()
    var backup_path := _backup_path()
    if primary_path == backup_path or primary_path.get_base_dir() != backup_path.get_base_dir():
        return ERR_INVALID_PARAMETER
    var primary := _read_file(primary_path)
    var backup := _read_file(backup_path)
    # Never replace unknown schema or bypass permission/network/IO errors.
    for prior in [primary, backup]:
        if prior["error"] != OK and not _recoverable(prior["error"]):
            return prior["error"]
    if primary["error"] != OK and backup["error"] != OK and (primary["error"] != ERR_FILE_NOT_FOUND or backup["error"] != ERR_FILE_NOT_FOUND):
        return ERR_INVALID_DATA
    var bytes := JSON.stringify(validated.to_dict(), "", true, true).to_utf8_buffer()
    _writing = true
    var prepared := _prepare_file(primary_path, bytes)
    if prepared["error"] != OK:
        _writing = false
        return prepared["error"]
    # Preserve last valid primary, never copy corruption over a valid backup.
    var error: Error = OK
    if primary["error"] == OK:
        error = _atomic_replace(backup_path, primary["bytes"])
    elif backup["error"] == ERR_FILE_NOT_FOUND:
        error = _atomic_replace(backup_path, bytes)
    if error == OK:
        error = _replace_file(prepared["path"], primary_path)
    var cleanup := _remove_temporary(prepared["path"])
    if cleanup != OK and error == OK:
        error = cleanup
    _writing = false
    return error


func write_new_game(saved: SaveGame, confirmed: bool = false) -> Dictionary:
    # Explicit Boot choice only. Preserve exact prior bytes, including corruption,
    # before replacing either slot. Ordinary read/flush never calls this path.
    var result := {"error": ERR_UNAUTHORIZED, "history": "", "rollback_error": OK}
    if not confirmed:
        return result
    if _writing:
        result["error"] = ERR_BUSY
        return result
    var fresh := saved.copy_validated() if saved != null else null
    if fresh == null:
        result["error"] = ERR_INVALID_DATA
        return result
    var expected := SaveGame.new()
    expected.world_states = fresh.world_states.duplicate(true)
    if fresh.to_dict() != expected.to_dict():
        result["error"] = ERR_INVALID_DATA
        return result
    var primary := _primary_path()
    var backup := _backup_path()
    if primary == backup or primary.get_base_dir() != backup.get_base_dir():
        result["error"] = ERR_INVALID_PARAMETER
        return result
    for path in [primary, backup]:
        var prior := _read_file(path)
        if prior["error"] != OK and not _recoverable(prior["error"]):
            result["error"] = prior["error"]
            return result
    _writing = true
    var history := primary.get_base_dir().path_join("savegame_history").path_join("new_game_%d_%d_%d" % [int(Time.get_unix_time_from_system()), OS.get_process_id(), Time.get_ticks_usec()])
    var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(history))
    var originals := {}
    if error == OK:
        result["history"] = history
        for path in [primary, backup]:
            var record := {"exists": FileAccess.file_exists(path), "copy": "", "sha256": ""}
            if record["exists"]:
                record["copy"] = history.path_join("primary.json" if path == primary else "backup.json")
                record["sha256"] = FileAccess.get_sha256(path)
                error = DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(record["copy"]))
                if error == OK and (record["sha256"].is_empty() or FileAccess.get_sha256(record["copy"]) != record["sha256"]):
                    error = ERR_FILE_CANT_WRITE
            originals[path] = record
            if error != OK:
                break
    if error == OK:
        var manifest := FileAccess.open(history.path_join("manifest.json"), FileAccess.WRITE)
        if manifest == null:
            error = FileAccess.get_open_error()
        else:
            manifest.store_string(JSON.stringify({"operation": "explicit_new_game", "originals": originals}, "  "))
            manifest.flush()
            error = manifest.get_error()
            manifest.close()
    var bytes := JSON.stringify(fresh.to_dict(), "", true, true).to_utf8_buffer()
    var prepared: Array[Dictionary] = []
    if error == OK:
        for path in [primary, backup]:
            var temporary := _prepare_file(path, bytes)
            prepared.append(temporary)
            error = temporary["error"]
            if error != OK:
                break
    if error == OK:
        error = _replace_file(prepared[1]["path"], backup)
        if error == OK:
            error = _replace_file(prepared[0]["path"], primary)
        if error != OK:
            for path in [primary, backup]:
                var rollback := _restore_new_game_original(path, originals[path])
                if rollback != OK:
                    result["rollback_error"] = rollback
    for temporary in prepared:
        var cleanup := _remove_temporary(temporary["path"])
        if cleanup != OK and error == OK:
            error = cleanup
    _writing = false
    result["error"] = error
    return result


func _restore_new_game_original(path: String, record: Dictionary) -> Error:
    if not record["exists"]:
        return DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) if FileAccess.file_exists(path) else OK
    if FileAccess.file_exists(path) and FileAccess.get_sha256(path) == record["sha256"]:
        return OK
    var temporary := path + ".tmp_rollback_" + str(OS.get_process_id()) + "_" + str(Time.get_ticks_usec())
    var error := DirAccess.copy_absolute(ProjectSettings.globalize_path(record["copy"]), ProjectSettings.globalize_path(temporary))
    if error == OK:
        error = _replace_file(temporary, path) if FileAccess.get_sha256(temporary) == record["sha256"] else ERR_FILE_CANT_WRITE
    var cleanup := _remove_temporary(temporary)
    return cleanup if cleanup != OK and error == OK else error


func _recoverable(error: Error) -> bool:
    return error in [ERR_FILE_NOT_FOUND, ERR_INVALID_DATA, ERR_PARSE_ERROR]


func _read_file(path: String) -> Dictionary:
    var result := {"error": OK, "data": null, "bytes": PackedByteArray()}
    # A directory is an IO obstacle, never a missing/corrupt save to overwrite.
    if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)):
        result["error"] = ERR_FILE_CANT_OPEN
        return result
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        result["error"] = FileAccess.get_open_error()
        return result
    var length := file.get_length()
    if length <= 0 or length > SaveGame.MAX_SERIALIZED_BYTES:
        file.close()
        result["error"] = ERR_INVALID_DATA
        return result
    var bytes := file.get_buffer(length)
    var error := file.get_error()
    file.close()
    if bytes.size() != length or error not in [OK, ERR_FILE_EOF]:
        result["error"] = error if error not in [OK, ERR_FILE_EOF] else ERR_FILE_CANT_READ
        return result
    if not _valid_utf8(bytes):
        result["error"] = ERR_INVALID_DATA
        return result
    var text := bytes.get_string_from_utf8()
    if text.to_utf8_buffer() != bytes:
        result["error"] = ERR_INVALID_DATA
        return result
    var parser := JSON.new()
    if parser.parse(text) != OK:
        result["error"] = ERR_PARSE_ERROR
        return result
    var decoded := SaveGame.decode(parser.data)
    result["error"] = decoded["error"]
    result["data"] = decoded["data"]
    if decoded["error"] == OK:
        result["bytes"] = bytes
    return result


func _atomic_replace(path: String, bytes: PackedByteArray) -> Error:
    var prepared := _prepare_file(path, bytes)
    if prepared["error"] != OK:
        return prepared["error"]
    var error := _replace_file(prepared["path"], path)
    var cleanup := _remove_temporary(prepared["path"])
    return cleanup if cleanup != OK and error == OK else error


func _prepare_file(path: String, bytes: PackedByteArray) -> Dictionary:
    var temporary := path + ".tmp_" + str(OS.get_process_id()) + "_" + str(Time.get_ticks_usec())
    var file := FileAccess.open(temporary, FileAccess.WRITE)
    if file == null:
        return {"error": FileAccess.get_open_error(), "path": ""}
    file.store_buffer(bytes)
    file.flush()
    var error := file.get_error()
    file.close()
    # Detect short writes/readback mismatch before changing either valid file.
    if error == OK:
        var verified := _read_file(temporary)
        if verified["error"] != OK or verified["bytes"] != bytes:
            error = ERR_FILE_CANT_WRITE
    if error != OK:
        _remove_temporary(temporary)
        return {"error": error, "path": ""}
    return {"error": OK, "path": temporary}


func _remove_temporary(path: String) -> Error:
    if not path.is_empty() and FileAccess.file_exists(path):
        return DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    return OK


func _valid_utf8(bytes: PackedByteArray) -> bool:
    # Reject malformed UTF-8 before conversion, avoiding lossy replacement text.
    var index := 0
    while index < bytes.size():
        var lead := int(bytes[index])
        if lead < 128:
            index += 1
            continue
        var count := 1 if lead >= 0xc2 and lead <= 0xdf else 2 if lead >= 0xe0 and lead <= 0xef else 3 if lead >= 0xf0 and lead <= 0xf4 else -1
        if count < 0 or index + count >= bytes.size():
            return false
        for offset in range(1, count + 1):
            if bytes[index + offset] & 0xc0 != 0x80:
                return false
        var second := int(bytes[index + 1])
        if (lead == 0xe0 and second < 0xa0) or (lead == 0xed and second >= 0xa0) or (lead == 0xf0 and second < 0x90) or (lead == 0xf4 and second >= 0x90):
            return false
        index += count + 1
    return true


func _replace_file(temporary: String, destination: String) -> Error:
    return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(destination))

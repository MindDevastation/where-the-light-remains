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
    # Preserve last valid primary, never copy corruption over a valid backup.
    var error: Error = OK
    if primary["error"] == OK:
        error = _atomic_replace(backup_path, primary["bytes"])
    elif backup["error"] == ERR_FILE_NOT_FOUND:
        error = _atomic_replace(backup_path, bytes)
    if error == OK:
        error = _atomic_replace(primary_path, bytes)
    _writing = false
    return error


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
    var temporary := path + ".tmp_" + str(OS.get_process_id()) + "_" + str(Time.get_ticks_usec())
    var file := FileAccess.open(temporary, FileAccess.WRITE)
    if file == null:
        return FileAccess.get_open_error()
    file.store_buffer(bytes)
    file.flush()
    var error := file.get_error()
    file.close()
    # Detect short writes/readback mismatch before changing either valid file.
    if error == OK:
        var verified := _read_file(temporary)
        if verified["error"] != OK or verified["bytes"] != bytes:
            error = ERR_FILE_CANT_WRITE
    if error == OK:
        error = _replace_file(temporary, path)
    if FileAccess.file_exists(temporary):
        var cleanup := DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
        if cleanup != OK and error == OK:
            error = cleanup
    return error


func _replace_file(temporary: String, destination: String) -> Error:
    return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(destination))

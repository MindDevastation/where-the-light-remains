extends Node
## CLI-only physical file tests. Every write is isolated from production saves.

class FixtureWriter extends "res://autoload/save_manager.gd":
    var directory: String
    var fail_destination := ""
    var replacement_count := 0
    var fail_prepare := false
    var primary_prepared := false
    var sequence_ok := true

    func _primary_path() -> String:
        return directory + "/save.json"

    func _backup_path() -> String:
        return directory + "/backup.json"

    func _replace_file(temporary: String, destination: String) -> Error:
        replacement_count += 1
        if destination == _backup_path():
            sequence_ok = sequence_ok and primary_prepared
        if destination == fail_destination:
            return ERR_FILE_CANT_WRITE
        return super._replace_file(temporary, destination)

    func _prepare_file(path: String, bytes: PackedByteArray) -> Dictionary:
        if path == _primary_path() and fail_prepare:
            return {"error": ERR_FILE_CANT_WRITE, "path": ""}
        var result := super._prepare_file(path, bytes)
        if path == _primary_path():
            primary_prepared = result["error"] == OK
        return result

var _failures: Array[String] = []
var _exit_errors := 0
var _fade_cancelled := false


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().create_timer(30.0, true).timeout.connect(func() -> void:
        push_error("SAVE_IO FAIL: timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()


func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
        push_error("SAVE_IO FAIL: " + message)


func _hash(path: String) -> String:
    return FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"


func _production_hashes() -> Dictionary:
    return {"settings": _hash(SettingsManager.SETTINGS_PATH), "primary": _hash(SaveManager.SAVE_PATH), "backup": _hash(SaveManager.BACKUP_PATH)}


func _store(path: String, bytes: PackedByteArray) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    _check(file != null, "Fixture write unavailable")
    if file != null:
        file.store_buffer(bytes)
        file.flush()
        _check(file.get_error() == OK, "Fixture write failed")
        file.close()


func _no_temps(directory: String) -> void:
    for filename in DirAccess.get_files_at(directory):
        _check(not filename.contains(".tmp_"), "Temporary file leaked: " + filename)


func _key_escape() -> void:
    var event := InputEventKey.new()
    event.keycode = KEY_ESCAPE
    event.pressed = true
    Input.parse_input_event(event)
    Input.flush_buffered_events()


func _click(button: Button) -> void:
    await get_tree().process_frame
    var position := button.get_global_rect().get_center()
    var motion := InputEventMouseMotion.new()
    motion.position = position
    motion.global_position = position
    Input.parse_input_event(motion)
    Input.flush_buffered_events()
    for pressed in [true, false]:
        var event := InputEventMouseButton.new()
        event.position = position
        event.global_position = position
        event.button_index = MOUSE_BUTTON_LEFT
        event.pressed = pressed
        Input.parse_input_event(event)
        Input.flush_buffered_events()
    await get_tree().process_frame


func _start_fade(fade: FadeOverlay) -> void:
    _fade_cancelled = not await fade.fade_to(1.0, 1.0)


func _run() -> void:
    print("SAVE_IO runtime: ", Engine.get_version_info()["string"], "; display=", DisplayServer.get_name())
    if DisplayServer.get_name() == "headless":
        get_tree().root.size = Vector2i(1280, 720)
    var original := GameState.capture_save()
    var hashes := _production_hashes()
    var dirty: bool = SaveManager.get("_dirty")
    var settings := SettingsManager.snapshot()
    var audio := [AudioDirector.current_stage, AudioDirector.current_state]
    var writer := FixtureWriter.new()
    writer.directory = "user://save_io_fixture_" + str(OS.get_process_id()) + "_" + str(Time.get_ticks_usec())
    _check(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(writer.directory)) == OK, "Fixture directory")
    var primary := writer._primary_path()
    var backup := writer._backup_path()
    var missing := writer.read_save()
    _check(missing["needs_new_game"] and missing["data"] == null and _hash(primary) == "absent", "Missing save is read-only decision")
    var fresh := SaveGame.new()
    _check(writer.write_save(fresh) == OK, "First atomic write")
    var first_hash := _hash(primary)
    _check(first_hash == _hash(backup) and first_hash != "absent", "First save creates recoverable backup")
    var partial := fresh.copy_validated()
    partial.stage_id = &"s02_warmth_light"
    partial.collected_fragments = [&"star", &"hearth"]
    partial.world_states = {"fixture": {"counter": 9007199254740991, "fraction": .1, "text": "Проверка"}}
    _check(writer.write_save(partial) == OK, "Second atomic write")
    var second_hash := _hash(primary)
    var loaded := writer.read_save()
    _check(loaded["error"] == OK and loaded["source"] == "primary" and loaded["data"].to_dict() == partial.to_dict(), "Real file exact round trip")
    _check(_hash(backup) == first_hash and second_hash != first_hash, "Backup retains last valid primary")
    _check(writer.sequence_ok, "New primary prepared before backup replacement")
    loaded["data"].world_states["fixture"]["counter"] = 1
    _check(writer.read_save()["data"].world_states["fixture"]["counter"] == SaveGame.MAX_SAFE_INTEGER, "Read snapshots isolated")
    writer.fail_prepare = true
    _check(writer.write_save(fresh) == ERR_FILE_CANT_WRITE and _hash(primary) == second_hash and _hash(backup) == first_hash, "Primary preparation failure preserves both files")
    writer.fail_prepare = false
    writer.fail_destination = backup
    _check(writer.write_save(fresh) == ERR_FILE_CANT_WRITE and _hash(primary) == second_hash and _hash(backup) == first_hash, "Backup replace failure preserves both old files")
    _no_temps(writer.directory)
    writer.fail_destination = primary
    _check(writer.write_save(fresh) == ERR_FILE_CANT_WRITE and _hash(primary) == second_hash and _hash(backup) == second_hash, "Primary replace failure preserves valid old primary and backup")
    _no_temps(writer.directory)
    writer.fail_destination = ""
    _store(primary, "{broken".to_utf8_buffer())
    var bad_hash := _hash(primary)
    var recovered := writer.read_save()
    _check(recovered["error"] == OK and recovered["source"] == "backup" and recovered["primary_error"] == ERR_PARSE_ERROR, "Corrupt primary recovers backup")
    _check(_hash(primary) == bad_hash and _hash(backup) == second_hash, "Recovery is read-only")
    _check(writer.write_save(fresh) == OK and _hash(backup) == second_hash, "Recovery write never backs up corruption")
    var future := partial.to_dict()
    future["save_version"] = 2
    _store(primary, JSON.stringify(future).to_utf8_buffer())
    var future_hash := _hash(primary)
    _check(writer.read_save()["error"] == ERR_UNAVAILABLE and not writer.read_save()["needs_new_game"], "Future primary cannot downgrade to backup")
    _check(writer.write_save(fresh) == ERR_UNAVAILABLE and _hash(primary) == future_hash and _hash(backup) == second_hash, "Future schema cannot be overwritten")
    _store(primary, JSON.stringify(fresh.to_dict()).to_utf8_buffer())
    _store(backup, JSON.stringify(future).to_utf8_buffer())
    var protected_primary := _hash(primary)
    _check(writer.write_save(partial) == ERR_UNAVAILABLE and _hash(primary) == protected_primary, "Future backup protected too")
    _store(primary, "false".to_utf8_buffer())
    _store(backup, "{broken".to_utf8_buffer())
    var both_hashes := [_hash(primary), _hash(backup)]
    var both_bad := writer.read_save()
    _check(both_bad["needs_new_game"] and both_bad["data"] == null and writer.write_save(fresh) == ERR_INVALID_DATA, "Both corrupt requires explicit decision")
    _check([_hash(primary), _hash(backup)] == both_hashes, "Both corrupt files preserved")
    var oversized := PackedByteArray()
    oversized.resize(SaveGame.MAX_SERIALIZED_BYTES + 1)
    oversized.fill(32)
    _store(primary, oversized)
    _check(writer.read_save()["primary_error"] == ERR_INVALID_DATA, "Oversize bounded before JSON parsing")
    for bytes in [PackedByteArray([0xff]), PackedByteArray([0xc0, 0x80]), PackedByteArray([0xe0, 0x80, 0x80]), PackedByteArray([0xed, 0xa0, 0x80]), PackedByteArray([0xf0, 0x80, 0x80, 0x80]), PackedByteArray([0xf4, 0x90, 0x80, 0x80]), PackedByteArray([0xe2, 0x82])]:
        _store(primary, bytes)
        _check(writer.read_save()["primary_error"] == ERR_INVALID_DATA, "Malformed UTF-8 rejected")
    _check(writer._valid_utf8("Проверка 🌅".to_utf8_buffer()) and writer._valid_utf8(PackedByteArray([0xf4, 0x8f, 0xbf, 0xbf])), "Valid multibyte UTF-8 including upper Unicode boundary")
    _store(primary, JSON.stringify(fresh.to_dict()).to_utf8_buffer())
    _store(backup, JSON.stringify(fresh.to_dict()).to_utf8_buffer())
    GameState.apply_save(partial)
    writer.mark_dirty()
    writer.fail_destination = primary
    _check(writer.flush_if_dirty() == ERR_FILE_CANT_WRITE and writer.get("_dirty"), "Failed dirty flush remains dirty")
    writer.fail_destination = ""
    _check(writer.flush_if_dirty() == OK and not writer.get("_dirty") and writer.read_save()["data"].to_dict() == partial.to_dict(), "Successful dirty flush commits captured state")
    var replacements := writer.replacement_count
    _check(writer.flush_if_dirty() == OK and writer.replacement_count == replacements, "Clean flush performs no IO")
    GameState.world_states = {"fixture": {"bad": Vector3.ONE}}
    writer.mark_dirty()
    var before_invalid := _hash(primary)
    _check(writer.flush_if_dirty() == ERR_INVALID_DATA and writer.get("_dirty") and _hash(primary) == before_invalid, "Invalid capture never changes disk/dirty")
    _check(writer.write_save(null) == ERR_INVALID_DATA, "Null resource rejected")
    var obstacle := writer.directory + "/obstacle"
    _check(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(obstacle)) == OK, "IO obstacle fixture")
    var failing := FixtureWriter.new()
    failing.directory = obstacle + "/missing_parent"
    _check(failing.write_save(fresh) != OK and not FileAccess.file_exists(failing._primary_path()), "Actual missing-parent write failure")
    failing.free()
    _check(writer._read_file(obstacle)["error"] == ERR_FILE_CANT_OPEN, "Directory obstacle is IO error, not corruption")
    print("SAVE_IO checked: first/previous backup, real JSON round trips, corruption fallback/read-only decisions, future-schema protection, backup/primary replacement failures, no temp leaks, bounded reads and dirty commit")

    # Force App's real flush to fail before any production IO. Actual modal/close path.
    SaveManager.mark_dirty()
    App.exit_failed.connect(func(_error: Error) -> void: _exit_errors += 1)
    var game := preload("res://core/game_root/game_root.tscn").instantiate()
    add_child(game)
    await get_tree().process_frame
    var dialog: ExitFailureDialog = game.get_node("UILayer/ExitFailureDialog")
    var fade: FadeOverlay = game.get_node("TransitionLayer/FadeOverlay")
    InputManager.set_mode(InputManager.Mode.GAMEPLAY)
    _start_fade(fade)
    App.request_safe_exit()
    await get_tree().process_frame
    _check(dialog.visible and get_tree().paused and InputManager.mode == InputManager.Mode.UI and SaveManager.get("_dirty") and _exit_errors == 1, "Failed App exit keeps game alive, dirty and modal")
    _check(_fade_cancelled and not fade.visible and not fade.busy, "Error cancels fade before showing usable modal")
    _check(dialog._message.get_theme_font("font").has_char("Н".unicode_at(0)), "Dialog Cyrillic glyph")
    await _click(dialog.retry_button)
    _check(_exit_errors == 2 and dialog.visible, "Retry repeats safe exit and retains ownership")
    get_tree().root.close_requested.emit()
    _check(_exit_errors == 3 and dialog.visible and not get_tree().auto_accept_quit, "Native close signal uses safe-exit guard")
    if DisplayServer.get_name() != "headless":
        await RenderingServer.frame_post_draw
        for argument in OS.get_cmdline_user_args():
            if argument.begins_with("--save-dialog-output="):
                var image := get_viewport().get_texture().get_image()
                _check(image.save_png(argument.trim_prefix("--save-dialog-output=")) == OK, "Dialog screenshot")
    await _click(dialog.stay_button)
    _check(not dialog.visible and not get_tree().paused and InputManager.mode == InputManager.Mode.GAMEPLAY, "Stay restores owned pause/mode")
    InputManager.set_paused(true)
    InputManager.set_mode(InputManager.Mode.UI)
    App.request_safe_exit()
    _key_escape()
    await get_tree().process_frame
    _check(not dialog.visible and get_tree().paused and InputManager.mode == InputManager.Mode.UI, "Esc leaves prior pause intact")
    InputManager.set_paused(false)
    InputManager.set_mode(InputManager.Mode.GAMEPLAY)
    App.request_safe_exit()
    InputManager.set_mode(InputManager.Mode.DISABLED)
    dialog.close()
    _check(InputManager.mode == InputManager.Mode.DISABLED and not get_tree().paused, "Later lock preserved after error modal")
    InputManager.set_mode(InputManager.Mode.GAMEPLAY)
    App.request_safe_exit()
    game.queue_free()
    await get_tree().process_frame
    _check(not get_tree().paused and InputManager.mode == InputManager.Mode.GAMEPLAY, "Removed failure scene releases only owned pause/mode")
    GameState.apply_save(original)
    SaveManager.set("_dirty", dirty)
    InputManager.set_mode(InputManager.Mode.UI)
    _check(_production_hashes() == hashes and SettingsManager.snapshot() == settings and [AudioDirector.current_stage, AudioDirector.current_state] == audio, "Production files/settings/audio unchanged")
    _no_temps(writer.directory)
    for filename in DirAccess.get_files_at(writer.directory):
        _check(DirAccess.remove_absolute(ProjectSettings.globalize_path(writer.directory + "/" + filename)) == OK, "Fixture file cleanup")
    _check(DirAccess.remove_absolute(ProjectSettings.globalize_path(obstacle)) == OK, "Obstacle cleanup")
    _check(DirAccess.remove_absolute(ProjectSettings.globalize_path(writer.directory)) == OK, "Fixture directory cleanup")
    writer.free()
    if _failures.is_empty():
        print("SAVE_IO PASS: actual atomic files/backup/recovery/dirty and failed App exit, Russian retry/stay, close guard; production files preserved")
    get_tree().quit(0 if _failures.is_empty() else 1)

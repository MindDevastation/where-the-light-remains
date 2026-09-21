extends Node
## Standalone test scene. Also exported unchanged with an actual release template.

var _failures: Array[String] = []
var _stage_events := 0
var _game: Node


func _ready() -> void:
    get_tree().create_timer(20.0).timeout.connect(func() -> void:
        push_error("DEBUG_TOOLS FAIL: timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()


func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
        push_error("DEBUG_TOOLS FAIL: " + message)


func _state() -> Dictionary:
    var fragments: Dictionary = GameState.collected_fragments
    var buses: Array = []
    for index in AudioServer.bus_count:
        buses.append([AudioServer.get_bus_name(index), AudioServer.get_bus_volume_db(index), AudioServer.is_bus_mute(index), AudioServer.is_bus_solo(index)])
    return {
        "stage": GameState.current_stage_id, "fragments": fragments.duplicate(true),
        "completed": GameState.game_completed, "dirty": SaveManager.get("_dirty"),
        "audio_stage": AudioDirector.current_stage, "audio_state": AudioDirector.current_state,
        "input": InputManager.mode, "mouse": Input.mouse_mode, "buses": buses,
        "primary": FileAccess.get_sha256(SaveManager.SAVE_PATH) if FileAccess.file_exists(SaveManager.SAVE_PATH) else "absent",
        "backup": FileAccess.get_sha256(SaveManager.BACKUP_PATH) if FileAccess.file_exists(SaveManager.BACKUP_PATH) else "absent",
    }


func _key(code: Key, pressed: bool = true, echo: bool = false) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.physical_keycode = code
    event.pressed = pressed
    event.echo = echo
    Input.parse_input_event(event)
    Input.flush_buffered_events()


func _run() -> void:
    var args := OS.get_cmdline_user_args()
    var expected := args.has("--expect-overlay")
    print("DEBUG_TOOLS runtime: ", Engine.get_version_info()["string"], "; debug=", OS.is_debug_build(), "; display=", DisplayServer.get_name(), "; expected_overlay=", expected)
    var services: Array[String] = []
    for property in ProjectSettings.get_property_list():
        var setting: String = property["name"]
        if setting.begins_with("autoload/"):
            services.append(setting.trim_prefix("autoload/"))
    services.sort()
    _check(services == ["App", "AudioDirector", "EventBus", "GameState", "InputManager", "SaveManager", "SceneRouter", "SettingsManager"], "Autoload baseline changed")
    EventBus.stage_changed.connect(func(_stage: StringName) -> void: _stage_events += 1)
    var before := _state()
    # Exercise the unchanged production root, also when this harness is the
    # startup scene in a disposable release-export fixture.
    var scene: PackedScene = load("res://core/game_root/game_root.tscn")
    _game = scene.instantiate()
    get_tree().root.add_child(_game)
    get_tree().current_scene = _game
    await get_tree().process_frame
    await get_tree().create_timer(0.6).timeout
    var overlay := _game.get_node_or_null("DebugOverlay")
    _check((overlay != null) == expected, "Unexpected development-tool availability")
    _check(_state() == before, "Startup/inspection mutated gameplay, files, audio or input")
    _check(_stage_events == 1, "Inspection emitted an extra stage event")
    _check(SceneRouter.get("_world_slot") == _game.get_node("WorldSlot"), "WorldSlot binding lost")
    if expected and overlay != null:
        await _check_overlay(overlay)
    elif not expected:
        _check(not ResourceLoader.has_cached("res://core/debug/debug_overlay.tscn"), "Disabled tools were loaded")
        print("DEBUG_TOOLS checked: disabled path does not load development resources")
    _check(_state() == before, "Test did not restore its fixtures or inspection changed state")
    _check(_stage_events == 1, "Debug input emitted a stage event")
    if _failures.is_empty():
        print("DEBUG_TOOLS PASS: gate, state/file integrity, autoloads; requesting App safe exit")
        App.request_safe_exit()
    else:
        get_tree().quit(1)


func _check_overlay(overlay: Node) -> void:
    var snapshot: Script = load("res://core/debug/debug_snapshot.gd")
    var before := _state()
    var captured: Dictionary = snapshot.capture(_game)
    captured["fragments"]["snapshot_only"] = true
    _check(not GameState.collected_fragments.has("snapshot_only"), "Snapshot shares mutable GameState data")
    _check(captured["stage"] == String(GameState.current_stage_id), "Wrong stage snapshot")
    _check(captured["buses"].size() == 10 and captured["worlds"].is_empty(), "Wrong bus/world snapshot")
    var text: Label = overlay.get_node("Panel/Margin/Text")
    _check(text.text.contains("ДИАГНОСТИКА РАЗРАБОТКИ") and text.text.contains("СОХРАНЕНИЕ"), "Russian inspector labels missing")
    var font := text.get_theme_font("font")
    for character in "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя":
        _check(font.has_char(character.unicode_at(0)), "Cyrillic glyph missing: " + character)
    for control in overlay.find_children("*", "Control", true, false):
        _check(control.mouse_filter == Control.MOUSE_FILTER_IGNORE and control.focus_mode == Control.FOCUS_NONE, "Debug UI can capture mouse/focus")

    GameState.current_stage_id = &"s02_warmth_light"
    AudioDirector.current_state = &"inspection_fixture"
    SaveManager.set("_dirty", true)
    await get_tree().create_timer(0.6).timeout
    _check(text.text.contains("s02_warmth_light") and text.text.contains("inspection_fixture"), "Live inspection did not refresh")
    _check(text.text.contains("Несохраненные изменения: да"), "Dirty save state was not shown")
    GameState.current_stage_id = before["stage"]
    AudioDirector.current_state = before["audio_state"]
    SaveManager.set("_dirty", before["dirty"])

    InputManager.set_mode(InputManager.Mode.GAMEPLAY)
    var captured_mouse := Input.mouse_mode
    _key(KEY_W)
    _key(KEY_F3)
    _check(not overlay.visible and not overlay.is_processing(), "F3 did not suspend the overlay")
    _check(Input.is_action_pressed("move_forward"), "F3 consumed held movement")
    _check(Input.mouse_mode == captured_mouse, "F3 changed mouse capture")
    _key(KEY_F3, true, true)
    _check(not overlay.visible, "Keyboard echo toggled the overlay")
    _key(KEY_F3, false)
    _key(KEY_F3)
    _check(overlay.visible and overlay.is_processing(), "F3 did not restore the overlay")
    _key(KEY_F3, false)
    _key(KEY_W, false)
    _key(KEY_E)
    _check(Input.is_action_pressed("interact"), "Interaction was intercepted")
    _key(KEY_E, false)
    _key(KEY_ESCAPE)
    _check(Input.is_action_pressed("pause") and Input.is_action_pressed("skip_sequence"), "Esc baseline changed")
    _key(KEY_ESCAPE, false)
    get_tree().paused = true
    _key(KEY_F3)
    _check(not overlay.visible, "F3 cannot hide while paused")
    _key(KEY_F3, false)
    _key(KEY_F3)
    _check(overlay.visible and get_tree().paused, "F3 changed pause state")
    _key(KEY_F3, false)
    get_tree().paused = false
    Input.mouse_mode = before["mouse"]
    _check(_state() == before, "Read-only overlay changed state during toggles")
    _check_save_preview(snapshot)
    print("DEBUG_TOOLS checked: live stage/save/audio, deep-copy snapshot, F3/echo/pause, input/capture, Cyrillic glyphs")

    if DisplayServer.get_name() != "headless":
        await get_tree().create_timer(0.6).timeout
        await RenderingServer.frame_post_draw
        var panel: Control = overlay.get_node("Panel")
        _check(panel.get_global_rect().end.y <= get_viewport().get_visible_rect().size.y, "Inspector extends below the viewport")
        _check(panel.get_global_rect().end.x <= get_viewport().get_visible_rect().size.x, "Inspector extends past the viewport edge")
        for argument in OS.get_cmdline_user_args():
            if argument.begins_with("--screenshot="):
                var path := argument.trim_prefix("--screenshot=")
                _check(get_viewport().get_texture().get_image().save_png(path) == OK, "Screenshot failed")
                print("DEBUG_TOOLS rendered Cyrillic evidence: ", path)


func _check_save_preview(snapshot: Script) -> void:
    # Fixtures are unique test files, never savegame.json or its backup.
    var path := "user://debug_inspection_fixture_%d.json" % Time.get_ticks_usec()
    _check(snapshot.inspect_save(path)["status"] == "missing", "Missing save not reported")
    var file := FileAccess.open(path, FileAccess.WRITE)
    file.store_string('{"stage_id":"s02_warmth_light","label":"Проверка"}')
    file.close()
    var hash_before := FileAccess.get_sha256(path)
    var info: Dictionary = snapshot.inspect_save(path)
    _check(info["status"] == "json_preview" and info["data"]["label"] == "Проверка", "Save JSON preview failed")
    _check(FileAccess.get_sha256(path) == hash_before, "Preview wrote to disk")
    file = FileAccess.open(path, FileAccess.WRITE)
    file.store_string('{"broken":')
    file.close()
    hash_before = FileAccess.get_sha256(path)
    _check(snapshot.inspect_save(path)["status"] == "invalid_json", "Malformed JSON not reported")
    _check(FileAccess.get_sha256(path) == hash_before, "Preview repaired/deleted malformed data")
    file = FileAccess.open(path, FileAccess.WRITE)
    file.store_string("x".repeat(262145))
    file.close()
    _check(snapshot.inspect_save(path)["status"] == "too_large", "Save preview is not bounded")
    _check(DirAccess.remove_absolute(path) == OK, "Fixture cleanup failed")
    print("DEBUG_TOOLS checked: missing/valid/malformed/oversize save preview without modifying source files")

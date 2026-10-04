extends Node
## Actual Russian menu buttons, read-only recovery and opted-in cinematic pause.

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().create_timer(30.0, true).timeout.connect(func() -> void:
        push_error("BOOT FAIL: timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()


func _check(condition: bool, message: String) -> void:
    _checks += 1
    if not condition:
        _failures.append(message)
        push_error("BOOT FAIL: " + message)


func _hashes() -> Array[String]:
    return [FileAccess.get_sha256(SaveManager.SAVE_PATH), FileAccess.get_sha256(SaveManager.BACKUP_PATH)]


func _store(path: String, text: String) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    _check(file != null, "Isolated test-owned slot writable")
    if file != null:
        file.store_string(text)
        file.close()


func _escape(pressed: bool) -> void:
    var key := InputEventKey.new()
    key.keycode = KEY_ESCAPE
    key.pressed = pressed
    Input.parse_input_event(key)
    await get_tree().process_frame


func _new_boot() -> ArchiveBoot:
    var instance := preload("res://core/boot/boot.tscn").instantiate()
    var boot := instance as ArchiveBoot
    if boot == null:
        instance.free()
        return null
    add_child(boot)
    return boot


func _run() -> void:
    var original := GameState.capture_save()
    var original_fov := SettingsManager.fov
    var original_duration := SceneRouter.fade_duration
    SceneRouter.fade_duration = .02
    var hashes := _hashes()
    var logical := GameState.capture_save().to_dict()
    var boot := _new_boot()
    _check(boot != null, "Boot resource has its parsed controller")
    if boot == null:
        get_tree().quit(1)
        return
    _check(boot.menu.visible and boot.continue_button.disabled and not boot.new_game_button.disabled, "Empty startup offers a Russian New Game without auto-start")
    _check(_hashes() == hashes and GameState.capture_save().to_dict() == logical and not SaveManager.get("_dirty"), "Boot startup inspects without applying/writing any save")
    _check(boot.game.get_node("WorldSlot").get_child_count() == 0 and not boot.game.get_node("PlayerContainer/Player").active, "Persistent GameRoot stays inactive until a choice")
    boot.settings_button.pressed.emit()
    _check(boot.settings.visible and not boot.main_panel.visible, "Actual menu Settings entry uses the reusable modal")
    boot.settings.cancel_button.pressed.emit()
    _check(not boot.settings.visible and boot.main_panel.visible and InputManager.mode == InputManager.Mode.UI, "Settings Cancel returns to menu")
    var prior := SaveGame.new()
    prior.stage_id = ArchiveProgress.INTRO
    ArchiveProgress.write_projection(prior)
    _check(SaveManager.write_save(prior) == OK, "Prepare real existing intro checkpoint")
    hashes = _hashes()
    boot.refresh_save()
    _check(not boot.continue_button.disabled and GameState.capture_save().to_dict() == logical, "Valid registered save enables Continue without applying it")
    boot.new_game_button.pressed.emit()
    _check(boot.confirm_panel.visible and _hashes() == hashes, "Prior progress requires a concrete New Game choice")
    boot.cancel_button.pressed.emit()
    _check(boot.main_panel.visible and not boot.confirm_panel.visible and _hashes() == hashes, "Cancel retains both slots exactly")
    _store(SaveManager.SAVE_PATH, "{broken primary")
    boot.refresh_save()
    hashes = _hashes()
    _check(not boot.continue_button.disabled and not boot.status_label.text.is_empty(), "Backup recovery is offered visibly")
    _check(await boot.continue_game() == OK and not boot.menu.visible, "Actual Continue materializes its IN_PLACE Archive stage")
    _check(GameState.current_stage_id == ArchiveProgress.INTRO and _hashes() == hashes and not SaveManager.get("_dirty"), "Backup Continue leaves primary/backup bytes and dirty state unchanged")
    boot.queue_free()
    await get_tree().process_frame
    _store(SaveManager.SAVE_PATH, "{broken primary again")
    _store(SaveManager.BACKUP_PATH, "broken backup")
    hashes = _hashes()
    boot = _new_boot()
    _check(boot.continue_button.disabled and not boot.new_game_button.disabled and _hashes() == hashes, "Both corrupt slots remain intact until explicit New Game")
    boot.new_game_button.pressed.emit()
    _check(boot.confirm_panel.visible, "Corrupt-save recovery also requires the explicit choice")
    _check(await boot.start_new_game() == OK, "Confirmed New Game persists fresh S00 and routes it")
    _check(GameState.current_stage_id == ArchiveProgress.PROLOGUE and not boot.menu.visible and InputManager.mode == InputManager.Mode.CINEMATIC, "New Game enters the actual prologue")
    var world := boot.game.get_node("WorldSlot").get_child(0) as ArchiveMain
    var prologue := world.get_node("Prologue") as ArchivePrologue
    await get_tree().process_frame
    var histories := DirAccess.get_directories_at("user://savegame_history")
    _check(histories.size() == 1, "One exact history directory for the explicit reset")
    if histories.size() == 1:
        var history := "user://savegame_history".path_join(histories[0])
        _check([FileAccess.get_sha256(history.path_join("primary.json")), FileAccess.get_sha256(history.path_join("backup.json"))] == hashes, "Both corrupt originals remain byte-identical in history")
    var elapsed := prologue.elapsed
    await _escape(true)
    await _escape(false)
    var pause := boot.game.get_node("UILayer/PauseMenu") as PauseMenu
    _check(pause.visible and get_tree().paused and InputManager.mode == InputManager.Mode.UI, "Fresh real Esc opens an opted-in cinematic pause")
    await get_tree().create_timer(.1, true).timeout
    _check(prologue.elapsed <= elapsed + .05, "Cinematic pause stops actual timeline progress")
    pause.settings_button.pressed.emit()
    boot.settings.fields["fov"].get_line_edit().text = "95"
    boot.settings.apply_button.pressed.emit()
    _check(pause.visible and not boot.settings.visible and is_equal_approx(prologue.camera.fov, 95) and is_equal_approx(boot.game.get_node("PlayerContainer/Player").camera.fov, 95), "Paused Settings keeps cinematic/player FOV matched")
    pause.resume_button.pressed.emit()
    _check(not get_tree().paused and InputManager.mode == InputManager.Mode.CINEMATIC, "Resume restores the cinematic mode owner")
    await get_tree().create_timer(.1).timeout
    _check(prologue.elapsed > elapsed, "Actual timeline continues after nested Settings/pause")
    boot.queue_free()
    await get_tree().process_frame
    var future := SaveGame.new().to_dict()
    future["save_version"] = 99
    _store(SaveManager.SAVE_PATH, JSON.stringify(future))
    hashes = _hashes()
    boot = _new_boot()
    _check(boot.continue_button.disabled and boot.new_game_button.disabled and not boot.status_label.text.is_empty(), "Future schema disables reset and Continue with a visible reason")
    boot.request_new_game()
    _check(not boot.confirm_panel.visible and _hashes() == hashes, "A programmatic stale New Game request cannot bypass future protection")
    boot.queue_free()
    await get_tree().process_frame
    prior.stage_id = ArchiveProgress.WING_ONE
    prior.checkpoint_id = &"star_collected"
    prior.milestones = {"archive_awakened": true, "wing_01_unlocked": true}
    ArchiveProgress.write_projection(prior)
    _store(SaveManager.SAVE_PATH, JSON.stringify(prior.to_dict()))
    boot = _new_boot()
    _check(boot.continue_button.disabled, "Domain-invalid known checkpoint cannot spawn behind unsolved locked gates")
    boot.queue_free()
    await get_tree().process_frame
    _check(SceneRouter.stage_definition(ArchiveProgress.PROLOGUE) == null and SceneRouter.stage_definition(ArchiveProgress.INTRO) == null, "Freed Boot releases only its owned registry entries")
    SceneRouter.fade_duration = original_duration
    SettingsManager.fov = original_fov
    GameState.apply_save(original)
    InputManager.set_mode(InputManager.Mode.UI)
    if _failures.is_empty():
        print("BOOT PASS: ", _checks, " assertions; read-only startup, real menu/recovery choices, protected reset, actual prologue and nested cinematic pause/settings")
    get_tree().quit(0 if _failures.is_empty() else 1)

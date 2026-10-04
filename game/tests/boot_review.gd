extends Node
## Actual native menu/S00 captures; isolated slots and bounded owned process.

var _output := ""
var _quality := "low"
var _captures: Array[Dictionary] = []


func _ready() -> void:
    get_tree().create_timer(55.0, true).timeout.connect(func() -> void:
        push_error("BOOT_REVIEW FAIL: timeout")
        get_tree().quit(1)
    )
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--review-output="):
            _output = arg.trim_prefix("--review-output=")
        if arg.begins_with("--quality="):
            _quality = arg.trim_prefix("--quality=")
    _run.call_deferred()


func _capture(name: String) -> void:
    for frame in 3:
        await get_tree().process_frame
    await RenderingServer.frame_post_draw
    var image := get_viewport().get_texture().get_image()
    var path := _output.path_join(name + "_" + _quality + ".png")
    if image.save_png(path) != OK:
        push_error("BOOT_REVIEW FAIL: capture write")
        get_tree().quit(1)
        return
    _captures.append({"name": name, "path": path, "width": image.get_width(), "height": image.get_height(), "stage": String(GameState.current_stage_id), "input_mode": InputManager.mode})


func _run() -> void:
    if _output.is_empty() or _quality not in ["low", "medium"]:
        get_tree().quit(1)
        return
    SettingsManager.graphics_preset = "Low" if _quality == "low" else "Medium"
    SettingsManager.apply_runtime(false)
    DisplayServer.window_move_to_foreground()
    var boot := preload("res://core/boot/boot.tscn").instantiate() as ArchiveBoot
    add_child(boot)
    await _capture("main_menu")
    boot.settings_button.pressed.emit()
    await _capture("menu_settings")
    boot.settings.cancel_button.pressed.emit()
    # Materialize a valid old checkpoint to review the real cancelable dialog.
    var old := SaveGame.new()
    old.stage_id = ArchiveProgress.INTRO
    ArchiveProgress.write_projection(old)
    if SaveManager.write_save(old) != OK:
        get_tree().quit(1)
        return
    boot.refresh_save()
    boot.new_game_button.pressed.emit()
    await _capture("new_game_choice")
    if await boot.start_new_game() != OK:
        get_tree().quit(1)
        return
    var world := boot.game.get_node("WorldSlot").get_child(0) as ArchiveMain
    var prologue := world.get_node("Prologue") as ArchivePrologue
    await _capture("s00_exterior")
    while prologue.elapsed < 1.2:
        await get_tree().process_frame
    await _capture("s00_spark")
    while prologue.elapsed < 4.0:
        await get_tree().process_frame
    await _capture("s00_entry")
    while GameState.current_stage_id == ArchiveProgress.PROLOGUE:
        await get_tree().process_frame
    await _capture("s01_handoff")
    var file := FileAccess.open(_output.path_join("captures_" + _quality + ".json"), FileAccess.WRITE)
    file.store_string(JSON.stringify({"status": "CAPTURED_FOR_REVIEW", "quality": _quality, "captures": _captures,
        "renderer": RenderingServer.get_current_rendering_method(), "device": RenderingServer.get_video_adapter_name()}, "  "))
    file.close()
    boot.queue_free()
    await get_tree().process_frame
    print("BOOT_REVIEW CAPTURED: ", _quality, "; 7 actual menu/cinematic/player views")
    get_tree().quit()

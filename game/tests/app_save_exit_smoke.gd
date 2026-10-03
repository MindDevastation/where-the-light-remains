extends Node
## CLI-only real App/SaveManager exit. Requires an isolated XDG_DATA_HOME fixture.


func _ready() -> void:
    get_tree().create_timer(10.0, true).timeout.connect(func() -> void:
        push_error("APP_SAVE_EXIT FAIL: exit timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()


func _run() -> void:
    var isolated_root := ""
    var native := false
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--save-exit-root="):
            isolated_root = argument.trim_prefix("--save-exit-root=").simplify_path()
        if argument == "--native-close":
            native = true
    var user_path := OS.get_user_data_dir().simplify_path()
    if isolated_root.is_empty() or not user_path.begins_with(isolated_root + "/") or FileAccess.file_exists(SaveManager.SAVE_PATH) or FileAccess.file_exists(SaveManager.BACKUP_PATH):
        push_error("APP_SAVE_EXIT FAIL: fresh isolated user directory required before any write")
        get_tree().quit(1)
        return
    var game := preload("res://core/game_root/game_root.tscn").instantiate()
    add_child(game)
    await get_tree().process_frame
    GameState.reset_for_new_game()
    GameState.current_stage_id = &"s02_warmth_light"
    GameState.collected_fragments = {&"star": true, &"hearth": true}
    GameState.world_states = {"fixture": {"counter": SaveGame.MAX_SAFE_INTEGER, "text": "Проверка"}}
    SaveManager.mark_dirty()
    print("APP_SAVE_EXIT requested: isolated real dirty flush; native=", native)
    if native:
        if DisplayServer.get_name() != "X11":
            push_error("APP_SAVE_EXIT FAIL: native fixture requires X11")
            get_tree().quit(1)
            return
        var driver := ProjectSettings.globalize_path("res://../tools/x11_close_driver.py")
        var window := DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE)
        var output: Array = []
        if OS.execute("/usr/bin/python3", [driver, "--window", str(window)], output, true) != 0:
            push_error("APP_SAVE_EXIT FAIL: close driver")
            get_tree().quit(1)
        for item in output:
            print(String(item).strip_edges())
    else:
        App.request_safe_exit()
        var loaded := SaveManager.read_save()
        if SaveManager.get("_dirty") or loaded["error"] != OK or loaded["data"].to_dict() != GameState.capture_save().to_dict():
            push_error("APP_SAVE_EXIT FAIL: App quit before successful dirty commit")
            get_tree().quit(1)
            return
        print("APP_SAVE_EXIT PASS: App committed exact state and cleared dirty before quit")

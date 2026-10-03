extends Node
## Real App/SaveManager exit during an unaccepted route, isolated by driver.
var _done := false
var _error: Error = FAILED
var _exit_errors := 0
var _target_events := 0
var _failed := false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().create_timer(20.0, true).timeout.connect(func() -> void:
        push_error("ROUTER_EXIT FAIL: timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()

func _check(value: bool, message: String) -> void:
    if not value:
        _failed = true
        push_error("ROUTER_EXIT FAIL: " + message)

func _launch() -> void:
    _error = await SceneRouter.request_registered_stage(&"s02_fixture")
    _done = true

func _click(button: Button) -> void:
    await get_tree().process_frame
    var point := button.get_global_rect().get_center()
    var motion := InputEventMouseMotion.new()
    motion.position = point
    motion.global_position = point
    Input.parse_input_event(motion)
    Input.flush_buffered_events()
    for down in [true, false]:
        var event := InputEventMouseButton.new()
        event.position = point
        event.global_position = point
        event.button_index = MOUSE_BUTTON_LEFT
        event.pressed = down
        Input.parse_input_event(event)
        Input.flush_buffered_events()
    await get_tree().process_frame

func _run() -> void:
    var isolated := ""
    var failing := false
    var native := false
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--save-exit-root="):
            isolated = argument.trim_prefix("--save-exit-root=").simplify_path()
        failing = failing or argument == "--exit-failure"
        native = native or argument == "--native-close"
    if isolated.is_empty() or not OS.get_user_data_dir().simplify_path().begins_with(isolated + "/") or FileAccess.file_exists(SaveManager.SAVE_PATH) or DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(SaveManager.SAVE_PATH)) or FileAccess.file_exists(SaveManager.BACKUP_PATH):
        push_error("ROUTER_EXIT FAIL: fresh isolated user directory required before any IO")
        get_tree().quit(1)
        return
    if DisplayServer.get_name() == "headless":
        get_tree().root.size = Vector2i(1280, 720)
    for spec in [[&"s01_fixture", "route_world_a"], [&"s02_fixture", "route_world_b"]]:
        var definition := StageDefinition.new()
        definition.stage_id = spec[0]
        definition.scene_path = "res://tests/fixtures/" + spec[1] + ".tscn"
        _check(SceneRouter.register_stage(definition) == OK, "Exit fixture registry")
    var game := preload("res://core/game_root/game_root.tscn").instantiate()
    add_child(game)
    SceneRouter.fade_duration = .06
    var initial := SaveGame.new()
    initial.stage_id = &"s01_fixture"
    initial.world_states = {"s01_fixture": {"counter": 1}}
    _check(await SceneRouter.request_registered_stage(&"s01_fixture", initial) == OK, "Original accepted world/state")
    var slot: Node3D = game.get_node("WorldSlot")
    var old := slot.get_child(0)
    var dialog: ExitFailureDialog = game.get_node("UILayer/ExitFailureDialog")
    var fade: FadeOverlay = game.get_node("TransitionLayer/FadeOverlay")
    App.exit_failed.connect(func(_failure: Error) -> void: _exit_errors += 1)
    EventBus.stage_changed.connect(func(id: StringName) -> void:
        if id == &"s02_fixture":
            _target_events += 1
    )
    if failing:
        _check(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(SaveManager.SAVE_PATH)) == OK, "Actual primary-path IO obstacle")
    SaveManager.mark_dirty()
    SceneRouter.fade_duration = .35
    _launch()
    while not _done and not SceneRouter.get("_route").get("committed", false):
        await get_tree().process_frame
    _check(not _done and GameState.current_stage_id == &"s02_fixture" and fade.busy, "Close is requested during temporary target fade-out")
    if native:
        _check(DisplayServer.get_name() == "X11", "Native close needs X11")
        var output: Array = []
        var window := DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE)
        var driver := ProjectSettings.globalize_path("res://../tools/x11_close_driver.py")
        _check(OS.execute("/usr/bin/python3", [driver, "--window", str(window)], output, true) == 0, "Actual native WM_DELETE_WINDOW")
        for item in output:
            print(String(item).strip_edges())
    else:
        App.request_safe_exit()
    if failing:
        while _exit_errors == 0:
            await get_tree().process_frame
        _check(_done and _error == ERR_SKIP and slot.get_child(0) == old and GameState.capture_save().to_dict() == initial.to_dict() and _target_events == 0 and SaveManager.get("_dirty"), "Failed exit first cancels target and restores original dirty state")
        _check(dialog.visible and get_tree().paused and InputManager.mode == InputManager.Mode.UI and not fade.visible and not fade.busy, "Usable error modal replaces route lock/fade")
        await _click(dialog.stay_button)
        _check(not dialog.visible and not get_tree().paused and InputManager.mode == InputManager.Mode.GAMEPLAY and game.get_node("PlayerContainer/Player").active, "Stay restores accepted gameplay without DISABLED lock")
        _check(DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveManager.SAVE_PATH)) == OK, "IO obstacle cleanup")
        if _failed:
            get_tree().quit(1)
            return
        print("ROUTER_EXIT failure recovery PASS: native=", native, "; rollback precedes failed flush; actual GUI Stay restores original gameplay")
        await App.request_safe_exit()
    elif not native:
        while not _done or SaveManager.get("_dirty"):
            await get_tree().process_frame
    var result := SaveManager.read_save()
    _check(_done and _error == ERR_SKIP and not SceneRouter.get("_transition_in_progress") and not SaveManager.get("_dirty") and result["error"] == OK and result["data"].to_dict() == initial.to_dict() and _target_events == 0, "Real App persists accepted original, never unaccepted target")
    if _failed:
        get_tree().quit(1)
    else:
        print("ROUTER_EXIT PASS: original s01_fixture persisted after transactional cancellation; native=", native, "; failure=", failing)

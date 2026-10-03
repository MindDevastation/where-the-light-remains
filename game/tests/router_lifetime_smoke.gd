extends Node
## Exercise removal/rebinding at actual preload, fades and physics boundaries.

class SlowLoader extends ResourceFormatLoader:
    var template: PackedScene

    func _get_recognized_extensions() -> PackedStringArray:
        return PackedStringArray(["tscn"])

    func _recognize_path(path: String, _type: StringName) -> bool:
        return path.ends_with("/threaded_router_cancel.tscn")

    func _handles_type(type: StringName) -> bool:
        return type == &"PackedScene"

    func _get_resource_type(path: String) -> String:
        return "PackedScene" if _recognize_path(path, &"PackedScene") else ""

    func _load(_path: String, _original: String, _sub_threads: bool, _cache: int) -> Variant:
        OS.delay_msec(400)
        return template.duplicate(true)

var _done := false
var _error: Error = FAILED
var _events := 0
var _failures: Array[String] = []

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().create_timer(35.0, true).timeout.connect(func() -> void:
        push_error("ROUTER_LIFETIME FAIL: timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()

func _check(value: bool, message: String) -> void:
    if not value:
        _failures.append(message)
        push_error("ROUTER_LIFETIME FAIL: " + message)

func _launch(id: StringName) -> void:
    _done = false
    _error = await SceneRouter.request_registered_stage(id)
    _done = true

func _wait_done() -> void:
    while not _done:
        await get_tree().process_frame

func _wait_phase(phase: String) -> void:
    while not _done:
        var route: Dictionary = SceneRouter.get("_route")
        var fade: Variant = route.get("fade")
        if phase == "preload" and SceneRouter.get("_preload_in_progress"):
            return
        if phase == "fade_in" and is_instance_valid(fade) and fade.busy and not route.get("detached", false):
            return
        if phase == "physics" and route.get("detached", false) and not route.get("committed", false):
            return
        if phase == "fade_out" and route.get("committed", false):
            return
        if phase == "physics":
            await get_tree().physics_frame
        else:
            await get_tree().process_frame
    _check(false, "Missed active phase: " + phase)

func _drain() -> void:
    while SceneRouter.get("_preload_in_progress"):
        await get_tree().process_frame

func _new_game() -> Node:
    var game := preload("res://core/game_root/game_root.tscn").instantiate()
    add_child(game)
    return game

func _register(id: StringName, path: String) -> void:
    var definition := StageDefinition.new()
    definition.stage_id = id
    definition.scene_path = path
    _check(SceneRouter.register_stage(definition) == OK, "Lifetime fixture registration")

func _external_fade(fade: FadeOverlay) -> void:
    await fade.fade_to(.35, .5)

func _run() -> void:
    if DisplayServer.get_name() == "headless":
        get_tree().root.size = Vector2i(1280, 720)
    var original := GameState.capture_save()
    var dirty: bool = SaveManager.get("_dirty")
    var duration: float = SceneRouter.fade_duration
    var audio := [AudioDirector.current_stage, AudioDirector.current_state]
    var loader := SlowLoader.new()
    loader.template = load("res://tests/fixtures/route_world_a.tscn")
    ResourceLoader.add_resource_format_loader(loader, true)
    _register(&"s01_fixture", "res://tests/fixtures/threaded_router_cancel.tscn")
    _register(&"s02_fixture", "res://tests/fixtures/route_world_b.tscn")
    SceneRouter.fade_duration = .12
    EventBus.stage_changed.connect(func(_id: StringName) -> void: _events += 1)
    # A fresh path/cache for each preload case ensures a real outstanding worker.
    for phase in ["preload", "fade_in", "physics", "fade_out"]:
        for action in ["remove", "rebind"]:
            var game := _new_game()
            _check(await SceneRouter.request_registered_stage(&"s02_fixture") == OK, "Lifetime original world")
            SaveManager.set("_dirty", false)
            var before := GameState.capture_save().to_dict()
            var events := _events
            var slot: Node3D = game.get_node("WorldSlot")
            var world := slot.get_child(0)
            var second: Node
            _launch(&"s01_fixture")
            await _wait_phase(phase)
            if action == "remove":
                game.queue_free()
            else:
                second = _new_game()
            await _wait_done()
            _check(_error == ERR_SKIP and not SceneRouter.get("_transition_in_progress") and SceneRouter.get("_route").is_empty() and GameState.capture_save().to_dict() == before and not SaveManager.get("_dirty") and AudioDirector.current_stage == &"s02_fixture" and InputManager.mode == InputManager.Mode.UI, phase + "/" + action + ": complete transaction cleanup")
            _check(_events == events + (1 if action == "rebind" else 0), phase + "/" + action + ": no target event (new root only)")
            if action == "rebind":
                _check(is_instance_valid(world) and slot.get_child_count() == 1 and slot.get_child(0) == world and second.get_node("WorldSlot").get_child_count() == 0, "Rebind preserves old world without populating new root")
                game.queue_free()
                second.queue_free()
            await _drain()
            await get_tree().process_frame
            # Loader must run again rather than reuse the previous result.
            loader.template = load("res://tests/fixtures/route_world_a.tscn")

    var game := _new_game()
    _check(await SceneRouter.request_registered_stage(&"s02_fixture") == OK, "Final original world")
    var slot: Node3D = game.get_node("WorldSlot")
    var player: FirstPersonPlayer = game.get_node("PlayerContainer/Player")
    var fade: FadeOverlay = game.get_node("TransitionLayer/FadeOverlay")
    var before := GameState.capture_save().to_dict()
    _launch(&"s01_fixture")
    await _wait_phase("fade_out")
    fade.clear()
    InputManager.set_mode(InputManager.Mode.CINEMATIC)
    _external_fade(fade)
    var revision := fade.request_revision
    await _wait_done()
    _check(_error == ERR_SKIP and fade.busy and fade.request_revision == revision and InputManager.mode == InputManager.Mode.CINEMATIC and GameState.capture_save().to_dict() == before, "Rollback preserves later fade and input owners")
    fade.clear()
    InputManager.set_mode(InputManager.Mode.GAMEPLAY)
    _launch(&"s01_fixture")
    await _wait_phase("physics")
    player.queue_free()
    await _wait_done()
    _check(_error == ERR_SKIP and InputManager.mode == InputManager.Mode.UI and not SceneRouter.get("_transition_in_progress"), "Freed player releases capture to UI")
    _check(not game.get_node("UILayer/InteractionHUD").visible and not game.get_node("UILayer/PauseMenu").open(), "HUD and pause tolerate removed player")
    game.queue_free()
    await get_tree().process_frame
    await _drain()
    ResourceLoader.remove_resource_format_loader(loader)
    _check(SceneRouter.unregister_stage(&"s01_fixture") == OK and SceneRouter.unregister_stage(&"s02_fixture") == OK, "Lifetime registry cleanup")
    GameState.apply_save(original)
    SaveManager.set("_dirty", dirty)
    AudioDirector.current_stage = audio[0]
    AudioDirector.current_state = audio[1]
    SceneRouter.fade_duration = duration
    if _failures.is_empty():
        print("ROUTER_LIFETIME PASS: actual preload/fade-in/physics/fade-out removal and rebind; state/audio/event/dirty cleanup; later fade/input ownership; freed player UI; pending engine load drain")
    get_tree().quit(0 if _failures.is_empty() else 1)

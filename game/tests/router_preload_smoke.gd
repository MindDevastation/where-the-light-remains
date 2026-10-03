extends Node
## Real slow threaded loader plus terminal/request fault injection; CLI only.

class SlowLoader extends ResourceFormatLoader:
    func _get_recognized_extensions() -> PackedStringArray:
        return PackedStringArray(["tscn"])

    func _recognize_path(path: String, _type: StringName) -> bool:
        return path.contains("/threaded_router_") and path.ends_with(".tscn")

    func _handles_type(type: StringName) -> bool:
        return type == &"PackedScene"

    func _get_resource_type(path: String) -> String:
        return "PackedScene" if _recognize_path(path, &"PackedScene") else ""

    func _load(_path: String, _original: String, _sub_threads: bool, _cache: int) -> Variant:
        OS.delay_msec(500)
        var node := Node3D.new()
        node.name = "ThreadedFixture"
        var scene := PackedScene.new()
        var error := scene.pack(node)
        node.free()
        return scene if error == OK else error

class TimeoutRouter extends "res://autoload/scene_router.gd":
    func _preload_timeout_msec() -> int:
        return 20

class FaultRouter extends "res://autoload/scene_router.gd":
    var request_error: Error = ERR_CANT_OPEN
    var collections := 0

    func _thread_request(_path: String) -> Error:
        return request_error

    func _thread_status(_path: String) -> ResourceLoader.ThreadLoadStatus:
        return ResourceLoader.THREAD_LOAD_FAILED

    func _thread_get(_path: String) -> Resource:
        collections += 1
        return null

var _failures: Array[String] = []
var _done := false
var _result: Dictionary

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().create_timer(15.0, true).timeout.connect(func() -> void:
        push_error("ROUTER_PRELOAD FAIL: timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()

func _check(value: bool, message: String) -> void:
    if not value:
        _failures.append(message)
        push_error("ROUTER_PRELOAD FAIL: " + message)

func _definition(id: StringName, path: String) -> StageDefinition:
    var definition := StageDefinition.new()
    definition.stage_id = id
    definition.scene_path = path
    definition.player_active = false
    definition.input_mode = InputManager.Mode.CINEMATIC
    return definition

func _launch(router: Node, id: StringName) -> void:
    _done = false
    _result = await router.preload_stage(id)
    _done = true

func _wait_result() -> void:
    while not _done:
        await get_tree().process_frame

func _wait_drain(router: Node) -> void:
    while router.get("_preload_in_progress"):
        await get_tree().process_frame

func _run() -> void:
    var state := GameState.capture_save().to_dict()
    var mode := InputManager.mode
    var dirty: bool = SaveManager.get("_dirty")
    var loader := SlowLoader.new()
    ResourceLoader.add_resource_format_loader(loader, true)
    var cancel_path := "res://tests/fixtures/threaded_router_cancel.tscn"
    var timeout_path := "res://tests/fixtures/threaded_router_timeout.tscn"
    _check(SceneRouter.register_stage(_definition(&"s05_fixture", cancel_path)) == OK, "Real slow loader registration")
    _launch(SceneRouter, &"s05_fixture")
    await get_tree().process_frame
    _check(not _done and SceneRouter.get("_preload_in_progress"), "Actual threaded work remains pending")
    SceneRouter.cancel_transition()
    await _wait_result()
    _check(_result["error"] == ERR_SKIP and _result["scene"] == null, "Cancellation returns without publishing scene")
    _check(SceneRouter.get("_preload_in_progress") and ResourceLoader.load_threaded_get_status(cancel_path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS, "Cancelled worker retained for nonblocking collection")
    _check(SceneRouter.unregister_stage(&"s05_fixture") == ERR_BUSY and (await SceneRouter.preload_stage(&"s05_fixture"))["error"] == ERR_BUSY, "No new request or registry mutation while draining")
    await _wait_drain(SceneRouter)
    _check(ResourceLoader.load_threaded_get_status(cancel_path) == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE, "Cancelled actual engine load token collected")
    _check(SceneRouter.unregister_stage(&"s05_fixture") == OK, "Registry available after drain")

    var timeout := TimeoutRouter.new()
    add_child(timeout)
    _check(timeout.register_stage(_definition(&"s06_fixture", timeout_path)) == OK, "Short-deadline fixture registration")
    var result: Dictionary = await timeout.preload_stage(&"s06_fixture")
    _check(result["error"] == ERR_TIMEOUT and timeout.get("_preload_in_progress"), "Timeout returns promptly while retaining pending worker")
    await _wait_drain(timeout)
    _check(ResourceLoader.load_threaded_get_status(timeout_path) == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE and timeout.unregister_stage(&"s06_fixture") == OK, "Timed-out actual engine token collected")
    timeout.queue_free()

    var fault := FaultRouter.new()
    add_child(fault)
    _check(fault.register_stage(_definition(&"s07_fixture", cancel_path)) == OK, "Fault fixture registration")
    result = await fault.preload_stage(&"s07_fixture")
    _check(result["error"] == ERR_CANT_OPEN and not fault.get("_preload_in_progress") and fault.collections == 0, "Request rejection leaves no owned token")
    fault.request_error = OK
    result = await fault.preload_stage(&"s07_fixture")
    _check(result["error"] == ERR_CANT_OPEN and not fault.get("_preload_in_progress") and fault.collections == 1, "Terminal failed request collected exactly once")
    fault.queue_free()
    ResourceLoader.remove_resource_format_loader(loader)
    await get_tree().process_frame
    _check(GameState.capture_save().to_dict() == state and InputManager.mode == mode and SaveManager.get("_dirty") == dirty, "Standalone preload never applies state, locks input or dirties save")
    if _failures.is_empty():
        print("ROUTER_PRELOAD PASS: real pending threaded cancellation/timeout, caller release, serialized drain and engine token collection; request/terminal failures; globals preserved")
    get_tree().quit(0 if _failures.is_empty() else 1)

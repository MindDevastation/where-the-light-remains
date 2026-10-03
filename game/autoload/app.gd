extends Node

const BUILD_FLAVOR := "development"
signal exit_failed(error: Error)
var _exit_pending := false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().auto_accept_quit = false
    get_tree().root.close_requested.connect(request_safe_exit)

func request_safe_exit() -> void:
    if _exit_pending:
        return
    _exit_pending = true
    # Never persist the temporary target state of an unaccepted route.
    await SceneRouter.cancel_and_wait()
    var error := _flush_exit()
    if error != OK:
        _exit_pending = false
        exit_failed.emit(error)
        return
    get_tree().quit()


func _flush_exit() -> Error:
    return SaveManager.flush_if_dirty()

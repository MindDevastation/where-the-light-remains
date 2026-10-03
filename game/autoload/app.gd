extends Node

const BUILD_FLAVOR := "development"
signal exit_failed(error: Error)

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().auto_accept_quit = false
    get_tree().root.close_requested.connect(request_safe_exit)

func request_safe_exit() -> void:
    var error := SaveManager.flush_if_dirty()
    if error != OK:
        exit_failed.emit(error)
        return
    get_tree().quit()

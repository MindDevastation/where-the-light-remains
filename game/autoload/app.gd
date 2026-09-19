extends Node

const BUILD_FLAVOR := "development"

func request_safe_exit() -> void:
    SaveManager.flush_if_dirty()
    get_tree().quit()

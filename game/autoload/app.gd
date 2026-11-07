extends Node

const BUILD_FLAVOR := "development"
signal exit_failed(error: Error)
var _exit_pending := false

func _enter_tree() -> void:
    # Assign after import, before UI nodes enter. A custom_font project setting
    # attempts to load imported TTF caches too early on a cache-free editor run.
    if Engine.is_editor_hint():
        return
    var theme := ThemeDB.get_project_theme()
    var font := load("res://art/fonts/archive_ui_font.tres") as Font
    if theme == null or font == null:
        push_error("Archive UI font/theme could not be loaded")
        return
    theme.default_font = font

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
    # Freeze further choices/timeline progress only after persistence succeeds.
    InputManager.set_mode(InputManager.Mode.DISABLED)
    InputManager.set_paused(true)
    await AudioDirector.prepare_safe_exit()
    get_tree().quit()


func _flush_exit() -> Error:
    return SaveManager.flush_if_dirty()

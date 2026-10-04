extends Node
## Shipping entry-point contract and actual menu Exit on protected existing slots.

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
    get_tree().create_timer(10.0, true).timeout.connect(func() -> void:
        push_error("BOOT_STARTUP FAIL: bounded exit timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()


func _check(condition: bool, message: String) -> void:
    _checks += 1
    if not condition:
        _failures.append(message)
        push_error("BOOT_STARTUP FAIL: " + message)


func _hashes() -> Array[String]:
    return [FileAccess.get_sha256(SaveManager.SAVE_PATH), FileAccess.get_sha256(SaveManager.BACKUP_PATH)]


func _run() -> void:
    var hashes := _hashes()
    var logical := GameState.capture_save().to_dict()
    var entry := String(ProjectSettings.get_setting("application/run/main_scene"))
    _check(entry == "res://core/boot/boot.tscn", "Shipping main scene is Boot")
    var packed := load(entry) as PackedScene
    _check(packed != null, "Configured entry loads as a PackedScene")
    if packed == null:
        get_tree().quit(1)
        return
    var instance := packed.instantiate()
    var boot := instance as ArchiveBoot
    _check(boot != null, "Shipping entry has the actual parsed Boot controller")
    if boot == null:
        instance.free()
        get_tree().quit(1)
        return
    add_child(boot)
    await get_tree().process_frame
    _check(boot.menu.visible and boot.main_panel.visible and not boot.busy, "Normal entry shows an idle Main Menu")
    _check(boot.game.get_node("WorldSlot").get_child_count() == 0 and not boot.game.get_node("PlayerContainer/Player").active, "Opening the game neither launches a world nor activates the player")
    _check(InputManager.mode == InputManager.Mode.UI and not get_tree().paused, "Menu owns UI mode with an unpaused tree")
    for service in ["App", "GameState", "SaveManager", "SceneRouter", "AudioDirector", "SettingsManager", "InputManager", "EventBus"]:
        var count := 0
        for node in get_tree().root.get_children():
            if node.name == service:
                count += 1
        _check(count == 1, "Exactly one actual autoload: " + service)
    _check(_hashes() == hashes and GameState.capture_save().to_dict() == logical and not SaveManager.get("_dirty"), "Normal menu preserves existing slots and logical state")
    _check(not boot.exit_button.disabled and boot.exit_button.text == "Выйти из игры", "Actual Russian menu Exit is enabled")
    if not _failures.is_empty():
        get_tree().quit(1)
        return
    boot.exit_button.pressed.emit()
    _check(App.get("_exit_pending") and _hashes() == hashes and not SaveManager.get("_dirty"), "Actual menu Exit uses App safe exit without writing a clean save")
    if _failures.is_empty():
        print("BOOT_STARTUP PASS: ", _checks, " assertions; exact shipping entry, idle menu, eight services, protected saves and actual safe Exit")
    else:
        get_tree().quit(1)

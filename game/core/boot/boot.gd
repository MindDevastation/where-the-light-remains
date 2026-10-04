class_name ArchiveBoot
extends Node
## Read-only startup inspection; explicit choices alone start or reset a game.

signal launch_finished(error: Error)
@onready var game: Node = $MainMenu/GameRoot
@onready var menu: Control = $MainMenu/MenuLayer/Menu
@onready var settings: SettingsMenu = $MainMenu/GameRoot/UILayer/SettingsMenu
var continue_button: Button
var new_game_button: Button
var settings_button: Button
var exit_button: Button
var confirm_button: Button
var cancel_button: Button
var status_label: Label
var main_panel: PanelContainer
var confirm_panel: PanelContainer
var busy := false
var _owned_stages: Array[StringName] = []
var _new_game_allowed := false
var _has_prior_slots := false


func _ready() -> void:
    _build_menu()
    game.get_node("UILayer/PauseMenu").allow_cinematic = true
    var registered := OK
    for id in ArchiveProgress.STAGES:
        var definition := StageDefinition.new()
        definition.stage_id = id
        definition.scene_path = "res://worlds/archive/archive_main.tscn"
        definition.player_active = id != ArchiveProgress.PROLOGUE
        definition.input_mode = InputManager.Mode.CINEMATIC if id == ArchiveProgress.PROLOGUE else InputManager.Mode.GAMEPLAY
        definition.presentation = StageDefinition.Presentation.FADE if id == ArchiveProgress.PROLOGUE else StageDefinition.Presentation.IN_PLACE
        var error := SceneRouter.register_stage(definition)
        if error == OK:
            _owned_stages.append(id)
        else:
            registered = error
    InputManager.set_mode(InputManager.Mode.UI)
    if registered != OK:
        _set_busy(true)
        status_label.text = "Не удалось подготовить игру."
        exit_button.disabled = false
    else:
        refresh_save()
    settings.closed.connect(func() -> void:
        if menu.visible:
            main_panel.show()
            settings_button.grab_focus()
    )


func _panel() -> PanelContainer:
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu.add_child(center)
    var panel := PanelContainer.new()
    panel.custom_minimum_size.x = 600
    var style := StyleBoxFlat.new()
    style.bg_color = Color("172335")
    style.border_color = Color("b5a47d")
    style.set_border_width_all(1)
    style.set_content_margin_all(32)
    panel.add_theme_stylebox_override("panel", style)
    panel.add_theme_font_size_override("font_size", 24)
    center.add_child(panel)
    return panel


func _column(panel: PanelContainer) -> VBoxContainer:
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 18)
    panel.add_child(column)
    return column


func _button(column: VBoxContainer, text: String, callback: Callable) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size.y = 48
    button.pressed.connect(callback)
    column.add_child(button)
    return button


func _label(column: VBoxContainer, text: String, size: int) -> Label:
    var label := Label.new()
    label.text = text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.custom_minimum_size.x = 536
    label.add_theme_font_size_override("font_size", size)
    column.add_child(label)
    return label


func _build_menu() -> void:
    menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var background := ColorRect.new()
    background.color = Color("0b1422")
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu.add_child(background)
    main_panel = _panel()
    var column := _column(main_panel)
    _label(column, "Where the Light Remains", 34)
    status_label = _label(column, "", 20)
    continue_button = _button(column, "Продолжить", continue_game)
    new_game_button = _button(column, "Новая игра", request_new_game)
    settings_button = _button(column, "Настройки", func() -> void:
        if not busy and menu.visible and not confirm_panel.visible and not get_tree().paused:
            main_panel.hide()
            settings.open()
    )
    exit_button = _button(column, "Выйти из игры", App.request_safe_exit)
    confirm_panel = _panel()
    column = _column(confirm_panel)
    _label(column, "Начать новую игру?", 30)
    _label(column, "Текущий прогресс будет заменен. Копии прежних файлов сохранения останутся в истории.", 22)
    confirm_button = _button(column, "Начать новую игру", start_new_game)
    cancel_button = _button(column, "Отмена", cancel_new_game)
    confirm_panel.hide()


func _valid_checkpoint(saved: SaveGame) -> bool:
    if saved == null:
        return false
    var definition := SceneRouter.stage_definition(saved.stage_id)
    if definition == null:
        return false
    var packed := load(definition.scene_path) as PackedScene
    if packed == null:
        return false
    var instance := packed.instantiate()
    var candidate := instance as WorldScene
    if candidate == null:
        instance.free()
        return false
    var valid: bool = candidate.prepare_state(saved)["error"] == OK
    candidate.free()
    return valid


func refresh_save() -> void:
    if busy:
        return
    var saved := SaveManager.read_save()
    _has_prior_slots = saved["primary_error"] != ERR_FILE_NOT_FOUND or saved["backup_error"] != ERR_FILE_NOT_FOUND
    continue_button.disabled = saved["error"] != OK or not _valid_checkpoint(saved["data"])
    _new_game_allowed = true
    for error in [saved["primary_error"], saved["backup_error"]]:
        if error not in [OK, ERR_FILE_NOT_FOUND, ERR_INVALID_DATA, ERR_PARSE_ERROR]:
            _new_game_allowed = false
    new_game_button.disabled = not _new_game_allowed
    if not _new_game_allowed:
        status_label.text = "Сохранение создано другой версией игры." if ERR_UNAVAILABLE in [saved["primary_error"], saved["backup_error"]] else "Не удалось прочитать сохранение. Проверьте доступ к файлам."
    elif saved["error"] == OK:
        status_label.text = "Доступна резервная копия сохранения." if saved["source"] == "backup" else ""
        if continue_button.disabled:
            status_label.text = "Это сохранение недоступно в текущей версии игры."
    elif saved["primary_error"] == ERR_FILE_NOT_FOUND and saved["backup_error"] == ERR_FILE_NOT_FOUND:
        status_label.text = ""
    else:
        status_label.text = "Сохранения повреждены. Можно начать новую игру с сохранением прежних файлов."
    (new_game_button if continue_button.disabled else continue_button).grab_focus()


func _can_choose() -> bool:
    return menu.visible and not busy and not settings.visible and not get_tree().paused and InputManager.mode == InputManager.Mode.UI


func _set_busy(value: bool) -> void:
    busy = value
    for button in [continue_button, new_game_button, settings_button, exit_button, confirm_button, cancel_button]:
        button.disabled = value


func request_new_game() -> void:
    if not _can_choose() or confirm_panel.visible or not _new_game_allowed:
        return
    refresh_save()
    if not _new_game_allowed:
        return
    if not _has_prior_slots:
        start_new_game()
        return
    main_panel.hide()
    confirm_panel.show()
    cancel_button.grab_focus()


func cancel_new_game() -> void:
    if busy or not confirm_panel.visible:
        return
    confirm_panel.hide()
    main_panel.show()
    new_game_button.grab_focus()


func start_new_game() -> Error:
    if not _can_choose() or (not confirm_panel.visible and _has_prior_slots) or not _new_game_allowed:
        return ERR_UNAUTHORIZED
    var current := SaveManager.read_save()
    if not confirm_panel.visible and (current["primary_error"] != ERR_FILE_NOT_FOUND or current["backup_error"] != ERR_FILE_NOT_FOUND):
        refresh_save()
        return ERR_UNAUTHORIZED
    var initial := SaveGame.new()
    var error := ArchiveProgress.write_projection(initial)
    if error == OK and not _valid_checkpoint(initial):
        error = ERR_INVALID_DATA
    if error != OK:
        launch_finished.emit(error)
        return error
    _set_busy(true)
    var written := SaveManager.write_new_game(initial, true)
    error = written["error"]
    if error == OK:
        menu.hide()
        error = await SceneRouter.request_resume_stage(initial)
    _finish_launch(error)
    return error


func continue_game() -> Error:
    if not _can_choose() or confirm_panel.visible or continue_button.disabled:
        return ERR_UNAUTHORIZED
    var saved := SaveManager.read_save()
    if saved["error"] != OK or not _valid_checkpoint(saved["data"]):
        refresh_save()
        launch_finished.emit(ERR_INVALID_DATA)
        return ERR_INVALID_DATA
    _set_busy(true)
    menu.hide()
    var error := await SceneRouter.request_resume_stage(saved["data"])
    _finish_launch(error)
    return error


func _finish_launch(error: Error) -> void:
    _set_busy(false)
    confirm_panel.hide()
    main_panel.show()
    if error != OK:
        menu.show()
        refresh_save()
        status_label.text = "Не удалось начать игру. Прежние файлы сохранения сохранены; попробуйте еще раз."
    launch_finished.emit(error)


func _unhandled_key_input(event: InputEvent) -> void:
    if _can_choose() and confirm_panel.visible and event.is_action_pressed(&"ui_cancel"):
        cancel_new_game()
        get_viewport().set_input_as_handled()


func _exit_tree() -> void:
    for id in _owned_stages:
        SceneRouter.unregister_stage(id)

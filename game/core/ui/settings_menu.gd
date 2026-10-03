class_name SettingsMenu
extends Control
## Reusable modal; callers own pause/scene routing. Controls edit a draft only.

signal closed
signal applied

var storage_path := SettingsManager.SETTINGS_PATH
var fields: Dictionary = {}
var error_label: Label
var apply_button: Button
var cancel_button: Button
var defaults_button: Button
var _panel: PanelContainer
var _previous_mode := InputManager.Mode.UI


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var dim := ColorRect.new()
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    dim.color = Color(0.015, 0.022, 0.035, 0.92)
    add_child(dim)
    _panel = PanelContainer.new()
    add_child(_panel)
    var style := StyleBoxFlat.new()
    style.bg_color = Color("172335")
    style.border_color = Color("b5a47d")
    style.set_border_width_all(1)
    style.set_content_margin_all(24)
    _panel.add_theme_stylebox_override("panel", style)
    _panel.add_theme_font_size_override("font_size", 22)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 16)
    _panel.add_child(column)
    var title := Label.new()
    title.text = "Настройки"
    title.add_theme_font_size_override("font_size", 30)
    column.add_child(title)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.follow_focus = true
    column.add_child(scroll)
    var grid := GridContainer.new()
    grid.columns = 2
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation", 24)
    grid.add_theme_constant_override("v_separation", 10)
    scroll.add_child(grid)
    _option(grid, "Разрешение", "resolution", ["1280 × 720", "1600 × 900", "1920 × 1080"])
    _toggle(grid, "Полный экран", "fullscreen")
    _option(grid, "Качество графики", "graphics_preset", ["Низкое", "Среднее", "Высокое"])
    _toggle(grid, "Тени", "shadows")
    _toggle(grid, "Эффекты", "effects")
    _range(grid, "Общая громкость", "master_volume", 0.0, 1.0, 0.01)
    _range(grid, "Музыка", "music_volume", 0.0, 1.0, 0.01)
    _range(grid, "Звуки", "sfx_volume", 0.0, 1.0, 0.01)
    _range(grid, "Чувствительность мыши", "mouse_sensitivity", 0.1, 2.0, 0.05)
    _range(grid, "Поле зрения", "fov", 50.0, 110.0, 1.0)
    _toggle(grid, "Инверсия по вертикали", "invert_y")
    error_label = Label.new()
    error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    error_label.add_theme_color_override("font_color", Color("f2a49c"))
    column.add_child(error_label)
    var actions := HBoxContainer.new()
    actions.add_theme_constant_override("separation", 12)
    column.add_child(actions)
    defaults_button = _button(actions, "По умолчанию")
    defaults_button.pressed.connect(func() -> void: _set_draft(SettingsManager.DEFAULTS))
    cancel_button = _button(actions, "Отмена")
    cancel_button.pressed.connect(close)
    apply_button = _button(actions, "Применить")
    apply_button.pressed.connect(_apply)
    resized.connect(_resize_panel)
    _resize_panel()
    hide()


func _label(grid: GridContainer, text: String) -> void:
    var label := Label.new()
    label.text = text
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    grid.add_child(label)


func _option(grid: GridContainer, label: String, key: String, options: Array) -> void:
    _label(grid, label)
    var field := OptionButton.new()
    field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    for option: String in options:
        field.add_item(option)
    grid.add_child(field)
    fields[key] = field


func _toggle(grid: GridContainer, label: String, key: String) -> void:
    _label(grid, label)
    var field := CheckButton.new()
    field.text = "Выключено"
    field.toggled.connect(func(pressed: bool) -> void: field.text = "Включено" if pressed else "Выключено")
    grid.add_child(field)
    fields[key] = field


func _range(grid: GridContainer, label: String, key: String, lower: float, upper: float, increment: float) -> void:
    _label(grid, label)
    var field := SpinBox.new()
    field.min_value = lower
    field.max_value = upper
    field.step = increment
    field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid.add_child(field)
    fields[key] = field


func _button(parent: Node, text: String) -> Button:
    var button := Button.new()
    button.text = text
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(button)
    return button


func _resize_panel() -> void:
    if _panel == null:
        return
    _panel.size = Vector2(minf(760.0, size.x - 32.0), minf(660.0, size.y - 32.0))
    _panel.position = (size - _panel.size) / 2.0


func open() -> void:
    if visible:
        return
    _previous_mode = InputManager.mode
    _set_draft(SettingsManager.snapshot())
    error_label.text = ""
    InputManager.set_mode(InputManager.Mode.UI)
    show()
    fields["resolution"].grab_focus()


func close() -> void:
    if not visible:
        return
    hide()
    if InputManager.mode == InputManager.Mode.UI:
        InputManager.set_mode(_previous_mode)
    closed.emit()


func _set_draft(values: Dictionary) -> void:
    for key in fields:
        var field: Control = fields[key]
        if field is OptionButton:
            field.select(SettingsManager.RESOLUTIONS.find(values[key]) if key == "resolution" else SettingsManager.PRESETS.find(values[key]))
        elif field is CheckButton:
            field.set_pressed_no_signal(values[key])
            field.text = "Включено" if values[key] else "Выключено"
        else:
            field.set_value_no_signal(values[key])
            # SpinBox may defer its displayed text update. Reset/open must also
            # replace unsubmitted text before a same-frame Apply or draft read.
            field.get_line_edit().text = str(values[key])


func draft() -> Dictionary:
    var values := {}
    for key in fields:
        var field: Control = fields[key]
        if field is OptionButton:
            values[key] = SettingsManager.RESOLUTIONS[field.selected] if key == "resolution" else SettingsManager.PRESETS[field.selected]
        elif field is CheckButton:
            values[key] = field.button_pressed
        else:
            # Button presses can precede the SpinBox focus-exit text commit.
            field.apply()
            values[key] = field.value
    return values


func _apply() -> void:
    var error := SettingsManager.apply_settings(draft(), storage_path)
    if error != OK:
        error_label.text = "Не удалось сохранить настройки. Изменения не применены. Код: %d" % error
        return
    applied.emit()
    close()


func _unhandled_key_input(event: InputEvent) -> void:
    if visible and event.is_action_pressed(&"ui_cancel"):
        close()
        get_viewport().set_input_as_handled()

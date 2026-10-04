class_name FragmentPresenter
extends Control
## One shared modal. The world owns acquisition/IO; quiet load only restores seen IDs.

signal closed
@export var fragments: Array[FragmentData] = []
var _seen: Dictionary = {}
var _previous_mode := InputManager.Mode.GAMEPLAY
var _mode_revision := -1
var title_label: Label
var couplet_label: Label
var feeling_label: Label
var sigil_view: TextureRect
var continue_button: Button
var _panel: PanelContainer


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    var dim := ColorRect.new()
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    dim.color = Color(0.015, 0.022, 0.035, .86)
    add_child(dim)
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(center)
    _panel = PanelContainer.new()
    _panel.custom_minimum_size = Vector2(820, 0)
    var style := StyleBoxFlat.new()
    style.bg_color = Color("172335")
    style.border_color = Color("b5a47d")
    style.set_border_width_all(1)
    style.set_content_margin_all(32)
    _panel.add_theme_stylebox_override("panel", style)
    center.add_child(_panel)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 22)
    _panel.add_child(column)
    sigil_view = TextureRect.new()
    sigil_view.custom_minimum_size = Vector2(100, 100)
    sigil_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    sigil_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    column.add_child(sigil_view)
    title_label = _label(column, 32)
    couplet_label = _label(column, 25)
    couplet_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    couplet_label.custom_minimum_size.x = 756
    feeling_label = _label(column, 22)
    feeling_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    feeling_label.custom_minimum_size.x = 756
    continue_button = Button.new()
    continue_button.text = "Продолжить"
    continue_button.custom_minimum_size.y = 48
    continue_button.add_theme_font_size_override("font_size", 24)
    column.add_child(continue_button)
    continue_button.pressed.connect(dismiss)
    hide()


func _label(parent: Node, size: int) -> Label:
    var label := Label.new()
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", size)
    parent.add_child(label)
    return label


func fragment(id: StringName) -> FragmentData:
    var found: FragmentData
    for data in fragments:
        if data != null and data.fragment_id == id:
            if found != null:
                return null
            found = data
    return found if found != null and found.valid() else null


func present_fragment(id: StringName) -> Error:
    if not is_inside_tree() or is_queued_for_deletion():
        return ERR_UNCONFIGURED
    if _seen.has(id):
        return ERR_ALREADY_EXISTS
    if visible or get_tree().paused or InputManager.mode != InputManager.Mode.GAMEPLAY:
        return ERR_BUSY
    var data := fragment(id)
    if data == null:
        return ERR_INVALID_DATA
    _seen[id] = true
    title_label.text = data.display_name
    couplet_label.text = "\n".join(data.couplet)
    feeling_label.text = data.feeling
    sigil_view.texture = data.sigil
    _previous_mode = InputManager.mode
    InputManager.set_mode(InputManager.Mode.UI)
    _mode_revision = InputManager.mode_revision
    show()
    continue_button.grab_focus()
    return OK


func restore_collected(ids: Array[StringName]) -> void:
    dismiss(false)
    _seen.clear()
    for id in ids:
        _seen[id] = true


func dismiss(emit_closed: bool = true) -> void:
    if not visible:
        return
    hide()
    if InputManager.mode == InputManager.Mode.UI and InputManager.mode_revision == _mode_revision:
        InputManager.set_mode(_previous_mode)
    _mode_revision = -1
    if emit_closed:
        closed.emit()


func _unhandled_key_input(event: InputEvent) -> void:
    if visible and event is InputEventKey and event.is_action_pressed(&"pause") and not event.is_echo():
        dismiss()
        get_viewport().set_input_as_handled()


func _exit_tree() -> void:
    dismiss(false)

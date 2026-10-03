class_name FadeOverlay
extends Control
## Presentation only. Callers own input locks, saves and scene routing.

signal fade_finished(completed: bool)

var busy := false
var shade: ColorRect
var loading: Label
var _from := 0.0
var _target := 0.0
var _duration := 0.0
var _elapsed := 0.0


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade = ColorRect.new()
    shade.color = Color(0, 0, 0, 0)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(shade)
    loading = Label.new()
    loading.text = "Загрузка…"
    loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    loading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    loading.add_theme_font_size_override("font_size", 26)
    loading.mouse_filter = Control.MOUSE_FILTER_IGNORE
    loading.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(loading)
    loading.hide()
    hide()
    set_process(false)


func fade_to(alpha: float, duration: float = .25) -> bool:
    if busy or not is_inside_tree() or not is_finite(alpha) or not is_finite(duration) or duration < 0:
        return false
    _target = clampf(alpha, 0.0, 1.0)
    if is_zero_approx(duration):
        _set_alpha(_target)
        return true
    _from = shade.color.a
    _duration = duration
    _elapsed = 0.0
    busy = true
    show()
    set_process(true)
    var completed: bool = await fade_finished
    return completed


func _process(delta: float) -> void:
    _elapsed += delta
    _set_alpha(lerpf(_from, _target, smoothstep(0.0, 1.0, minf(_elapsed / _duration, 1.0))))
    if _elapsed >= _duration:
        busy = false
        set_process(false)
        _set_alpha(_target)
        fade_finished.emit(true)


func _set_alpha(alpha: float) -> void:
    shade.color.a = alpha
    visible = busy or alpha > 0.0


func clear() -> void:
    cancel()
    _set_alpha(0.0)
    loading.hide()


func cancel() -> void:
    if busy:
        busy = false
        set_process(false)
        fade_finished.emit(false)


func set_loading(enabled: bool) -> void:
    loading.visible = enabled


func _input(_event: InputEvent) -> void:
    if visible:
        get_viewport().set_input_as_handled()


func _exit_tree() -> void:
    cancel()

class_name FragmentSigilEffect
extends Node
## Cosmetic modal glyph only. Never owns input, audio, progression or save IO.

const DISSOLVE := preload("res://art/vfx/fragment_sigil_dissolve.gdshader")
const REVEAL_SECONDS := 0.35
const DISSOLVE_SECONDS := 0.28
enum Phase {IDLE, REVEAL, DISSOLVE}

var amount: float:
    get: return _amount
var active: bool:
    get: return _phase != Phase.IDLE

var _phase := Phase.IDLE
var _amount := 1.0
var _revision := 0
var _visual_id := 0
var _owner_id := 0
var _ghost_id := 0
var _ghost_parent_id := 0
var _reveal_material: ShaderMaterial
var _ghost_material: ShaderMaterial
var _animation: Tween


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_PAUSABLE
    set_process(false)
    EventBus.settings_changed.connect(_on_settings_changed)
    get_window().size_changed.connect(cancel)


func bind(visual: TextureRect) -> Error:
    cancel()
    _visual_id = 0
    _owner_id = 0
    var owner_node := get_parent()
    if owner_node == null or not is_instance_valid(visual) or not owner_node.is_ancestor_of(visual) or visual.material != null:
        return ERR_INVALID_PARAMETER
    _visual_id = visual.get_instance_id()
    _owner_id = owner_node.get_instance_id()
    return OK


func _visual() -> TextureRect:
    var owner_node := instance_from_id(_owner_id) as Node if is_instance_id_valid(_owner_id) else null
    var visual := instance_from_id(_visual_id) as TextureRect if is_instance_id_valid(_visual_id) else null
    if owner_node == null or visual == null or visual.is_queued_for_deletion() or not owner_node.is_ancestor_of(visual):
        return null
    return visual


func _owner_valid() -> bool:
    return is_inside_tree() and not is_queued_for_deletion() and get_parent() != null and \
        get_parent().get_instance_id() == _owner_id and not get_parent().is_queued_for_deletion()


func _supported_layout(visual: TextureRect) -> bool:
    var transform := visual.get_global_transform()
    return visual.is_inside_tree() and visual.global_position.is_finite() and visual.size.is_finite() and \
        transform.x.is_equal_approx(Vector2.RIGHT) and transform.y.is_equal_approx(Vector2.DOWN)


func _material(value: float) -> ShaderMaterial:
    var material := ShaderMaterial.new()
    material.shader = DISSOLVE
    material.set_shader_parameter("amount", value)
    return material


func reveal() -> void:
    cancel()
    var visual := _visual()
    if not _owner_valid() or visual == null or visual.material != null or visual.texture == null or \
            not visual.is_visible_in_tree() or not SettingsManager.effects or not _supported_layout(visual):
        return
    _phase = Phase.REVEAL
    _amount = 0.0
    _reveal_material = _material(0.0)
    visual.material = _reveal_material
    var revision := _revision
    _animation = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    _animation.tween_method(_step_reveal.bind(revision), 0.0, 1.0, REVEAL_SECONDS)
    _animation.tween_callback(_finish_reveal.bind(revision))
    set_process(true)


func _step_reveal(value: float, revision: int) -> void:
    if revision != _revision: return
    var visual := _visual()
    if not _owner_valid() or visual == null or not visual.is_visible_in_tree() or visual.material != _reveal_material:
        cancel()
        return
    _amount = value
    _reveal_material.set_shader_parameter("amount", value)


func _finish_reveal(revision: int) -> void:
    if revision == _revision:
        cancel()


func dissolve() -> void:
    var visual := _visual()
    var start := _amount if _phase == Phase.REVEAL else 1.0
    var allowed := _owner_valid() and visual != null and visual.texture != null and visual.is_visible_in_tree() and \
        SettingsManager.effects and _supported_layout(visual) and visual.size.x > 0 and visual.size.y > 0 and start > 0.0001
    if allowed:
        allowed = visual.material == null or visual.material == _reveal_material
    # Snapshot before cancel restores the original material. No caller callback.
    var ghost := TextureRect.new() if allowed else null
    if ghost != null:
        ghost.name = "FragmentSigilGhost"
        ghost.expand_mode = visual.expand_mode
        ghost.stretch_mode = visual.stretch_mode
        # Set sizing policy before texture/size: the default texture minimum
        # would otherwise clamp a 100px glyph rect to its 128px source size.
        ghost.texture = visual.texture
        ghost.size = visual.size
        ghost.texture_filter = visual.texture_filter
        ghost.modulate = visual.modulate
        ghost.self_modulate = visual.self_modulate
        ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
        ghost.focus_mode = Control.FOCUS_NONE
    var position := visual.global_position if allowed else Vector2.ZERO
    cancel()
    if ghost == null: return
    var host := get_parent().get_parent()
    if host == null or host.is_queued_for_deletion():
        ghost.free()
        return
    host.add_child(ghost)
    ghost.global_position = position
    if ghost.get_canvas() != visual.get_canvas():
        ghost.queue_free()
        return
    _ghost_id = ghost.get_instance_id()
    _ghost_parent_id = host.get_instance_id()
    _ghost_material = _material(start)
    ghost.material = _ghost_material
    _phase = Phase.DISSOLVE
    _amount = start
    var revision := _revision
    _animation = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
    _animation.tween_method(_step_dissolve.bind(revision), start, 0.0, DISSOLVE_SECONDS * start)
    _animation.tween_callback(_finish_dissolve.bind(revision))
    set_process(true)


func _ghost() -> TextureRect:
    var ghost := instance_from_id(_ghost_id) as TextureRect if is_instance_id_valid(_ghost_id) else null
    if ghost == null or ghost.is_queued_for_deletion() or ghost.get_parent() == null or \
            ghost.get_parent().get_instance_id() != _ghost_parent_id or ghost.material != _ghost_material:
        return null
    return ghost


func _step_dissolve(value: float, revision: int) -> void:
    if revision != _revision: return
    if not _owner_valid() or _ghost() == null:
        cancel()
        return
    _amount = value
    _ghost_material.set_shader_parameter("amount", value)


func _finish_dissolve(revision: int) -> void:
    if revision == _revision:
        cancel()


func cancel() -> void:
    _revision += 1
    if _animation != null: _animation.kill()
    _animation = null
    var visual := _visual()
    if visual != null and _reveal_material != null and visual.material == _reveal_material:
        visual.material = null
    var ghost := _ghost()
    if ghost != null:
        ghost.hide()
        ghost.queue_free()
    _ghost_id = 0
    _ghost_parent_id = 0
    _reveal_material = null
    _ghost_material = null
    _phase = Phase.IDLE
    _amount = 1.0
    set_process(false)


func _process(_delta: float) -> void:
    var visual := _visual()
    if not _owner_valid() or _phase == Phase.REVEAL and \
            (visual == null or not visual.is_visible_in_tree() or visual.material != _reveal_material) or \
            _phase == Phase.DISSOLVE and _ghost() == null:
        cancel()


func _on_settings_changed() -> void:
    if not SettingsManager.effects:
        cancel()


func _exit_tree() -> void:
    cancel()

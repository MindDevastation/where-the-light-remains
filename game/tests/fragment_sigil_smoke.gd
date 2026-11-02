extends Node
## Actual modal lifecycle, native Tween and ownership. No gameplay/save writes.

const PRESENTER := preload("res://gameplay/collectibles/fragment_presenter.tscn")
var _checks := 0
var _failures := 0
var _closed := 0
var _layer: CanvasLayer


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _layer = CanvasLayer.new()
    add_child(_layer)
    get_tree().create_timer(35.0, true).timeout.connect(func() -> void:
        push_error("FRAGMENT_SIGIL timeout")
        get_tree().quit(1))
    _run.call_deferred()


func _check(value: bool, message: String) -> void:
    _checks += 1
    if not value:
        _failures += 1
        push_error("FRAGMENT_SIGIL FAIL: " + message)


func _fresh() -> FragmentPresenter:
    InputManager.set_mode(InputManager.Mode.GAMEPLAY)
    var modal := PRESENTER.instantiate() as FragmentPresenter
    _layer.add_child(modal)
    modal.closed.connect(func() -> void: _closed += 1)
    return modal


func _wait(seconds: float = 0.4) -> void:
    await get_tree().create_timer(seconds, true).timeout


func _ghosts() -> Array[Node]:
    return _layer.find_children("FragmentSigilGhost*", "TextureRect", false, false)


func _run() -> void:
    var dto := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var effects := SettingsManager.effects
    SettingsManager.effects = true
    var modal := _fresh()
    _check(modal.present_fragment(&"star") == OK, "present returns immediately")
    _check(modal.title_label.text == "Звезда" and not modal.couplet_label.text.is_empty() and
        modal.continue_button.is_visible_in_tree() and modal.continue_button.has_focus(), "text and Continue ready at first frame")
    _check(InputManager.mode == InputManager.Mode.UI and AudioDirector.playback_snapshot()["duck_locks"] == 1,
        "existing modal owns input and one duck synchronously")
    var effect := modal._sigil_effect
    _check(effect.active and modal.sigil_view.material is ShaderMaterial, "native reveal starts")
    _check(modal.present_fragment(&"hearth") == ERR_BUSY and modal.present_fragment(&"star") == ERR_ALREADY_EXISTS,
        "busy/duplicate presentation unchanged")
    await _wait(0.07)
    get_tree().paused = true
    var paused := effect.amount
    await _wait(0.12)
    _check(effect.amount == paused and paused > 0.0 and paused < 1.0, "pause freezes intermediate reveal uniform")
    get_tree().paused = false
    await _wait()
    _check(not effect.active and modal.sigil_view.material == null, "settled reveal restores original rendering")
    var original_rect := modal.sigil_view.get_global_rect()
    modal.continue_button.pressed.emit()
    _check(not modal.visible and _closed == 1 and InputManager.mode == InputManager.Mode.GAMEPLAY and
        AudioDirector.playback_snapshot()["duck_locks"] == 0, "Continue immediately closes and releases input/audio once")
    _check(_ghosts().size() == 1 and effect.active, "one outgoing glyph survives modal hide")
    var ghost := _ghosts()[0] as TextureRect
    _check(ghost.get_global_rect() == original_rect, "outgoing glyph preserves exact source size and position")
    _check(ghost.mouse_filter == Control.MOUSE_FILTER_IGNORE and ghost.focus_mode == Control.FOCUS_NONE,
        "outgoing glyph cannot intercept interaction")
    get_tree().paused = true
    paused = effect.amount
    await _wait(0.1)
    _check(effect.amount == paused, "pause also freezes outgoing dissolve")
    get_tree().paused = false
    await _wait()
    _check(_ghosts().is_empty() and not effect.active, "outgoing glyph expires without an owner leak")
    modal.queue_free()
    await get_tree().process_frame

    modal = _fresh()
    modal.present_fragment(&"star")
    modal.dismiss()
    _check(not modal.visible and _ghosts().is_empty(), "same-frame early close has no invisible ghost")
    modal.queue_free()
    await get_tree().process_frame
    modal = _fresh()
    modal.present_fragment(&"star")
    await _wait(0.08)
    var partial := modal._sigil_effect.amount
    var escape := InputEventKey.new()
    escape.keycode = KEY_ESCAPE
    escape.physical_keycode = KEY_ESCAPE
    escape.pressed = true
    modal._unhandled_key_input(escape)
    _check(not modal.visible and modal._sigil_effect.amount == partial and _ghosts().size() == 1,
        "early Escape dissolves from current coverage without a full glyph flash")
    var old_closed := _closed
    modal.restore_collected([&"star"])
    await get_tree().process_frame
    _check(_ghosts().is_empty() and not modal._sigil_effect.active and _closed == old_closed,
        "quiet restore cancels outgoing effect without another closed signal")
    modal.queue_free()
    await get_tree().process_frame

    SettingsManager.effects = false
    modal = _fresh()
    modal.present_fragment(&"hearth")
    _check(modal.sigil_view.material == null and not modal._sigil_effect.active, "effects-off immediately shows original glyph")
    modal.dismiss()
    _check(_ghosts().is_empty(), "effects-off dismiss creates no quad or Tween")
    modal.queue_free()
    await get_tree().process_frame
    SettingsManager.effects = true
    modal = _fresh()
    modal.present_fragment(&"star")
    await _wait(0.05)
    SettingsManager.effects = false
    EventBus.settings_changed.emit()
    _check(modal.sigil_view.material == null and not modal._sigil_effect.active, "disabling effects cancels current reveal")
    SettingsManager.effects = true
    modal._sigil_effect.reveal()
    get_window().size_changed.emit()
    _check(modal.sigil_view.material == null and not modal._sigil_effect.active, "resize cancels old layout animation")
    modal._sigil_effect.reveal()
    var foreign := ShaderMaterial.new()
    foreign.shader = FragmentSigilEffect.DISSOLVE
    foreign.set_shader_parameter("amount", 0.23)
    modal.sigil_view.material = foreign
    await _wait(0.07)
    _check(modal.sigil_view.material == foreign and foreign.get_shader_parameter("amount") == 0.23 and
        not modal._sigil_effect.active, "foreign material is preserved; stale reveal stops")
    modal.sigil_view.material = null
    modal._sigil_effect.reveal()
    modal.sigil_view.reparent(_layer)
    await _wait(0.05)
    _check(not modal._sigil_effect.active, "foreign visual reparent invalidates original lease")
    modal.sigil_view.queue_free()
    modal.queue_free()
    await get_tree().process_frame

    modal = _fresh()
    modal.present_fragment(&"hearth")
    await _wait()
    modal.dismiss()
    ghost = _ghosts()[0]
    ghost.material = foreign
    await _wait(0.06)
    _check(is_instance_valid(ghost) and ghost.material == foreign and not modal._sigil_effect.active,
        "foreign outgoing material is neither modified nor freed")
    ghost.queue_free()
    modal.queue_free()
    await get_tree().process_frame
    modal = _fresh()
    modal.present_fragment(&"star")
    await _wait()
    modal.dismiss()
    ghost = _ghosts()[0]
    ghost.reparent(self)
    var previous: float = (ghost.material as ShaderMaterial).get_shader_parameter("amount")
    await _wait(0.06)
    _check(is_instance_valid(ghost) and (ghost.material as ShaderMaterial).get_shader_parameter("amount") == previous and
        not modal._sigil_effect.active, "reparented outgoing quad is relinquished before further writes")
    ghost.queue_free()
    modal.queue_free()
    await get_tree().process_frame

    modal = _fresh()
    modal.present_fragment(&"star")
    modal._sigil_effect.reparent(self)
    await _wait(0.05)
    _check(modal.sigil_view.material == null and not modal._sigil_effect.active, "effect reparent cancels and restores its original visual")
    modal._sigil_effect.queue_free()
    modal.queue_free()
    await get_tree().process_frame
    modal = _fresh()
    modal.scale = Vector2(1.1, 1.1)
    modal.present_fragment(&"hearth")
    _check(not modal._sigil_effect.active and modal.sigil_view.material == null, "transformed layout safely uses static glyph")
    modal.dismiss()
    _check(_ghosts().is_empty(), "transformed layout creates no misplaced outgoing quad")
    modal.queue_free()
    await get_tree().process_frame

    modal = _fresh()
    modal.present_fragment(&"star")
    await _wait(0.08)
    var other := _fresh()
    other.present_fragment(&"hearth")
    _check(modal.sigil_view.material != other.sigil_view.material, "concurrent instances never share mutable shader state")
    modal.dismiss(false)
    other.dismiss(false)
    modal.queue_free()
    other.queue_free()
    await get_tree().process_frame
    modal = _fresh()
    modal.present_fragment(&"star")
    await _wait()
    modal.closed.connect(func() -> void:
        _check(modal.present_fragment(&"hearth") == OK, "closed callback may present next fragment synchronously"))
    modal.dismiss()
    _check(modal.visible and modal.title_label.text == "Очаг" and modal._sigil_effect.active and
        AudioDirector.playback_snapshot()["duck_locks"] == 1, "old dismiss cannot cancel reentrant presentation or release its duck")
    await get_tree().process_frame
    _check(_ghosts().is_empty(), "new presentation removes outgoing old glyph")
    modal.queue_free()
    await get_tree().process_frame
    _check(_ghosts().is_empty() and AudioDirector.playback_snapshot()["duck_locks"] == 0,
        "scene exit cancels reveal and releases existing audio lease")
    modal = _fresh()
    modal.present_fragment(&"star")
    await _wait()
    modal.dismiss()
    modal.queue_free()
    await get_tree().process_frame
    await get_tree().process_frame
    _check(_ghosts().is_empty(), "owner free during dissolve leaves no detached quad")
    _check(GameState.capture_save().to_dict() == dto and SaveManager.get("_dirty") == dirty,
        "all cosmetic lifecycle paths preserve DTO and dirty flag")
    SettingsManager.effects = effects
    InputManager.set_mode(InputManager.Mode.UI)
    print("FRAGMENT_SIGIL %s: %d assertions" % ["PASS" if _failures == 0 else "FAIL", _checks])
    get_tree().quit(0 if _failures == 0 else 1)

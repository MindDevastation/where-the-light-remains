extends Node
## Native modal API/timeline samples, not a gameplay walkthrough.

const PRESENTER := preload("res://gameplay/collectibles/fragment_presenter.tscn")
var _output := ""
var _preset := "Medium"
var _checks := 0
var _failures := 0
var _captures: Array[Dictionary] = []
var _layer: CanvasLayer


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--review-output="): _output = arg.trim_prefix("--review-output=")
        if arg.begins_with("--review-preset="): _preset = arg.trim_prefix("--review-preset=")
    get_tree().create_timer(70.0, true).timeout.connect(func() -> void:
        push_error("FRAGMENT_SIGIL_REVIEW timeout")
        get_tree().quit(1))
    _run.call_deferred()


func _check(value: bool, message: String) -> void:
    _checks += 1
    if not value:
        _failures += 1
        push_error("FRAGMENT_SIGIL_REVIEW FAIL: " + message)


func _capture(name: String, amount: float) -> Image:
    await RenderingServer.frame_post_draw
    var image := get_viewport().get_texture().get_image()
    var filename := "%s_%s_%dx%d.png" % [name, _preset.to_lower(), image.get_width(), image.get_height()]
    _check(image.get_size() == get_window().size and image.save_png(_output.path_join(filename)) == OK,
        "original native framebuffer saved: " + name)
    _captures.append({"file": filename, "view": name, "amount": amount,
        "size": [image.get_width(), image.get_height()], "preset": _preset,
        "scope": "Actual modal API and owned Tween timeline sample over a flat fixture background; no world/input/save action"})
    return image


func _run() -> void:
    _check(not _output.is_empty() and _preset in ["Low", "Medium"], "bounded review arguments")
    var dto := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    SettingsManager.graphics_preset = _preset
    SettingsManager.effects = true
    SettingsManager.apply_runtime(false)
    _layer = CanvasLayer.new()
    add_child(_layer)
    var background := ColorRect.new()
    background.color = Color("101a26")
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _layer.add_child(background)
    for id: StringName in [&"star", &"hearth"]:
        var modal := PRESENTER.instantiate() as FragmentPresenter
        _layer.add_child(modal)
        InputManager.set_mode(InputManager.Mode.GAMEPLAY)
        _check(modal.present_fragment(id) == OK, "normal present: " + String(id))
        var effect := modal._sigil_effect
        effect._animation.pause()
        # Layout is allowed to settle while the actual reveal Tween is paused.
        for frame in 3: await get_tree().process_frame
        var hidden := await _capture(String(id) + "_reveal_zero", effect.amount)
        effect._animation.custom_step(FragmentSigilEffect.REVEAL_SECONDS / 3.0)
        _check(is_equal_approx(effect.amount, 0.5), "native sine reveal reaches half coverage")
        var middle := await _capture(String(id) + "_reveal_half", effect.amount)
        get_tree().paused = true
        await get_tree().create_timer(0.08, true).timeout
        var paused := await _capture(String(id) + "_reveal_paused", effect.amount)
        _check(paused.get_data() == middle.get_data(), "paused intermediate framebuffer is identical")
        get_tree().paused = false
        effect._animation.custom_step(FragmentSigilEffect.REVEAL_SECONDS)
        _check(not effect.active and modal.sigil_view.material == null, "native timeline completion restores original glyph")
        var settled := await _capture(String(id) + "_settled", 1.0)
        _check(hidden.get_data() != middle.get_data() and middle.get_data() != settled.get_data(), "materialization changes actual pixels")
        var full := ShaderMaterial.new()
        full.shader = FragmentSigilEffect.DISSOLVE
        full.set_shader_parameter("amount", 1.0)
        modal.sigil_view.material = full
        var shader_full := await _capture(String(id) + "_shader_one", 1.0)
        _check(settled.get_data() == shader_full.get_data(), "amount one is exact original glyph raster")
        modal.sigil_view.material = null
        var original_rect := modal.sigil_view.get_global_rect()
        modal.dismiss()
        _check(not modal.visible and InputManager.mode == InputManager.Mode.GAMEPLAY and
            AudioDirector.playback_snapshot()["duck_locks"] == 0, "normal close does not wait for outgoing effect")
        _check(effect.active and effect._ghost() != null, "outgoing quad is present outside hidden modal")
        _check(effect._ghost().get_global_rect() == original_rect, "outgoing quad preserves original glyph rectangle")
        effect._animation.pause()
        effect._animation.custom_step(FragmentSigilEffect.DISSOLVE_SECONDS * 2.0 / 3.0)
        _check(is_equal_approx(effect.amount, 0.5), "native sine dissolve reaches half coverage")
        await _capture(String(id) + "_dissolve_half", effect.amount)
        effect._animation.custom_step(FragmentSigilEffect.DISSOLVE_SECONDS)
        for frame in 2: await get_tree().process_frame
        _check(_layer.find_children("FragmentSigilGhost*", "TextureRect", false, false).is_empty(), "outgoing quad cleaned")
        await _capture(String(id) + "_dissolve_finished", 0.0)
        modal.queue_free()
        await get_tree().process_frame
    SettingsManager.effects = false
    var static_modal := PRESENTER.instantiate() as FragmentPresenter
    _layer.add_child(static_modal)
    InputManager.set_mode(InputManager.Mode.GAMEPLAY)
    static_modal.present_fragment(&"star")
    for frame in 3: await get_tree().process_frame
    _check(not static_modal._sigil_effect.active and static_modal.sigil_view.material == null, "effects off static original")
    await _capture("star_effects_off", 1.0)
    static_modal.dismiss(false)
    static_modal.queue_free()
    await get_tree().process_frame
    _check(GameState.capture_save().to_dict() == dto and SaveManager.get("_dirty") == dirty, "DTO and dirty flag preserved")
    var receipt := {"status": "PASS_CAPTURE_ONLY" if _failures == 0 else "FAIL", "checks": _checks,
        "failures": _failures, "captures": _captures, "renderer": RenderingServer.get_current_rendering_method(),
        "device": RenderingServer.get_video_adapter_name(), "preset": _preset,
        "scope": "Star/Hearth modal glyph VFX only; native API/timeline fixture; no world carrier, later sigils, route, persistence or target GPU acceptance"}
    var file := FileAccess.open(_output.path_join("captures_%s.json" % _preset.to_lower()), FileAccess.WRITE)
    file.store_string(JSON.stringify(receipt, "  ") + "\n")
    file.close()
    print("FRAGMENT_SIGIL_REVIEW %s: %d assertions; %d captures" % ["CAPTURED" if _failures == 0 else "FAIL", _checks, _captures.size()])
    get_tree().quit(0 if _failures == 0 else 1)

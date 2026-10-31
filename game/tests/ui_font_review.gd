extends Node
## Font/layout fixtures using actual current UI. No gameplay or disk-save action.

const FONT := preload("res://art/fonts/archive_ui_font.tres")
var _output := ""
var _checks := 0
var _failures := 0
var _captures: Array[Dictionary] = []

func _check(value: bool, message: String) -> void:
    _checks += 1
    if not value:
        _failures += 1
        push_error("UI_FONT_REVIEW FAIL: " + message)


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--review-output="): _output = arg.trim_prefix("--review-output=")
    get_tree().create_timer(100.0, true).timeout.connect(func() -> void:
        push_error("UI_FONT_REVIEW timeout")
        get_tree().quit(1))
    _run.call_deferred()


func _shaping() -> void:
    var corpus: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/data/ui_font_corpus.json"))
    var server := TextServerManager.get_primary_interface()
    _check(FONT.base_font.get_font_name() == "Open Sans" and FONT.fallbacks.size() == 2, "bundled font family and explicit fallback chain")
    for font: FontFile in [FONT.base_font, FONT.fallbacks[0], FONT.fallbacks[1]]:
        _check(not font.allow_system_fallback, "host font fallback disabled: " + font.get_font_name())
    _check(is_equal_approx(FONT.variation_opentype[server.name_to_tag("wght")], 600.0) and
        is_equal_approx(FONT.variation_opentype[server.name_to_tag("wdth")], 100.0), "native semibold axes")
    var notices: Dictionary = FONT.get_meta("third_party_notices")
    for pair: Array in [["Open Sans", "open_sans"], ["Noto Sans Symbols", "noto_sans_symbols"], ["Noto Sans Symbols 2", "noto_sans_symbols_2"]]:
        _check(notices[pair[0]] == FileAccess.get_file_as_string("res://art/fonts/" + pair[1] + "/OFL.txt"), "full upstream notice retained in font metadata")
    var families := {}
    var points: Array = corpus["codepoints"] + corpus["fallback_specimen_codepoints"]
    for codepoint: int in points:
        var line := TextLine.new()
        _check(line.add_string(String.chr(codepoint), FONT, 24), "TextServer accepts codepoint %04X" % codepoint)
        var glyphs := server.shaped_text_get_glyphs(line.get_rid())
        var good := not glyphs.is_empty()
        for glyph: Dictionary in glyphs:
            good = good and glyph["font_rid"].is_valid() and int(glyph["index"]) > 0
            if glyph["font_rid"].is_valid():
                var family := server.font_get_name(glyph["font_rid"])
                good = good and family in ["Open Sans", "Noto Sans Symbols", "Noto Sans Symbols 2"]
                families[family] = true
        _check(good, "bundled native glyph without tofu/host substitution: %04X" % codepoint)
    _check(families.size() == 3, "both fallback families are actually used by native shaping")
    print("UI_FONT_SHAPING: corpus_strings=", corpus["source_string_count"], "; codepoints=", corpus["codepoints"].size(), "; native_families=", families.keys())


func _inspect(root: Node) -> int:
    var count := 0
    var nodes: Array[Node] = [root]
    nodes.append_array(root.find_children("*", "Control", true, false))
    for node: Node in nodes:
        if not node is Control or not node.is_visible_in_tree(): continue
        var control := node as Control
        var value := ""
        if node is Label: value = node.text
        elif node is BaseButton: value = node.text
        elif node is LineEdit: value = node.text
        else: continue
        if value.is_empty(): continue
        count += 1
        _check(control.get_theme_font("font") == FONT, "effective font on " + str(control.get_path()))
        _check(control.size.x + 0.5 >= control.get_minimum_size().x and control.size.y + 0.5 >= control.get_minimum_size().y,
            "text control fits native minimum: " + str(control.get_path()))
        if node is Label:
            _check(node.get_visible_line_count() == node.get_line_count(), "all label lines fit: " + str(control.get_path()))
        var in_scroll := false
        var parent := node.get_parent()
        while parent != null:
            if parent is ScrollContainer: in_scroll = true
            parent = parent.get_parent()
        if not in_scroll:
            var rect := control.get_global_rect()
            var viewport := Rect2(Vector2.ZERO, Vector2(get_window().size))
            _check(viewport.grow(1.0).encloses(rect), "text control inside actual window: " + str(control.get_path()))
    _check(count > 0, "visible text controls inspected")
    return count


func _capture(name: String, root: Node, specimen: bool = false) -> void:
    for frame in 4: await get_tree().process_frame
    var controls := _inspect(root)
    await RenderingServer.frame_post_draw
    var image := get_viewport().get_texture().get_image()
    _check(image.get_size() == get_window().size, "actual framebuffer matches window")
    var filename := "%s_%dx%d.png" % [name, image.get_width(), image.get_height()]
    _check(image.save_png(_output.path_join(filename)) == OK, "native original capture")
    _captures.append({"file": filename, "view": name, "size": [image.get_width(), image.get_height()],
        "visible_text_controls": controls, "synthetic_font_specimen": specimen,
        "scope": "Existing UI API/pose fixture, not actual keyboard/mouse/gameplay/save action"})


func _run() -> void:
    _check(not _output.is_empty(), "output required")
    _shaping()
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var boot := preload("res://core/boot/boot.tscn").instantiate() as ArchiveBoot
    add_child(boot)
    boot.game.get_node("PlayerContainer/Player").set_physics_process(false)
    await _capture("main_menu", boot.menu)
    # Confirmation is a visual pose; the destructive new-game action is never invoked.
    boot.main_panel.hide()
    boot.confirm_panel.show()
    await _capture("new_game_confirmation", boot.menu)
    boot.confirm_panel.hide()
    boot.settings.open()
    await _capture("settings_top", boot.settings)
    var scroll := boot.settings.find_children("*", "ScrollContainer", true, false)[0] as ScrollContainer
    scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
    await _capture("settings_bottom", boot.settings)
    boot.settings.close()
    boot.menu.hide()
    var pause := boot.game.get_node("UILayer/PauseMenu") as PauseMenu
    pause.show()
    pause.get("_panel").show()
    await _capture("pause_menu", pause)
    pause.hide()
    var overlay := CanvasLayer.new()
    overlay.layer = 5
    add_child(overlay)
    var fragments := preload("res://gameplay/collectibles/fragment_presenter.tscn").instantiate() as FragmentPresenter
    overlay.add_child(fragments)
    for id: StringName in [&"star", &"hearth"]:
        InputManager.set_mode(InputManager.Mode.GAMEPLAY)
        _check(fragments.present_fragment(id) == OK, "existing fragment presentation API")
        await _capture(String(id) + "_fragment", fragments)
        fragments.dismiss(false)
    var notice := CheckpointNotice.new()
    overlay.add_child(notice)
    notice.open()
    await _capture("checkpoint_notice", notice)
    notice.close()
    var exit_dialog := boot.game.get_node("UILayer/ExitFailureDialog") as ExitFailureDialog
    exit_dialog.open(ERR_CANT_CREATE)
    await _capture("exit_failure", exit_dialog)
    exit_dialog.close()
    var specimen := Label.new()
    specimen.position = Vector2(32, 32)
    specimen.add_theme_font_size_override("font_size", 24)
    specimen.text = "Кириллица: "
    for codepoint in range(0x410, 0x430): specimen.text += String.chr(codepoint)
    specimen.text += String.chr(0x401) + "\n"
    for codepoint in range(0x430, 0x450): specimen.text += String.chr(codepoint)
    specimen.text += String.chr(0x451) + "\n0123456789 "
    for codepoint: int in [0x2192, 0x23ce, 0x2713, 0x231b, 0x25a0]: specimen.text += String.chr(codepoint) + " "
    overlay.add_child(specimen)
    await _capture("font_specimen", specimen, true)
    _check(GameState.capture_save().to_dict() == before and SaveManager.get("_dirty") == dirty, "UI font fixtures preserve DTO/dirty flag")
    var file := FileAccess.open(_output.path_join("captures_%dx%d.json" % [get_window().size.x, get_window().size.y]), FileAccess.WRITE)
    file.store_string(JSON.stringify({"status": "PASS_CAPTURE_ONLY" if _failures == 0 else "FAIL", "checks": _checks,
        "failures": _failures, "captures": _captures, "renderer": RenderingServer.get_current_rendering_method(),
        "device": RenderingServer.get_video_adapter_name(), "font": FONT.resource_path,
        "scope": "Current UI font binding/glyph/layout fixtures; no real input, persistence failure, route or full visual acceptance"}, "  ") + "\n")
    file.close()
    overlay.queue_free()
    boot.queue_free()
    await get_tree().process_frame
    print("UI_FONT_REVIEW ", "CAPTURED" if _failures == 0 else "FAIL", ": ", _checks, " checks; ten native views")
    get_tree().quit(0 if _failures == 0 else 1)

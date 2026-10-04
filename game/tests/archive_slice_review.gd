extends Node
## Actual Forward+ player view and Cyrillic modals; always bounded and test-owned.

var _output := ""
var _quality := "low"
var _captures: Array[Dictionary] = []


func _ready() -> void:
    get_tree().create_timer(45.0, true).timeout.connect(func() -> void:
        push_error("ARCHIVE_SLICE_REVIEW timeout")
        get_tree().quit(1)
    )
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--review-output="):
            _output = arg.trim_prefix("--review-output=")
        if arg.begins_with("--quality="):
            _quality = arg.trim_prefix("--quality=")
    _run.call_deferred()


func _capture(name: String) -> void:
    # Container minimum sizes, wrapping and Button draw all settle after show().
    for frame in 30:
        await get_tree().process_frame
    await get_tree().create_timer(.25).timeout
    await RenderingServer.frame_post_draw
    var image := get_viewport().get_texture().get_image()
    var path := _output.path_join(name + ".png")
    if image.save_png(path) != OK:
        push_error("Could not capture review image")
        get_tree().quit(1)
        return
    var world := get_node("GameRoot/WorldSlot").get_child(0) as ArchiveMain
    var presenter := world.get_node("FragmentLayer/FragmentPresenter") as FragmentPresenter
    var button := presenter.continue_button
    var bright_button_pixels := 0
    if presenter.visible:
        # Verify the rendered text inside the actual button, excluding its border.
        # Node visibility alone does not establish that the captured UI was drawn.
        var rect := button.get_global_rect().grow(-5)
        for y in range(int(rect.position.y), int(rect.end.y)):
            for x in range(int(rect.position.x), int(rect.end.x)):
                var pixel := image.get_pixel(x, y)
                if minf(pixel.r, minf(pixel.g, pixel.b)) > .67:
                    bright_button_pixels += 1
        if bright_button_pixels < 200:
            push_error("Fragment Continue text absent from rendered capture: " + name)
            get_tree().quit(1)
            return
    _captures.append({"name": name, "path": path, "width": image.get_width(), "height": image.get_height(),
        "modal_visible": presenter.visible, "button_visible": button.is_visible_in_tree(),
        "button_rect": [button.global_position.x, button.global_position.y, button.size.x, button.size.y],
        "button_text": button.text, "bright_button_pixels": bright_button_pixels})


func _run() -> void:
    if _output.is_empty() or _quality not in ["low", "medium"]:
        push_error("Missing review output/quality")
        get_tree().quit(1)
        return
    SettingsManager.graphics_preset = "Low" if _quality == "low" else "Medium"
    SettingsManager.apply_runtime(false)
    var game := preload("res://core/game_root/game_root.tscn").instantiate()
    add_child(game)
    var definition := StageDefinition.new()
    definition.stage_id = ArchiveProgress.WING_ONE
    definition.scene_path = "res://worlds/archive/archive_main.tscn"
    SceneRouter.register_stage(definition)
    var saved := SaveGame.new()
    saved.stage_id = ArchiveProgress.WING_ONE
    saved.checkpoint_id = &"archive_awakened"
    saved.milestones = {"archive_awakened": true, "wing_01_unlocked": true}
    ArchiveProgress.write_projection(saved)
    if await SceneRouter.request_registered_stage(saved.stage_id, saved) != OK:
        push_error("Review route failed")
        get_tree().quit(1)
        return
    var world := game.get_node("WorldSlot").get_child(0) as ArchiveMain
    var player := game.get_node("PlayerContainer/Player") as FirstPersonPlayer
    player.spawn_at(Transform3D(Basis.IDENTITY, Vector3(1.8, .004, -20)))
    player.look_at(Vector3(0, .004, -23))
    player.head.rotation.x = .04
    await _capture("room_cold_" + _quality)
    var rings := world.get_node("Wing01/Room/Rings") as LightRingPuzzle
    var presenter := world.get_node("FragmentLayer/FragmentPresenter") as FragmentPresenter
    for index in 3:
        for click in index + 1:
            rings.rotate_ring(index)
    await _capture("fragment_star_" + _quality)
    presenter.dismiss()
    var focus := world.get_node("Wing01/Room/Focus") as LightFocusPuzzle
    focus.cycle()
    focus.cycle()
    await _capture("fragment_hearth_" + _quality)
    presenter.dismiss()
    await get_tree().create_timer(.9).timeout
    await _capture("room_warm_" + _quality)
    var file := FileAccess.open(_output.path_join("captures_" + _quality + ".json"), FileAccess.WRITE)
    file.store_string(JSON.stringify({"status": "CAPTURED_FOR_REVIEW", "quality": _quality, "captures": _captures,
        "renderer": RenderingServer.get_current_rendering_method(), "device": RenderingServer.get_video_adapter_name()}, "  "))
    file.close()
    game.queue_free()
    await get_tree().process_frame
    SceneRouter.unregister_stage(ArchiveProgress.WING_ONE)
    print("ARCHIVE_SLICE_REVIEW CAPTURED: ", _quality, "; 4 actual player/modal views")
    get_tree().quit()

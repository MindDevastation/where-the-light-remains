extends SceneTree
## Isolated CLI review; never the main scene or a gameplay controller.

var meshes: Array[MeshInstance3D] = []


func _initialize() -> void:
    _run.call_deferred()


func _check(condition: bool, message: String) -> bool:
    if not condition:
        push_error("ARCHIVE_KIT_REVIEW FAIL: " + message)
        quit(1)
    return condition


func _gather(node: Node) -> void:
    if node is MeshInstance3D:
        meshes.append(node)
    for child in node.get_children():
        _gather(child)


func _frame() -> Image:
    for i in 5:
        await process_frame
    await RenderingServer.frame_post_draw
    return root.get_texture().get_image()


func _label(parent: Node, text: String, position: Vector2, size: int) -> Label:
    var label := Label.new()
    label.text = text
    label.position = position
    label.size = Vector2(root.size.x - 80, 45)
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", Color("ecdab8"))
    label.add_theme_color_override("font_shadow_color", Color("101723"))
    label.add_theme_constant_override("shadow_offset_x", 2)
    label.add_theme_constant_override("shadow_offset_y", 2)
    parent.add_child(label)
    return label


func _run() -> void:
    var view := "front"
    var output := ""
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--view="):
            view = arg.trim_prefix("--view=")
        elif arg.begins_with("--screenshot="):
            output = arg.trim_prefix("--screenshot=")
    if not _check(view in ["front", "reverse", "corner"] and not output.is_empty(), "Expected view and screenshot path"):
        return
    if not _check(DisplayServer.get_name() == "X11" and RenderingServer.get_current_rendering_method() == "forward_plus" and RenderingServer.get_current_rendering_driver_name() == "vulkan", "Real X11/Vulkan/Forward+ required"):
        return
    var stage := Node3D.new()
    root.add_child(stage)
    var world := WorldEnvironment.new()
    var environment := Environment.new()
    world.environment = environment
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("0d172e")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    environment.ambient_light_energy = .36
    environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
    environment.tonemap_mode = Environment.TONE_MAPPER_ACES
    var sky := Sky.new()
    var sky_material := ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color("172d60")
    sky_material.sky_horizon_color = Color("837666")
    sky_material.ground_bottom_color = Color("171e2d")
    sky_material.ground_horizon_color = Color("665b4c")
    sky.sky_material = sky_material
    environment.sky = sky
    stage.add_child(world)
    var key := DirectionalLight3D.new()
    key.light_color = Color("ffddb0")
    key.light_energy = 1.0
    key.rotation_degrees = Vector3(-50, 150, 0)
    key.shadow_enabled = true
    stage.add_child(key)
    var fill := DirectionalLight3D.new()
    fill.light_color = Color("719be4")
    fill.light_energy = .65
    fill.rotation_degrees = Vector3(-35, -20, 0)
    stage.add_child(fill)
    var path: String = "res://tests/fixtures/archive_kit_corner.tscn" if view == "corner" else "res://tests/fixtures/archive_kit_sample.tscn"
    var packed: PackedScene = load(path)
    if not _check(packed != null, "Assembly missing"):
        return
    var assembly: Node3D = packed.instantiate()
    stage.add_child(assembly)
    _gather(assembly)
    var camera := Camera3D.new()
    camera.keep_aspect = Camera3D.KEEP_WIDTH
    camera.fov = 52
    stage.add_child(camera)
    if view == "corner":
        camera.position = Vector3(6.274, 7.0325, -10.361)
        camera.look_at(Vector3(-1.5, 1.8, 1.3))
    else:
        camera.position = Vector3(9.75, 6.77, -15.6 if view == "front" else 15.6)
        camera.look_at(Vector3(0, 1.7, 0))
    camera.current = true
    var canvas := CanvasLayer.new()
    stage.add_child(canvas)
    var russian: String = {"front": "Вид спереди", "reverse": "Обратная сторона", "corner": "Прямой угол и единая опора"}[view]
    var title: Label = _label(canvas, "АРХИВ · МОДУЛЬНЫЙ ОБРАЗЕЦ", Vector2(36, 24), 30)
    var subtitle: Label = _label(canvas, russian + " · Камень и латунь · Проверка геометрии и материалов", Vector2(38, 65), 21)
    for label in [title, subtitle]:
        for character in label.text:
            if not _check(label.get_theme_font("font").has_char(character.unicode_at(0)), "Missing Cyrillic glyph"):
                return
    var full: Image = await _frame()
    for mesh in meshes:
        mesh.visible = false
    var blank: Image = await _frame()
    var contribution := 0.0
    var observations := 0
    for y in range(160, root.size.y - 90, 8):
        for x in range(100, root.size.x - 100, 8):
            var a: Color = full.get_pixel(x, y)
            var b: Color = blank.get_pixel(x, y)
            contribution += (absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)) / 3
            observations += 1
    contribution /= observations
    if not _check(contribution > .03, "No actual assembly contribution to framebuffer"):
        return
    for mesh in meshes:
        mesh.visible = true
    var final_image: Image = await _frame()
    if not _check(final_image.get_size() == Vector2i(1920, 1080) and final_image.save_png(output) == OK, "Screenshot resolution/save failed"):
        return
    print("ARCHIVE_KIT_REVIEW counters (isolated software preview): meshes=", meshes.size(), "; draw_calls=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), "; texture_bytes=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED))
    print("ARCHIVE_KIT_REVIEW PASS: view=", view, "; rgb_delta=", contribution, "; actual X11/Vulkan/Forward+; Cyrillic; one shadow-casting directional + cool nonshadow fill; screenshot=", output)
    root.get_node("App").call("request_safe_exit")

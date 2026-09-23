extends SceneTree
## Disposable material capabilities, not authored production-library assets.

var specimens: Array[MeshInstance3D] = []
var centers: Array[Vector3] = []
var camera: Camera3D


func _initialize() -> void:
    _run.call_deferred()


func _check(condition: bool, message: String) -> bool:
    if not condition:
        push_error("MATERIAL_PREFLIGHT FAIL: " + message)
        quit(1)
    return condition


func _capture() -> Image:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    return root.get_texture().get_image()


func _run() -> void:
    if not _check(DisplayServer.get_name() == "X11" and RenderingServer.get_current_rendering_driver_name() == "vulkan" and RenderingServer.get_current_rendering_method() == "forward_plus", "Requires actual X11/Vulkan/Forward+"):
        return
    var screenshot := ""
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--screenshot="):
            screenshot = arg.trim_prefix("--screenshot=")
    if not _check(not screenshot.is_empty(), "Missing --screenshot output path"):
        return
    var stage := Node3D.new()
    root.add_child(stage)
    var world := WorldEnvironment.new()
    world.environment = Environment.new()
    world.environment.background_mode = Environment.BG_COLOR
    world.environment.background_color = Color("17212b")
    world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    world.environment.ambient_light_color = Color("c8daed")
    world.environment.ambient_light_energy = 0.6
    stage.add_child(world)
    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-30, -35, 0)
    key.light_energy = 2.0
    stage.add_child(key)
    camera = Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 7.0
    camera.position = Vector3(0, 0, 12)
    stage.add_child(camera)
    camera.current = true
    var names := ["Камень · непрозрачность", "Латунь · металл", "Дерево · гладкость", "Матовое стекло · alpha", "Кристалл · alpha", "Свет · эмиссия"]
    var colors := [Color("d3c7aa"), Color("b88a43"), Color("503021"), Color(0.55, 0.78, 0.91, 0.42), Color(0.58, 0.48, 0.9, 0.25), Color("ffc36b")]
    var roughness := [0.85, 0.28, 0.24, 0.7, 0.08, 0.4]
    var canvas := CanvasLayer.new()
    root.add_child(canvas)
    for index in 6:
        var center := Vector3(float(index % 3 - 1) * 3.4, 1.65 if index < 3 else -1.55, 0)
        centers.append(center)
        # Contrasting cards reveal alpha blending without any production texture.
        for stripe in 4:
            var card := MeshInstance3D.new()
            var quad := QuadMesh.new()
            quad.size = Vector2(0.43, 1.8)
            card.mesh = quad
            card.position = center + Vector3((float(stripe) - 1.5) * 0.43, 0, -0.95)
            var backing := StandardMaterial3D.new()
            backing.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
            backing.albedo_color = Color("d5e0eb") if stripe % 2 == 0 else Color("344455")
            card.material_override = backing
            stage.add_child(card)
        var instance := MeshInstance3D.new()
        var sphere := SphereMesh.new()
        sphere.radius = 0.85
        sphere.height = 1.7
        sphere.radial_segments = 48
        sphere.rings = 24
        instance.mesh = sphere
        instance.position = center
        var material := StandardMaterial3D.new()
        material.albedo_color = colors[index]
        material.roughness = roughness[index]
        if index == 1:
            material.metallic = 0.85
        if index == 3 or index == 4:
            material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        if index == 5:
            material.emission_enabled = true
            material.emission = colors[index]
            material.emission_energy_multiplier = 2.0
        instance.material_override = material
        stage.add_child(instance)
        specimens.append(instance)
        var label := Label.new()
        label.text = names[index]
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.add_theme_font_size_override("font_size", 22)
        label.size = Vector2(360, 40)
        canvas.add_child(label)
        label.position = camera.unproject_position(center + Vector3(0, -1.12, 0)) - Vector2(180, 0)
        for character in label.text:
            if not _check(label.get_theme_font("font").has_char(character.unicode_at(0)), "Missing label glyph"):
                return
    var rendered: Image = await _capture()
    if not _check(not rendered.is_empty(), "Framebuffer readback is empty"):
        return
    for instance in specimens:
        instance.visible = false
    var backing_only: Image = await _capture()
    # Each specimen must contribute actual pixels, independently of the UI.
    for index in 6:
        var point := camera.unproject_position(centers[index])
        var delta := 0.0
        var count := 0
        for y in range(int(point.y) - 35, int(point.y) + 36, 5):
            for x in range(int(point.x) - 35, int(point.x) + 36, 5):
                var a := rendered.get_pixel(x, y)
                var b := backing_only.get_pixel(x, y)
                delta += absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)
                count += 3
        delta /= count
        if not _check(delta > 0.015, "No rendered contribution: " + names[index]):
            return
        print("MATERIAL_PREFLIGHT rendered: ", names[index], "; mean_rgb_delta=", delta)
    for instance in specimens:
        instance.visible = true
    var final_image: Image = await _capture()
    if not _check(final_image.save_png(screenshot) == OK, "PNG save failed"):
        return
    print("MATERIAL_PREFLIGHT runtime: ", Engine.get_version_info()["string"], "; display=", DisplayServer.get_name(), "; driver=", RenderingServer.get_current_rendering_driver_name(), "; renderer=", RenderingServer.get_current_rendering_method(), "; image=", final_image.get_size())
    print("MATERIAL_PREFLIGHT PASS: six capability specimens rendered; opacity/metallic/roughness/alpha/emission; Cyrillic; screenshot=", screenshot)
    root.get_node("App").call("request_safe_exit")

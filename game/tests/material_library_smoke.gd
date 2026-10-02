extends SceneTree
## CLI-only review/validation of the shared authored material resources.

const FAMILIES := ["observatory_stone", "aged_brass", "dark_walnut", "memory_glass", "crystal_glass", "archive_emissive_gold"]
const TITLES := ["Светлый камень", "Состаренная латунь", "Тёмный орех", "Матовое стекло памяти", "Кристалл", "Золотое свечение"]
var materials: Array[StandardMaterial3D] = []
var meshes: Array[MeshInstance3D] = []
var centers: Array[Vector3] = []
var camera: Camera3D
var tiles := false
var lighting := "neutral"
var output := ""
var hold := false
var v2 := false
var families := FAMILIES.duplicate()
var titles := TITLES.duplicate()


func _initialize() -> void:
    _run.call_deferred()


func _check(condition: bool, message: String) -> bool:
    if not condition:
        push_error("MATERIAL_LIBRARY FAIL: " + message)
        quit(1)
    return condition


func _frame() -> Image:
    for frame in 4:
        await process_frame
    await RenderingServer.frame_post_draw
    return root.get_texture().get_image()


func _label(canvas: CanvasLayer, text: String, point: Vector2, width: float, size: int) -> Label:
    var label := Label.new()
    label.text = text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", size)
    label.size = Vector2(width, 50)
    label.position = point - Vector2(width / 2.0, 0)
    canvas.add_child(label)
    return label


func _mean_delta(a: Image, b: Image, center: Vector2) -> float:
    var delta := 0.0
    var count := 0
    for y in range(int(center.y) - 45, int(center.y) + 46, 6):
        for x in range(int(center.x) - 45, int(center.x) + 46, 6):
            var ca := a.get_pixel(x, y)
            var cb := b.get_pixel(x, y)
            delta += absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b)
            count += 3
    return delta / count


func _run() -> void:
    if not _check(DisplayServer.get_name() == "X11" and RenderingServer.get_current_rendering_method() == "forward_plus" and RenderingServer.get_current_rendering_driver_name() == "vulkan", "Requires graphical X11/Vulkan/Forward+"):
        return
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--screenshot="):
            output = arg.trim_prefix("--screenshot=")
        elif arg.begins_with("--light="):
            lighting = arg.trim_prefix("--light=")
        elif arg == "--tiles":
            tiles = true
        elif arg == "--hold":
            hold = true
        elif arg == "--v2":
            v2 = true
    if not _check(not output.is_empty() and lighting in ["neutral", "warm", "cool"], "Expected screenshot path and valid light preset"):
        return
    if v2:
        families.append_array(["dark_iron", "aged_leather", "crimson_textile", "navy_textile", "clear_glass", "resonance_teal"])
        titles.append_array(["Тёмное железо", "Состаренная кожа", "Багряная ткань", "Синяя ткань", "Прозрачное стекло", "Бирюзовое свечение"])
    for family in families:
        var path: String = "res://art/materials/m_" + family + ".tres"
        var material: StandardMaterial3D = load(path)
        if not _check(material != null and not material.resource_local_to_scene and load(path) == material, "Shared resource failed: " + path):
            return
        materials.append(material)
    for index in 3:
        if not _check(materials[index].albedo_texture != null and materials[index].normal_enabled and materials[index].normal_texture != null and materials[index].roughness_texture != null, "Missing authored maps"):
            return
    if not _check(materials[3].refraction_enabled and materials[4].refraction_enabled and materials[5].emission_enabled, "Missing optical/emission capability"):
        return
    if v2:
        for index in [6, 7, 8, 9]:
            if not _check(materials[index].albedo_texture != null and materials[index].normal_texture != null and materials[index].roughness_texture != null, "Missing v2 authored maps"):
                return
        if not _check(materials[8].albedo_texture == materials[9].albedo_texture and materials[8].normal_texture == materials[9].normal_texture and materials[8].roughness_texture == materials[9].roughness_texture, "Textile variants must share maps"):
            return
        if not _check(not materials[2].clearcoat_enabled and materials[10].refraction_enabled and materials[11].emission_enabled, "V2 aged wood/clear glass/teal behavior missing"):
            return
    var stage := Node3D.new()
    root.add_child(stage)
    var world := WorldEnvironment.new()
    var environment := Environment.new()
    world.environment = environment
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("0d172e") if v2 else Color("141b24")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    environment.ambient_light_energy = 0.55
    environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
    environment.tonemap_mode = Environment.TONE_MAPPER_ACES
    environment.glow_enabled = true
    environment.glow_intensity = 0.45
    var sky := Sky.new()
    var sky_material := ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color("172d60") if v2 else Color("374456")
    sky_material.sky_horizon_color = Color("b8c1ce")
    sky_material.ground_bottom_color = Color("25232b")
    sky_material.ground_horizon_color = Color("8a8583")
    sky.sky_material = sky_material
    environment.sky = sky
    stage.add_child(world)
    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-22, -30, 0)
    key.light_energy = 1.25
    key.light_color = Color("fff4df")
    if lighting == "warm":
        key.light_color = Color("ffb878")
    elif lighting == "cool":
        key.light_color = Color("9abfff")
    stage.add_child(key)
    var fill := DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(15, 50, 0)
    fill.light_color = Color("a6c6ed")
    fill.light_energy = 0.3
    stage.add_child(fill)
    camera = Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 8.7 if v2 and not tiles else 7.4
    camera.position = Vector3(0, 0, 12)
    stage.add_child(camera)
    camera.current = true
    var canvas := CanvasLayer.new()
    root.add_child(canvas)
    var header: String = "БИБЛИОТЕКА МАТЕРИАЛОВ · " + {"neutral": "НЕЙТРАЛЬНЫЙ СВЕТ", "warm": "ТЁПЛЫЙ СВЕТ", "cool": "ХОЛОДНЫЙ СВЕТ"}[lighting]
    if tiles:
        header = "ПОВТОРЕНИЕ КАРТ · 4 × 4 · ОБЩИЕ МАТЕРИАЛЫ"
    if v2:
        header = "АРХИВ · МАТЕРИАЛЫ V2 · " + {"neutral": "НЕЙТРАЛЬНЫЙ СВЕТ", "warm": "ТЁПЛЫЙ СВЕТ", "cool": "ХОЛОДНЫЙ СВЕТ"}[lighting]
        if tiles:
            header = "АРХИВ · КАРТЫ V2 · ПОВТОРЕНИЕ 4 × 4"
    _label(canvas, header, Vector2(root.size.x / 2.0, 32), root.size.x, 26)
    var indices: Array = [0, 1, 2] if tiles else range(families.size())
    if v2 and tiles:
        indices = [0, 1, 2, 6, 7, 8, 9]
    var count := indices.size()
    for sample in count:
        var index: int = indices[sample]
        var center := Vector3(float(sample % 3 - 1) * 3.5, 0.0 if tiles else (1.6 if sample < 3 else -1.5), 0)
        if v2:
            center = Vector3((float(sample % 4) - 1.5) * 3.3, (1.0 - floorf(float(sample) / 4.0)) * 2.45 if not tiles else (1.5 if sample < 4 else -1.5), 0)
        centers.append(center)
        var instance := MeshInstance3D.new()
        if tiles:
            var quad := QuadMesh.new()
            quad.size = Vector2(2.4, 2.4) if v2 else Vector2(3.0, 3.0)
            var arrays := quad.get_mesh_arrays()
            var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
            for i in uv.size():
                uv[i] *= 4.0
            arrays[Mesh.ARRAY_TEX_UV] = uv
            var tile_mesh := ArrayMesh.new()
            tile_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
            instance.mesh = tile_mesh
        else:
            var sphere := SphereMesh.new()
            sphere.radius = 0.9
            sphere.height = 1.8
            sphere.radial_segments = 64
            sphere.rings = 32
            instance.mesh = sphere
        instance.position = center
        instance.material_override = materials[index]
        stage.add_child(instance)
        meshes.append(instance)
        if index == 3 or index == 4 or (v2 and index == 10):
            instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
            for stripe in 8:
                var card := MeshInstance3D.new()
                var quad := QuadMesh.new()
                quad.size = Vector2(0.235, 1.85)
                card.mesh = quad
                card.position = center + Vector3((float(stripe) - 3.5) * 0.235, 0, -1.0)
                var backing := StandardMaterial3D.new()
                backing.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
                backing.albedo_color = Color("cad7e4") if stripe % 2 == 0 else Color("24364b")
                card.material_override = backing
                stage.add_child(card)
        var label_offset := -1.32 if v2 and tiles else (-1.9 if tiles else -1.12)
        var label := _label(canvas, titles[index], camera.unproject_position(center + Vector3(0, label_offset, 0)), 355 if v2 else 500, 23 if v2 else 28)
        for character in label.text:
            if not _check(label.get_theme_font("font").has_char(character.unicode_at(0)), "Missing Cyrillic glyph"):
                return
    # Allow environment radiance and material pipelines to settle before capture.
    for frame in 12:
        await process_frame
    var full: Image = await _frame()
    for mesh in meshes:
        mesh.visible = false
    var without: Image = await _frame()
    for index in count:
        var delta := _mean_delta(full, without, camera.unproject_position(centers[index]))
        var family: String = families[indices[index]]
        if not _check(delta > 0.015, "No rendered contribution: " + family):
            return
        print("MATERIAL_LIBRARY rendered: ", family, "; rgb_delta=", delta)
    for mesh in meshes:
        mesh.visible = true
    var final_image: Image = await _frame()
    if not _check(final_image.save_png(output) == OK, "Screenshot save failed"):
        return
    print("MATERIAL_LIBRARY counters (preview only): draw_calls=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), "; texture_bytes=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED))
    print("MATERIAL_LIBRARY PASS: shared resources=", families.size(), "; rendered=", count, "; authored maps; actual X11/Vulkan/Forward+; Cyrillic; light=", lighting, "; tiles=", tiles, "; image=", final_image.get_size(), "; screenshot=", output)
    if not hold:
        root.get_node("App").call("request_safe_exit")

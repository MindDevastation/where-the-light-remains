extends SceneTree
## Real Forward+ asset review, opt-in CLI only; no gameplay state.

var parts: Array[Node3D] = []


func _initialize() -> void:
    _run.call_deferred()


func _check(condition: bool, message: String) -> bool:
    if not condition:
        push_error("WING01_REVIEW FAIL: " + message)
        quit(1)
    return condition


func _frame() -> Image:
    for i in 5:
        await process_frame
    await RenderingServer.frame_post_draw
    return root.get_texture().get_image()


func _difference(a: Image, b: Image) -> Dictionary:
    var total := 0.0
    var changed := 0
    var samples := 0
    for y in range(150, a.get_height()-20, 4):
        for x in range(20, a.get_width()-20, 4):
            var c: Color = a.get_pixel(x,y)
            var d: Color = b.get_pixel(x,y)
            var value := (absf(c.r-d.r)+absf(c.g-d.g)+absf(c.b-d.b))/3
            total += value
            changed += int(value > .015)
            samples += 1
    return {"mean":total/samples,"changed_samples":changed}


func _label(parent: Node, text: String, position: Vector2, size: int) -> Label:
    var label := Label.new()
    label.text = text
    label.position = position
    label.size = Vector2(root.size.x - 80,45)
    label.add_theme_font_size_override("font_size",size)
    label.add_theme_color_override("font_color",Color("ecdab8"))
    label.add_theme_color_override("font_shadow_color",Color("101723"))
    label.add_theme_constant_override("shadow_offset_x",2)
    label.add_theme_constant_override("shadow_offset_y",2)
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
    if not _check(view in ["front","reverse","focus"] and not output.is_empty(),"Review arguments"):
        return
    if not _check(DisplayServer.get_name()=="X11" and RenderingServer.get_current_rendering_method()=="forward_plus" and RenderingServer.get_current_rendering_driver_name()=="vulkan","Actual X11/Vulkan Forward+"):
        return
    var stage := Node3D.new()
    root.add_child(stage)
    var world := WorldEnvironment.new()
    var env := Environment.new()
    world.environment = env
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("0d172e")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.ambient_light_energy = .4
    env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
    env.tonemap_mode = Environment.TONE_MAPPER_ACES
    var sky := Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color("172d60")
    sky_mat.sky_horizon_color = Color("837666")
    sky_mat.ground_bottom_color = Color("171e2d")
    sky_mat.ground_horizon_color = Color("665b4c")
    sky.sky_material = sky_mat
    env.sky = sky
    stage.add_child(world)
    var key := DirectionalLight3D.new()
    key.light_color = Color("ffddb0")
    key.light_energy = 1.3
    key.rotation_degrees = Vector3(-50,150,0)
    key.shadow_enabled = true
    stage.add_child(key)
    var fill := DirectionalLight3D.new()
    fill.light_color = Color("719be4")
    fill.light_energy = .75
    fill.rotation_degrees = Vector3(-35,-20,0)
    stage.add_child(fill)
    var floor_scene: PackedScene = load("res://worlds/archive/modules/archive_floor_1m.tscn")
    for z in range(-2,3):
        for x in range(-3,3):
            var tile: Node3D = floor_scene.instantiate()
            tile.position = Vector3(x+.5,0,z+.5)
            stage.add_child(tile)
    var packed: PackedScene = load("res://gameplay/puzzles/wing01/wing01_optics_sample.tscn")
    var assembly: Node3D = packed.instantiate()
    stage.add_child(assembly)
    for id in ["Frame","Outer","Middle","Inner","Focus"]:
        parts.append(assembly.get_node(id))
    var camera := Camera3D.new()
    camera.fov = 43
    camera.keep_aspect = Camera3D.KEEP_WIDTH
    stage.add_child(camera)
    if view == "front":
        camera.position = Vector3(-2.85,3.12,-7.8)
        camera.look_at(Vector3(0,1.35,0))
    elif view == "reverse":
        camera.position = Vector3(4.2,3.27,7.2)
        camera.look_at(Vector3(0,1.35,0))
    else:
        camera.position = Vector3(1.34,1.23,-2.9)
        camera.look_at(Vector3(.68,.59,-.56))
    camera.current = true
    var canvas := CanvasLayer.new()
    stage.add_child(canvas)
    var russian: String = {"front":"Три оптических кольца","reverse":"Раздельные детали и задняя опора","focus":"Колесо фокуса · Пять положений"}[view]
    for label in [_label(canvas,"КРЫЛО СВЕТА · МЕХАНИЧЕСКИЙ ОБРАЗЕЦ",Vector2(36,24),30),
                  _label(canvas,russian + " · Латунь, камень, дерево и железо",Vector2(38,65),21)]:
        for character in label.text:
            if not _check(label.get_theme_font("font").has_char(character.unicode_at(0)),"Cyrillic glyph coverage"):
                return
    var full: Image = await _frame()
    if not _check(full.get_size()==Vector2i(1920,1080),"Full-resolution framebuffer"):
        return
    for part in parts:
        part.visible = false
    var blank: Image = await _frame()
    var contribution := _difference(full,blank)
    if not _check(contribution.mean > .005,"Actual assembly framebuffer contribution"):
        return
    # Front view proves every component renders and all four joints visibly move.
    if view == "front":
        for part in parts:
            part.visible = true
            var neutral: Image = await _frame()
            var isolated := _difference(neutral,blank)
            if not _check(isolated.changed_samples>25,"Visible individual component: "+part.name):
                return
            if part.name != "Frame":
                part.rotation.z = deg_to_rad(72 if part.name == "Focus" else 37)
                var pose: Image = await _frame()
                var moved := _difference(neutral,pose)
                if not _check(moved.changed_samples>15,"Actual articulated framebuffer change: "+part.name):
                    return
                print("WING01_FRAME_MOTION PASS: ",part.name,"; isolated=",isolated,"; motion=",moved)
                part.rotation.z = 0
            part.visible = false
    for part in parts:
        part.visible = true
    full = await _frame()
    var error := full.save_png(output)
    if not _check(error==OK,"Actual viewport PNG saved"):
        return
    print("WING01_REVIEW PASS: view=",view,"; contribution=",contribution,"; draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"; texture_bytes=",Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED))
    stage.queue_free()
    await process_frame
    quit(0)

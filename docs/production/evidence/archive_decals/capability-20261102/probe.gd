extends Node3D
func _ready() -> void:
    var surface := MeshInstance3D.new()
    surface.mesh = PlaneMesh.new()
    surface.mesh.size = Vector2(3, 3)
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.6, 0.5, 0.35)
    surface.material_override = material
    add_child(surface)
    var light := DirectionalLight3D.new()
    add_child(light)
    light.rotation_degrees = Vector3(-55, -25, 0)
    var camera := Camera3D.new()
    add_child(camera)
    camera.position = Vector3(0, 3, 2)
    camera.look_at(Vector3.ZERO)
    camera.current = true
    var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
    image.fill(Color(1, 1, 1, 0))
    for y in range(8, 56):
        for x in range(8, 56):
            if Vector2(x - 32, y - 32).length() < 22: image.set_pixel(x, y, Color.WHITE)
    var decal := Decal.new()
    decal.texture_albedo = ImageTexture.create_from_image(image)
    decal.modulate = Color(0.12, 0.075, 0.04, 0.65)
    decal.position.y = 0.01
    decal.size = Vector3(2, 0.05, 2)
    decal.upper_fade = 0.0
    decal.lower_fade = 0.0
    add_child(decal)
    for frame in 3: await get_tree().process_frame
    await RenderingServer.frame_post_draw
    var on := get_viewport().get_texture().get_image()
    on.save_png("res://decal_on.png")
    decal.hide()
    await RenderingServer.frame_post_draw
    var off := get_viewport().get_texture().get_image()
    off.save_png("res://decal_off.png")
    if on.get_data() == off.get_data():
        push_error("DECAL_CAPABILITY no rendered difference")
        get_tree().quit(1)
        return
    print("DECAL_CAPABILITY PASS: native projected alpha changes actual pixels")
    get_tree().quit(0)

extends SceneTree
## Isolated candidate specimens; no game root/autoload or shipping placement.
var _checks := 0
var _output := ""
var _quality := "low"
var _captures: Array[Dictionary] = []

func _initialize() -> void:
    _run.call_deferred()

func check(value: bool, label: String) -> bool:
    _checks+=1
    if not value:
        push_error("COOL_DARK_STONE_REVIEW FAIL: "+label);quit(1)
    return value

func source_image(path: String) -> Image:
    var image:=Image.new()
    if not check(image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))==OK,"Source PNG decode"):return null
    return image

func frame() -> Image:
    for i in 8: await process_frame
    await RenderingServer.frame_post_draw
    return root.get_texture().get_image()

func label(canvas: CanvasLayer, text: String, y: float) -> void:
    var item:=Label.new();item.text=text;item.position=Vector2(0,y);item.size=Vector2(960,45)
    item.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;item.add_theme_font_size_override("font_size",24);canvas.add_child(item)
    var glyphs:=true
    for character in text:glyphs=glyphs and item.get_theme_font("font").has_char(character.unicode_at(0))
    check(glyphs,"Actual Cyrillic specimen labels")

func _run() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--review-output="):_output=arg.trim_prefix("--review-output=")
        elif arg.begins_with("--quality="):_quality=arg.trim_prefix("--quality=")
    if not check(not _output.is_empty() and _quality in ["low","medium"],"Output and quality"):return
    if not check(DisplayServer.get_name()=="X11" and RenderingServer.get_current_rendering_method()=="forward_plus","Actual native X11/Forward+"):return
    root.scaling_3d_scale=.75 if _quality=="low" else 1.0;root.msaa_3d=Viewport.MSAA_DISABLED
    root.positional_shadow_atlas_size=512 if _quality=="low" else 2048
    var saves: Dictionary={}
    for name: String in ["savegame.json","savegame.backup.json"]:
        var path: String="user://"+name
        if not check(FileAccess.file_exists(path),"Protected fixture exists"):return
        saves[path]=FileAccess.get_sha256(path)
    var stone:=load("res://art/materials/m_cool_dark_stone.tres") as StandardMaterial3D
    var warm:=load("res://art/materials/m_observatory_stone.tres") as StandardMaterial3D
    if not check(stone!=null and stone!=warm and not stone.resource_local_to_scene and load(stone.resource_path)==stone,"Distinct shared editable master"):return
    if not check(stone.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED and not stone.emission_enabled and not stone.refraction_enabled and is_zero_approx(stone.metallic),"Opaque matte nonmetallic PBR"):return
    if not check(stone.normal_enabled and is_equal_approx(stone.normal_scale,.5) and stone.texture_filter==BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC,"Normal scale and anisotropic mipmaps"):return
    if not check(stone.roughness_texture_channel==BaseMaterial3D.TEXTURE_CHANNEL_GREEN,"ORM roughness channel"):return
    for texture: Texture2D in [stone.albedo_texture,stone.normal_texture,stone.roughness_texture]:
        if not check(texture is CompressedTexture2D and texture.get_width()==1024 and texture.get_height()==1024 and texture.get_image().has_mipmaps(),"Actual1024 native compressed mip chain"):return
    var normal:=source_image("res://art/textures/material_library/t_cool_dark_stone_normal.png")
    var orm:=source_image("res://art/textures/material_library/t_cool_dark_stone_orm.png")
    var albedo:=source_image("res://art/textures/material_library/t_cool_dark_stone_albedo.png")
    var valid:=true;var color:=Vector3.ZERO;var count:=0
    for y in range(0,1024,31):
        for x in range(0,1024,31):
            var n:=normal.get_pixel(x,y);var direction:=Vector3(n.r,n.g,n.b)*2-Vector3.ONE
            var data:=orm.get_pixel(x,y);var c:=albedo.get_pixel(x,y)
            valid=valid and absf(direction.length()-1)<.015 and direction.z>.93 and data.r>.999 and data.g>.80 and data.g<.95 and is_zero_approx(data.b)
            color+=Vector3(c.r,c.g,c.b);count+=1
    if not check(valid,"Unit +Y normals and matte dielectric data ranges"):return
    color/=count
    if not check(color.x>.16 and color.x<.22 and color.z>color.y and color.y>color.x,"Restrained original cool dark albedo"):return
    var stage:=Node3D.new();root.add_child(stage)
    var world:=WorldEnvironment.new();stage.add_child(world);var environment:=Environment.new();world.environment=environment
    environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("141b24")
    environment.ambient_light_source=Environment.AMBIENT_SOURCE_SKY;environment.ambient_light_energy=.55
    environment.reflected_light_source=Environment.REFLECTION_SOURCE_SKY;environment.tonemap_mode=Environment.TONE_MAPPER_ACES
    var sky:=Sky.new();var sky_material:=ProceduralSkyMaterial.new()
    sky_material.sky_top_color=Color("374456");sky_material.sky_horizon_color=Color("b8c1ce")
    sky_material.ground_bottom_color=Color("25232b");sky_material.ground_horizon_color=Color("8a8583")
    sky.sky_material=sky_material;environment.sky=sky
    var key:=DirectionalLight3D.new();key.rotation_degrees=Vector3(-22,-30,0);key.light_energy=1.25;stage.add_child(key)
    var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(15,50,0);fill.light_color=Color("a6c6ed");fill.light_energy=.3;stage.add_child(fill)
    var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=7.2;camera.position=Vector3(0,0,12);stage.add_child(camera);camera.current=true
    var canvas:=CanvasLayer.new();root.add_child(canvas)
    label(canvas,"MAT-005 · ИЗОЛИРОВАННЫЕ ОБРАЗЦЫ",25)
    label(canvas,"Холодный темный камень                     Принятый теплый камень",445)
    var materials: Array[StandardMaterial3D]=[stone,warm];var specimens: Array[MeshInstance3D]=[]
    for i in 2:
        var mesh:=MeshInstance3D.new();var sphere:=SphereMesh.new();sphere.radius=1;sphere.height=2;sphere.radial_segments=64;sphere.rings=32
        mesh.mesh=sphere;mesh.position=Vector3(-1.7 if i==0 else 1.7,0,0);mesh.material_override=materials[i];stage.add_child(mesh);specimens.append(mesh)
    for lighting: String in ["neutral","warm","cool","tiles"]:
        key.light_color=Color("ffb878") if lighting=="warm" else (Color("9abfff") if lighting=="cool" else Color("fff4df"))
        if lighting=="tiles":
            for i in 2:
                var quad:=QuadMesh.new();quad.size=Vector2(2.5,2.5)
                var arrays:=quad.get_mesh_arrays();var uv: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
                for vertex in uv.size():uv[vertex]*=4
                arrays[Mesh.ARRAY_TEX_UV]=uv
                var tile:=ArrayMesh.new();tile.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);specimens[i].mesh=tile
        for i in 20:await process_frame
        var full: Image=await frame()
        for mesh in specimens:mesh.visible=false
        var empty: Image=await frame()
        for i in 2:
            var center:=camera.unproject_position(specimens[i].global_position);var delta:=0.0;var samples:=0
            for y in range(int(center.y)-45,int(center.y)+46,6):
                for x in range(int(center.x)-45,int(center.x)+46,6):
                    var a:=full.get_pixel(x,y);var b:=empty.get_pixel(x,y)
                    delta+=absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b);samples+=3
            if not check(delta/samples>.015,"Actual framebuffer material contribution "+lighting+str(i)):return
            specimens[i].visible=true
        var image: Image=await frame();var filename: String="stone_"+lighting+"_"+_quality+".png"
        if not check(image.save_png(_output.path_join(filename))==OK,"Capture save"):return
        _captures.append({"file":filename,"lighting":lighting,"tiles":4 if lighting=="tiles" else 1,
            "render_scale":root.scaling_3d_scale,"size":[image.get_width(),image.get_height()],"shipping_assignment":false,
            "materials":[stone.resource_path,warm.resource_path],"draw_calls":int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))})
    for path: String in saves:
        if not check(saves[path]==FileAccess.get_sha256(path),"Protected primary/backup unchanged"):return
    if not check(specimens[0].material_override==stone and specimens[1].material_override==warm,"Shared masters preserved after specimens"):return
    var f:=FileAccess.open(_output.path_join("captures_"+_quality+".json"),FileAccess.WRITE)
    f.store_string(JSON.stringify({"status":"CAPTURED_FOR_REVIEW","quality":_quality,"scope":"unbound_material_specimens",
        "renderer":RenderingServer.get_current_rendering_method(),"device":RenderingServer.get_video_adapter_name(),"assertions":_checks,"captures":_captures},"  "));f.close()
    canvas.queue_free();stage.queue_free();await process_frame
    print("COOL_DARK_STONE_REVIEW PASS: ",_checks," assertions;4 actual native specimens;unbound/no gameplay;protected saves")
    quit(0)

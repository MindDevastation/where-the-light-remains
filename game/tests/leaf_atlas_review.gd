extends SceneTree
## Native unbound UV/alpha specimens only; no gameplay or plant actor.
var _checks := 0
var _output := ""
var _quality := "low"
var _captures: Array[Dictionary] = []

func _initialize() -> void:
    _run.call_deferred()

func check(value: bool, text: String) -> bool:
    _checks+=1
    if not value:
        push_error("LEAF_ATLAS_REVIEW FAIL: "+text);quit(1)
    return value

func frame() -> Image:
    for i in 8: await process_frame
    await RenderingServer.frame_post_draw
    return root.get_texture().get_image()

func label(canvas: CanvasLayer, text: String, y: float) -> void:
    var item:=Label.new();item.text=text;item.position=Vector2(0,y);item.size=Vector2(960,40)
    item.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;item.add_theme_font_size_override("font_size",23);canvas.add_child(item)
    var glyphs:=true
    for character in text:glyphs=glyphs and item.get_theme_font("font").has_char(character.unicode_at(0))
    check(glyphs,"Cyrillic atlas labels")

func _run() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--review-output="):_output=arg.trim_prefix("--review-output=")
        elif arg.begins_with("--quality="):_quality=arg.trim_prefix("--quality=")
    if not check(not _output.is_empty() and _quality in ["low","medium"],"Output/profile"):return
    if not check(DisplayServer.get_name()=="X11" and RenderingServer.get_current_rendering_method()=="forward_plus","Actual native Forward+/X11"):return
    if not check(not root.has_node("GameRoot") and not root.has_node("SettingsManager"),"No gameplay autoload"):return
    root.scaling_3d_scale=.75 if _quality=="low" else 1.0;root.msaa_3d=Viewport.MSAA_DISABLED
    var saves: Dictionary={}
    for name: String in ["savegame.json","savegame.backup.json"]:
        var path: String="user://"+name
        if not check(FileAccess.file_exists(path),"Protected fixture exists"):return
        saves[path]=FileAccess.get_sha256(path)
    var material:=load("res://art/materials/m_archive_leaf_cutout.tres") as StandardMaterial3D
    if not check(material!=null and not material.resource_local_to_scene and load(material.resource_path)==material,"Shared editable material identity"):return
    if not check(material.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR and is_equal_approx(material.alpha_scissor_threshold,.5) and material.cull_mode==BaseMaterial3D.CULL_DISABLED,"Explicit two-sided .5 cutout"):return
    if not check(not material.emission_enabled and not material.refraction_enabled and not material.normal_enabled and is_zero_approx(material.metallic) and is_equal_approx(material.roughness,.85),"Matte dielectric; no new shader/glow/refraction"):return
    var texture:=material.albedo_texture
    if not check(texture is CompressedTexture2D and texture.get_width()==1774 and texture.get_height()==887 and texture.get_image().has_mipmaps(),"Actual returned dimensions/native compressed mip chain"):return
    if not check(material.texture_filter==BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC,"Anisotropic mip filtering"):return
    var source:=Image.new()
    if not check(source.load_png_from_buffer(FileAccess.get_file_as_bytes("res://art/textures/foliage/t_archive_leaf_atlas.png"))==OK and source.get_format()==Image.FORMAT_RGBA8,"Preserved actual RGBA source decode"):return
    var stage:=Node3D.new();root.add_child(stage)
    var world:=WorldEnvironment.new();stage.add_child(world);var environment:=Environment.new();world.environment=environment
    environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("17212b")
    environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color("bbc8d6");environment.ambient_light_energy=.5
    environment.tonemap_mode=Environment.TONE_MAPPER_ACES
    var key:=DirectionalLight3D.new();key.rotation_degrees=Vector3(-15,-20,0);key.light_energy=1.2;stage.add_child(key)
    var back:=DirectionalLight3D.new();back.rotation_degrees=Vector3(0,180,0);back.light_energy=.6;stage.add_child(back)
    var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=6.4;camera.position=Vector3(0,0,12);stage.add_child(camera);camera.current=true
    var canvas:=CanvasLayer.new();root.add_child(canvas)
    label(canvas,"MAT-012 · ИЗОЛИРОВАННЫЙ ЛИСТОВОЙ АТЛАС",18)
    label(canvas,"Вырезание alpha · восемь UV-ячеек · без игрового размещения",493)
    var specimens: Array[MeshInstance3D]=[]
    for row in 2:
        for column in 4:
            var center:=Vector3(-3.3+column*2.2,1.1-row*2.2,0)
            for by in 2:
                for bx in 2:
                    var background:=MeshInstance3D.new();var plane:=QuadMesh.new();plane.size=Vector2(.95,.95);background.mesh=plane
                    var paint:=StandardMaterial3D.new();paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;paint.albedo_color=Color("45576c") if (bx+by)%2==0 else Color("a5a4a0")
                    background.material_override=paint;background.position=center+Vector3(-.475+bx*.95,.475-by*.95,-.08);stage.add_child(background)
            var quad:=QuadMesh.new();quad.size=Vector2(1.9,1.9);var arrays:=quad.get_mesh_arrays();var uv: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
            for vertex in uv.size():uv[vertex]=Vector2((uv[vertex].x+column)/4.0,(uv[vertex].y+row)/2.0)
            arrays[Mesh.ARRAY_TEX_UV]=uv;var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
            var specimen:=MeshInstance3D.new();specimen.mesh=mesh;specimen.position=center;specimen.material_override=material;stage.add_child(specimen);specimens.append(specimen)
    for lighting: String in ["neutral","warm","cool","distance"]:
        camera.size=12.0 if lighting=="distance" else 6.4
        key.light_color=Color("ffb878") if lighting=="warm" else (Color("9abfff") if lighting=="cool" else Color("fff4df"))
        for i in specimens.size():specimens[i].rotation.y=PI if lighting=="cool" and i<4 else 0.0
        var full: Image=await frame()
        for specimen in specimens:specimen.visible=false
        var empty: Image=await frame()
        for i in specimens.size():
            var leaf_delta:=0.0;var leaf_samples:=0;var gutter_delta:=0.0;var gutter_samples:=0
            for gy in range(1,16):
                for gx in range(1,16):
                    var local_uv:=Vector2(gx/16.0,gy/16.0);var atlas_uv:=Vector2((local_uv.x+i%4)/4.0,(local_uv.y+i/4)/2.0)
                    var alpha:=source.get_pixel(int(atlas_uv.x*source.get_width()),int(atlas_uv.y*source.get_height())).a
                    var pixel:=camera.unproject_position(specimens[i].to_global(Vector3((local_uv.x-.5)*1.9,(.5-local_uv.y)*1.9,0)))
                    var a:=full.get_pixel(int(pixel.x),int(pixel.y));var b:=empty.get_pixel(int(pixel.x),int(pixel.y))
                    var delta:=absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)
                    if alpha>.97:leaf_delta+=delta;leaf_samples+=1
                    elif alpha<.01 and (gx<=2 or gx>=14 or gy<=2 or gy>=14):gutter_delta+=delta;gutter_samples+=1
            if not check(leaf_samples>15 and leaf_delta/leaf_samples>.04,"Actual visible leaf "+lighting+str(i)):return
            if not check(gutter_samples>60 and gutter_delta/gutter_samples<.025,"Actual transparent gutter "+lighting+str(i)):return
        for specimen in specimens:specimen.visible=true
        var image: Image=await frame();var filename: String="leaf_atlas_"+lighting+"_"+_quality+".png"
        if not check(image.save_png(_output.path_join(filename))==OK,"Save native capture"):return
        _captures.append({"file":filename,"lighting":lighting,"leaf_cells":8,"top_row_reverse_facing":lighting=="cool","camera_size":camera.size,"render_scale":root.scaling_3d_scale,"size":[image.get_width(),image.get_height()],"shipping_assignment":false,"material":material.resource_path})
    for path: String in saves:
        if not check(saves[path]==FileAccess.get_sha256(path),"Protected primary/backup unchanged"):return
    var shared:=true
    for specimen in specimens:shared=shared and specimen.material_override==material
    if not check(shared,"Eight specimens retain one shared cutout"):return
    var f:=FileAccess.open(_output.path_join("captures_"+_quality+".json"),FileAccess.WRITE)
    f.store_string(JSON.stringify({"status":"CAPTURED_FOR_REVIEW","quality":_quality,"scope":"unbound_leaf_alpha_specimens","renderer":RenderingServer.get_current_rendering_method(),"device":RenderingServer.get_video_adapter_name(),"assertions":_checks,"captures":_captures},"  "));f.close()
    canvas.queue_free();stage.queue_free();await process_frame
    print("LEAF_ATLAS_REVIEW PASS: ",_checks," assertions;4 actual native alpha specimens;unbound/no gameplay;protected saves")
    quit(0)

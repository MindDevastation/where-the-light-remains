extends SceneTree
## Metric strip fixtures only; no shipping carrier or gameplay autoload.
var _checks := 0
var _output := ""
var _quality := "low"
var _captures: Array[Dictionary] = []

func _initialize() -> void:
    _run.call_deferred()

func check(value: bool, text: String) -> bool:
    _checks+=1
    if not value:
        push_error("STONE_TRIM_REVIEW FAIL: "+text);quit(1)
    return value

func frame() -> Image:
    for i in 8:await process_frame
    await RenderingServer.frame_post_draw
    return root.get_texture().get_image()

func source_image(path: String) -> Image:
    var image:=Image.new()
    if not check(image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))==OK,"Actual source PNG decode"):return null
    return image

func actual_metric_uv(mesh: ArrayMesh) -> bool:
    var arrays:=mesh.surface_get_arrays(0)
    var positions: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
    var uv: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
    var pmin:=Vector2(INF,INF);var pmax:=Vector2(-INF,-INF)
    var umin:=Vector2(INF,INF);var umax:=Vector2(-INF,-INF)
    for i in positions.size():
        var p:=Vector2(positions[i].x,positions[i].y)
        pmin=pmin.min(p);pmax=pmax.max(p);umin=umin.min(uv[i]);umax=umax.max(uv[i])
    var physical:=pmax-pmin;var texels: Vector2=(umax-umin)*2048
    return physical.x>0 and physical.y>0 and absf(texels.x/physical.x-1024)<.005 and absf(texels.y/physical.y-1024)<.005

func caption(canvas: CanvasLayer, text: String, y: float) -> void:
    var item:=Label.new();item.text=text;item.position=Vector2(0,y);item.size=Vector2(960,35);item.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    item.add_theme_font_size_override("font_size",22);canvas.add_child(item)
    var glyphs:=true
    for character in text:glyphs=glyphs and item.get_theme_font("font").has_char(character.unicode_at(0))
    check(glyphs,"Cyrillic metric labels")

func _run() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--review-output="):_output=arg.trim_prefix("--review-output=")
        elif arg.begins_with("--quality="):_quality=arg.trim_prefix("--quality=")
    if not check(not _output.is_empty() and _quality in ["low","medium"],"Output/profile"):return
    if not check(DisplayServer.get_name()=="X11" and RenderingServer.get_current_rendering_method()=="forward_plus","Actual native X11/Forward+"):return
    if not check(not root.has_node("GameRoot") and not root.has_node("SettingsManager"),"No gameplay autoload"):return
    root.scaling_3d_scale=.75 if _quality=="low" else 1.0;root.msaa_3d=Viewport.MSAA_DISABLED
    var saves: Dictionary={}
    for name: String in ["savegame.json","savegame.backup.json"]:
        var path: String="user://"+name
        if not check(FileAccess.file_exists(path),"Protected fixture exists"):return
        saves[path]=FileAccess.get_sha256(path)
    var material:=load("res://art/materials/m_stone_ornament_trim.tres") as StandardMaterial3D
    if not check(material!=null and not material.resource_local_to_scene and load(material.resource_path)==material,"Shared editable master"):return
    if not check(material.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED and not material.emission_enabled and not material.refraction_enabled and is_zero_approx(material.metallic),"Opaque matte nonmetallic"):return
    if not check(material.normal_enabled and is_equal_approx(material.normal_scale,1.0) and material.roughness_texture_channel==BaseMaterial3D.TEXTURE_CHANNEL_GREEN and material.texture_filter==BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC,"+Y normal/ORM G/anisotropic mips"):return
    for texture: Texture2D in [material.albedo_texture,material.normal_texture,material.roughness_texture]:
        if not check(texture is CompressedTexture2D and texture.get_width()==2048 and texture.get_height()==2048 and texture.get_image().has_mipmaps(),"Actual2K compressed mip chain"):return
    var normal:=source_image("res://art/textures/trims/t_stone_ornament_trim_normal.png")
    var orm:=source_image("res://art/textures/trims/t_stone_ornament_trim_orm.png")
    # Fixture owns an identical region contract copied under res://tests by validator.
    var contract: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/stone_trim_regions.json"))
    var regions: Array=contract["regions"].duplicate(true)
    regions.append({"id":"first_fillet_60mm","uv_v":[.0475,.0775],"physical_width_m":.06})
    var valid:=true
    for region: Dictionary in regions:
        var v0: float=region["uv_v"][0];var v1: float=region["uv_v"][1]
        valid=valid and absf((v1-v0)*2048/float(region["physical_width_m"])-1024)<.001
        for y in range(int(v0*2048)+1,int(v1*2048),7):
            for x in range(0,2048,61):
                var n:=normal.get_pixel(x,y);var direction:=Vector3(n.r,n.g,n.b)*2-Vector3.ONE;var data:=orm.get_pixel(x,y)
                valid=valid and absf(direction.length()-1)<.015 and direction.z>.3 and data.r>.999 and data.g>.76 and data.g<.92 and is_zero_approx(data.b)
    if not check(valid,"Metric regions/unit normals/dielectric ranges"):return
    var stage:=Node3D.new();root.add_child(stage)
    var world:=WorldEnvironment.new();stage.add_child(world);var environment:=Environment.new();world.environment=environment
    environment.background_mode=Environment.BG_COLOR;environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.tonemap_mode=Environment.TONE_MAPPER_ACES
    var key:=DirectionalLight3D.new();stage.add_child(key)
    var core:=OmniLight3D.new();core.position=Vector3(0,2.35,0);core.omni_range=5.5;core.light_specular=.25;core.shadow_enabled=false;stage.add_child(core)
    var room:=OmniLight3D.new();room.position=Vector3(0,3.6,-22);room.omni_range=9;room.light_color=Color(.43,.65,1);room.light_energy=2.5;stage.add_child(room)
    var board:=Node3D.new();stage.add_child(board)
    var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=2.35;stage.add_child(camera);camera.current=true
    var canvas:=CanvasLayer.new();root.add_child(canvas)
    caption(canvas,"TRIM-002 · КАМЕННЫЕ ПРОФИЛИ · 1024 PX/М",18)
    caption(canvas,"A паз · B валик · C цоколь · D бордюр · E торец · A 60 мм",492)
    var panels: Array[MeshInstance3D]=[];var centres: Array[Vector3]=[]
    var height_sum:=.09*(regions.size()-1)
    for region: Dictionary in regions:height_sum+=float(region["physical_width_m"])
    var top:=height_sum*.5
    for region: Dictionary in regions:
        var width: float=region["physical_width_m"];var center:=Vector3(0,top-width*.5,0);centres.append(center);top-=width+.09
        for side in 2:
            var quad:=QuadMesh.new();quad.size=Vector2(2,width);var arrays:=quad.get_mesh_arrays();var uv: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
            for vertex in uv.size():uv[vertex].y=lerpf(float(region["uv_v"][0]),float(region["uv_v"][1]),uv[vertex].y)
            arrays[Mesh.ARRAY_TEX_UV]=uv;var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
            if not check(actual_metric_uv(mesh),"Actual imported vertex/UV metric spans "+str(region["id"])):return
            var panel:=MeshInstance3D.new();panel.mesh=mesh;panel.position=center+Vector3(-1 if side==0 else 1,0,0);panel.material_override=material;board.add_child(panel);panels.append(panel)
    for lighting: String in ["neutral","corridor_cold","hub_awake","mips"]:
        var scene_subset:=lighting in ["corridor_cold","hub_awake"]
        board.position=Vector3(0,2,-15) if lighting=="corridor_cold" else Vector3(0,1.8,-2.5)
        camera.position=board.position+Vector3(0,0,12);camera.size=5.0 if lighting=="mips" else 2.35
        environment.background_color=Color(.025,.04,.065) if scene_subset else Color("17212b")
        environment.ambient_light_color=Color(.5,.64,.8) if scene_subset else Color("c8c4be");environment.ambient_light_energy=.22 if scene_subset else .5
        key.rotation_degrees=Vector3(-65,-25,0) if scene_subset else Vector3(-28,-40,0)
        key.light_color=Color(.55,.7,.9) if scene_subset else Color("fff4df");key.light_energy=.38 if scene_subset else 1.25
        room.visible=lighting=="corridor_cold";core.visible=lighting=="hub_awake";core.light_color=Color(1,.68,.36);core.light_energy=1.8
        if not check(not scene_subset or (is_equal_approx(key.light_energy,.38) and is_equal_approx(environment.ambient_light_energy,.22)),"Exact current environment/moon subset"):return
        var full: Image=await frame()
        for panel in panels:panel.visible=false
        var empty: Image=await frame()
        for i in centres.size():
            var delta:=0.0;var samples:=0
            for gy in range(2,9):
                for gx in range(1,32):
                    var point:=centres[i]+Vector3(-2+gx/8.0,(gy/10.0-.5)*float(regions[i]["physical_width_m"]),0)
                    var pixel:=camera.unproject_position(board.to_global(point));var a:=full.get_pixel(int(pixel.x),int(pixel.y));var b:=empty.get_pixel(int(pixel.x),int(pixel.y))
                    delta+=absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b);samples+=1
            if not check(delta/samples>.03,"Actual region framebuffer "+lighting+str(i)):return
        for panel in panels:panel.visible=true
        if lighting=="neutral":
            material.normal_scale=0;var flat: Image=await frame();material.normal_scale=1
            var delta:=0.0;var samples:=0
            for i in centres.size():
                for gy in range(2,9):
                    for gx in range(1,32):
                        var point:=centres[i]+Vector3(-2+gx/8.0,(gy/10.0-.5)*float(regions[i]["physical_width_m"]),0)
                        var pixel:=camera.unproject_position(board.to_global(point));var a:=full.get_pixel(int(pixel.x),int(pixel.y));var b:=flat.get_pixel(int(pixel.x),int(pixel.y))
                        delta+=absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b);samples+=1
            if not check(delta/samples>.008,"Actual authored normal/profile contribution versus privately flattened reference"):return
        var image: Image=await frame();var filename: String="stone_trim_"+lighting+"_"+_quality+".png"
        if not check(image.save_png(_output.path_join(filename))==OK,"Save final capture"):return
        _captures.append({"file":filename,"lighting":lighting,"scope":"isolated_metric_trim_uv","regions":6,"physical_u_length_m":4,"u_repeats":2,"density_px_per_m":1024,"render_scale":root.scaling_3d_scale,"camera_size":camera.size,"scene_lighting_subset":scene_subset,"all_scene_lights_reproduced":false,"shipping_assignment":false,"normal_scale":material.normal_scale,"size":[image.get_width(),image.get_height()]})
    for path: String in saves:
        if not check(saves[path]==FileAccess.get_sha256(path),"Protected primary/backup unchanged"):return
    var shared:=true
    for panel in panels:shared=shared and panel.material_override==material
    if not check(shared and is_equal_approx(material.normal_scale,1.0),"Shared master restored after sensitivity measurement"):return
    var f:=FileAccess.open(_output.path_join("captures_"+_quality+".json"),FileAccess.WRITE)
    f.store_string(JSON.stringify({"status":"CAPTURED_FOR_REVIEW","quality":_quality,"renderer":RenderingServer.get_current_rendering_method(),"device":RenderingServer.get_video_adapter_name(),"assertions":_checks,"captures":_captures},"  "));f.close()
    canvas.queue_free();stage.queue_free();await process_frame
    print("STONE_TRIM_REVIEW PASS: ",_checks," assertions;4 metric/native specimens;unbound;protected saves")
    quit(0)

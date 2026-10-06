extends Node
var _checks := 0
var _failures: Array[String] = []

func check(value: bool,label: String) -> void:
    _checks+=1
    if not value:
        _failures.append(label)
        push_error("ARCHIVE_POLISHED_BRASS FAIL: "+label)

func _ready() -> void:
    _run.call_deferred()

func _run() -> void:
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var quality: String = SettingsManager.graphics_preset
    var effects: bool = SettingsManager.effects
    var material := load("res://art/materials/m_polished_brass.tres") as StandardMaterial3D
    var aged := load("res://art/materials/m_aged_brass.tres") as StandardMaterial3D
    check(material!=null and material!=aged and load(material.resource_path)==material and not material.resource_local_to_scene,"Distinct reusable shared master")
    check(material.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED and not material.emission_enabled and not material.refraction_enabled,"Opaque nonemissive conventional PBR")
    check(material.normal_enabled and is_equal_approx(material.normal_scale,.3) and material.texture_filter==BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC,"Subtle normal and anisotropic mipmaps")
    check(material.roughness_texture_channel==BaseMaterial3D.TEXTURE_CHANNEL_GREEN and material.metallic_texture_channel==BaseMaterial3D.TEXTURE_CHANNEL_BLUE and material.roughness_texture==material.metallic_texture,"Exact shared ORM channels")
    for texture: Texture2D in [material.albedo_texture,material.normal_texture,material.roughness_texture]:
        check(texture!=null and texture.get_width()==1024 and texture.get_height()==1024,"Actual1024 imported texture")
        check(texture is CompressedTexture2D and texture.get_image().has_mipmaps(),"Native compressed texture mip chain")
    var normal := Image.load_from_file("res://art/textures/material_library/t_polished_brass_normal.png")
    var orm := Image.load_from_file("res://art/textures/material_library/t_polished_brass_orm.png")
    var old_orm := Image.load_from_file("res://art/textures/material_library/t_aged_brass_orm.png")
    var valid := true
    var rough := 0.0
    var old_rough := 0.0
    var samples := 0
    for y in range(0,1024,31):
        for x in range(0,1024,31):
            var n := normal.get_pixel(x,y)
            var direction := Vector3(n.r,n.g,n.b)*2-Vector3.ONE
            var data := orm.get_pixel(x,y)
            valid=valid and absf(direction.length()-1)<.015 and direction.z>.97 and data.r>.999 and data.g>.19 and data.g<.29 and data.b>.97
            rough+=data.g;old_rough+=old_orm.get_pixel(x,y).g;samples+=1
    check(valid,"Original data maps preserve unit +Y normals/ORM ranges")
    check(rough/samples<old_rough/samples-.08,"Maintained polished response differs from aged brass")
    var world := preload("res://worlds/archive/archive_main.tscn").instantiate() as ArchiveMain
    add_child(world);world.set_process(false);world.get_node("Prologue").set_process(false)
    await get_tree().physics_frame
    var outer := world.get_node("Hub/Astrolabe/OuterRing") as MeshInstance3D
    var inner := world.get_node("Hub/Astrolabe/InnerRing") as MeshInstance3D
    var outer_mesh := outer.mesh
    var inner_mesh := inner.mesh
    var outer_pose := outer.transform
    var inner_pose := inner.transform
    check(outer.material_override==material and inner.material_override==material,"Only two existing toruses use shared polished master")
    check(outer.material_overlay==null and inner.material_overlay==null,"No inspect/emission overlay required for hero surface")
    var podium: MeshInstance3D = world.get_node("Hub/Mechanism").find_children("*","MeshInstance3D",true,false)[0]
    check(podium.mesh.surface_get_material(3)==aged,"Accepted lower housing retains aged brass")
    check((world.get_node("Hub/Finale/Table") as MeshInstance3D).material_override!=material,"Hidden later-stage placeholder not rematerialed")
    for preset: String in ["Low","Medium"]:
        SettingsManager.graphics_preset=preset;SettingsManager.effects=false;EventBus.settings_changed.emit()
        check(outer.material_override==material and inner.material_override==material,"Material preserved on quality/effects-off "+preset)
        var state:=ArchiveProgress.fresh();state["awakened"]=true;state["unlocked"][0]=true
        check(world.apply_stage_state(ArchiveProgress.WING_ONE,state)==OK,"Quiet awakened projection "+preset)
        check(outer.mesh==outer_mesh and inner.mesh==inner_mesh and outer.transform==outer_pose and inner.transform==inner_pose,"Geometry and child transforms preserved "+preset)
        check(outer.material_override==material and inner.material_override==material,"Quiet reload retains shared master "+preset)
    check(world.slice_bindings_valid(),"Existing route/target bindings remain valid")
    check(GameState.capture_save().to_dict()==before and SaveManager.get("_dirty")==dirty,"Logical DTO/dirty readonly")
    world.queue_free();await get_tree().process_frame
    SettingsManager.graphics_preset=quality;SettingsManager.effects=effects
    if _failures.is_empty():print("ARCHIVE_POLISHED_BRASS PASS: ",_checks," assertions; actual maps/import/material/quality/state/retained hero interfaces")
    get_tree().quit(0 if _failures.is_empty() else 1)

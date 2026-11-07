extends SceneTree
## Isolated native asset import review. No gameplay/autoload/save state is loaded.

var output := ""
var report := {}

func _initialize() -> void:
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--output="):
            output = argument.trim_prefix("--output=")
    assert(not output.is_empty(), "An owned output directory is required")
    call_deferred("review")

func review() -> void:
    var stage := Node3D.new()
    root.add_child(stage)
    var model = load("res://sm_s01_archive_core_hero_v1.glb").instantiate()
    stage.add_child(model)
    var meshes: Array[MeshInstance3D] = []
    for node in model.find_children("*", "MeshInstance3D", true, false):
        meshes.append(node)
    assert(meshes.size() == 7, "Expected seven separate mesh parts")
    assert(model.find_children("*", "Light3D", true, false).is_empty())
    assert(model.find_children("*", "AnimationPlayer", true, false).is_empty())
    assert(model.find_children("*", "CollisionObject3D", true, false).is_empty())
    var materials := {}
    var triangles := 0
    var surfaces := 0
    var boxes: Array[AABB] = []
    var parts := []
    for instance in meshes:
        assert(instance.scale.is_equal_approx(Vector3.ONE))
        boxes.append(instance.global_transform * instance.get_aabb())
        var part_triangles := 0
        for surface in range(instance.mesh.get_surface_count()):
            var arrays := instance.mesh.surface_get_arrays(surface)
            var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
            var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
            var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
            var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
            assert(vertices.size() > 0 and normals.size() == vertices.size())
            assert(uvs.size() == vertices.size())
            for vertex in vertices: assert(vertex.is_finite())
            for normal in normals: assert(normal.is_finite() and normal.length() > 0.99)
            var material = instance.mesh.surface_get_material(surface)
            assert(material is StandardMaterial3D)
            if material.normal_enabled:
                var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
                assert(tangents.size() == vertices.size() * 4)
                assert(material.get_texture(BaseMaterial3D.TEXTURE_NORMAL) != null)
                assert(material.get_texture(BaseMaterial3D.TEXTURE_ALBEDO) != null)
                assert(material.get_texture(BaseMaterial3D.TEXTURE_ROUGHNESS) != null)
                assert(material.ao_enabled, "ORM occlusion channel missing")
            materials[material.resource_name] = {
                "normal_enabled": material.normal_enabled,
                "ao_enabled": material.ao_enabled,
                "transparency": material.transparency,
                "emission_enabled": material.emission_enabled
            }
            part_triangles += indices.size() / 3 if not indices.is_empty() else vertices.size() / 3
            surfaces += 1
        triangles += part_triangles
        parts.append({"name": str(instance.name), "triangles": part_triangles})
    assert(triangles == 29780, str(triangles))
    assert(surfaces == 12, str(surfaces))
    assert(materials.size() == 6, str(materials))
    var pivot = model.find_child("CoreAssembly", true, false)
    assert(pivot != null and pivot.position.is_equal_approx(Vector3(0,1.02,0)))
    var bounds := boxes[0]
    for box in boxes: bounds = bounds.merge(box)
    assert(bounds.position.y >= -0.0001)
    report = {"status":"PASS", "godot":Engine.get_version_info(),
        "triangles":triangles,"mesh_count":meshes.size(),"surfaces":surfaces,
        "materials":materials,"parts":parts,
        "bounds_m":{"min":str(bounds.position),"size":str(bounds.size)},
        "pivot_m":[0,1.02,0],"asset_lights":0,"asset_colliders":0,"asset_animations":0,
        "scope":"Standalone asset on software Vulkan; not target GPU or gameplay acceptance"}

    var world := WorldEnvironment.new()
    var environment := Environment.new()
    var sky := Sky.new()
    var sky_material := ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color(0.12,0.19,0.3)
    sky_material.sky_horizon_color = Color(0.5,0.56,0.68)
    sky_material.ground_bottom_color = Color(0.07,0.05,0.03)
    sky.sky_material = sky_material
    environment.sky = sky
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.018,0.025,0.04)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
    environment.tonemap_mode = Environment.TONE_MAPPER_AGX
    environment.glow_enabled = true
    environment.glow_intensity = 0.45
    world.environment = environment
    stage.add_child(world)
    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-40,-35,0)
    key.light_color = Color(1.0,0.88,0.7)
    key.light_energy = 1.7
    key.shadow_enabled = true
    stage.add_child(key)
    var rim := DirectionalLight3D.new()
    rim.rotation_degrees = Vector3(-25,140,0)
    rim.light_color = Color(0.4,0.6,1.0)
    rim.light_energy = 0.8
    stage.add_child(rim)
    var ground := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(20,20)
    ground.mesh = plane
    var ground_material := StandardMaterial3D.new()
    ground_material.albedo_color = Color(0.025,0.035,0.05)
    ground_material.roughness = 0.7
    ground.material_override = ground_material
    stage.add_child(ground)
    var camera := Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 1.93
    camera.position = Vector3(-3.5,3.1,2.5)
    stage.add_child(camera)
    camera.look_at(Vector3(0,0.8,0))
    camera.current = true
    for frame in range(12): await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(output.path_join("godot_front.png"))
    camera.position = Vector3(3,2.1,-3.5)
    camera.look_at(Vector3(0,0.8,0))
    for frame in range(4): await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(output.path_join("godot_reverse.png"))
    report["draw_calls_fixture_frame"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
    report["texture_memory_fixture_bytes"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED)
    var receipt := FileAccess.open(output.path_join("godot_import.json"),FileAccess.WRITE)
    receipt.store_string(JSON.stringify(report,"  ")+"\n")
    print("ARCHIVE_CORE_GODOT_PASS ",triangles," triangles, ",surfaces," surfaces")
    quit(0)

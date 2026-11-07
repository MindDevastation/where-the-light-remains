extends SceneTree
## Exact recovered resources in an isolated native renderer capability fixture.
var checks := 0
var failures: Array[String] = []
var output := ""

func check(condition: bool, label: String) -> void:
    checks += 1
    if not condition:
        failures.append(label)
        push_error(label)

func _initialize() -> void:
    output = OS.get_environment("WLR_CORE_OUTPUT")
    assert(not output.is_empty())
    call_deferred("run")

func run() -> void:
    var scene: PackedScene = load("res://art/scenes/hero_props/archive_core_upper.tscn")
    var a = scene.instantiate()
    var b = scene.instantiate()
    root.add_child(a)
    root.add_child(b)
    a.position.y = 1.8
    var meshes := []
    var parts := []
    var triangles := 0
    var surfaces := 0
    var radius := 0.0
    var texture_ids := {}
    for node in a.find_children("*", "MeshInstance3D", true, false):
        if not node.is_visible_in_tree():
            continue
        meshes.append(node)
        var part_triangles := 0
        for surface in node.mesh.get_surface_count():
            var arrays: Array = node.mesh.surface_get_arrays(surface)
            var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
            var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
            part_triangles += indices.size() / 3 if not indices.is_empty() else vertices.size() / 3
            surfaces += 1
            var material = node.get_active_material(surface)
            check(material is StandardMaterial3D, "Native PBR material " + str(node.name))
            for slot in [BaseMaterial3D.TEXTURE_ALBEDO, BaseMaterial3D.TEXTURE_NORMAL, BaseMaterial3D.TEXTURE_ROUGHNESS]:
                var texture = material.get_texture(slot)
                if texture == null or texture_ids.has(texture.get_instance_id()):
                    continue
                var image: Image = texture.get_image()
                check(image != null and image.has_mipmaps(), "Embedded texture has native mip chain")
                texture_ids[texture.get_instance_id()] = true
            for vertex in vertices:
                radius = maxf(radius, (node.global_transform * vertex - a.global_position).length())
        triangles += part_triangles
        parts.append({"name": str(node.name), "triangles": part_triangles})
    check(meshes.size() == 6, "Exactly three rings, one mount and two core surfaces")
    check(triangles == 8888, "Measured visible triangle count")
    check(surfaces == 7, "Measured visible surface count")
    check(radius < 0.601, "Every actual vertex is inside the continuous-yaw enclosure")
    check(a.find_children("*", "Light3D", true, false).is_empty(), "No asset light owner")
    check(a.find_children("*", "CollisionObject3D", true, false).is_empty(), "No asset collision owner")
    check(a.find_children("*", "AnimationPlayer", true, false).is_empty(), "No asset animation clock")
    var ea: MeshInstance3D = a.get_node("VisualCore/ArchiveCentralMechanism/CoreAssembly/CoreEnergy")
    var eb: MeshInstance3D = b.get_node("VisualCore/ArchiveCentralMechanism/CoreAssembly/CoreEnergy")
    var original: StandardMaterial3D = ea.mesh.surface_get_material(0)
    var peak := original.emission_energy_multiplier
    var ma: StandardMaterial3D = ea.get_surface_override_material(0)
    var mb: StandardMaterial3D = eb.get_surface_override_material(0)
    check(peak > 0.0, "Original source has an emissive peak")
    check(ma != original and ma != mb, "Energy overrides belong to separate instances")
    check(is_zero_approx(ma.emission_energy_multiplier) and is_zero_approx(mb.emission_energy_multiplier), "Both instances start asleep")
    a.project_energy(0.5)
    check(is_equal_approx(ma.emission_energy_multiplier, peak * 0.5), "Existing caller amount projects without another clock")
    check(is_zero_approx(mb.emission_energy_multiplier), "Second instance remains asleep")
    a.project_energy(2.0)
    check(is_equal_approx(ma.emission_energy_multiplier, peak) and is_equal_approx(a.warmth, 1.0), "Warm upper clamp")
    a.project_energy(-1.0)
    check(is_zero_approx(ma.emission_energy_multiplier) and is_zero_approx(a.warmth), "Cold lower clamp")
    check(is_equal_approx(original.emission_energy_multiplier, peak), "Shared imported PBR source remains unchanged")
    root.remove_child(b)
    check(eb.get_surface_override_material(0) == null, "Exit restores the original override slot")
    root.add_child(b)
    check(is_zero_approx(eb.get_active_material(0).emission_energy_multiplier), "Re-entry starts asleep")
    var foreign := StandardMaterial3D.new()
    foreign.emission_energy_multiplier = 0.7
    ea.set_surface_override_material(0, foreign)
    a.project_energy(1.0)
    root.remove_child(a)
    check(ea.get_surface_override_material(0) == foreign and is_equal_approx(foreign.emission_energy_multiplier, 0.7), "Later material owner survives projection and exit")
    a.free()
    b.project_energy(1.0)
    var environment_node := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.03, 0.04, 0.06)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.6, 0.7, 0.9)
    environment.ambient_light_energy = 0.4
    environment_node.environment = environment
    root.add_child(environment_node)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-35, -30, 0)
    light.light_energy = 1.8
    root.add_child(light)
    var camera := Camera3D.new()
    camera.position = Vector3(-1.6, 1.4, 1.8)
    root.add_child(camera)
    camera.look_at(Vector3.ZERO)
    camera.current = true
    for frame in 8:
        await process_frame
    await RenderingServer.frame_post_draw
    check(root.get_texture().get_image().save_png(output.path_join("capability.png")) == OK, "Actual rendered capability image saved")
    var result := {"status": "PASS" if failures.is_empty() else "FAIL", "checks": checks, "failures": failures,
        "visible_triangles": triangles, "visible_meshes": meshes.size(), "surfaces": surfaces, "parts": parts,
        "all_yaw_enclosure_actual_vertex_radius_m": radius, "unique_mipped_textures": texture_ids.size(),
        "original_energy_peak": peak, "renderer": RenderingServer.get_current_rendering_method(),
        "scope": "Isolated exact original GLB references and projection lifecycle on software Vulkan. Capability image uses fixture lighting, not shipping scene or style acceptance."}
    var file := FileAccess.open(output.path_join("component.json"), FileAccess.WRITE)
    file.store_string(JSON.stringify(result, "  ") + "\n")
    file.close()
    print("CORE_HERO_COMPONENT ", result.status, " checks=", checks)
    quit(0 if failures.is_empty() else 1)

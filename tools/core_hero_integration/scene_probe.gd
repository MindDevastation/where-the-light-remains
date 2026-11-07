extends Node
## Matched source-scene poses. Actual E/clock/disk reload is a separate fixture.
var checks := 0
var failures: Array[String] = []
var output := ""
var variant := ""
var preset := ""

func check(condition: bool, label: String) -> void:
    checks += 1
    if not condition:
        failures.append(label)
        push_error(label)

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    output = OS.get_environment("WLR_CORE_OUTPUT")
    variant = OS.get_environment("WLR_CORE_VARIANT")
    preset = OS.get_environment("WLR_CORE_PRESET")
    assert(not output.is_empty() and variant in ["baseline", "staged"] and preset in ["Low", "Medium"])
    run.call_deferred()

func segment_gap(point: Vector3, start: Vector3, finish: Vector3) -> float:
    var delta := finish - start
    return point.distance_to(start + delta * clampf((point-start).dot(delta)/delta.length_squared(), 0.0, 1.0))

func run() -> void:
    SettingsManager.graphics_preset = preset
    SettingsManager.effects = preset != "Low"
    SettingsManager.apply_runtime(false)
    var game := preload("res://core/game_root/game_root.tscn").instantiate()
    add_child(game)
    var definition := StageDefinition.new()
    definition.stage_id = ArchiveProgress.INTRO
    definition.scene_path = "res://tests/fixtures/core_hero_baseline_20261107.tscn" if variant == "baseline" else "res://worlds/archive/archive_main.tscn"
    definition.presentation = StageDefinition.Presentation.IN_PLACE
    check(SceneRouter.register_stage(definition) == OK, "Register source scene")
    var saved := SaveGame.new()
    saved.stage_id = ArchiveProgress.INTRO
    saved.checkpoint_id = &"prologue_completed"
    saved.milestones = {"prologue_completed": true}
    ArchiveProgress.write_projection(saved)
    check(await SceneRouter.request_resume_stage(saved) == OK, "Quiet source scene entry")
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var world := game.get_node("WorldSlot").get_child(0) as ArchiveMain
    var player := game.get_node("PlayerContainer/Player") as FirstPersonPlayer
    var hub := world.get_node("Hub/Onboarding") as ArchiveOnboarding
    player.set_physics_process(false)
    var access := []
    var minimum_gap := INF
    for path in hub.target_paths:
        var component := hub.get_node(path) as InteractionTarget
        var area := component.get_parent() as Node3D
        var enabled := component.enabled
        component.enabled = true
        var heading := Vector3(area.global_position.x, 0, area.global_position.z).normalized()
        for angle in [-30, -15, 0, 15, 30]:
            var origin := area.global_position + heading.rotated(Vector3.UP, deg_to_rad(angle)) * 0.75
            origin.y = 0.004
            player.spawn_at(Transform3D(Basis.IDENTITY, origin))
            player.look_at(Vector3(area.global_position.x, origin.y, area.global_position.z))
            player.head.rotation.x = -atan2(player.camera.global_position.y-area.global_position.y, 0.75)
            await get_tree().physics_frame
            await get_tree().physics_frame
            check(player.call("_pick_target") == component, "Actual player ray: " + str(path) + " " + str(angle))
            var camera_from := player.camera.global_position
            var ray_end := camera_from - player.camera.global_basis.z * player.interaction_reach
            var query := PhysicsRayQueryParameters3D.create(camera_from, ray_end, player.interaction_mask)
            query.collide_with_areas = true
            query.hit_from_inside = true
            query.exclude = [player.get_rid()]
            var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
            check(not hit.is_empty() and hit.collider == area, "Actual collision query: " + str(path) + " " + str(angle))
            if not hit.is_empty():
                var gap := segment_gap(world.get_node("Hub/Astrolabe").global_position, camera_from, hit.position) - 0.601
                minimum_gap = minf(minimum_gap, gap)
                check(gap > 0.02, "Whole upper enclosure clears the control ray at every yaw")
                access.append({"target": str(path), "angle_degrees": angle, "enclosure_ray_clearance_m": gap})
        component.enabled = enabled
    check(access.size() == 20, "Twenty authored approach queries")
    var core = world.get_node_or_null("Hub/Astrolabe/CoreHeroUpper")
    check((core != null) == (variant == "staged"), "Correct original/staged scene variant")
    if core != null:
        check(is_zero_approx(core.warmth), "Scene starts asleep")
    var captures := []
    # Freeze scene processing for matched still poses; call only quiet projection.
    world.process_mode = Node.PROCESS_MODE_DISABLED
    for particle in world.find_children("*", "GPUParticles3D", true, false):
        particle.speed_scale = 0.0
        particle.emitting = false
    var views := [
        {"name": "front_asleep", "feet": Vector3(0,0.004,2.6), "target": Vector3(0,1.8,0), "awake": false},
        {"name": "front_awakened", "feet": Vector3(0,0.004,2.6), "target": Vector3(0,1.8,0), "awake": true},
        {"name": "control_oblique_awakened", "feet": Vector3(1.8,0.004,1.8), "target": Vector3(0,1.5,0), "awake": true}
    ]
    for view in views:
        var projection := ArchiveProgress.fresh()
        projection["awakened"] = view.awake
        projection["unlocked"][0] = view.awake
        check(world.apply_stage_state(ArchiveProgress.WING_ONE if view.awake else ArchiveProgress.INTRO, projection) == OK, "Quiet pose projection")
        player.spawn_at(Transform3D(Basis.IDENTITY, view.feet))
        player.look_at(Vector3(view.target.x, view.feet.y, view.target.z))
        var flat := Vector2(view.target.x-view.feet.x, view.target.z-view.feet.z).length()
        player.head.rotation.x = atan2(view.target.y-player.camera.global_position.y, flat)
        player.camera.make_current()
        for frame in 8:
            await get_tree().process_frame
        await RenderingServer.frame_post_draw
        var image := get_viewport().get_texture().get_image()
        var filename: String = variant + "_" + view.name + "_" + preset.to_lower() + ".png"
        check(image.save_png(output.path_join(filename)) == OK, "Original native frame saved")
        captures.append({"file": filename, "size": [image.get_width(), image.get_height()],
            "core_warmth": core.warmth if core != null else null,
            "core_light_energy": world.get_node("Hub/CoreLight").light_energy,
            "camera_transform": str(player.camera.global_transform), "quiet_pose": true})
    check(GameState.capture_save().to_dict() == before and SaveManager.get("_dirty") == dirty, "Still review preserves logical DTO and dirty state")
    var environment: Environment = world.get_node("Environment").environment
    var result := {"status": "PASS" if failures.is_empty() else "FAIL", "checks": checks, "failures": failures,
        "variant": variant, "preset": preset, "effects": SettingsManager.effects,
        "renderer": RenderingServer.get_current_rendering_method(), "device": RenderingServer.get_video_adapter_name(),
        "glow": environment.glow_enabled, "volumetrics": environment.volumetric_fog_enabled,
        "access": access, "minimum_continuous_yaw_ray_clearance_m": minimum_gap, "captures": captures,
        "scope": "Matched original/staged shipping camera and lighting, quiet API poses and actual player target queries. Software Vulkan, not performance or final art acceptance. Actual E/clock/pause/disk reload is separate."}
    var file := FileAccess.open(output.path_join(variant + "_" + preset.to_lower() + ".json"), FileAccess.WRITE)
    file.store_string(JSON.stringify(result, "  ") + "\n")
    file.close()
    game.queue_free()
    await get_tree().process_frame
    SceneRouter.unregister_stage(ArchiveProgress.INTRO)
    print("CORE_HERO_SCENE ", result.status, " ", variant, " ", preset, " checks=", checks)
    get_tree().quit(0 if failures.is_empty() else 1)

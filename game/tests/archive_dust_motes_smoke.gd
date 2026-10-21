extends Node
## Actual runtime decoration contracts; no primary save writes.

var _checks := 0
var _failures: Array[String] = []

func check(value: bool, label: String) -> void:
    _checks += 1
    if not value:
        _failures.append(label)
        push_error(label)

func _ready() -> void:
    _run.call_deferred()

func _run() -> void:
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var original_preset: String = SettingsManager.graphics_preset
    var original_effects: bool = SettingsManager.effects
    var world := preload("res://worlds/archive/archive_main.tscn").instantiate() as ArchiveMain
    add_child(world)
    world.get_node("Prologue").set_process(false)
    world.set_process(false)
    await get_tree().process_frame
    var clouds := [world.get_node("Hub/DustMotes"), world.get_node("Wing01/Room/DustMotes")]
    check(world.find_children("*", "GPUParticles3D", true, false).size() == 2, "Exactly two bounded particle volumes")
    check(clouds[0].position == Vector3(3, 2, 0) and clouds[1].position == Vector3(1.8, 2, -22), "Actual placements inside existing rooms")
    for cloud: ArchiveDustMotes in clouds:
        var p := cloud.particles
        check(p.local_coords and p.use_fixed_seed, "Local deterministic particle coordinates")
        check(p.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "No particle shadow")
        check(p.lifetime == 12.0 and p.fixed_fps == 30, "Bounded lifetime/simulation rate")
        check(p.draw_passes == 1 and p.draw_pass_1 is QuadMesh, "One native two-triangle billboard")
        check((p.draw_pass_1 as QuadMesh).size == Vector2(.025,.025), "Small secondary footprint")
        var motion := p.process_material as ParticleProcessMaterial
        check(motion.gravity == Vector3.ZERO and motion.initial_velocity_max <= .04, "Slow drift, no acceleration")
        var padding := Vector3.ONE * (p.lifetime * motion.initial_velocity_max + .025 * motion.scale_max)
        check(p.visibility_aabb.encloses(AABB(-motion.emission_box_extents-padding,2*(motion.emission_box_extents+padding))), "Visibility AABB contains all lifetime drift")
        check(not cloud.find_children("*", "CollisionObject3D",true,false).size() and not cloud.find_children("*", "Light3D",true,false).size(), "No collider/light/target")
    check(clouds[0].particles.process_material != clouds[1].particles.process_material, "Per-instance motion resource")
    SettingsManager.effects = true
    for quality: String in ["Low", "Medium", "High"]:
        SettingsManager.graphics_preset = quality
        EventBus.settings_changed.emit()
        check(world.apply_stage_state(ArchiveProgress.PROLOGUE,ArchiveProgress.fresh()) == OK, "Quiet S00 projection")
        await get_tree().process_frame
        for cloud: ArchiveDustMotes in clouds:
            check(not cloud.visible and not cloud.particles.emitting and cloud.particles.speed_scale == 0, "S00 decoration disabled")
        check(world.apply_stage_state(ArchiveProgress.INTRO,ArchiveProgress.fresh()) == OK, "Quiet S01 projection")
        await get_tree().process_frame
        for cloud: ArchiveDustMotes in clouds:
            check(cloud.visible and cloud.particles.emitting, "S01 active decoration")
            check(cloud.particles.amount == ArchiveDustMotes.COUNTS[quality], "Actual quality count")
        var state := ArchiveProgress.fresh()
        state["awakened"] = true
        state["unlocked"][0] = true
        check(world.apply_stage_state(ArchiveProgress.WING_ONE,state) == OK, "Quiet S02 projection")
        await get_tree().process_frame
        for cloud: ArchiveDustMotes in clouds:
            check(cloud.visible and cloud.particles.emitting, "S02 preserves decoration without progress events")
        InputManager.set_paused(true)
        for cloud: ArchiveDustMotes in clouds:
            check(cloud.particles.speed_scale == 0, "GPU simulation frozen on pause")
        SettingsManager.effects = false
        EventBus.settings_changed.emit()
        for cloud: ArchiveDustMotes in clouds:
            check(not cloud.visible and not cloud.particles.emitting, "Effects off while paused")
        InputManager.set_paused(false)
        for cloud: ArchiveDustMotes in clouds:
            check(cloud.particles.speed_scale == 0, "Unpause does not restart disabled effects")
        SettingsManager.effects = true
        EventBus.settings_changed.emit()
        for cloud: ArchiveDustMotes in clouds:
            check(cloud.visible and cloud.particles.emitting and cloud.particles.speed_scale == 1, "Effects resumes without a state writer")
    check(GameState.capture_save().to_dict() == before and SaveManager.get("_dirty") == dirty, "Logical save/dirty state unchanged")
    world.queue_free()
    await get_tree().process_frame
    EventBus.settings_changed.emit()
    InputManager.set_paused(true)
    InputManager.set_paused(false)
    check(not is_instance_valid(world), "Freed effect/world callbacks do not survive")
    SettingsManager.graphics_preset = original_preset
    SettingsManager.effects = original_effects
    print("ARCHIVE_DUST_MOTES PASS: %d assertions; actual resource/quality/pause/quiet projection and readonly save contracts" % _checks)
    get_tree().quit(0 if _failures.is_empty() else 1)

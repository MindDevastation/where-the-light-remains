extends Node
## Bounded real S00 timeline, collision path, pause and same-frame camera handoff.

var _failures: Array[String] = []
var _checks := 0
var _stages: Array[StringName] = []
var _checkpoints: Array[StringName] = []
var _sparks: Array[Error] = []


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().create_timer(25.0, true).timeout.connect(func() -> void:
        push_error("ARCHIVE_LAST_SPARK FAIL: timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()


func _check(condition: bool, message: String) -> void:
    _checks += 1
    if not condition:
        _failures.append(message)
        push_error("ARCHIVE_LAST_SPARK FAIL: " + message)


func _run() -> void:
    var original := GameState.capture_save()
    var dirty: bool = SaveManager.get("_dirty")
    var duration := SceneRouter.fade_duration
    var original_fov := SettingsManager.fov
    SettingsManager.fov = 95.0
    var game := preload("res://core/game_root/game_root.tscn").instantiate()
    add_child(game)
    var slot: Node3D = game.get_node("WorldSlot")
    var player: FirstPersonPlayer = game.get_node("PlayerContainer/Player")
    var fade: FadeOverlay = game.get_node("TransitionLayer/FadeOverlay")
    for id in [ArchiveProgress.PROLOGUE, ArchiveProgress.INTRO]:
        var definition := StageDefinition.new()
        definition.stage_id = id
        definition.scene_path = "res://worlds/archive/archive_main.tscn"
        definition.presentation = StageDefinition.Presentation.FADE if id == ArchiveProgress.PROLOGUE else StageDefinition.Presentation.IN_PLACE
        definition.player_active = id != ArchiveProgress.PROLOGUE
        definition.input_mode = InputManager.Mode.CINEMATIC if id == ArchiveProgress.PROLOGUE else InputManager.Mode.GAMEPLAY
        _check(SceneRouter.register_stage(definition) == OK, "Register S00 or shared S01 handoff")
    SceneRouter.fade_duration = .02
    EventBus.stage_changed.connect(func(id: StringName) -> void: _stages.append(id))
    EventBus.checkpoint_reached.connect(func(id: StringName) -> void: _checkpoints.append(id))
    var initial := SaveGame.new()
    _check(initial.stage_id == ArchiveProgress.PROLOGUE and ArchiveProgress.write_projection(initial) == OK, "Fresh S00 logical projection")
    var entered := await SceneRouter.request_resume_stage(initial)
    _check(entered == OK, "Materialize dormant Archive for S00")
    if entered != OK:
        get_tree().quit(1)
        return
    var world := slot.get_child(0) as ArchiveMain
    var world_id := world.get_instance_id()
    var prologue := world.get_node("Prologue") as ArchivePrologue
    prologue.spark_ignited.connect(func(error: Error) -> void: _sparks.append(error))
    _check(prologue.spark.mesh==null and prologue.spark_art.texture==preload("res://art/vfx/last_spark.svg") and is_equal_approx(prologue.spark_art.pixel_size,.0025) and prologue.spark_art.billboard==BaseMaterial3D.BILLBOARD_ENABLED and not prologue.spark_art.shaded, "Native original SVG/billboard, primitive removed")
    _check(prologue.spark_art.get_script()==null and prologue.spark_art.get_child_count()==0 and prologue.spark_art.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and prologue.spark.position.is_equal_approx(Vector3(0,3.3,9.65)), "Fixed original root; no separate process, light, collider, shadow or animation")
    var sampled_save := GameState.capture_save().to_dict()
    var sampled_dirty: bool = SaveManager.get("_dirty")
    var sampled_elapsed := prologue.elapsed
    var sampled_events := _sparks.size()
    var bounded := true
    for seconds in [0.0,1.0,1.7,3.8,6.0,8.0,20.0]:
        prologue._set_spark_pose(seconds)
        bounded=bounded and absf(prologue.spark_art.position.x)<=.01501 and absf(prologue.spark_art.position.y)<=.02001 and prologue.spark_art.position.z==0 and prologue.spark_art.scale.x>=.95999 and prologue.spark_art.scale.x<=1.00001 and prologue.spark_art.modulate.a>=.83999 and prologue.spark_art.modulate.a<=1.00001
    _check(bounded and prologue.elapsed==sampled_elapsed and _sparks.size()==sampled_events and GameState.capture_save().to_dict()==sampled_save and SaveManager.get("_dirty")==sampled_dirty, "Pure bounded cosmetic samples cannot advance time/events/save")
    prologue._set_spark_pose(sampled_elapsed)
    _check(not player.active and InputManager.mode == InputManager.Mode.CINEMATIC and not InputManager.can_move(), "S00 starts with disabled first-person gameplay")
    await get_tree().process_frame
    await get_tree().physics_frame
    _check(prologue.camera.is_current() and not prologue.spark.visible, "Actual exterior camera precedes first spark")
    _check(is_zero_approx(prologue.lock_bolt.position.x), "Fresh S00 has a fully engaged bolt")
    _check(_sparks.is_empty() and AudioDirector.playback_snapshot()["players"].all(func(p: Dictionary) -> bool: return not p["playing"]), "Unbound shipping prologue remains scoreless before the spark")
    _check(is_equal_approx(prologue.camera.fov, player.camera.fov) and is_equal_approx(player.camera.fov, 95.0), "Cinematic and player use the same configured FOV")
    for edge in [Vector3(3, .6, 15), Vector3(0, .6, 18)]:
        var guard_ray := PhysicsRayQueryParameters3D.create(Vector3(0, .6, 15), edge, 1)
        _check(not world.get_world_3d().direct_space_state.intersect_ray(guard_ray).is_empty(), "Exterior ground ends are physically guarded")
    var ray := PhysicsRayQueryParameters3D.create(Vector3(0, 1.6, 15), Vector3(0, 1.6, 4), 1)
    _check(not world.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(), "Closed main entrance initially blocks the camera path")
    while prologue.elapsed < 1.2:
        await get_tree().process_frame
    _check(prologue.spark.visible and world.get_node("Routes/Wing01/Gate").status == ArchiveGate.Status.DORMANT, "First spark appears without awakening the Archive")
    _check(_sparks == [ERR_UNCONFIGURED] and AudioDirector.current_state == ArchivePrologue.SPARK_MUSIC_STATE, "Unbound first spark emits exactly one silent semantic request")
    _check(is_zero_approx(prologue.lock_bolt.position.x), "The first spark precedes bolt release")
    while prologue.elapsed < 1.7:
        await get_tree().process_frame
    _check(prologue.lock_bolt.position.x < 0 and prologue.lock_bolt.position.x > -.24 and is_equal_approx(prologue.left_door.position.x, -.65), "Actual clock retracts the bolt while both leaves remain closed")
    var paused_at := prologue.elapsed
    var paused_camera := prologue.camera.global_transform
    var paused_mote := prologue.spark_art.transform
    var paused_color := prologue.spark_art.modulate
    var paused_bolt := prologue.lock_bolt.global_transform
    InputManager.set_paused(true)
    InputManager.set_mode(InputManager.Mode.UI)
    await get_tree().create_timer(.15, true).timeout
    _check(is_equal_approx(prologue.elapsed, paused_at) and prologue.camera.global_transform.is_equal_approx(paused_camera), "Cinematic simulation and camera remain frozen while paused")
    _check(prologue.lock_bolt.global_transform.is_equal_approx(paused_bolt), "Partial bolt release freezes with the cinematic")
    _check(prologue.spark_art.transform.is_equal_approx(paused_mote) and prologue.spark_art.modulate==paused_color, "Mote drift/breath/alpha freeze with original paused clock")
    InputManager.set_mode(InputManager.Mode.CINEMATIC)
    InputManager.set_paused(false)
    while prologue.elapsed < 2.0:
        await get_tree().process_frame
    _check(is_equal_approx(prologue.lock_bolt.position.x, -.24), "Bolt clears the keeper before the unchanged door opening interval")
    while prologue.elapsed < 3.8:
        await get_tree().process_frame
    await get_tree().physics_frame
    _check(world.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(), "Opened door and trimmed authored walls leave a real continuous entry path")
    _check(prologue.camera.global_position.z < 15 and prologue.camera.global_position.z > 4, "Realtime camera enters rather than changing world scenes")
    var loading_frame := false
    var before_camera := prologue.camera.global_transform
    while GameState.current_stage_id == ArchiveProgress.PROLOGUE:
        before_camera = prologue.camera.global_transform
        await get_tree().process_frame
        loading_frame = loading_frame or fade.busy or fade.visible
    _check(slot.get_child(0).get_instance_id() == world_id and world.stage_id == ArchiveProgress.INTRO, "S00 hands off to S01 in the same Archive instance")
    _check(_sparks == [ERR_UNCONFIGURED], "Pause/resume and subsequent cinematic frames never repeat the seed request")
    _check(not loading_frame and not fade.busy and not fade.visible, "No loading/fade/black frame during cinematic handoff")
    _check(player.active and player.camera.is_current() and InputManager.mode == InputManager.Mode.GAMEPLAY, "Persistent player camera and gameplay receive control")
    _check(player.camera.global_position.distance_to(before_camera.origin) < .03 and player.camera.global_basis.is_equal_approx(before_camera.basis), "Player camera matches terminal cinematic position and look")
    _check(player.global_position.distance_to(Vector3(0, .004, 4)) < .03, "Safe first-person feet at the main entrance end")
    _check(_stages == [ArchiveProgress.PROLOGUE, ArchiveProgress.INTRO] and _checkpoints == [&"prologue_completed"], "Exactly one S00 completion stage/checkpoint event")
    _check(GameState.capture_save().collected_fragments.is_empty() and not GameState.milestones.get("archive_awakened", false), "Prologue grants no fragments and leaves the starting lens chain intact")
    var checkpoint: SaveGame = SaveManager.read_save()["data"]
    _check(checkpoint != null and checkpoint.stage_id == ArchiveProgress.INTRO and checkpoint.checkpoint_id == &"prologue_completed" and not SaveManager.get("_dirty"), "Actual accepted S01 checkpoint persisted")
    _check(await world.complete_prologue() == ERR_UNAUTHORIZED and _checkpoints.size() == 1, "Completed prologue cannot replay acquisition or IO")
    _check(await SceneRouter.request_resume_stage(checkpoint) == OK, "Resume the actual S01 checkpoint through its IN_PLACE registry")
    world = slot.get_child(0) as ArchiveMain
    _check(not world.get_node("Prologue/Camera3D").is_current() and player.active and _checkpoints.size() == 1, "Quiet S01 load does not replay S00")
    var resumed_prologue := world.get_node("Prologue") as ArchivePrologue
    _check(is_equal_approx(resumed_prologue.lock_bolt.position.x, -.24), "Quiet S01 resume restores the released bolt")
    _check(resumed_prologue.spark_art.position==Vector3.ZERO and resumed_prologue.spark_art.scale==Vector3.ONE and resumed_prologue.spark_art.modulate==Color.WHITE, "Quiet physical S01 resume restores deterministic rest without reveal")
    resumed_prologue.spark_ignited.connect(func(error: Error) -> void: _sparks.append(error))
    await get_tree().process_frame
    _check(_sparks == [ERR_UNCONFIGURED] and AudioDirector.current_stage == ArchiveProgress.INTRO, "Restored completed prologue never requests a new seed")
    game.queue_free()
    await get_tree().process_frame
    for id in [ArchiveProgress.PROLOGUE, ArchiveProgress.INTRO]:
        SceneRouter.unregister_stage(id)
    SceneRouter.fade_duration = duration
    SettingsManager.fov = original_fov
    GameState.apply_save(original)
    SaveManager.set("_dirty", dirty)
    InputManager.set_mode(InputManager.Mode.UI)
    if _failures.is_empty():
        print("ARCHIVE_LAST_SPARK PASS: ", _checks, " assertions; native local mote, real timeline/pause, original single event and quiet physical S01 resume")
    get_tree().quit(0 if _failures.is_empty() else 1)

extends Node
## Actual approved kit reuse and player-capsule traversal; no full art acceptance.

var _checks := 0
var _failures: Array[String] = []


func _ready() -> void:
    get_tree().create_timer(20.0, true).timeout.connect(func() -> void:
        push_error("ARCHIVE_CORRIDOR_ART FAIL: timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()


func _check(condition: bool, message: String) -> void:
    _checks += 1
    if not condition:
        _failures.append(message)
        push_error("ARCHIVE_CORRIDOR_ART FAIL: " + message)


func _run() -> void:
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var world := preload("res://worlds/archive/archive_main.tscn").instantiate() as ArchiveMain
    add_child(world)
    var player := preload("res://core/player/player.tscn").instantiate() as FirstPersonPlayer
    world.add_child(player)
    player.set_physics_process(false)
    var saved := SaveGame.new()
    saved.stage_id = ArchiveProgress.WING_ONE
    saved.milestones = {"archive_awakened": true, "wing_01_unlocked": true}
    var prepared := world.prepare_state(saved)
    _check(prepared["error"] == OK, "Awakened actual world accepts existing projection")
    _check(world.apply_stage_state(saved.stage_id, prepared["state"]) == OK, "Quiet S02 restore still applies")
    var controller := world.get_node("StageController") as ArchiveStageController
    _check(controller.open_wing(0, false) == OK, "Wing I retains existing physical gate eligibility")
    await get_tree().physics_frame
    await get_tree().physics_frame
    var art := world.get_node("Wing01/Corridor/Presentation") as Node3D
    _check(art.get_child_count() == 7, "Only four wall bays, two seam piers and one room portal")
    for part: Node3D in art.get_children():
        _check(part.scale.is_equal_approx(Vector3.ONE), "Approved module dimensions remain unscaled")
        _check(part.position.y == 0.0 and part.position.x == roundf(part.position.x) and part.position.z == roundf(part.position.z), "Module stays on approved meter grid")
        _check(part.get_node("Art").get_child_count() > 0, "Actual imported art is loaded")
    for side in ["L", "R"]:
        var guard := world.get_node("Wing01/Corridor/CorridorWall" + side) as StaticBody3D
        _check(guard.collision_layer == 1 and not guard.get_node("Mesh").visible, "Original upper safety guard stays solid while graybox skin is hidden")
    var capsule := (player.get_node("CollisionShape3D") as CollisionShape3D).shape as CapsuleShape3D
    _check(capsule != null and is_equal_approx(capsule.radius, .35) and is_equal_approx(capsule.height, 1.8), "Uses actual shipping player capsule dimensions")
    var space := world.get_world_3d().direct_space_state
    for depth in [-8.5, -10.0, -12.0, -14.0, -15.0, -16.0]:
        var query := PhysicsShapeQueryParameters3D.new()
        query.shape = capsule
        query.transform = Transform3D(Basis.IDENTITY, Vector3(0, .92, depth))
        query.collision_mask = 1
        _check(space.intersect_shape(query, 1).is_empty(), "Player has centerline clearance through corridor/portal at " + str(depth))
    player.global_position = Vector3(0, .02, -8.5)
    var collision := player.move_and_collide(Vector3(0, 0, -7.5))
    _check(collision == null and is_equal_approx(player.global_position.z, -16.0), "Actual player traverses to room through unchanged route")
    collision = player.move_and_collide(Vector3(0, 0, 7.5))
    _check(collision == null and is_equal_approx(player.global_position.z, -8.5), "Actual player returns through portal without obstruction")
    player.global_position = Vector3(0, .02, -12)
    collision = player.move_and_collide(Vector3(3, 0, 0))
    _check(collision != null and player.global_position.x < 1.4, "Approved seam pier physically blocks lateral wall escape")
    _check(controller.bindings_valid(), "Five gate/channel bindings remain valid")
    _check(GameState.capture_save().to_dict() == before and SaveManager.get("_dirty") == dirty, "Presentation and test do not mutate global progression or dirty state")
    world.queue_free()
    await get_tree().process_frame
    if _failures.is_empty():
        print("ARCHIVE_CORRIDOR_ART PASS: %d assertions" % _checks)
        get_tree().quit(0)
    else:
        get_tree().quit(1)

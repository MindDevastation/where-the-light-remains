extends Node
## Actual room approaches and kit wall stopping with the shipping player capsule.

var _checks := 0
var _failures: Array[String] = []

func _ready() -> void:
    get_tree().create_timer(20.0, true).timeout.connect(func() -> void:
        push_error("ARCHIVE_ROOM_ART FAIL: timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()

func _check(condition: bool, message: String) -> void:
    _checks += 1
    if not condition:
        _failures.append(message)
        push_error("ARCHIVE_ROOM_ART FAIL: " + message)

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
    _check(prepared["error"] == OK, "Existing S02 projection prepares")
    _check(world.apply_stage_state(saved.stage_id, prepared["state"]) == OK, "Existing quiet S02 restoration applies")
    var controller := world.get_node("StageController") as ArchiveStageController
    _check(controller.open_wing(0, false) == OK, "Existing gate opens without persistence")
    await get_tree().physics_frame
    await get_tree().physics_frame
    var room := world.get_node("Wing01/Room") as Node3D
    var art := room.get_node("Presentation") as Node3D
    var modules_valid := art.get_child_count() == 19
    for part: Node3D in art.get_children():
        modules_valid = modules_valid and part.scale.is_equal_approx(Vector3.ONE) and part.position.y == 0.0
        modules_valid = modules_valid and part.position.x == roundf(part.position.x) and part.position.z == roundf(part.position.z)
        modules_valid = modules_valid and part.get_node("Art").get_child_count() > 0
    _check(modules_valid, "Approved shared module art loads unscaled on the meter grid")
    for name in ["RoomWallL", "RoomWallR", "RoomBack"]:
        var guard := room.get_node(name) as StaticBody3D
        _check(guard.collision_layer == 1 and not guard.get_node("Mesh").visible, "Higher original guard stays solid without old skin: " + name)
    var shape := (player.get_node("CollisionShape3D") as CollisionShape3D).shape
    var space := world.get_world_3d().direct_space_state
    var feet: Array[Vector3] = []
    for name in ["Star", "Hearth"]:
        feet.append((world.get_node("Spawns/" + name) as Node3D).global_position)
    for name in ["Outer", "Middle", "Inner", "Focus"]:
        var grip := room.get_node("Rings/Carrier/" + name + "/Grip") as Node3D
        feet.append(Vector3(grip.global_position.x, .004, grip.global_position.z + 1.5))
    for position: Vector3 in feet:
        var query := PhysicsShapeQueryParameters3D.new()
        query.shape = shape
        query.transform = Transform3D(Basis.IDENTITY, position + Vector3(0, .9, 0))
        query.collision_mask = 1
        _check(space.intersect_shape(query, 1).is_empty(), "Actual shipping capsule has checkpoint/grip approach clearance at " + str(position))
    player.global_position = Vector3(0, .02, -16)
    var hit := player.move_and_collide(Vector3(0, 0, -3))
    _check(hit == null and is_equal_approx(player.global_position.z, -19), "Room entrance still reaches the puzzle approach")
    for boundary in [
        {"feet": Vector3(-3.8, .02, -19), "motion": Vector3(-2, 0, 0)},
        {"feet": Vector3(3.8, .02, -19), "motion": Vector3(2, 0, 0)},
        {"feet": Vector3(0, .02, -25.5), "motion": Vector3(0, 0, -3)}
    ]:
        player.global_position = boundary["feet"]
        hit = player.move_and_collide(boundary["motion"])
        _check(hit != null and art.is_ancestor_of(hit.get_collider()), "Approved kit physically stops escape at side/back boundary")
    _check(world.slice_bindings_valid() and controller.bindings_valid(), "Puzzle and five route bindings remain valid")
    _check(GameState.capture_save().to_dict() == before and SaveManager.get("_dirty") == dirty, "Presentation does not change progression/dirty state")
    world.queue_free()
    await get_tree().process_frame
    if _failures.is_empty():
        print("ARCHIVE_ROOM_ART PASS: %d assertions" % _checks)
    get_tree().quit(0 if _failures.is_empty() else 1)

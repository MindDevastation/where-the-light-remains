extends Node
## Actual room approaches and kit wall stopping with the shipping player capsule.

var _checks := 0
var _failures: Array[String] = []

func _ready() -> void:
    get_tree().create_timer(35.0, true).timeout.connect(func() -> void:
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
    var modules_valid := art.get_child_count() == 21
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
    await _test_floor(world, player, space)
    _test_entrance_junctions(world, player, space)
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

func _test_entrance_junctions(world: ArchiveMain, player: FirstPersonPlayer, space: PhysicsDirectSpaceState3D) -> void:
    var room := world.get_node("Wing01/Room") as Node3D
    var art := room.get_node("Presentation") as Node3D
    for side in ["L", "R"]:
        var sign_x := -1.0 if side == "L" else 1.0
        var expected := Vector3(sign_x * 2, 0, -15)
        var pier := art.get_node("PierEntrance" + side) as Node3D
        var owners := 0
        for candidate: Node3D in world.find_children("*", "Node3D", true, false):
            if candidate.scene_file_path == "res://worlds/archive/modules/archive_pier_4m.tscn" and candidate.global_position.is_equal_approx(expected):
                owners += 1
        _check(owners == 1 and pier.global_position.is_equal_approx(expected), "Exactly one approved pier owns entrance junction " + side)
        var body := pier.get_node("Collision") as StaticBody3D
        var excluded: Array[RID] = []
        for other: StaticBody3D in world.find_children("*", "StaticBody3D", true, false):
            if other != body:
                excluded.append(other.get_rid())
        var ray := PhysicsRayQueryParameters3D.create(Vector3(sign_x * 1.5, 2, -15), Vector3(sign_x * 2.2, 2, -15), 1, excluded)
        var hit := space.intersect_ray(ray)
        _check(not hit.is_empty() and hit["collider"] == body, "New entrance pier has its own solid blocker " + side)
        var guard := room.get_node("RoomFront" + side) as StaticBody3D
        var shape := guard.get_node("CollisionShape3D").shape as BoxShape3D
        var skin := guard.get_node("Mesh") as MeshInstance3D
        _check(guard.collision_layer == 1 and guard.global_position.is_equal_approx(Vector3(sign_x * 3.5, 2.75, -14.85)) and shape.size.is_equal_approx(Vector3(3, 5.5, .3)) and skin.visible and is_equal_approx(skin.global_position.z, -15), "Original higher front guard stays intact; temporary skin aligns with the portal " + side)
    for x in [-.75, 0.0, .75]:
        for direction in [-1.0, 1.0]:
            var start := Vector3(x, .02, -13.5 if direction < 0 else -17.5)
            var motion := Vector3(0, 0, direction * 4)
            player.global_position = start
            var hit := player.move_and_collide(motion)
            _check(hit == null and player.global_position.is_equal_approx(start + motion), "Shipping capsule crosses the entrance in lane " + str(x) + ", direction " + str(direction))

func _test_floor(world: ArchiveMain, player: FirstPersonPlayer, space: PhysicsDirectSpaceState3D) -> void:
    var tiles := world.get_node("Wing01/Room/TileFloor") as Node3D
    var slab := world.get_node("Wing01/Room/RoomFloor") as StaticBody3D
    var shared_shape: Shape3D = tiles.get_child(0).get_node("Collision/Solid").shape
    var valid_tiles := tiles.get_child_count() == 120
    for tile: Node3D in tiles.get_children():
        valid_tiles = valid_tiles and tile.scale.is_equal_approx(Vector3.ONE) and tile.position.y == 0.0
        valid_tiles = valid_tiles and is_equal_approx(fposmod(tile.position.x, 1.0), .5) and is_equal_approx(fposmod(tile.position.z, 1.0), .5)
        valid_tiles = valid_tiles and tile.get_node("Art").get_child_count() > 0 and tile.get_node("Collision/Solid").shape == shared_shape
    _check(valid_tiles, "Loaded room tiles share the approved collision resource on the cell-center phase")
    _check(slab.collision_layer == 1 and not slab.get_node("Mesh").visible, "Original room slab stays solid without a coplanar skin")
    var excluded: Array[RID] = []
    for body in world.find_children("*", "StaticBody3D", true, false):
        if not tiles.is_ancestor_of(body):
            excluded.append(body.get_rid())
    var supported_seams := true
    for x in [-4.0, -2.0, 0.0, 2.0, 4.0]:
        for z in range(-26, -15):
            var ray := PhysicsRayQueryParameters3D.create(Vector3(x, .2, z), Vector3(x, -.2, z), 1, excluded)
            var hit := space.intersect_ray(ray)
            supported_seams = supported_seams and not hit.is_empty()
            if not hit.is_empty():
                supported_seams = supported_seams and tiles.is_ancestor_of(hit["collider"]) and hit["normal"].is_equal_approx(Vector3.UP) and is_zero_approx(hit["position"].y)
    _check(supported_seams, "Tile colliders alone provide flush support at sampled row/column intersections across the room")
    slab.collision_layer = 0
    await get_tree().physics_frame
    player.global_position = Vector3(3, .15, -16.5)
    var landing := player.move_and_collide(Vector3(0, -.3, 0))
    _check(landing != null and landing.get_normal().is_equal_approx(Vector3.UP) and tiles.is_ancestor_of(landing.get_collider()), "Actual player lands on approved tiles with old room slab disabled")
    for direction in [-1.0, 1.0]:
        var start_z := player.global_position.z
        var grounded := true
        for step in range(180):
            await get_tree().physics_frame
            player.velocity = Vector3(0, -1, direction * 3)
            player.move_and_slide()
            grounded = grounded and player.is_on_floor() and absf(player.global_position.y) < .01
        _check(grounded and absf(player.global_position.z - start_z - direction * 9) < .08, "Grounded actual player crosses room row seams without the fallback, direction " + str(direction))
    player.global_position = Vector3(3, .002, -17.5)
    for direction in [-1.0, 1.0]:
        var start_x := player.global_position.x
        var grounded := true
        for step in range(120):
            await get_tree().physics_frame
            player.velocity = Vector3(direction * 3, -1, 0)
            player.move_and_slide()
            grounded = grounded and player.is_on_floor() and absf(player.global_position.y) < .01
        _check(grounded and absf(player.global_position.x - start_x - direction * 6) < .08, "Grounded actual player crosses room column seams without snagging, direction " + str(direction))
    slab.collision_layer = 1
    await get_tree().physics_frame

extends Node
## CLI-only real controller/physics/GUI fixture; no story world or puzzle solver.

var _failures: Array[String] = []
var _game: Node
var _player: FirstPersonPlayer
var _world: Node3D
var _hud: InteractionHUD
var _interactions := 0


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().create_timer(90.0).timeout.connect(func() -> void:
        push_error("PLAYER_INTERACTION FAIL: timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()


func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
        push_error("PLAYER_INTERACTION FAIL: " + message)


func _ticks(count: int = 3) -> void:
    for i in count:
        await get_tree().physics_frame
    await get_tree().process_frame


func _key(code: Key, pressed: bool, echo: bool = false) -> void:
    var event := InputEventKey.new()
    event.physical_keycode = code
    event.keycode = code
    event.pressed = pressed
    event.echo = echo
    Input.parse_input_event(event)
    Input.flush_buffered_events()


func _motion(delta: Vector2) -> void:
    var event := InputEventMouseMotion.new()
    event.relative = delta * 3.0 # Deliberately scaled: look must use screen pixels.
    event.screen_relative = delta
    Input.parse_input_event(event)
    Input.flush_buffered_events()


func _spawn(position: Vector3, yaw: float = 0.0) -> void:
    _player.spawn_at(Transform3D(Basis(Vector3.UP, yaw), position))


func _run() -> void:
    print("PLAYER_INTERACTION runtime: ", Engine.get_version_info()["string"], "; display=", DisplayServer.get_name())
    var scene: PackedScene = load("res://core/game_root/game_root.tscn")
    _game = scene.instantiate()
    add_child(_game)
    _player = _game.get_node("PlayerContainer/Player")
    _hud = _game.get_node("UILayer/InteractionHUD")
    _check(not _player.active and not _player.is_physics_processing(), "Empty GameRoot activated player")
    _check(not _player.camera.is_current() and not _hud.visible, "Inactive player has camera/HUD")
    _check(InputManager.mode == InputManager.Mode.UI, "Player took over input mode")
    _world = (load("res://tests/fixtures/archive_kit_sample.tscn") as PackedScene).instantiate()
    _game.get_node("WorldSlot").add_child(_world)
    InputManager.set_mode(InputManager.Mode.GAMEPLAY)
    get_window().focus_entered.emit() # Synthetic keyboard/controller tests, not OS input.
    _player.set_active(true)
    await _ticks()
    await _archive_walk()
    _world.free()
    _world = Node3D.new()
    _game.get_node("WorldSlot").add_child(_world)
    _solid(Vector3(0, -.1, 0), Vector3(16, .2, 16))
    await _movement_and_look()
    await _interaction()
    await _review()
    _player.set_active(false)
    InputManager.set_paused(false)
    InputManager.set_mode(InputManager.Mode.UI)
    if _failures.is_empty():
        print("PLAYER_INTERACTION PASS: actual player traversal, walk/look gates, physics picks/occlusion/races, Russian HUD")
    get_tree().quit(0 if _failures.is_empty() else 1)


func _archive_walk() -> void:
    for yaw in [0.0, PI/2]:
        _world.rotation.y = yaw
        for lane in [-.75, 0.0, .75]:
            _spawn(_world.global_transform * Vector3(lane, .004, 1.5), yaw)
            await _ticks()
            _key(KEY_W, true)
            var min_y := 1.0
            var max_y := -1.0
            for i in 71:
                await get_tree().physics_frame
                min_y = minf(min_y, _player.global_position.y)
                max_y = maxf(max_y, _player.global_position.y)
            _key(KEY_W, false)
            await _ticks(1)
            var local := _world.to_local(_player.global_position)
            _check(local.z < -1.45 and absf(local.x - lane) < .02, "Actual player stopped in Archive lane: " + str(local))
            _check(absf(min_y) < .02 and absf(max_y) < .02 and _player.is_on_floor(), "Player floor discontinuity")
            print("PLAYER_ARCHIVE_WALK: yaw=", yaw, "; lane=", lane, "; feet=", local, "; height=", min_y, "..", max_y)
        _spawn(_world.global_transform * Vector3(-4, .004, 1.5), yaw)
        await _ticks()
        _key(KEY_W, true)
        await _ticks(65)
        _key(KEY_W, false)
        var local := _world.to_local(_player.global_position)
        _check(local.z >= .54 and local.z <= .59, "World wall did not stop production capsule: " + str(local))
    print("PLAYER_ARCHIVE PASS: six actual controller traversals at two yaws; world wall stopping")


func _movement_and_look() -> void:
    _spawn(Vector3(0, .004, 0))
    await _ticks()
    _key(KEY_W, true)
    await _ticks(12)
    var cardinal_speed := Vector2(_player.velocity.x, _player.velocity.z).length()
    _key(KEY_D, true)
    await _ticks(12)
    _check(is_equal_approx(cardinal_speed, _player.walk_speed), "Unexpected cardinal speed")
    _check(is_equal_approx(Vector2(_player.velocity.x, _player.velocity.z).length(), cardinal_speed), "Diagonal speed boost")
    _key(KEY_W, false)
    _key(KEY_D, false)
    _spawn(Vector3(0, .004, 0), PI/2)
    await _ticks()
    _key(KEY_W, true)
    await _ticks(12)
    _check(_player.global_position.x < -.4 and absf(_player.global_position.z) < .02, "Walking ignored heading")
    InputManager.set_paused(true)
    var paused_position := _player.global_position
    _check(absf(_player.velocity.x) < .001, "Pause did not clear planar velocity synchronously")
    await get_tree().create_timer(.1).timeout
    _check(_player.global_position == paused_position, "Player advanced while paused")
    InputManager.set_paused(false)
    _key(KEY_W, true, true)
    await _ticks()
    _check(_player.global_position.distance_to(paused_position) < .01, "Echo resumed walking after pause")
    _key(KEY_W, false)
    _key(KEY_W, true)
    get_window().focus_exited.emit()
    var unfocused := _player.global_position
    await _ticks()
    _check(_player.global_position.distance_to(unfocused) < .01, "Unfocused player kept walking")
    get_window().focus_entered.emit()
    _key(KEY_W, false)
    _spawn(Vector3(0, .004, 0))
    InputManager.set_mode(InputManager.Mode.UI)
    InputManager.set_mode(InputManager.Mode.GAMEPLAY)
    _motion(Vector2(999, 999))
    _check(_player.rotation.is_zero_approx() and _player.head.rotation.is_zero_approx(), "Recapture warped view")
    _motion(Vector2(100, 50))
    _check(absf(_player.rotation.y + .2) < .001 and absf(_player.head.rotation.x + .1) < .001, "Look sensitivity or unscaled pixel mapping")
    SettingsManager.invert_y = true
    _motion(Vector2(0, 50))
    _check(absf(_player.head.rotation.x) < .001, "Invert-Y failed")
    _motion(Vector2(0, 100000))
    _check(absf(_player.head.rotation.x - deg_to_rad(85)) < .001, "Pitch clamp failed")
    SettingsManager.invert_y = false
    SettingsManager.fov = 91.0
    EventBus.settings_changed.emit()
    _check(is_equal_approx(_player.camera.fov, 91), "FOV setting not applied")
    SettingsManager.fov = 75.0
    EventBus.settings_changed.emit()
    InputManager.set_mode(InputManager.Mode.LIMITED_LOOK)
    _motion(Vector2.ZERO)
    _motion(Vector2(20, 0))
    _check(absf(_player.rotation.y + .24) < .001, "LIMITED_LOOK did not permit look")
    _key(KEY_W, true)
    var limited_position := _player.global_position
    await _ticks()
    _check(_player.global_position.distance_to(limited_position) < .01, "LIMITED_LOOK allowed walking")
    _key(KEY_W, false)
    InputManager.set_mode(InputManager.Mode.UI)
    var yaw := _player.rotation.y
    _motion(Vector2(40, 40))
    _check(_player.rotation.y == yaw, "UI motion reached player look")
    InputManager.set_mode(InputManager.Mode.GAMEPLAY)
    print("PLAYER_MOVE_LOOK PASS: normalized speed, heading, pause/focus/held key, unscaled sensitivity, pitch, invert-Y, FOV and LIMITED_LOOK")


func _solid(position: Vector3, size: Vector3) -> StaticBody3D:
    var body := StaticBody3D.new()
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = size
    shape.shape = box
    body.add_child(shape)
    body.position = position
    _world.add_child(body)
    return body


func _area(position: Vector3) -> Area3D:
    var area := Area3D.new()
    area.collision_layer = 2
    area.collision_mask = 0
    area.monitoring = false
    var shape := CollisionShape3D.new()
    var sphere := SphereShape3D.new()
    sphere.radius = .16
    shape.shape = sphere
    area.add_child(shape)
    var target := InteractionTarget.new()
    target.name = "InteractionTarget"
    target.interacted.connect(func(actor: Node3D) -> void:
        _check(actor == _player, "Interaction actor mismatch")
        _interactions += 1
    )
    area.add_child(target)
    _world.add_child(area)
    area.position = position
    return area


func _press_interact() -> void:
    _key(KEY_E, true)
    _key(KEY_E, false)
    await _ticks()


func _interaction() -> void:
    _spawn(Vector3(0, .004, 0))
    var area := _area(Vector3(0, 1.62, -1.8))
    var target: InteractionTarget = area.get_node("InteractionTarget")
    await _ticks()
    _check(_player.focused_target == target and _hud.get_node("Prompt").text == "E · Взаимодействовать", "Ray/HUD did not acquire explicit component")
    await _press_interact()
    _check(_interactions == 1, "E did not dispatch once")
    _key(KEY_E, true, true)
    await _ticks()
    _key(KEY_E, false)
    _check(_interactions == 1, "Keyboard echo repeated interaction")
    var wall := _solid(Vector3(0, 1.62, -1), Vector3(1, 2, .15))
    await _ticks()
    _check(_player.focused_target == null, "Picked through a world wall")
    await _press_interact()
    _check(_interactions == 1, "Interaction dispatched through occluder")
    wall.free()
    area.position.z = -3.0
    await _ticks()
    _check(_player.focused_target == null, "Ray exceeded maximum reach")
    area.position.z = -1.8
    await _ticks()
    _key(KEY_E, true)
    target.enabled = false
    _key(KEY_E, false)
    await _ticks()
    _check(_interactions == 1 and _player.focused_target == null, "Stale target availability race")
    target.enabled = true
    await _ticks()
    _key(KEY_E, true)
    InputManager.set_paused(true)
    InputManager.set_paused(false)
    _key(KEY_E, false)
    await _ticks()
    _check(_interactions == 1, "Pending E crossed pause boundary")
    _key(KEY_E, true)
    area.free()
    _key(KEY_E, false)
    await _ticks()
    _check(_interactions == 1 and _player.focused_target == null, "Deleted target was used")
    area = _area(Vector3(0, 1.62, -1.8))
    await _ticks()
    _key(KEY_E, true)
    area.position.z = -4.0
    _key(KEY_E, false)
    await _ticks()
    _check(_interactions == 1, "Moved target was used from old ray cache")
    area.position.z = -1.8
    await _ticks()
    var inside := _solid(_player.camera.global_position, Vector3(.1, .1, .1))
    # Keep this ray probe off the walk layer: capsule recovery must not move
    # the camera outside it before hit_from_inside can actually be tested.
    inside.collision_layer = 2
    inside.collision_mask = 0
    await _ticks()
    _check(_player.focused_target == null, "Ray starting inside solid bypassed occlusion")
    inside.free()
    await _ticks()
    _check(_player.focused_target != null, "Pick did not recover after occluder removal")
    var nearer := _area(Vector3(0, 1.62, -1.0))
    nearer.get_node("InteractionTarget").enabled = false
    await _ticks()
    _check(_player.focused_target == null, "Disabled nearer area was bypassed to a far target")
    nearer.free()
    await _ticks()
    _key(KEY_E, true)
    area.queue_free()
    _key(KEY_E, false)
    await _ticks()
    _check(_interactions == 1 and _player.focused_target == null, "Queued collider was used")
    var font: Font = _hud.get_node("Prompt").get_theme_font("font")
    for character in "Взаимодействовать":
        _check(font.has_char(character.unicode_at(0)), "Russian prompt glyph missing")
    print("PLAYER_INTERACTION_RAY PASS: range, nearest solid, single E/echo, disable/delete/move/pause races, inside-solid occlusion")


func _review() -> void:
    if DisplayServer.get_name() == "headless":
        return
    var assembly: Node3D = (load("res://gameplay/puzzles/wing01/wing01_optics_sample.tscn") as PackedScene).instantiate()
    _world.add_child(assembly)
    var grip: Area3D = assembly.get_node("Middle/Grip")
    var target := InteractionTarget.new()
    target.name = "InteractionTarget"
    target.interacted.connect(func(actor: Node3D) -> void:
        _check(actor == _player, "Wing I grip actor mismatch")
        _interactions += 1
    )
    grip.add_child(target)
    _spawn(Vector3(0, .004, -2.4), PI)
    _player.camera.look_at(grip.global_position, Vector3.UP)
    var floor_mesh := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(16, 16)
    floor_mesh.mesh = plane
    floor_mesh.material_override = load("res://art/materials/m_observatory_stone.tres")
    _world.add_child(floor_mesh)
    var light := DirectionalLight3D.new()
    # Reuse accepted Wing I review lighting, including sky specular for brass.
    light.rotation_degrees = Vector3(-50, 150, 0)
    light.light_color = Color("ffddb0")
    light.light_energy = 1.3
    light.shadow_enabled = true
    _world.add_child(light)
    var fill := DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-35, -20, 0)
    fill.light_color = Color("719be4")
    fill.light_energy = .75
    _world.add_child(fill)
    var environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("0d172e")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.ambient_light_energy = .4
    env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
    env.tonemap_mode = Environment.TONE_MAPPER_ACES
    var sky := Sky.new()
    var sky_material := ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color("172d60")
    sky_material.sky_horizon_color = Color("837666")
    sky_material.ground_bottom_color = Color("171e2d")
    sky_material.ground_horizon_color = Color("665b4c")
    sky.sky_material = sky_material
    env.sky = sky
    environment.environment = env
    _world.add_child(environment)
    await _ticks(6)
    _check(_player.focused_target == target, "Actual Wing I grip adapter was not picked")
    await _press_interact()
    _check(_interactions == 2, "E did not dispatch through the actual Wing I grip component")
    await RenderingServer.frame_post_draw
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--screenshot="):
            var path := argument.trim_prefix("--screenshot=")
            var image := get_viewport().get_texture().get_image()
            _check(image.get_size() == Vector2i(1920, 1080), "Review resolution mismatch")
            _check(image.save_png(path) == OK, "Review screenshot failed")
            print("PLAYER_INTERACTION screenshot: ", path)

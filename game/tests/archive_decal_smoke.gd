extends Node
## New static decal data and actual imported carrier; no save/gameplay action.

var _checks := 0
var _failures := 0


func _ready() -> void:
    get_tree().create_timer(35.0, true).timeout.connect(func() -> void:
        push_error("ARCHIVE_DECAL_SMOKE timeout")
        get_tree().quit(1))
    _run.call_deferred()


func _check(value: bool, message: String) -> void:
    _checks += 1
    if not value:
        _failures += 1
        push_error("ARCHIVE_DECAL_SMOKE FAIL: " + message)


func _run() -> void:
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
        "res://art/textures/archive_decals_v1/archive_decal_manifest.json"))
    for record: Dictionary in manifest["textures"]:
        var texture := load("res://art/textures/archive_decals_v1/" + record["file"]) as Texture2D
        var image := texture.get_image()
        _check(image != null and image.get_size() == Vector2i(record["size"][0], record["size"][1]), "native imported dimensions")
        _check(image.has_mipmaps(), "distance sampling has generated mipmaps")
        image.clear_mipmaps()
        image.convert(Image.FORMAT_RGBA8)
        var digest := HashingContext.new()
        digest.start(HashingContext.HASH_SHA256)
        digest.update(image.get_data())
        _check(digest.finish().hex_encode() == record["decoded_rgba_sha256"], "native lossless RGBA equals authored pixels")
        if record["kind"] != "atlas":
            var decal := load("res://art/decals/archive_" + record["kind"] + ".tscn").instantiate() as Decal
            _check(decal.get_script() == null and decal.get_child_count() == 0 and decal.texture_albedo == texture,
                "script-free variant binds correct exact crop")
            _check(decal.texture_normal == null and decal.texture_orm == null and decal.texture_emission == null,
                "surface normal, ORM and emission are not replaced")
            _check(decal.cull_mask == 1 and decal.distance_fade_enabled and decal.distance_fade_begin == 8.0 and
                decal.distance_fade_length == 4.0, "bounded receiver layer and distance budget")
            decal.free()
    var world := preload("res://worlds/archive/archive_main.tscn").instantiate() as ArchiveMain
    add_child(world)
    var state := ArchiveProgress.fresh()
    state["awakened"] = true
    state["unlocked"][0] = true
    _check(world.apply_stage_state(ArchiveProgress.WING_ONE, state) == OK, "quiet existing S02 projection")
    var bowl := world.get_node("Wing01/Room/Hearth/Bowl") as Node3D
    var decals := bowl.find_children("*", "Decal", true, false)
    _check(decals.size() == 2 and world.find_children("*", "Decal", true, false).size() == 2,
        "shipping scene has exactly two bounded first-carrier projections")
    var meshes := bowl.find_children("*", "MeshInstance3D", true, false)
    _check(meshes.size() == 1 and bowl.get_script() == null and
        bowl.find_children("*", "CollisionObject3D", true, false).is_empty(), "original visual has no extra mesh, script or collider")
    var mesh := meshes[0] as MeshInstance3D
    var original_mesh := mesh.mesh
    var original_materials: Array[Material] = []
    for surface in mesh.mesh.get_surface_count(): original_materials.append(mesh.get_active_material(surface))
    var ray_body := StaticBody3D.new()
    ray_body.collision_layer = 8
    ray_body.collision_mask = 0
    var shape := CollisionShape3D.new()
    shape.shape = mesh.mesh.create_trimesh_shape()
    ray_body.add_child(shape)
    world.add_child(ray_body)
    ray_body.global_transform = mesh.global_transform
    await get_tree().physics_frame
    for decal: Decal in decals:
        var top := decal.global_position + Vector3.UP * decal.size.y / 2
        var bottom := decal.global_position - Vector3.UP * decal.size.y / 2
        var query := PhysicsRayQueryParameters3D.create(top, bottom, 8)
        var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
        _check(not hit.is_empty() and hit["collider"] == ray_body, "actual imported surface intersects projection centre: " + decal.name)
        _check(bottom.y > .05 and decal.size.y <= .0751, "shallow projection excludes room floor: " + decal.name)
        _check(decal.is_visible_in_tree() and decal.get_script() == null and decal.process_mode == Node.PROCESS_MODE_INHERIT,
            "static detail has no custom processing or state owner")
        if not hit.is_empty(): print("ARCHIVE_DECAL_SURFACE ", decal.name, ": ", hit["position"])
    ray_body.queue_free()
    SettingsManager.effects = false
    SettingsManager.graphics_preset = "Low"
    SettingsManager.apply_runtime(false)
    _check(decals.all(func(node: Node) -> bool: return node.is_visible_in_tree()), "static material detail remains at Low/effects-off")
    state["star_collected"] = true
    state["hearth_collected"] = true
    state["completed"][0] = true
    state["light_restored"] = true
    state["unlocked"][1] = true
    _check(world.apply_stage_state(ArchiveProgress.WING_ONE, state) == OK and
        decals.all(func(node: Node) -> bool: return node.is_visible_in_tree()), "warm quiet restoration does not replay or replace decals")
    _check(mesh.mesh == original_mesh, "imported carrier mesh identity preserved")
    for surface in original_materials.size():
        _check(mesh.get_active_material(surface) == original_materials[surface], "original shared surface material preserved")
    _check(world.slice_bindings_valid() and GameState.capture_save().to_dict() == before and SaveManager.get("_dirty") == dirty,
        "puzzle bindings, DTO and dirty flag preserved")
    world.queue_free()
    await get_tree().process_frame
    print("ARCHIVE_DECAL_SMOKE %s: %d assertions" % ["PASS" if _failures == 0 else "FAIL", _checks])
    get_tree().quit(0 if _failures == 0 else 1)

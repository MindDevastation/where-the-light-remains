extends Node
## Bounded changed-resource checks; does not replay the unrelated gate suite.

const CHANNEL := preload("res://worlds/archive/common/archive_light_channel.tscn")
var _failures := 0
var _checks := 0

func _check(value: bool, message: String) -> void:
    _checks += 1
    if not value:
        _failures += 1
        push_error("ARCHIVE_CHANNEL_TRIM FAIL: " + message)


func _point_key(point: Vector3) -> String:
    return "%d,%d,%d" % [roundi(point.x * 1000000), roundi(point.y * 1000000), roundi(point.z * 1000000)]


func _geometry(mesh: ArrayMesh, expected: int, rails: bool) -> void:
    _check(mesh.get_surface_count() == 1, "one shared surface")
    var arrays := mesh.surface_get_arrays(0)
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
    var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
    var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
    _check(vertices.size() == expected * 3 and normals.size() == vertices.size() and
        uv.size() == vertices.size() and tangents.size() == vertices.size() * 4, "complete native triangle attributes")
    var edges := {}
    var valid := true
    var maximum_tangent_dot := 0.0
    for index in range(0, vertices.size(), 3):
        var a := vertices[index]
        var b := vertices[index + 1]
        var c := vertices[index + 2]
        var center := (a + b + c) / 3.0
        var origin := Vector3(0.075 if center.x > 0.0 else -0.075, 0, 0) if rails else Vector3.ZERO
        valid = valid and (b - a).cross(c - a).length() > 0.0000001 and Plane(a, b, c).normal.dot(center - origin) > 0.000001
        valid = valid and absf((uv[index + 1] - uv[index]).cross(uv[index + 2] - uv[index])) > 0.0000001
        for corner in 3:
            var vertex := index + corner
            var tangent := Vector3(tangents[vertex * 4], tangents[vertex * 4 + 1], tangents[vertex * 4 + 2])
            valid = valid and vertices[vertex].is_finite() and normals[vertex].is_finite() and uv[vertex].is_finite() and tangent.is_finite()
            maximum_tangent_dot = maxf(maximum_tangent_dot, absf(tangent.dot(normals[vertex])))
            # ArrayMesh stores octahedrally packed 16-bit attributes. Bound the
            # decoded error to 0.0144 degrees rather than assuming exact floats.
            valid = valid and is_equal_approx(normals[vertex].length(), 1.0) and is_equal_approx(tangent.length(), 1.0) and maximum_tangent_dot < 0.00025
            valid = valid and is_finite(tangents[vertex * 4 + 3]) and is_equal_approx(absf(tangents[vertex * 4 + 3]), 1.0)
            var first := _point_key(vertices[vertex])
            var second := _point_key(vertices[index + (corner + 1) % 3])
            var edge := first + ":" + second if first < second else second + ":" + first
            edges[edge] = int(edges.get(edge, 0)) + 1
    _check(valid, "finite outward nondegenerate triangles, UVs, unit normals and orthogonal tangents")
    print("CHANNEL_PACKED_ATTRIBUTES rails=", rails, "; maximum_decoded_tangent_dot=", maximum_tangent_dot, "; bound=0.00025")
    _check(edges.values().all(func(count: int) -> bool: return count == 2), "every welded edge has exactly two incident triangles")
    var bounds := mesh.get_aabb()
    _check(bounds.position.is_equal_approx(Vector3(-0.09, -0.014, -2.35) if rails else Vector3(-0.06, -0.015, -2.35)) and
        bounds.size.is_equal_approx(Vector3(0.18, 0.028, 4.7) if rails else Vector3(0.12, 0.03, 4.7)), "authored bounds")


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _run.call_deferred()


func _run() -> void:
    var saved := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var channel := CHANNEL.instantiate() as ArchiveLightChannel
    channel.process_mode = Node.PROCESS_MODE_PAUSABLE
    add_child(channel)
    var visual := channel.get_node("Mesh") as MeshInstance3D
    var rails := visual.get_node("Rails") as MeshInstance3D
    _geometry(visual.mesh as ArrayMesh, 60, false)
    _geometry(rails.mesh as ArrayMesh, 120, true)
    _check(rails.get_parent() == visual and rails.transform == Transform3D.IDENTITY and rails.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
        "rails inherit the owned visual without new shadow passes")
    _check(rails.material_override.resource_path == "res://art/materials/m_dark_iron.tres", "existing shared textured iron")
    _check(visual.position == Vector3(0, 0.02, 0) and is_equal_approx(channel.pulse_duration, 0.7), "unchanged visual translation and pulse duration")
    var active := channel.active_material as StandardMaterial3D
    var completed := channel.completed_material as StandardMaterial3D
    _check(active.albedo_color.is_equal_approx(Color(0.13, 0.70, 0.94, 1)) and active.emission.is_equal_approx(active.albedo_color) and
        completed.albedo_color.is_equal_approx(Color(1, 0.62, 0.16, 1)) and completed.emission.is_equal_approx(completed.albedo_color) and
        is_equal_approx(active.emission_energy_multiplier, 2.5) and is_equal_approx(completed.emission_energy_multiplier, 2.5), "unchanged state colors and emission")
    _check(not channel.visible and not channel.pulse_running and channel.pulse() == ERR_UNAVAILABLE, "quiet dormant state rejects pulse")
    var events := [0]
    channel.pulse_finished.connect(func() -> void: events[0] += 1)
    _check(channel.apply_state(ArchiveLightChannel.Status.ACTIVE, true) == OK and channel.visible and visual.material_override == active, "active core and inherited rails")
    var marker := channel.get_node("RoutePulse") as MeshInstance3D
    _check(marker.position.is_equal_approx(Vector3(0, 0.125, 2.35)), "baseline forward endpoint")
    await get_tree().process_frame
    get_tree().paused = true
    var paused_position := marker.position
    await get_tree().create_timer(0.12, true).timeout
    _check(marker.position.is_equal_approx(paused_position) and events[0] == 0, "pulse freezes during tree pause")
    get_tree().paused = false
    _check(channel.apply_state(ArchiveLightChannel.Status.COMPLETED) == OK and not channel.pulse_running and visual.material_override == completed, "quiet completion cancels old pulse and switches core")
    await get_tree().process_frame
    _check(channel.get_node_or_null("RoutePulse") == null and events[0] == 0, "cancel has no stale marker or completion")
    visual.position = Vector3(0.3, 0.08, -0.2)
    visual.rotation.y = 0.4
    visual.scale = Vector3(1.2, 0.8, 1.38)
    _check(channel.pulse(true) == OK, "reverse pulse with transformed visual")
    marker = channel.get_node("RoutePulse") as MeshInstance3D
    _check(marker.position.is_equal_approx(visual.transform * Vector3(0, 0.105, -2.35)) and rails.global_transform.is_equal_approx(visual.global_transform), "baseline transformed reverse endpoint and rail inheritance")
    await get_tree().create_timer(0.8).timeout
    _check(events[0] == 1 and not channel.pulse_running, "one completion after resume and reverse pulse")
    _check(channel.pulse() == OK, "pulse before ownership loss")
    marker = channel.get_node("RoutePulse") as MeshInstance3D
    marker.reparent(self)
    await get_tree().process_frame
    await get_tree().process_frame
    _check(not channel.pulse_running and is_instance_valid(marker) and events[0] == 1,
        "existing process guard preserves foreign marker and cancels pulse at the frame boundary")
    var foreign_position := marker.position
    await get_tree().process_frame
    await get_tree().process_frame
    _check(marker.position.is_equal_approx(foreign_position), "cancelled tween has no later foreign marker writes")
    marker.queue_free()
    _check(channel.apply_state(ArchiveLightChannel.Status.DORMANT) == OK and not channel.visible and not channel.is_processing(), "dormant hides both skins without processing")
    channel.queue_free()
    await get_tree().process_frame
    _check(GameState.capture_save().to_dict() == saved and SaveManager.get("_dirty") == dirty, "component checks preserve DTO and dirty flag")
    print("ARCHIVE_CHANNEL_TRIM_SMOKE ", "PASS" if _failures == 0 else "FAIL", ": ", _checks, " bounded resource/state checks; 180 triangles")
    get_tree().quit(0 if _failures == 0 else 1)

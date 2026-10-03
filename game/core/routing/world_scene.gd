class_name WorldScene
extends Node3D
## Quiet world root: controllers validate/apply only their own approved namespace.

@export var stage_id: StringName = &""
@export var default_spawn: NodePath
@export var checkpoint_spawns: Dictionary = {}


func prepare_state(saved: SaveGame) -> Dictionary:
    var failure := {"error": ERR_INVALID_DATA, "state": {}, "spawn": Transform3D.IDENTITY}
    if saved == null:
        return failure
    var validated := saved.copy_validated()
    if validated == null or validated.stage_id != stage_id:
        return failure
    var default_marker := _spawn_marker(default_spawn)
    if default_marker == null or not valid_spawn_transform(_marker_transform(default_marker)):
        return failure
    # Validate every declared checkpoint, not only the requested one.
    var seen := {}
    for checkpoint in checkpoint_spawns:
        if not SaveGame.identifier(checkpoint) or seen.has(String(checkpoint)) or typeof(checkpoint_spawns[checkpoint]) != TYPE_NODE_PATH:
            return failure
        seen[String(checkpoint)] = true
        var checkpoint_marker := _spawn_marker(checkpoint_spawns[checkpoint])
        if checkpoint_marker == null or not valid_spawn_transform(_marker_transform(checkpoint_marker)):
            return failure
    var path := default_spawn
    if not validated.checkpoint_id.is_empty():
        if not checkpoint_spawns.has(validated.checkpoint_id):
            return failure
        path = checkpoint_spawns[validated.checkpoint_id]
    var marker := _spawn_marker(path)
    if marker == null:
        return failure
    var spawn := _marker_transform(marker)
    if not valid_spawn_transform(spawn):
        return failure
    var state: Dictionary = validated.world_states.get(stage_id, {})
    var error := validate_logical_state(state.duplicate(true))
    if error != OK:
        failure["error"] = error
        return failure
    return {"error": OK, "state": state.duplicate(true), "spawn": spawn}


func _marker_transform(marker: Marker3D) -> Transform3D:
    var spawn := marker.transform
    var ancestor := marker.get_parent()
    while ancestor != self:
        if not ancestor is Node3D:
            return Transform3D(Basis.IDENTITY, Vector3(NAN, NAN, NAN))
        spawn = ancestor.transform * spawn
        ancestor = ancestor.get_parent()
    # Relative to WorldSlot, works before the candidate enters SceneTree.
    return transform * spawn


func validate_logical_state(state: Dictionary) -> Error:
    # A world without a controller cannot silently accept unknown puzzle states.
    return OK if state.is_empty() else ERR_UNAVAILABLE


func apply_logical_state(state: Dictionary) -> Error:
    return validate_logical_state(state)


func _spawn_marker(path: NodePath) -> Marker3D:
    if path.is_empty() or path.is_absolute() or path.get_subname_count() != 0:
        return null
    var marker := get_node_or_null(path) as Marker3D
    if marker == null or not is_ancestor_of(marker):
        return null
    var ancestor := marker.get_parent()
    while ancestor != self:
        if not ancestor is Node3D:
            return null
        ancestor = ancestor.get_parent()
    return marker


static func valid_spawn_transform(spawn: Transform3D) -> bool:
    for value in [spawn.origin.x, spawn.origin.y, spawn.origin.z,
            spawn.basis.x.x, spawn.basis.x.y, spawn.basis.x.z,
            spawn.basis.y.x, spawn.basis.y.y, spawn.basis.y.z,
            spawn.basis.z.x, spawn.basis.z.y, spawn.basis.z.z]:
        if not is_finite(value):
            return false
    # Upright unit-scale capsule; yaw is allowed, pitch/roll/mirroring/shear are not.
    return spawn.basis.y.is_equal_approx(Vector3.UP) and spawn.basis.is_equal_approx(spawn.basis.orthonormalized()) and is_equal_approx(spawn.basis.determinant(), 1.0)

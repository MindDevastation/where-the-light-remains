class_name ArchiveStageController
extends Node
## Local binding of durable progression to accepted T019 presentation components.

@export var gates: Array[NodePath] = []
@export var channels: Array[NodePath] = []
@export var finale_path: NodePath
var _state: Dictionary = ArchiveProgress.fresh()


func _local(path: NodePath) -> Node:
    if path.is_empty() or path.is_absolute() or path.get_subname_count() != 0:
        return null
    var node := get_node_or_null(path)
    var world := get_parent()
    if node == null or node.is_queued_for_deletion() or world == null or not world.is_ancestor_of(node):
        return null
    return node


func bindings_valid() -> bool:
    if not is_inside_tree() or is_queued_for_deletion() or gates.size() != 5 or channels.size() != 5:
        return false
    var ids: Array[int] = []
    for paths in [gates, channels]:
        for path in paths:
            var node := _local(path)
            if node == null or node.get_instance_id() in ids:
                return false
            if paths == gates and not node is ArchiveGate or paths == channels and not node is ArchiveLightChannel:
                return false
            if not node.bindings_valid():
                return false
            ids.append(node.get_instance_id())
    return _local(finale_path) is Node3D


func apply_state(state: Dictionary, animated: bool = false) -> Error:
    if not ArchiveProgress.valid(state):
        return ERR_INVALID_DATA
    if not bindings_valid():
        return ERR_UNCONFIGURED
    var previous := _state.duplicate(true)
    _state = state.duplicate(true)
    for index in 5:
        var gate := _local(gates[index]) as ArchiveGate
        var channel := _local(channels[index]) as ArchiveLightChannel
        var completed: bool = state["completed"][index]
        var unlocked: bool = state["unlocked"][index]
        var status := ArchiveGate.Status.COMPLETED if completed else ArchiveGate.Status.UNLOCKED if unlocked else ArchiveGate.Status.DORMANT
        # Keep an already opened eligible passage open during live milestones.
        if animated and unlocked and gate.status == ArchiveGate.Status.OPEN and not completed:
            status = ArchiveGate.Status.OPEN
        gate.apply_state(status, animated)
        var light := ArchiveLightChannel.Status.COMPLETED if completed else ArchiveLightChannel.Status.ACTIVE if unlocked else ArchiveLightChannel.Status.DORMANT
        channel.apply_state(light, animated and not completed)
        if animated and completed and not previous["completed"][index]:
            channel.pulse(true)
    var finale := _local(finale_path) as Node3D
    finale.visible = state["finale_ready"]
    return OK


func open_wing(index: int, animated: bool = true) -> Error:
    if index < 0 or index >= 5:
        return ERR_INVALID_PARAMETER
    if not bindings_valid():
        return ERR_UNCONFIGURED
    if not _state["unlocked"][index]:
        return ERR_UNAUTHORIZED
    var gate := _local(gates[index]) as ArchiveGate
    return gate.apply_state(ArchiveGate.Status.COMPLETED if _state["completed"][index] else ArchiveGate.Status.OPEN, animated)


func capture_presentation() -> Dictionary:
    return _state.duplicate(true)

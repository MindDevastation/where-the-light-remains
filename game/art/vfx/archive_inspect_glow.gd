class_name ArchiveInspectGlow
extends Node
## Surface feedback only; the existing player's actual ray owns selection.

@export var player_path := NodePath("../../../PlayerContainer/Player")
@export var target_paths: Array[NodePath] = []
@export var visual_paths: Array[NodePath] = []
@export var wash_material: Material
var _player: FirstPersonPlayer
var _target: InteractionTarget
var _visuals: Array[int] = []
var _originals: Array[Material] = []


func _ready() -> void:
    _player = get_node_or_null(player_path) as FirstPersonPlayer
    if _player != null:
        _player.focus_changed.connect(_on_focus_changed)


func bindings_valid() -> bool:
    if target_paths.is_empty() or target_paths.size() != visual_paths.size() or wash_material == null:
        return false
    for index in target_paths.size():
        if not get_node_or_null(target_paths[index]) is InteractionTarget or _meshes(get_node_or_null(visual_paths[index])).is_empty():
            return false
    return true


func _meshes(root: Node) -> Array[MeshInstance3D]:
    var meshes: Array[MeshInstance3D] = []
    if not is_instance_valid(root):
        return meshes
    if root is MeshInstance3D:
        meshes.append(root)
    for child in root.find_children("*", "MeshInstance3D", true, false):
        meshes.append(child as MeshInstance3D)
    return meshes


func _on_focus_changed(target: InteractionTarget) -> void:
    _clear()
    if not is_instance_valid(_player) or not _player.active or not InputManager.can_interact() or \
            not is_instance_valid(target) or _player.focused_target != target or not target.is_available_to(_player):
        return
    for index in mini(target_paths.size(), visual_paths.size()):
        if get_node_or_null(target_paths[index]) != target:
            continue
        _target = target
        for visual: MeshInstance3D in _meshes(get_node_or_null(visual_paths[index])):
            # An already authored overlay belongs to another presentation owner.
            if visual.material_overlay != null:
                continue
            _visuals.append(visual.get_instance_id())
            _originals.append(visual.material_overlay)
            visual.material_overlay = wash_material
        return


func _process(_delta: float) -> void:
    if _target != null and (not is_instance_valid(_target) or not is_instance_valid(_player) or \
            not InputManager.can_interact() or _player.focused_target != _target or not _target.is_available_to(_player)):
        _clear()


func active_visual_count() -> int:
    var count := 0
    for identity: int in _visuals:
        var visual := instance_from_id(identity) as MeshInstance3D if is_instance_id_valid(identity) else null
        if visual != null and visual.material_overlay == wash_material:
            count += 1
    return count


func _clear() -> void:
    for index in _visuals.size():
        var identity := _visuals[index]
        var visual := instance_from_id(identity) as MeshInstance3D if is_instance_id_valid(identity) else null
        if visual != null and visual.material_overlay == wash_material:
            visual.material_overlay = _originals[index]
    _visuals.clear()
    _originals.clear()
    _target = null


func _exit_tree() -> void:
    _clear()

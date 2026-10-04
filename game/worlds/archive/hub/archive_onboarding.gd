class_name ArchiveOnboarding
extends Node3D
## Local quest-item chain; the world commits durable milestones after awakening.

signal phase_changed(phase: Phase)
signal activation_requested
enum Phase {CLOSED, PANEL_OPEN, LENS_HELD, LENS_INSTALLED, AWAKENING, AWAKENED}
enum Step {PANEL, TAKE_LENS, INSTALL_LENS, ACTIVATE}

@export var target_paths: Array[NodePath] = []
@export var loose_lens_path: NodePath
@export var installed_lens_path: NodePath
var _phase: Phase = Phase.CLOSED

var phase: Phase:
    get: return _phase


func advance(step: Step) -> Error:
    if int(step) not in range(4):
        return ERR_INVALID_PARAMETER
    if int(_phase) != int(step):
        return ERR_UNAUTHORIZED
    _phase = (int(_phase) + 1) as Phase
    _refresh()
    phase_changed.emit(_phase)
    if _phase == Phase.AWAKENING:
        activation_requested.emit()
    return OK


func restore_awakened(awakened: bool) -> void:
    _phase = Phase.AWAKENED if awakened else Phase.CLOSED
    _refresh()


func retry_activation() -> void:
    _phase = Phase.LENS_INSTALLED
    _refresh()


func _refresh() -> void:
    for index in target_paths.size():
        var target := get_node_or_null(target_paths[index]) as InteractionTarget
        if target != null:
            target.enabled = index == int(_phase)
    var loose := get_node_or_null(loose_lens_path) as Node3D
    var installed := get_node_or_null(installed_lens_path) as Node3D
    if loose != null:
        loose.visible = _phase in [Phase.CLOSED, Phase.PANEL_OPEN]
    if installed != null:
        installed.visible = _phase >= Phase.LENS_INSTALLED

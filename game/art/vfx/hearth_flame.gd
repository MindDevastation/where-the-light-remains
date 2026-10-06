extends Node3D
## Local Hearth presentation only. Visibility remains owned by ArchiveMain.

var _phase := 0.0
var _lobes: Array[MeshInstance3D] = []
var _rest: Array[Transform3D] = []

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_PAUSABLE
    for child: MeshInstance3D in get_children():
        _lobes.append(child)
        _rest.append(child.transform)
    visibility_changed.connect(_sync_visibility)
    _sync_visibility()

func _sync_visibility() -> void:
    # Every projection starts from a reproducible quiet pose. No burst, signal,
    # audio request, light or save mutation is owned by this effect.
    _phase = 0.0
    for index in _lobes.size():
        _lobes[index].transform = _rest[index]
    set_process(is_visible_in_tree())

func _process(delta: float) -> void:
    if not is_visible_in_tree():
        return
    _phase = fmod(_phase + delta, TAU * 10.0)
    for index in _lobes.size():
        var pose := _rest[index]
        var sway := sin(_phase * .8 + index * 1.7) * .018
        pose.basis = pose.basis.scaled_local(Vector3(1.0, 1.0 + sway, 1.0))
        pose.origin.x += sway * .35
        _lobes[index].transform = pose

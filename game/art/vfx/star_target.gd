extends Sprite3D
## Quiet canonical sigil presentation; ArchiveMain owns fragment visibility.

var _phase := 0.0
var _rest_scale := Vector3.ONE
var _rest_modulate := Color.WHITE

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_PAUSABLE
    _rest_scale = scale
    _rest_modulate = modulate
    visibility_changed.connect(_sync_visibility)
    _sync_visibility()

func _sync_visibility() -> void:
    _phase = 0.0
    scale = _rest_scale
    modulate = _rest_modulate
    set_process(is_visible_in_tree())

func _process(delta: float) -> void:
    if not is_visible_in_tree():
        return
    _phase = fmod(_phase+delta,TAU/.8)
    var breath := cos(_phase*.8)
    scale = _rest_scale*(1.0+.012*(1.0-breath))
    modulate = _rest_modulate
    modulate.a *= .91+.09*breath

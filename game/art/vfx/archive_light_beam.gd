extends MeshInstance3D
## Palette setup only; puzzle owners keep visibility, authored poses and scale.

@export var beam_color := Color(.3,.78,1,1):
    set(value):
        beam_color = value
        if is_node_ready():
            _apply_palette()
@export_range(0.0,3.0,.1) var beam_energy := 1.4:
    set(value):
        beam_energy = clampf(value,0.0,3.0)
        if is_node_ready():
            _apply_palette()

func _ready() -> void:
    _apply_palette()
    set_process(false)

func _apply_palette() -> void:
    set_instance_shader_parameter("beam_tint",beam_color)
    set_instance_shader_parameter("beam_energy",beam_energy)
    var halo := get_node("Halo") as MeshInstance3D
    halo.set_instance_shader_parameter("beam_tint",beam_color)
    halo.set_instance_shader_parameter("beam_energy",beam_energy)

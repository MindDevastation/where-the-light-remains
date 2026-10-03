extends Node3D
## Detect callbacks that escaped the routing lock; engineering fixture only.
var process_ticks := 0
var physics_ticks := 0

func _process(_delta: float) -> void:
    process_ticks += 1

func _physics_process(_delta: float) -> void:
    physics_ticks += 1

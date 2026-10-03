class_name InteractionTarget
extends Node
## Explicit collider child. Puzzle/world controllers connect the local signal.

signal interacted(actor: Node3D)

@export var enabled := true
@export var prompt := "Взаимодействовать"


func is_available_to(actor: Node3D) -> bool:
    return enabled and is_inside_tree() and not is_queued_for_deletion() and is_instance_valid(actor) and actor.is_inside_tree()


func interact(actor: Node3D) -> bool:
    if not is_available_to(actor):
        return false
    interacted.emit(actor)
    return true

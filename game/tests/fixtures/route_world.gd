extends WorldScene
## Engineering counter only, not an authored puzzle.
@export var fail_apply := false
var applied_counter := 0


func validate_logical_state(state: Dictionary) -> Error:
    if state.is_empty():
        return OK
    return OK if state.size() == 1 and state.has("counter") and typeof(state["counter"]) == TYPE_INT and state["counter"] in range(4) else ERR_INVALID_DATA


func apply_logical_state(state: Dictionary) -> Error:
    var error := validate_logical_state(state)
    if error != OK:
        return error
    if fail_apply:
        return FAILED
    applied_counter = state.get("counter", 0)
    return OK

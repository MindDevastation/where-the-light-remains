class_name ArchiveProgress
extends RefCounted
## Pure save-to-presentation projection. No Nodes, globals, IO or animation.

const INTRO := &"s01_observatory"
const WING_ONE := &"s02_wing_01"
const STAGES: Array[StringName] = [INTRO, WING_ONE]
const KEYS := ["awakened", "unlocked", "completed", "memories", "light_restored",
    "star_collected", "hearth_collected", "finale_ready"]


static func fresh() -> Dictionary:
    return {"awakened": false, "unlocked": [false, false, false, false, false],
        "completed": [false, false, false, false, false], "memories": [false, false, false],
        "light_restored": false, "star_collected": false, "hearth_collected": false,
        "finale_ready": false}


static func valid(state: Dictionary) -> bool:
    if state.size() != KEYS.size():
        return false
    for key in KEYS:
        if not state.has(key):
            return false
    for key in ["awakened", "light_restored", "star_collected", "hearth_collected", "finale_ready"]:
        if typeof(state[key]) != TYPE_BOOL:
            return false
    for key in ["unlocked", "completed", "memories"]:
        if not state[key] is Array or state[key].size() != (3 if key == "memories" else 5):
            return false
        for value in state[key]:
            if typeof(value) != TYPE_BOOL:
                return false
    if state["unlocked"][0] != state["awakened"] or state["star_collected"] != state["light_restored"] or \
            state["hearth_collected"] != state["completed"][0]:
        return false
    if state["light_restored"] and not state["awakened"] or state["hearth_collected"] and not state["star_collected"]:
        return false
    for index in 5:
        if state["completed"][index] and not state["unlocked"][index]:
            return false
        if index > 0 and state["unlocked"][index] and not state["completed"][index - 1]:
            return false
    if state["unlocked"][1] != state["completed"][0]:
        return false
    if state["unlocked"][2] and not state["memories"][0] or state["unlocked"][3] and not state["memories"][1]:
        return false
    for index in 3:
        var wing: int = [1, 2, 4][index]
        if state["memories"][index] and not state["completed"][wing]:
            return false
    var ready: bool = not state["completed"].has(false) and not state["memories"].has(false)
    return state["finale_ready"] == ready


static func from_save(saved: SaveGame) -> Dictionary:
    var result := {"error": ERR_INVALID_DATA, "state": {}}
    var copy := saved.copy_validated() if saved != null else null
    if copy == null:
        return result
    var flags: Dictionary = copy.milestones
    var state := fresh()
    state["awakened"] = flags.get("archive_awakened", false)
    state["light_restored"] = flags.get("wing_01_light_restored", false)
    state["star_collected"] = copy.collected_fragments.has(&"star")
    state["hearth_collected"] = copy.collected_fragments.has(&"hearth")
    for index in 5:
        state["unlocked"][index] = flags.get("wing_%02d_unlocked" % (index + 1), false)
        state["completed"][index] = flags.get("wing_%02d_completed" % (index + 1), false)
    for index in 3:
        state["memories"][index] = flags.get("memory_%02d_completed" % (index + 1), false)
    state["finale_ready"] = not state["completed"].has(false) and not state["memories"].has(false)
    if not valid(state) or flags.get("fragment_star_collected", false) != state["star_collected"] or \
            flags.get("fragment_hearth_collected", false) != state["hearth_collected"]:
        return result
    for index in 5:
        if state["completed"][index] != (copy.collected_fragments.size() >= (index + 1) * 2):
            return result
    for stage in STAGES:
        var owned_state: Dictionary = copy.world_states.get(stage, {})
        if not owned_state.is_empty() and owned_state != state:
            return result
    return {"error": OK, "state": state}


static func write_projection(saved: SaveGame) -> Error:
    # Milestones/fragments are authoritative; replace only owned namespaces.
    var probe := saved.copy_validated() if saved != null else null
    if probe == null:
        return ERR_INVALID_DATA
    for stage in STAGES:
        probe.world_states.erase(stage)
    var projected := from_save(probe)
    if projected["error"] != OK:
        return projected["error"]
    for stage in STAGES:
        saved.world_states[stage] = projected["state"].duplicate(true)
    return OK

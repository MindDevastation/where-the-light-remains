class_name SaveGame
extends Resource
## Logical data only. Domain controllers validate their own approved world states.

const VERSION := 1
const MAX_SERIALIZED_BYTES := 262144
const MAX_JSON_NODES := 4096
const MAX_JSON_DEPTH := 8
const MAX_SAFE_NUMBER := 9007199254740991.0
const FOUND_ORDER: Array[StringName] = [
    &"star", &"hearth", &"echo", &"sprout", &"feather", &"bell",
    &"sun_glint", &"double_moon", &"constellation", &"clear_crystal",
]
const FIELDS: Array[String] = [
    "save_version", "stage_id", "checkpoint_id", "collected_fragments",
    "world_states", "milestones", "achievement_ids", "game_completed",
]

var stage_id: StringName = &"s00_prologue"
var checkpoint_id: StringName = &""
var collected_fragments: Array[StringName] = []
var world_states: Dictionary = {}
var milestones: Dictionary = {}
var achievement_ids: Array[StringName] = []
var game_completed := false


func to_dict() -> Dictionary:
    if collected_fragments.size() > FOUND_ORDER.size() or achievement_ids.size() > 128 or milestones.size() > 128:
        return {}
    if not _valid_json(world_states, 0, [MAX_JSON_NODES]):
        return {}
    for key in milestones:
        if not identifier(key) or typeof(milestones[key]) != TYPE_BOOL:
            return {}
    var fragments: Array[String] = []
    var achievements: Array[String] = []
    for id in collected_fragments:
        fragments.append(String(id))
    for id in achievement_ids:
        achievements.append(String(id))
    return {
        "save_version": VERSION, "stage_id": String(stage_id),
        "checkpoint_id": String(checkpoint_id), "collected_fragments": fragments,
        "world_states": world_states.duplicate(true), "milestones": milestones.duplicate(true),
        "achievement_ids": achievements, "game_completed": game_completed,
    }


func copy_validated() -> SaveGame:
    return decode(to_dict())["data"]


static func identifier(value: Variant, empty_allowed: bool = false) -> bool:
    if typeof(value) not in [TYPE_STRING, TYPE_STRING_NAME]:
        return false
    var text := String(value)
    if text.is_empty():
        return empty_allowed
    if text.length() > 96:
        return false
    return RegEx.create_from_string("^[A-Za-z_][A-Za-z0-9_]*$").search(text) != null


static func decode(value: Variant) -> Dictionary:
    var failure := {"error": ERR_INVALID_DATA, "data": null}
    if not value is Dictionary:
        return failure
    if not value.has("save_version") or typeof(value["save_version"]) not in [TYPE_INT, TYPE_FLOAT]:
        return failure
    var version := float(value["save_version"])
    if not is_finite(version) or version != floorf(version) or version < 1:
        return failure
    if version != VERSION:
        return {"error": ERR_UNAVAILABLE, "data": null}
    if value.size() != FIELDS.size():
        return failure
    for key in FIELDS:
        if not value.has(key):
            return failure
    if not identifier(value["stage_id"]) or RegEx.create_from_string("^s(?:0[0-9]|1[0-5])_[a-z][a-z0-9_]*$").search(String(value["stage_id"])) == null:
        return failure
    if not identifier(value["checkpoint_id"], true) or typeof(value["game_completed"]) != TYPE_BOOL:
        return failure
    if not value["collected_fragments"] is Array or value["collected_fragments"].size() > FOUND_ORDER.size():
        return failure
    for index in value["collected_fragments"].size():
        var id: Variant = value["collected_fragments"][index]
        if typeof(id) not in [TYPE_STRING, TYPE_STRING_NAME] or String(id) != String(FOUND_ORDER[index]):
            return failure
    if value["game_completed"] and (not String(value["stage_id"]).begins_with("s15_") or value["collected_fragments"].size() != FOUND_ORDER.size()):
        return failure
    if not value["world_states"] is Dictionary or not value["milestones"] is Dictionary or not value["achievement_ids"] is Array:
        return failure
    if value["milestones"].size() > 128 or value["achievement_ids"].size() > 128:
        return failure
    for key in value["milestones"]:
        if not identifier(key) or typeof(value["milestones"][key]) != TYPE_BOOL:
            return failure
    for key in value["world_states"]:
        if not identifier(key) or not value["world_states"][key] is Dictionary:
            return failure
    var seen := {}
    for id in value["achievement_ids"]:
        if not identifier(id) or seen.has(String(id)):
            return failure
        seen[String(id)] = true
    if not _valid_json(value["world_states"], 0, [MAX_JSON_NODES]):
        return failure
    var normalized: Dictionary = _clone_json(value)
    if JSON.stringify(normalized, "", true, true).to_utf8_buffer().size() > MAX_SERIALIZED_BYTES:
        return failure
    var saved := SaveGame.new()
    saved.stage_id = StringName(normalized["stage_id"])
    saved.checkpoint_id = StringName(normalized["checkpoint_id"])
    for id in normalized["collected_fragments"]:
        saved.collected_fragments.append(StringName(id))
    for id in normalized["achievement_ids"]:
        saved.achievement_ids.append(StringName(id))
    saved.world_states = normalized["world_states"]
    saved.milestones = normalized["milestones"]
    saved.game_completed = normalized["game_completed"]
    return {"error": OK, "data": saved}


static func _valid_json(value: Variant, depth: int, budget: Array) -> bool:
    budget[0] -= 1
    if depth > MAX_JSON_DEPTH or budget[0] < 0:
        return false
    match typeof(value):
        TYPE_NIL, TYPE_BOOL:
            return true
        TYPE_INT, TYPE_FLOAT:
            return is_finite(float(value)) and absf(float(value)) <= MAX_SAFE_NUMBER
        TYPE_STRING, TYPE_STRING_NAME:
            return String(value).length() <= 512
        TYPE_ARRAY:
            for item in value:
                if not _valid_json(item, depth + 1, budget):
                    return false
        TYPE_DICTIONARY:
            var seen := {}
            for key in value:
                if not identifier(key) or seen.has(String(key)) or not _valid_json(value[key], depth + 1, budget):
                    return false
                seen[String(key)] = true
        _:
            return false
    return true


static func _clone_json(value: Variant) -> Variant:
    if value is Dictionary:
        var copy := {}
        for key in value:
            copy[String(key)] = _clone_json(value[key])
        return copy
    if value is Array:
        var copy := []
        for item in value:
            copy.append(_clone_json(item))
        return copy
    return String(value) if typeof(value) == TYPE_STRING_NAME else value

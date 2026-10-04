class_name FragmentData
extends Resource
## Canonical copy and internal finale metadata; presentation never renders order/letter.

@export var fragment_id: StringName
@export var display_name := ""
@export var sigil: Texture2D
@export var couplet: PackedStringArray
@export_multiline var feeling := ""
@export_range(0, 9, 1) var final_order := 0
@export var acrostic_letter := ""


func valid() -> bool:
    var found_index := SaveGame.FOUND_ORDER.find(fragment_id)
    var letters := ["Я", "Л", "Ю", "Б", "Л", "Ю", "Т", "Е", "Б", "Я"]
    return found_index >= 0 and not display_name.is_empty() and sigil != null and \
        couplet.size() == 2 and not couplet[0].is_empty() and not couplet[1].is_empty() and \
        not feeling.is_empty() and final_order == (found_index ^ 1) and acrostic_letter == letters[final_order]

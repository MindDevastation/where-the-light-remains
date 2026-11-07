extends SceneTree
## Bounded native font-resource pack, not a platform/game release export.

func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 1 or not args[0].is_absolute_path() or FileAccess.file_exists(args[0]):
        quit(1)
        return
    var pack := PCKPacker.new()
    assert(pack.pck_start(args[0]) == OK)
    var files: Array[String] = ["res://art/fonts/archive_ui_font.tres", "res://art/fonts/provenance.json"]
    var provenance: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/fonts/provenance.json"))
    for item: Dictionary in provenance["files"]:
        var path: String = "res://" + String(item["repository_path"]).trim_prefix("game/")
        assert(FileAccess.get_sha256(path) == item["sha256"])
        files.append(path)
        if path.ends_with(".ttf"):
            files.append(path + ".import")
            var config := ConfigFile.new()
            assert(config.load(path + ".import") == OK)
            assert(not config.get_value("params", "allow_system_fallback", true))
            files.append(config.get_value("remap", "path"))
    for path: String in files:
        assert(pack.add_file(path, ProjectSettings.globalize_path(path)) == OK)
    assert(pack.flush() == OK)
    print("UI_FONT_PACK PASS: ", files.size(), " native font/source/import files; full notices in resource metadata")
    quit(0)

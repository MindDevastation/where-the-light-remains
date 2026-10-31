extends SceneTree
## Executed in an empty owned project with no source fonts on disk.

func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    assert(args.size() == 2 and args[0].is_absolute_path() and args[1].is_absolute_path())
    assert(not DirAccess.dir_exists_absolute("res://art/fonts"))
    assert(ProjectSettings.load_resource_pack(args[0]))
    var font := load("res://art/fonts/archive_ui_font.tres") as FontVariation
    assert(font != null and font.base_font.get_font_name() == "Open Sans" and font.fallbacks.size() == 2)
    var provenance: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/fonts/provenance.json"))
    var verified := []
    for item: Dictionary in provenance["files"]:
        var path: String = "res://" + String(item["repository_path"]).trim_prefix("game/")
        assert(FileAccess.get_sha256(path) == item["sha256"])
        verified.append({"path": path, "sha256": item["sha256"]})
    var notices: Dictionary = font.get_meta("third_party_notices")
    for pair: Array in [["Open Sans", "open_sans"], ["Noto Sans Symbols", "noto_sans_symbols"], ["Noto Sans Symbols 2", "noto_sans_symbols_2"]]:
        assert(notices[pair[0]] == FileAccess.get_file_as_string("res://art/fonts/" + pair[1] + "/OFL.txt"))
    for face: FontFile in [font.base_font, font.fallbacks[0], font.fallbacks[1]]:
        assert(not face.allow_system_fallback)
    var server := TextServerManager.get_primary_interface()
    var families := {}
    for codepoint: int in [0x401, 0x451, 0x42f, 0x44f, 0x2192, 0x23ce, 0x2713]:
        var line := TextLine.new()
        assert(line.add_string(String.chr(codepoint), font, 24))
        var glyphs := server.shaped_text_get_glyphs(line.get_rid())
        assert(not glyphs.is_empty())
        for glyph: Dictionary in glyphs:
            assert(glyph["font_rid"].is_valid() and int(glyph["index"]) > 0)
            families[server.font_get_name(glyph["font_rid"])] = true
    assert(families.size() == 3)
    var file := FileAccess.open(args[1], FileAccess.WRITE)
    assert(file != null)
    file.store_string(JSON.stringify({"status": "PASS", "source_fonts_absent_before_mount": true,
        "verified_sources": verified, "native_families": families.keys(), "complete_notices_equal": true,
        "scope": "Native font PCK mounted in empty project; not a platform/game export or release audit"}, "  ") + "\n")
    file.close()
    print("UI_FONT_PACK_READBACK PASS: isolated pack glyphs, complete notices and exact upstream bytes")
    quit(0)

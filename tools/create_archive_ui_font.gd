extends SceneTree
## Offline font resource assembly; original TTF and license bytes stay intact.

func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 1 or not args[0].is_absolute_path() or FileAccess.file_exists(args[0]):
        push_error("Expected one new absolute font-resource output file")
        quit(1)
        return
    var primary := load("res://art/fonts/open_sans/OpenSans-VF.ttf") as FontFile
    var text_fallback := load("res://art/fonts/noto_sans_symbols/NotoSansSymbols-VF.ttf") as FontFile
    var symbols := load("res://art/fonts/noto_sans_symbols_2/NotoSansSymbols2-Regular.ttf") as FontFile
    if primary == null or text_fallback == null or symbols == null or primary.allow_system_fallback or text_fallback.allow_system_fallback or symbols.allow_system_fallback:
        push_error("All imported fonts must disable system fallback")
        quit(1)
        return
    var font := FontVariation.new()
    font.resource_name = "Archive UI Open Sans Semibold with bundled symbols"
    font.base_font = primary
    font.fallbacks = [text_fallback, symbols]
    var text := TextServerManager.get_primary_interface()
    font.variation_opentype = {text.name_to_tag("wght"): 600.0, text.name_to_tag("wdth"): 100.0}
    font.set_meta("source_repository", "https://github.com/google/fonts")
    font.set_meta("source_commit", "6c1dbe27dcf7d817d4b62cec033ba77fa8e2a5ec")
    # Exported native resources retain complete copyright/license notices.
    font.set_meta("third_party_notices", {
        "Open Sans": FileAccess.get_file_as_string("res://art/fonts/open_sans/OFL.txt"),
        "Noto Sans Symbols": FileAccess.get_file_as_string("res://art/fonts/noto_sans_symbols/OFL.txt"),
        "Noto Sans Symbols 2": FileAccess.get_file_as_string("res://art/fonts/noto_sans_symbols_2/OFL.txt")})
    if ResourceSaver.save(font, args[0]) != OK:
        quit(1)
        return
    print("ARCHIVE_UI_FONT_SOURCE PASS: Open Sans wght600/wdth100; bundled text/symbol fallback; complete notices")
    quit(0)

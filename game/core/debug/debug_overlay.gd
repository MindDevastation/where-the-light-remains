extends CanvasLayer
## Opt-in, passive development overlay. F3 never changes gameplay/input mode.

const Snapshot := preload("res://core/debug/debug_snapshot.gd")
const REFRESH_SECONDS := 0.5
const SAVE_STATUS := {
    "missing": "нет файла", "unreadable": "ошибка чтения",
    "too_large": "превышен лимит просмотра 256 КиБ",
    "invalid_json": "ошибка JSON", "json_preview": "JSON прочитан (без проверки схемы)",
}

@onready var _text: Label = $Panel/Margin/Text
var _game_root: Node
var _elapsed := 0.0
var _frames := 0


func _ready() -> void:
    if not OS.is_debug_build() or App.BUILD_FLAVOR != "development" or not OS.get_cmdline_user_args().has("--dev-tools"):
        queue_free()
        return
    _game_root = get_parent()
    _refresh(0.0)


func _process(delta: float) -> void:
    _elapsed += delta
    _frames += 1
    if _elapsed >= REFRESH_SECONDS:
        _refresh(_elapsed * 1000.0 / _frames)
        _elapsed = 0.0
        _frames = 0


func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.keycode == KEY_F3 and event.pressed and not event.echo:
        visible = not visible
        set_process(visible)
        _elapsed = 0.0
        _frames = 0
        if visible:
            _refresh(0.0)
        get_viewport().set_input_as_handled()


func _save_line(title: String, info: Dictionary) -> String:
    var line := "%s: %s · %d байт" % [title, SAVE_STATUS[info["status"]], info["bytes"]]
    if info.has("data"):
        var preview := JSON.stringify(info["data"])
        line += "\n  " + preview.left(220) + ("…" if preview.length() > 220 else "")
    return line


func _refresh(frame_ms: float) -> void:
    var data := Snapshot.capture(_game_root)
    var lines := PackedStringArray([
        "ДИАГНОСТИКА РАЗРАБОТКИ · Только чтение · F3: скрыть / показать",
        "Этап: %s · Пауза: %s · Режим ввода: %s" % [data["stage"], _yes_no(data["paused"]), data["input_mode"]],
        "Фрагменты: %s · Игра завершена: %s" % [JSON.stringify(data["fragments"]).left(220), _yes_no(data["completed"])],
        "",
        "СОХРАНЕНИЕ · Несохраненные изменения: " + _yes_no(data["save_dirty"]),
        _save_line(data["primary"]["path"], data["primary"]),
        _save_line(data["backup"]["path"], data["backup"]),
        "",
        "СЦЕНА: " + (data["scene"] if not data["scene"].is_empty() else "не назначена"),
        "Мир: " + (JSON.stringify(data["worlds"]).left(300) if not data["worlds"].is_empty() else "WorldSlot пуст"),
        "",
        "FPS: %d · Кадр (среднее): %.2f мс · Узлы: %d" % [data["fps"], frame_ms, data["nodes"]],
        "Процесс: %.2f мс · Физика: %.2f мс · Вызовы отрисовки: %d" % [data["process_ms"], data["physics_ms"], data["draw_calls"]],
        "",
        "ЗВУК · Этап AudioDirector: %s · Состояние: %s" % [data["audio_stage"] if not data["audio_stage"].is_empty() else "не назначен", data["audio_state"]],
    ])
    for bus: Dictionary in data["buses"]:
        lines.append("%s → %s: %.1f дБ · Выкл.: %s · Соло: %s" % [
            bus["name"], "выход" if bus["send"] == "output" else bus["send"],
            bus["db"], _yes_no(bus["mute"]), _yes_no(bus["solo"]),
        ])
    _text.text = "\n".join(lines)


func _yes_no(value: bool) -> String:
    return "да" if value else "нет"

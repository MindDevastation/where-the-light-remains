extends SceneTree
## CLI-only routing check. Test players/effects never enter production scenes.

const LAYOUT_PATH := "res://audio/default_bus_layout.tres"
const BUS_NAMES: Array[StringName] = [
    &"Master", &"Music", &"Music_Main", &"Music_Stems", &"SFX",
    &"SFX_Critical", &"SFX_World", &"Ambience", &"UI", &"VO_RESERVED",
]
const SENDS: Dictionary = {
    &"Music": &"Master", &"Music_Main": &"Music", &"Music_Stems": &"Music",
    &"SFX": &"Master", &"SFX_Critical": &"SFX", &"SFX_World": &"SFX",
    &"Ambience": &"Master", &"UI": &"Master", &"VO_RESERVED": &"Master",
}
const SILENT_PEAK := 0.00001

var _failures: Array[String] = []
var _captures: Dictionary = {}
var _player: AudioStreamPlayer


func _initialize() -> void:
    create_timer(30.0).timeout.connect(_on_timeout)
    _run.call_deferred()


func _on_timeout() -> void:
    push_error("AUDIO_BUS FAIL: mixer test did not finish within 30 seconds")
    quit(1)


func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
        push_error("AUDIO_BUS FAIL: " + message)


func _check_layout() -> void:
    _check(ProjectSettings.get_setting("audio/buses/default_bus_layout") == LAYOUT_PATH, "Project default layout is not configured")
    _check(ResourceLoader.exists(LAYOUT_PATH, "AudioBusLayout"), "Missing AudioBusLayout resource")
    _check(AudioServer.bus_count == BUS_NAMES.size(), "Expected 10 automatically loaded buses, got %d" % AudioServer.bus_count)
    for index in BUS_NAMES.size():
        var bus: StringName = BUS_NAMES[index]
        var actual := AudioServer.get_bus_index(bus)
        _check(actual == index, "Missing or misplaced bus: " + bus)
        if actual < 0:
            continue
        _check(is_zero_approx(AudioServer.get_bus_volume_db(actual)), "Non-neutral default gain: " + bus)
        _check(not AudioServer.is_bus_mute(actual), "Unexpected default mute: " + bus)
        _check(not AudioServer.is_bus_solo(actual), "Unexpected default solo: " + bus)
        _check(not AudioServer.is_bus_bypassing_effects(actual), "Unexpected effect bypass: " + bus)
        _check(AudioServer.get_bus_effect_count(actual) == 0, "Unexpected production effect: " + bus)
        if actual > 0:
            var destination: StringName = SENDS[bus]
            _check(AudioServer.get_bus_send(actual) == destination, "Wrong send: " + bus)
            var parent := AudioServer.get_bus_index(AudioServer.get_bus_send(actual))
            _check(parent >= 0 and parent < actual, "Send must reach an earlier bus: " + bus)


func _make_tone() -> AudioStreamWAV:
    # In-memory test signal; not a production audio asset or microphone input.
    var rate := int(AudioServer.get_mix_rate())
    var sample_count := rate * 30
    var data := PackedByteArray()
    data.resize(sample_count * 2)
    for sample in range(sample_count):
        data.encode_s16(sample * 2, int(32767.0 * 0.1 * sin(TAU * 440.0 * sample / rate)))
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = rate
    stream.data = data
    return stream


func _measure(bus: StringName) -> Dictionary:
    _player.bus = bus
    # Allow the mixer to apply the new route/gain, then discard prior samples.
    await create_timer(0.10).timeout
    for capture: AudioEffectCapture in _captures.values():
        capture.clear_buffer()
    await create_timer(0.15).timeout
    var peaks: Dictionary = {}
    for name in _captures:
        var capture: AudioEffectCapture = _captures[name]
        var frames := capture.get_buffer(capture.get_frames_available())
        var peak := 0.0
        for frame in frames:
            peak = maxf(peak, maxf(absf(frame.x), absf(frame.y)))
        peaks[name] = peak
    return peaks


func _run() -> void:
    print("AUDIO_BUS runtime: ", Engine.get_version_info()["string"], "; display=", DisplayServer.get_name(), "; audio=", AudioServer.get_driver_name())
    print("AUDIO_BUS source: project default layout; generated PCM through the real mixer; no speaker test")
    # Validate automatic startup loading before making any AudioServer changes.
    _check_layout()
    if not _failures.is_empty():
        quit(1)
        return
    var original := AudioServer.generate_bus_layout()
    for bus in [&"Master", &"Music", &"SFX"]:
        var capture := AudioEffectCapture.new()
        capture.buffer_length = 0.5
        AudioServer.add_bus_effect(AudioServer.get_bus_index(bus), capture)
        _captures[bus] = capture
    _player = AudioStreamPlayer.new()
    _player.stream = _make_tone()
    root.add_child(_player)
    _player.play()

    var baseline: Dictionary = {}
    for bus in BUS_NAMES:
        var peaks: Dictionary = await _measure(bus)
        baseline[bus] = peaks[&"Master"]
        _check(absf(peaks[&"Master"] - 0.1) < 0.01, "Unexpected signal amplitude at Master from " + bus)
        for group in [&"Music", &"SFX"]:
            var belongs: bool = bus == group or SENDS.get(bus, &"") == group
            if belongs:
                _check(peaks[group] > 0.05, "Signal bypassed parent " + group + " from " + bus)
            else:
                _check(peaks[group] < SILENT_PEAK, "Signal leaked into " + group + " from " + bus)
        print("AUDIO_BUS route: ", bus, " -> ", SENDS.get(bus, &"output"), "; peaks=", JSON.stringify(peaks))

    for group in [&"Music", &"SFX"]:
        var parent := AudioServer.get_bus_index(group)
        var children: Array[StringName] = []
        for bus in SENDS:
            if SENDS[bus] == group:
                children.append(bus)
        AudioServer.set_bus_volume_db(parent, linear_to_db(0.5))
        for child in children:
            var peaks: Dictionary = await _measure(child)
            var ratio: float = peaks[&"Master"] / maxf(baseline[child], 0.000001)
            _check(absf(ratio - 0.5) < 0.04, "Parent gain did not halve output from " + child)
            print("AUDIO_BUS gain: ", child, "; half-gain ratio=", ratio)
        AudioServer.set_bus_volume_db(parent, 0.0)
        AudioServer.set_bus_mute(parent, true)
        for child in children:
            var peaks: Dictionary = await _measure(child)
            _check(peaks[&"Master"] < SILENT_PEAK, "Parent mute did not silence " + child)
            print("AUDIO_BUS mute: ", child, "; Master peak=", peaks[&"Master"])
        var independent: Array = [&"SFX_Critical", &"Ambience", &"UI"] if group == &"Music" else [&"Music_Main"]
        for bus in independent:
            var peaks: Dictionary = await _measure(bus)
            _check(peaks[&"Master"] > 0.05, "Muting " + group + " silenced independent bus " + bus)
        AudioServer.set_bus_mute(parent, false)
        print("AUDIO_BUS checked parent gain/mute and branch independence: ", group)

    _player.stop()
    # Let the audio thread finish the stopped playback before freeing resources.
    await create_timer(0.10).timeout
    _player.free()
    AudioServer.set_bus_layout(original)
    _captures.clear()
    _check_layout()
    if _failures.is_empty():
        print("AUDIO_BUS PASS: automatic layout, all routes, parent gain/mute and restored neutral state")
        quit()
    else:
        quit(1)

extends Node
## Actual registered worlds/fades/rollback while the global Director plays PCM.

class ProbeRouter extends "res://autoload/scene_router.gd":
    var fade_out_audio: Dictionary = {}

    func _route_fade(alpha: float) -> bool:
        if alpha > .5:
            fade_out_audio = AudioDirector.playback_snapshot()
        return await super._route_fade(alpha)

var _checks := 0
var _failures: Array[String] = []
var _done := false
var _error: Error = FAILED


func _ready() -> void:
    get_tree().create_timer(25.0, true).timeout.connect(func() -> void:
        push_error("AUDIO_ROUTE FAIL: bounded route timeout")
        get_tree().quit(1)
    )
    _run.call_deferred()


func _check(condition: bool, message: String) -> void:
    _checks += 1
    if not condition:
        _failures.append(message)
        push_error("AUDIO_ROUTE FAIL: " + message)


func _cue(id: StringName) -> MusicCue:
    var bytes := PackedByteArray()
    bytes.resize(16000 * 16)
    for sample in 8000 * 16:
        bytes.encode_s16(sample * 2, int(3276.0 * sin(TAU * 440.0 * sample / 8000.0)))
    var wav := AudioStreamWAV.new()
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.mix_rate = 8000
    wav.data = bytes
    var cue := MusicCue.new()
    cue.cue_id = id
    cue.stream = wav
    return cue


func _playing(id: StringName) -> bool:
    for player in AudioDirector.playback_snapshot()["players"]:
        if player["playing"] and player["cue"] == id:
            return true
    return false


func _position(id: StringName) -> float:
    for player in AudioDirector.playback_snapshot()["players"]:
        if player["playing"] and player["cue"] == id:
            return player["position"]
    return -1.0


func _launch(router: ProbeRouter, saved: SaveGame) -> void:
    _done = false
    _error = await router.request_resume_stage(saved)
    _done = true


func _wait_fade(router: ProbeRouter) -> void:
    while not _done and not router.get("_fade").busy:
        await get_tree().process_frame


func _wait_done() -> void:
    while not _done:
        await get_tree().process_frame


func _run() -> void:
    var original := GameState.capture_save()
    var hashes := [FileAccess.get_sha256(SaveManager.SAVE_PATH), FileAccess.get_sha256(SaveManager.BACKUP_PATH)]
    var game := preload("res://core/game_root/game_root.tscn").instantiate()
    add_child(game)
    var slot: Node3D = game.get_node("WorldSlot")
    var router := ProbeRouter.new()
    add_child(router)
    router.bind_world_slot(slot, game.get_node("PlayerContainer/Player"), game.get_node("TransitionLayer/FadeOverlay"))
    router.fade_duration = .08
    var a := _cue(&"route_a")
    var b := _cue(&"route_b")
    for spec in [[&"s01_fixture", "route_world_a", a], [&"s02_fixture", "route_world_b", b]]:
        var definition := StageDefinition.new()
        definition.stage_id = spec[0]
        definition.scene_path = "res://tests/fixtures/" + String(spec[1]) + ".tscn"
        _check(router.register_stage(definition) == OK, "Register actual route fixture world")
        var music := MusicStage.new()
        music.stage_id = spec[0]
        music.scripted_only = true
        music.initial_state = &"fixture_idle" if spec[0] == &"s01_fixture" else &"fixture_tone"
        music.authored_states[&"fixture_tone"] = spec[2]
        _check(AudioDirector.register_stage(music) == OK, "Register bound actual route music fixture")
    var initial := SaveGame.new()
    initial.stage_id = &"s01_fixture"
    var target := SaveGame.new()
    target.stage_id = &"s02_fixture"
    _check(await router.request_resume_stage(initial) == OK, "Initialize actual source world")
    _check(router.fade_out_audio.get("pending_stage", false), "Audio lease is held before initial fade-out")
    AudioDirector.set_music_state(&"fixture_tone", 0.0)
    await get_tree().create_timer(.25).timeout
    var first := slot.get_child(0)
    var source := GameState.capture_save().to_dict()
    var position := _position(a.cue_id)
    router.fade_duration = .25
    _launch(router, target)
    await _wait_fade(router)
    _check(not _done and router.fade_out_audio["pending_stage"] and _playing(a.cue_id) and not _playing(b.cue_id), "Known transition holds playlist selection before fade-out while old cue remains actual playback")
    await get_tree().create_timer(.08).timeout
    router.cancel_transition()
    await _wait_done()
    _check(_error == ERR_SKIP and slot.get_child(0) == first and GameState.capture_save().to_dict() == source, "Fade-out cancellation preserves source world and exact logical state")
    _check(AudioDirector.current_stage == initial.stage_id and _playing(a.cue_id) and _position(a.cue_id) >= position, "Actual router rollback retains outgoing stream without rewind/restart")
    router.fade_duration = .08
    _check(await router.request_resume_stage(target) == OK, "Actual target route accepts")
    _check(GameState.current_stage_id == target.stage_id and AudioDirector.current_stage == target.stage_id and not AudioDirector.playback_snapshot()["pending_stage"] and _playing(b.cue_id), "Target cue starts only after the last route acceptance guard")
    await get_tree().create_timer(2.1).timeout
    var second := slot.get_child(0)
    source = GameState.capture_save().to_dict()
    position = _position(b.cue_id)
    router.fade_duration = .2
    _launch(router, initial)
    while not _done and not router.get("_route").get("committed", false):
        await get_tree().process_frame
    _check(not _done and AudioDirector.playback_snapshot()["pending_stage"] and _playing(b.cue_id), "Post-state-commit fade still retains the accepted source cue")
    router.cancel_transition()
    await _wait_done()
    _check(_error == ERR_SKIP and slot.get_child(0) == second and GameState.capture_save().to_dict() == source and AudioDirector.current_stage == target.stage_id and _position(b.cue_id) >= position, "Post-commit cancellation rolls back world/metadata without restarting music")
    _launch(router, initial)
    await _wait_fade(router)
    var silence := AudioDirector.force_silence()
    await _wait_done()
    _check(_error == ERR_SKIP and slot.get_child(0) == second and GameState.capture_save().to_dict() == source, "Newer silence supersedes actual pending route and rolls back its world")
    _check(silence > 0 and AudioDirector.playback_snapshot()["silence_locks"] == 1 and AudioDirector.current_state == &"silence" and not _playing(b.cue_id), "Stale route cleanup cannot release the newer silence owner")
    AudioDirector.release_silence(silence)
    AudioDirector.set_music_state(&"unbound_fixture_state", 0.0)
    for id in [initial.stage_id, target.stage_id]:
        _check(AudioDirector.unregister_stage(id) == OK, "Release fixture music profile")
    router.queue_free()
    game.queue_free()
    await get_tree().create_timer(.2, true).timeout
    GameState.apply_save(original)
    _check(not SaveManager.get("_dirty") and [FileAccess.get_sha256(SaveManager.SAVE_PATH), FileAccess.get_sha256(SaveManager.BACKUP_PATH)] == hashes, "All actual resume/cancel routes retain both protected save hashes and clean dirty state")
    if _failures.is_empty():
        print("AUDIO_ROUTE PASS: ", _checks, " assertions; actual fade/commit/rollback playback and later silence ownership")
    get_tree().quit(0 if _failures.is_empty() else 1)

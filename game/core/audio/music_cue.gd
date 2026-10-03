class_name MusicCue
extends Resource
## Immutable runtime binding. Source masters are not runtime bindings by default.

@export var cue_id: StringName = &""
@export var source_title := ""
@export var stream: AudioStream
@export_range(-24.0, 0.0) var gain_db := 0.0
@export var vocal := false


func copy_validated() -> MusicCue:
    if not SaveGame.identifier(cue_id) or source_title.length() > 128 or not is_finite(gain_db) or gain_db < -24.0 or gain_db > 0.0:
        return null
    # Only finite, ordinary file/PCM streams. Interactive/custom streams need
    # their own authored contract rather than invented length/loop semantics.
    if not (stream is AudioStreamWAV or stream is AudioStreamOggVorbis or stream is AudioStreamMP3):
        return null
    if not is_finite(stream.get_length()) or stream.get_length() <= 0.0:
        return null
    var copy := MusicCue.new()
    copy.cue_id = cue_id
    copy.source_title = source_title
    copy.stream = stream.duplicate() as AudioStream
    copy.gain_db = gain_db
    copy.vocal = vocal
    return copy


func is_looping() -> bool:
    if stream is AudioStreamWAV:
        return stream.loop_mode != AudioStreamWAV.LOOP_DISABLED
    return stream.loop if stream is AudioStreamOggVorbis or stream is AudioStreamMP3 else false

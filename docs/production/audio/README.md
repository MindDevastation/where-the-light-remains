# S00/S01/S02 source edit and export work

`slice_edit_manifest.json` maps all twelve sealed source WAVs to canonical cue
names, source intervals, semantic intent, finite playback and pending acceptance.
Full S01/S02 takes are review candidates; no cue is bound to shipping scenes.
Both S00 intervals remain blocked on actual first-note/motif selection. No stems
were supplied, and this tool does not fabricate them by automatic separation.

`tools/audio_slice.py` requires Python 3.11+, NumPy, FFmpeg/ffprobe with libvorbis.
Run from the repository root. Every output directory must be new and inside
`docs/production/evidence/audio_director/`; game/audio and assets are forbidden.
Source SHA checks run before and after processing. FFmpeg commands have a
45-second timeout, no stdin and no overwrite. Keep an outer timeout too.

```sh
timeout 30 python -B tools/test_audio_slice.py
timeout 180 python -B tools/audio_slice.py analyze \
  --output docs/production/evidence/audio_director/slice-analysis-NEW
timeout 120 python -B tools/audio_slice.py export \
  --cue mus_s01_archive_awakening_v01 \
  --output docs/production/evidence/audio_director/s01-unique-review-NEW
```

Analysis records stereo PCM envelopes and EBU R128 integrated loudness, LRA and
true peak. An energy envelope cannot identify notes, vocals, motif identity or
musical loop points. Export preserves dynamic range and adds only recorded edge
fades and attenuation if needed. Vorbis quality 5, stereo 48 kHz, finite playback.
The decoded review derivative must stay at/below -1 dBTP, an engineering safety
ceiling; this is not a canonical loudness target. No normalization to an invented
LUFS value, limiter or dynamic compressor is applied. Lossy compression is
measured after encoding and retried with attenuation when necessary.

PASS means measured bytes, format, duration and protection checks passed. It
does not mean a musical/edit/palette/no-vocal/scene-mix/license check passed.
Review derivatives live with evidence until their authored acceptance exists.
Then perform initially cache-free Godot import/mixer/world/progression/resume
validation before shipping bindings. The immutable master WAVs remain in assets.

Two unique review cues now exist in `s01-unique-review-1/` and
`s02-unique-review-1/` under the evidence directory. To import them only into an
exact temporary cache-free project and capture actual Godot mixer output:

```sh
timeout 180 python -B tools/validate_archive_reconstruction.py \
  --godot /absolute/path/to/Godot_v4.7.2-stable_linux.x86_64 \
  --output docs/production/evidence/audio_director/unique-godot-review-NEW \
  --tests audio_review_smoke boot_startup_smoke normal_startup \
  --save-mode read-only \
  --review-family docs/production/evidence/audio_director/s01-unique-review-1 \
    docs/production/evidence/audio_director/s02-unique-review-1
```

The validator verifies sealed derivative SHA/path/identity and copies OGGs into
`game/audio/review/` only inside its temporary project. It checks source hashes
and removes that project/cache afterward. The shipping working copy never gains
these media/bindings. `audio_review_smoke` expects the two exact unique cues;
running that test without private review media intentionally fails. Accepted
technical evidence is `unique-godot-review-2/` (30 assertions plus main-entry
regressions); listening/edit/motif and actual speaker/scene-mix remain unverified.

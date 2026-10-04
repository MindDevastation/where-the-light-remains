# Аудиокандидаты S00/S01/S02

Технические кандидаты для прослушивания и монтажа. Игровые сцены их не используют.
Музыкальный мотив, инструментальность, микс и лицензии требуют отдельной приемки.
Исходные WAV сохранены; S00 ждет выбора первой ноты.

| Cue | Этап / роль | OGG / evidence | Длительность, с | LUFS / dBTP | Статус |
| --- | --- | --- | ---: | --- | --- |
| mus_s00_archive_seed_v01 | S00 / scripted seed source | [Source WAV (not runtime cue)](../../../assets/audio/music/A_Archive/stages/S00_Prologue/unique/Sparse%20Awakening%20vol.2.wav) | 168.16 source | — | First-note selection pending |
| mus_s00_archive_seed_alternate_v01 | S00 / scripted supplemental source | [Source WAV (not runtime cue)](../../../assets/audio/music/A_Archive/stages/S00_Prologue/supplemental/Sparse%20Awakening.wav) | 164.00 source | — | First-note selection pending |
| mus_s01_archive_awakening_v01 | S01 / unique first | [OGG](../evidence/audio_director/s01-unique-review-1/mus_s01_archive_awakening_v01.ogg) · [proof](../evidence/audio_director/s01-unique-review-1/verification.json) | 129.72 | -15.9 / -3.1 | Technical PASS; musical pending |
| mus_s02_cold_to_warm_v01 | S02 / unique first | [OGG](../evidence/audio_director/s02-unique-review-1/mus_s02_cold_to_warm_v01.ogg) · [proof](../evidence/audio_director/s02-unique-review-1/verification.json) | 127.96 | -16.5 / -3.6 | Technical PASS; musical pending |
| mus_s01_activation_sequence_v01 | S01 / group A shared source | [OGG](../evidence/audio_director/s01-activation-review-1/mus_s01_activation_sequence_v01.ogg) · [proof](../evidence/audio_director/s01-activation-review-1/verification.json) | 117.40 | -16.2 / -3.1 | Technical PASS; musical pending |
| mus_s01_archive_fragment_v01 | S01 / group A shared source | [OGG](../evidence/audio_director/s01-fragment-review-1/mus_s01_archive_fragment_v01.ogg) · [proof](../evidence/audio_director/s01-fragment-review-1/verification.json) | 173.00 | -16.5 / -4.1 | Technical PASS; musical pending |
| mus_s01_hub_motif_v01 | S01 / group A shared source | [OGG](../evidence/audio_director/s01-hub-motif-review-1/mus_s01_hub_motif_v01.ogg) · [proof](../evidence/audio_director/s01-hub-motif-review-1/verification.json) | 118.00 | -15.6 / -2.6 | Technical PASS; musical pending |
| mus_s01_mechanism_light_v01 | S01 / group A shared source | [OGG](../evidence/audio_director/s01-mechanism-review-1/mus_s01_mechanism_light_v01.ogg) · [proof](../evidence/audio_director/s01-mechanism-review-1/verification.json) | 132.76 | -15.2 / -2.7 | Technical PASS; musical pending |
| mus_s01_resonant_puzzle_v01 | S01 / group A shared source | [OGG](../evidence/audio_director/s01-resonant-review-1/mus_s01_resonant_puzzle_v01.ogg) · [proof](../evidence/audio_director/s01-resonant-review-1/verification.json) | 178.40 | -16.3 / -3.5 | Technical PASS; musical pending |
| mus_s02_silent_roads_v01 | S02 / group B shared source | [OGG](../evidence/audio_director/s02-silent-roads-review-1/mus_s02_silent_roads_v01.ogg) · [proof](../evidence/audio_director/s02-silent-roads-review-1/verification.json) | 119.96 | -14.7 / -2.7 | Technical PASS; musical pending |
| mus_s02_muted_pulse_v01 | S02 / group B shared source | [OGG](../evidence/audio_director/s02-muted-pulse-review-2/mus_s02_muted_pulse_v01.ogg) · [proof](../evidence/audio_director/s02-muted-pulse-review-2/verification.json) | 79.84 | -17.3 / -3.8 | Technical PASS; musical pending |
| mus_s02_quiet_exhale_v01 | S02 / group B shared source | [OGG](../evidence/audio_director/s02-quiet-exhale-review-1/mus_s02_quiet_exhale_v01.ogg) · [proof](../evidence/audio_director/s02-quiet-exhale-review-1/verification.json) | 128.56 | -13.7 / -2.7 | Technical PASS; musical pending |

Готово 10 из 10 конечных кандидатов S01/S02. S00 в этот счет не входит.

30 проверок Godot для двух уникальных OGG: ../evidence/audio_director/unique-godot-review-2/.
Полный private cache-free Godot прогон: [93 pool + 30 unique-cue assertions, защищенные save-файлы и вход в игру](../evidence/audio_director/full-pools-godot-review-1/results.json). Все десять OGG дали реальный PCM; музыкальная приемка остается открытой.

## S00 opening audition proposals

These short windows support listening without downloading a full master first.
They are not selected first notes or authored/approved cues. The original WAVs
above remain unchanged and authoritative. Both seed manifest intervals are null.

| Source | Original window | Audition | Independent technical receipt | Selection |
| --- | --- | --- | --- | --- |
| Sparse Awakening vol.2 | 0–8 s | [Opening OGG](../evidence/audio_director/s00-opening-audition-1/audition.ogg) | [Exact-byte checks](../evidence/audio_director/s00-opening-audition-1/audition_checks.json) | Pending listening; note/motif unset |

Use `tools/audio_audition.py` for another explicit bounded window. Only actual
listening/edit selection may change the seed manifest; an audition PASS cannot.

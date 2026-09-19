# Audio provenance / license register

Status: **partially populated — exact source metadata still required for each source master where not explicitly known**.

Do not invent provenance. The current WAV package was supplied by the project owner as approved source material. Before release, each external/generated file must record generator/library/source, account/license basis if applicable, original filename, acquisition/generation date and attribution requirement.

## Current music package

All curated source masters are located under `assets/audio/music/` and mapped in `MUSIC_INDEX.md`.

| Field | Status |
|---|---|
| Owner-supplied source master | confirmed by repository intake |
| Exact generator/service per file | pending explicit metadata where not recorded |
| Runtime use | approved subject to final artifact/quality pass |
| Attribution | do not assume; verify source terms |
| Runtime format | source WAV retained; derived compressed runtime files TBD |

## Release requirement

Before RC, store a row per third-party/generated asset with source URL/service, date, original name, usage basis and required credit. For library SFX, also retain a local record/screenshot of the relevant license terms as required by the master Audio Direction.

# S00 offline listening review

Current page: `../evidence/audio_director/s00-listening-panel-1/listen.html`.
Generate only a new evidence family:

```sh
python3 -B tools/audio_review_panel.py --output docs/production/evidence/audio_director/NEW_FAMILY
```

The builder checks exact sealed audition/proposal/manifest identities and embeds
both OGGs. No master hydration/export is required. Proposals remain pending;
first note, motif, fade/cadence edit and musical acceptance require listening to
and checking the actual source. The 0–8 s excerpts cannot cover later notes.

Targeted checks: `python3 -B -m unittest -v test_audio_review_panel` from `tools/`,
and `node --test tools/test_audio_review_panel.js` from the repository root.
Real-browser checks use the installed Node Playwright package:

```sh
timeout --kill-after=5 120 node tools/validate_audio_review_panel.js --browser /ABSOLUTE/CHROME_HEADLESS_SHELL --page docs/production/evidence/audio_director/s00-listening-panel-1/listen.html --output docs/production/evidence/audio_director/NEW_BROWSER_FAMILY
```

The new environment's default Playwright CDN served a 195-byte HTML response,
not the archive. The official direct artifact succeeded:
`https://storage.googleapis.com/chrome-for-testing-public/151.0.7922.34/linux64/chrome-headless-shell-linux64.zip`.
Expected 120,231,126 bytes, storage content MD5 `792047b3c2625d7d4b0fc7c4fc67d7ad`;
ZIP members were fully read (CRC verification), extracted with short-write loops,
flushed/fsynced and byte counts checked. Actual version: 151.0.7922.34.
This is local transient tooling, not a shipped dependency or target-GPU evidence.

Sixteen actual browser checks and inspected mobile/desktop captures are in
`s00-listening-browser-2/`. The first mobile full-page capture omitted offscreen
paint after resizing; all mobile-width content is now put inside a bounded
capture viewport. Earlier family and validator bytes are preserved.
Every downloaded synthetic TEST proposal is removed with its private fixture.
The page performs no external requests, uploads, manifest writes or game binding.

# Pause and fade shell

## Implementation brief — 2026-10-03 UTC

Authority: technical baseline, QA checklist, InputManager ownership/evidence,
accepted player and settings evidence. Environment baseline stays authenticated
TCP X11 / Godot Vulkan Forward+; graphical checks run serially.

GameRoot owns an initially hidden Russian pause panel and transparent transition
overlay. Fresh Esc may open pause only for an active player in GAMEPLAY or
LIMITED_LOOK, while focused and unpaused. Empty root/UI/DISABLED/CINEMATIC do not
consume Esc to invent a sequence-skip policy. Cinematic pause/hold-to-skip arbitration
remains the future sequence controller's task; no hold duration is assigned here.

Pause remembers requested mode, delegates pause/capture to InputManager, and
exposes «Продолжить», «Настройки», «Выйти из игры». Settings remain responsive while
paused; Cancel/Apply returns to pause. Fresh Esc resumes; repeat events never toggle.
An external transition lock dismisses the panel and releases only its own pause
without overwriting that lock. No restart/main-menu routing or fake world is added.
Exit uses the existing App safe-exit path; the full SaveManager remains Milestone 2.

The fade overlay is presentation only: explicit awaited fade, overlap rejection,
completion/cancellation while paused, clear and optional Russian «Загрузка…».
It does not route scenes, save state or own input modes. The caller coordinates
input locking. Pointer/key events are blocked while the overlay is opaque/animating.
No automatic fade is attached to scene changes, especially the canonical seamless
Stage 14→15 transition. Default .25 s is technical API tuning, not authored timing.

Acceptance: actual controller frozen during pause; held-key/recapture boundary;
Settings nesting and Esc precedence; LIMITED_LOOK restoration and later locks;
external pause release; audio/service/file integrity; awaited fade completion,
overlap/cancel/free behavior and GUI blocking; clean import, existing input/player/
settings/debug/startup regressions; actual Russian pause/loading screenshots.
Actual accepted evidence follows.

## Accepted implementation — 2026-10-03 UTC

**PASS** on clean committed source `5d31141dce857cd551acf3084edcf198d8844322`.
See `evidence/pause_fade/README.md`; 183 tracked game/tools files unchanged.
Production player physically stops on Esc; actual GUI Cancel/Apply remains paused,
FOV updates to 96, mouse/Esc resume preserves mode and held-key/recapture guards.
Unsupported modes/focus are gated, later DISABLED and external resume survive.
Removing an owned pause root releases simulation without dereferencing freed UI.

Fade runs while paused, rejects overlap/invalid requests, resolves awaiters on
clear/free, and blocks real GUI/key dispatch when opaque. Clear updates visuals
before emitting cancellation; immediate cancel cannot leave an invisible input
blocker. Explicit zero-duration fades and loading text are tested. Cancellation
keeps current opacity; `clear()` is the explicit transparent cleanup. No scene
change or canonical finale fade is attached.

Actual 1920×1080 pause and 1280×720 loading images inspected (Settings Apply changes
the window to its chosen 1280×720). Root/eight-autoload startup and input/player/
settings/read-only-debug regressions pass. Settings reset/open now synchronously
replace unsubmitted numeric text, with a regression for defaults after typed text.
The pause fixture uses typed text rather than a same-frame programmatic Range
setter, which Godot can defer displaying. Audio and production files are preserved.
App safe-exit dispatch is exercised; full SaveGame remains the next milestone.

This initial shell layout is not final art or target-hardware certification.
Cinematic Esc/skip policy, main menu, full routing/save/playback and story worlds
remain separate. Exactly eight autoloads and canonical art/puzzle budgets remain.

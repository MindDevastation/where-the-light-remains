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
Acceptance remains pending until retained evidence.

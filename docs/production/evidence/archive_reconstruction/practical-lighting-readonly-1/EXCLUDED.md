Diagnostic run only. The selected archive_prologue_smoke legitimately writes its
owned physical checkpoint, so it is incompatible with this runner's read-only
physical-slot invariant despite all35 assertions passing. Retain FAIL unchanged.
Current split rerun assigns real S00/S01/S02 progression to test-owned private
slots and presentation/route/placement tests to protected read-only private slots.
No shipping behavior was changed to bypass that invariant. The later source
test correction avoids reading the old light after physical reload frees its
world; current validation uses a new evidence family.

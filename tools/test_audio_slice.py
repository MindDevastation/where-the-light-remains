#!/usr/bin/env python3
"""Guard actual source/acceptance boundaries before audio review exports."""
import argparse
import tempfile
import unittest
from unittest.mock import patch

import audio_slice as audio


class ExportProtection(unittest.TestCase):
    def _reject_manifest_edit(self, edit, error):
        original = audio.json.loads(audio.MANIFEST.read_text())
        edit(original)
        raw = audio.json.dumps(original)
        read = audio.Path.read_text
        with patch.object(audio.Path, 'read_text', lambda p, *a, **kw: raw if p == audio.MANIFEST else read(p, *a, **kw)):
            with self.assertRaisesRegex(ValueError, error):
                audio.load_manifest()

    def test_sealed_twelve_sources_are_current(self):
        manifest = audio.load_manifest()
        self.assertEqual(len(manifest['entries']), 12)
        self.assertEqual({e['stage'] for e in manifest['entries']}, {'S00', 'S01', 'S02'})

    def test_changed_source_cannot_reach_export(self):
        with patch.object(audio, 'digest', return_value='0' * 64):
            with self.assertRaisesRegex(ValueError, 'SHA mismatch'):
                audio.load_manifest()

    def test_unselected_s00_creates_no_output(self):
        with tempfile.TemporaryDirectory(dir=audio.REVIEW) as parent:
            destination = audio.Path(parent) / 'not_created'
            args = argparse.Namespace(operation='export', cue='mus_s00_archive_seed_v01', output=destination)
            with self.assertRaisesRegex(ValueError, 'selection is pending'):
                audio.execute(args)
            self.assertFalse(destination.exists())

    def test_runtime_and_masters_cannot_be_output(self):
        for destination in [audio.ROOT / 'game/audio/not_created', audio.ROOT / 'assets/audio/not_created']:
            args = argparse.Namespace(operation='export', cue='mus_s01_archive_awakening_v01', output=destination)
            with self.assertRaisesRegex(ValueError, 'outside shipping'):
                audio.execute(args)
            self.assertFalse(destination.exists())

    def test_existing_review_folder_is_never_overwritten(self):
        with tempfile.TemporaryDirectory(dir=audio.REVIEW) as parent:
            sentinel = audio.Path(parent) / 'keep.txt'
            sentinel.write_bytes(b'owner evidence')
            args = argparse.Namespace(operation='export', cue='mus_s01_archive_awakening_v01', output=audio.Path(parent))
            with self.assertRaises(FileExistsError):
                audio.execute(args)
            self.assertEqual(sentinel.read_bytes(), b'owner evidence')

    def test_manifest_cannot_misstate_recipe_or_source_duration(self):
        self._reject_manifest_edit(lambda m: m['entries'][0]['compression'].update(quality=0), 'encoding recipe')
        self._reject_manifest_edit(lambda m: m['entries'][0].update(source_duration_seconds=1), 'duration differs')

    def test_non_finite_or_unsafe_peak_ceiling_is_rejected(self):
        for value in [float('nan'), float('inf'), 0]:
            self._reject_manifest_edit(lambda m: m.update(candidate_true_peak_ceiling_dbtp=value), 'safety ceiling')


if __name__ == '__main__':
    unittest.main()

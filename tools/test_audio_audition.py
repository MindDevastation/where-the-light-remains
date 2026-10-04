#!/usr/bin/env python3
"""Audition windows must never become a seed selection or shipping overwrite."""
import argparse
import copy
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import audio_audition as audition


class AuditionProtection(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = audition.audio.load_manifest()
        cls.seed = cls.manifest['entries'][0]

    def test_opening_window_preserves_blocked_seed_recipe(self):
        before = copy.deepcopy(self.seed)
        audition.parameters(self.seed, 0, 8, .02, .25)
        self.assertEqual(self.seed, before)
        self.assertIsNone(self.seed['interval_seconds'])
        self.assertEqual(self.seed['interval_status'], 'BLOCKED_FIRST_NOTE_AND_MOTIF_SELECTION')

    def test_other_stage_sources_are_not_reexported(self):
        with self.assertRaisesRegex(ValueError, 'two S00'):
            audition.parameters(self.manifest['entries'][2], 0, 8, .02, .25)

    def test_non_finite_or_outside_or_overbudget_windows_are_rejected(self):
        for start, end in [(float('nan'), 8), (0, float('inf')), (-1, 8), (0, .3),
                           (0, 21), (168, 169), (8, 7)]:
            with self.subTest(start=start, end=end), self.assertRaises(ValueError):
                audition.parameters(self.seed, start, end, .02, .25)

    def test_overlapping_negative_or_non_finite_fades_are_rejected(self):
        for fades in [(-.1, .1), (.1, float('nan')), (5, 5)]:
            with self.subTest(fades=fades), self.assertRaises(ValueError):
                audition.parameters(self.seed, 0, 8, *fades)

    def test_shipping_and_original_masters_are_forbidden_destinations(self):
        for path in [audition.ROOT / 'game/audio/forbidden', audition.ROOT / 'assets/audio/forbidden', audition.REVIEW]:
            with self.subTest(path=path), self.assertRaisesRegex(ValueError, 'outside shipping'):
                audition.destination(path)

    def test_existing_evidence_is_immutable(self):
        with tempfile.TemporaryDirectory() as private:
            folder = Path(private) / 'keep'
            folder.mkdir()
            owner = folder / 'owner.txt'
            owner.write_bytes(b'Existing evidence')
            with patch.object(audition, 'REVIEW', Path(private)), self.assertRaises(FileExistsError):
                audition.destination(folder)
            self.assertEqual(owner.read_bytes(), b'Existing evidence')

    def test_failed_encoder_keeps_diagnostics_but_never_accepts_or_changes_seed(self):
        with tempfile.TemporaryDirectory() as private:
            folder = Path(private) / 'failed'
            args = argparse.Namespace(cue=self.seed['cue_id'], start=0, end=8,
                                      fade_in=.02, fade_out=.25, output=folder)
            before = audition.audio.MANIFEST.read_bytes()
            with patch.object(audition, 'REVIEW', Path(private)), \
                    patch.object(audition.audio, 'command', side_effect=RuntimeError('bounded encoder failure')), \
                    self.assertRaisesRegex(RuntimeError, 'encoder failure'):
                audition.execute(args)
            record = json.loads((folder / 'results.json').read_text())
            self.assertEqual(record['status'], 'FAIL')
            self.assertEqual(record['acceptance'], audition.ACCEPTANCE)
            self.assertFalse((folder / 'audition.ogg').exists())
            self.assertFalse((folder / 'proposal.json').exists())
            self.assertFalse((folder / 'verification.json').exists())
            self.assertEqual(audition.audio.MANIFEST.read_bytes(), before)


if __name__ == '__main__':
    unittest.main()

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

    def test_audition_cannot_receive_normal_export_verification(self):
        # Real audition metadata remains a different acceptance class, even
        # when its format/measurement technically passed.
        record = json.loads((audition.REVIEW / 's00-opening-audition-1/results.json').read_text())
        with tempfile.TemporaryDirectory() as private:
            folder = Path(private)
            (folder / 'results.json').write_text(json.dumps(record))
            with self.assertRaisesRegex(ValueError, 'technically passed review export'):
                audition.audio.verify_family(folder, self.manifest)
            self.assertFalse((folder / 'verification.json').exists())

    def test_opening_audition_does_not_unlock_original_seed_export(self):
        with tempfile.TemporaryDirectory() as private:
            folder = Path(private) / 'never_created'
            args = argparse.Namespace(operation='export', cue=self.seed['cue_id'], output=folder)
            with patch.object(audition.audio, 'REVIEW', Path(private)), \
                    self.assertRaisesRegex(ValueError, 'selection is pending'):
                audition.audio.execute(args)
            self.assertFalse(folder.exists())

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

    def test_completed_receipt_is_persisted_and_read_back_without_partial_file(self):
        with tempfile.TemporaryDirectory() as private:
            path = Path(private) / 'results.json'
            audition.write_receipt(path, {'status': 'RUNNING'})
            audition.write_receipt(path, {'status': 'PASS', 'command_count': 4})
            self.assertEqual(json.loads(path.read_text()), {'status': 'PASS', 'command_count': 4})
            self.assertEqual(list(path.parent.iterdir()), [path])

    def test_receipt_read_back_mismatch_cannot_report_success(self):
        with tempfile.TemporaryDirectory() as private:
            path = Path(private) / 'results.json'
            with patch.object(Path, 'read_bytes', return_value=b'stale receipt'), \
                    self.assertRaisesRegex(RuntimeError, 'read-back mismatch'):
                audition.write_receipt(path, {'status': 'PASS'})
            self.assertFalse(path.with_name('results.json.pending').exists())

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

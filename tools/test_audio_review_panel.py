#!/usr/bin/env python3
"""Seal/identity guards for the existing auditions; no master re-export."""
import copy
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import audio_review_panel as review


class ReviewProtection(unittest.TestCase):
    def test_catalog_uses_only_two_sealed_unselected_excerpts(self):
        data, _ = review.catalog()
        self.assertEqual(len(data['candidates']), 2)
        for candidate in data['candidates']:
            self.assertIsNone(candidate['note_identity'])
            self.assertIsNone(candidate['four_note_motif'])
            self.assertFalse(candidate['shipping_binding'])
            self.assertTrue(candidate['media_data_url'].startswith('data:audio/ogg;base64,'))

    def test_failed_family_cannot_be_displayed_as_accepted(self):
        with patch.object(review, 'FAMILIES', ('s00-alternate-opening-audition-1',)), \
                self.assertRaisesRegex(ValueError, 'Incomplete or unaccepted'):
            review.catalog()

    def test_selected_or_mismatched_manifest_source_is_rejected(self):
        manifest = json.loads(review.audition.audio.MANIFEST.read_text())
        for field, value in [('interval_seconds', [0, 1]), ('source_sha256', 'f' * 64)]:
            altered = copy.deepcopy(manifest)
            altered['entries'][0][field] = value
            with self.subTest(field=field), tempfile.TemporaryDirectory() as private:
                path = Path(private) / 'manifest.json'
                path.write_text(json.dumps(altered))
                with patch.object(review.audition.audio, 'MANIFEST', path), self.assertRaises(ValueError):
                    review.catalog()

    def test_changed_sealed_bytes_are_rejected(self):
        real = review.audition.audio.digest
        def altered(path):
            return '0' * 64 if path.name == 'audition.ogg' else real(path)
        with patch.object(review.audition.audio, 'digest', side_effect=altered), \
                self.assertRaisesRegex(ValueError, 'Sealed audition bytes'):
            review.catalog()

    def test_existing_review_and_shipping_destinations_cannot_be_overwritten(self):
        for path in [review.audition.REVIEW / review.FAMILIES[0], review.ROOT / 'game/audio/review']:
            with self.subTest(path=path), self.assertRaises((FileExistsError, ValueError)):
                review.build(path)


if __name__ == '__main__':
    unittest.main()

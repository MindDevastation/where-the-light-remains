#!/usr/bin/env python3
"""Guard actual source/acceptance boundaries before audio review exports."""
import argparse
import tempfile
import unittest
import copy
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
        with tempfile.TemporaryDirectory() as parent:
            destination = audio.Path(parent) / 'not_created'
            args = argparse.Namespace(operation='export', cue='mus_s00_archive_seed_v01', output=destination)
            with patch.object(audio, 'REVIEW', audio.Path(parent)), self.assertRaisesRegex(ValueError, 'selection is pending'):
                audio.execute(args)
            self.assertFalse(destination.exists())

    def test_runtime_and_masters_cannot_be_output(self):
        for destination in [audio.ROOT / 'game/audio/not_created', audio.ROOT / 'assets/audio/not_created']:
            args = argparse.Namespace(operation='export', cue='mus_s01_archive_awakening_v01', output=destination)
            with self.assertRaisesRegex(ValueError, 'outside shipping'):
                audio.execute(args)
            self.assertFalse(destination.exists())

    def test_existing_review_folder_is_never_overwritten(self):
        with tempfile.TemporaryDirectory() as parent:
            folder = audio.Path(parent) / 'family'
            folder.mkdir()
            sentinel = folder / 'keep.txt'
            sentinel.write_bytes(b'owner evidence')
            args = argparse.Namespace(operation='export', cue='mus_s01_archive_awakening_v01', output=folder)
            with patch.object(audio, 'REVIEW', audio.Path(parent)), self.assertRaises(FileExistsError):
                audio.execute(args)
            self.assertEqual(sentinel.read_bytes(), b'owner evidence')

    def test_manifest_cannot_misstate_recipe_or_source_duration(self):
        self._reject_manifest_edit(lambda m: m['entries'][0]['compression'].update(quality=0), 'encoding recipe')
        self._reject_manifest_edit(lambda m: m['entries'][0].update(source_duration_seconds=1), 'duration differs')

    def test_non_finite_or_unsafe_peak_ceiling_is_rejected(self):
        for value in [float('nan'), float('inf'), 0]:
            self._reject_manifest_edit(lambda m: m.update(candidate_true_peak_ceiling_dbtp=value), 'safety ceiling')

    def test_timed_out_child_preserves_diagnostics(self):
        with tempfile.TemporaryDirectory() as parent:
            output = audio.Path(parent) / 'bounded.log'
            failure = audio.subprocess.TimeoutExpired(['ffmpeg'], 45, output=b'partial progress\n')
            with patch.object(audio.subprocess, 'run', side_effect=failure):
                with self.assertRaisesRegex(RuntimeError, 'Command failed'):
                    audio.command(['ffmpeg'], output)
            self.assertEqual(output.read_bytes(), b'partial progress\n')
            record = audio.json.loads((output.parent / 'commands.jsonl').read_text())
            self.assertTrue(record['timed_out'])
            self.assertEqual(record['stdout_sha256'], audio.digest(output))

    def test_tampered_derivative_cannot_receive_verification(self):
        original = audio.json.loads((audio.REVIEW / 's02-unique-review-1/results.json').read_text())
        manifest = audio.load_manifest()
        with tempfile.TemporaryDirectory() as parent:
            folder = audio.Path(parent).resolve()
            result = copy.deepcopy(original)
            record = result['records'][0]
            media = folder / (record['cue_id'] + '.ogg')
            media.write_bytes((audio.ROOT / record['derivative_path']).read_bytes() + b'tampered')
            record['derivative_path'] = media.name
            result['tool_sha256'] = audio.digest(audio.Path(audio.__file__))
            (folder / 'results.json').write_text(audio.json.dumps(result))
            with patch.object(audio, 'ROOT', folder), self.assertRaisesRegex(ValueError, 'Derivative path/SHA'):
                audio.verify_family(folder, manifest)
            self.assertFalse((folder / 'verification.json').exists())

    def test_existing_verification_receipt_remains_immutable(self):
        folder = audio.REVIEW / 's02-unique-review-1'
        receipt = folder / 'verification.json'
        before = receipt.read_bytes()
        with self.assertRaises(FileExistsError):
            audio.verify_family(folder, audio.load_manifest())
        self.assertEqual(receipt.read_bytes(), before)

    def test_intermediate_media_cannot_receive_verification(self):
        with tempfile.TemporaryDirectory() as parent:
            folder = audio.Path(parent).resolve()
            (folder / 'mus_s01_fixture_v01.attempt0.ogg').write_bytes(b'unaccepted partial')
            with self.assertRaisesRegex(ValueError, 'intermediate media'):
                audio.verify_family(folder, audio.load_manifest())
            self.assertFalse((folder / 'verification.json').exists())

    def test_command_trace_recovers_from_stale_file_replacement(self):
        with tempfile.TemporaryDirectory() as parent:
            folder = audio.Path(parent)
            completed = audio.subprocess.CompletedProcess(['fixture'], 0, b'actual stdout\n')
            with patch.object(audio.subprocess, 'run', return_value=completed):
                audio.command(['fixture', 'first'], folder / 'first.log')
                (folder / 'commands.jsonl').write_text('')
                audio.command(['fixture', 'second'], folder / 'second.log')
            records = [audio.json.loads(r) for r in (folder / 'commands.jsonl').read_text().splitlines()]
            self.assertEqual([r['command'][-1] for r in records], ['first', 'second'])
            for record in records:
                self.assertEqual(record['stdout_sha256'], audio.digest(folder / record['stdout_file']))


if __name__ == '__main__':
    unittest.main()

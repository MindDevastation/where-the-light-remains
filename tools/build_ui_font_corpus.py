#!/usr/bin/env python3
"""Rebuild the exact current Cyrillic source corpus without changing game copy."""
import hashlib
import json
from pathlib import Path
import re
import unicodedata


def build(root):
    rows = []
    points = set(range(32, 127)) | set(range(0x410, 0x450)) | {0x401, 0x451}
    for source in sorted((root / 'game').rglob('*')):
        if not source.is_file() or source.suffix not in {'.gd', '.tscn', '.tres'} or \
                any(part in source.parts for part in ['.godot', 'tests', 'fonts']):
            continue
        for match in re.finditer(r'"((?:\\.|[^"\\])*)"', source.read_text()):
            value = match[1]
            if not re.search('[\u0400-\u04ff]', value):
                continue
            try:
                value = json.loads('"' + value + '"')
            except json.JSONDecodeError:
                continue
            values = {ord(char) for char in value if unicodedata.category(char)[0] != 'C'}
            points |= values
            rows.append({'path': source.relative_to(root).as_posix(),
                         'text_sha256': hashlib.sha256(value.encode()).hexdigest(),
                         'codepoints': sorted(values)})
    return {'scope': 'Non-test source quoted Cyrillic strings plus basic Latin/digits/punctuation and full Russian alphabet. Development overlay included. No new shipping copy.',
            'source_string_count': len(rows), 'codepoints': sorted(points), 'source_strings': rows,
            'fallback_specimen_codepoints': [0x2192, 0x23ce, 0x2713, 0x231b, 0x25a0]}


if __name__ == '__main__':
    root = Path(__file__).resolve().parents[1]
    corpus = build(root)
    target = root / 'game/tests/data/ui_font_corpus.json'
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(corpus, indent=2) + '\n')
    print(json.dumps({'source_strings': corpus['source_string_count'],
                      'unique_codepoints': len(corpus['codepoints'])}))

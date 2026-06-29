#!/usr/bin/env python3

import hashlib
import json
import os
import zipfile

SOURCE_DIR  = os.path.dirname(os.path.abspath(__file__))
OUTPUT_FILE = os.path.join(SOURCE_DIR, 'hashes.json')


def md5_of_stream(stream, chunk: int = 65536) -> str:
    h = hashlib.md5()
    while True:
        buf = stream.read(chunk)
        if not buf:
            break
        h.update(buf)
    return h.hexdigest()


hashes: dict[str, str] = {}
zips = sorted(f for f in os.listdir(SOURCE_DIR) if f.lower().endswith('.zip'))

if not zips:
    print('No .zip files found.')
    raise SystemExit

for zip_name in zips:
    folder = os.path.splitext(zip_name)[0]
    print(f'Now > {zip_name}...')

    with zipfile.ZipFile(os.path.join(SOURCE_DIR, zip_name)) as zf:
        for entry in zf.infolist():
            if entry.filename.endswith('/'):
                continue

            path = entry.filename.replace('\\', '/')
            if not path.startswith(f'{folder}/'):
                path = f'{folder}/{path}'

            with zf.open(entry) as stream:
                hashes[path] = md5_of_stream(stream)

with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
    json.dump(hashes, f, indent=2, ensure_ascii=False)

print(f'\nDone > hashes.json  ({len(hashes)} entries)')
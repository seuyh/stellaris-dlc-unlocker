#!/usr/bin/env python3

import urllib.request
import json
import os

REPO    = 'seuyh/stellaris-dlc-unlocker'
FOLDERS = ['creamapi_steam_files', 'creamapi_launcher_files']
TOKEN   = os.environ.get('GITHUB_TOKEN', '')


def gh_get(url: str) -> list:
    req = urllib.request.Request(url, headers={
        'User-Agent': 'manifest-generator/1.0',
        **({'Authorization': f'Bearer {TOKEN}'} if TOKEN else {})
    })
    with urllib.request.urlopen(req, timeout=10) as r:
        return json.loads(r.read())


for folder in FOLDERS:
    url   = f'https://api.github.com/repos/{REPO}/contents/{folder}'
    items = gh_get(url)

    manifest = [
        {'name': item['name'], 'sha': item['sha']}
        for item in items
        if item['type'] == 'file' and item['name'] != 'manifest.json'
    ]

    out_dir  = os.path.join(os.path.dirname(__file__), folder)
    out_file = os.path.join(out_dir, 'manifest.json')
    os.makedirs(out_dir, exist_ok=True)

    with open(out_file, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)

    print(f'[{folder}] → {len(manifest)} files → {out_file}')

print('Done.')
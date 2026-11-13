"""Validate the deployable web package; optionally compare its public content."""
import argparse, hashlib, json, re, subprocess
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--url');args=p.parse_args()
root=Path(__file__).resolve().parent.parent
def public_get(path):
    return subprocess.run(['curl','--fail','--silent','--show-error','--retry','2','--max-time','90',args.url.rstrip('/')+'/'+path],check=True,capture_output=True).stdout
manifest=(root/'lib/content_manifest.dart').read_text()
entries=re.findall(r'[\"\']([^\"\']+)[\"\']:\s*\(\s*bytes:\s*(\d+),\s*hash:\s*[\"\']([0-9a-f]{64})[\"\']',manifest)
assert len(entries)==12, 'Expected 12 versioned lessons'
for lesson,size,digest in entries:
    rel=f'content/{lesson}.v1.json'
    data=(root/rel).read_bytes()
    assert len(data)==int(size) and hashlib.sha256(data).hexdigest()==digest, rel
    body=json.loads(data)
    assert body['id']==lesson and body['version']==1 and len(body['questions'])==3
    assert body['example'] and body['goal']
    for q in body['questions']:
        if q['choices']:
            assert 0<=q['answer']<len(q['choices']) and len(q['feedback'])==len(q['choices'])
    assert (root/'build/web'/rel).read_bytes()==data
    if args.url:
        assert public_get(rel)==data, 'Public package mismatch: '+rel
worker=(root/'build/web/offline.js').read_text()
files=json.loads(re.search(r'const files = (\[.*?\])\.map',worker).group(1))
assert 'index.html' in files and 'main.dart.js' in files
assert not any(f.startswith('content/') for f in files), 'Optional content must not be preloaded'
for name in files:
    assert '..' not in Path(name).parts and (root/'build/web'/name).is_file(), name
for forbidden in ['.env','key.properties','local.properties','schema.sql']:
    assert not list((root/'build/web').rglob(forbidden)), forbidden
if args.url:
    for name in ['','offline.js','main.dart.js','manifest.json','revision-docente.html']:
        data=public_get(name)
        if name in ['offline.js','main.dart.js']:
            assert data==(root/'build/web'/name).read_bytes(), name
print(f'PASS: 12 lecciones, 36 ejercicios, {len(files)} recursos offline y huellas SHA-256'+(' verificadas públicamente.' if args.url else '.'))

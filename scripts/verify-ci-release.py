#!/usr/bin/env python3
"""Verify retained CI assets before executing the signed CLI without credentials."""
import hashlib
import json
import os
from pathlib import Path
import stat
import subprocess
import sys
import tempfile
import zipfile

assets, proof_path = map(Path, sys.argv[1:])
proof = json.loads(proof_path.read_text())
assert proof['sourceCommit'] == os.environ['EXPECTED_SHA']
assert proof['tag'] == os.environ['EXPECTED_TAG']
assert proof['dryRun'] == (os.environ['EXPECTED_DRY'] == 'true')
assert proof['repository'] == 'openclaw/Swabble'
assert proof['defaultBranch'] == 'main'
assert proof['tag'] == 'v' + proof['version']
assert (proof['tagObject'] is None) == proof['dryRun']
archive = assets / 'swabble-macos.zip'
assert sorted(p.name for p in assets.iterdir()) == sorted([
    archive.name, 'SHA256SUMS', 'release-inventory.json'])
assert all(p.is_file() and not p.is_symlink() for p in assets.iterdir())
digest = hashlib.sha256(archive.read_bytes()).hexdigest()
assert (assets / 'SHA256SUMS').read_text() == f'{digest}  {archive.name}\n'
expected = dict(schemaVersion=2, **proof, identifier='com.steipete.swabble',
    teamIdentifier='FWJYW4S8P8', architectures=['arm64', 'x86_64'],
    assets=[dict(name=archive.name, sha256=digest, size=archive.stat().st_size)])
assert json.loads((assets / 'release-inventory.json').read_text()) == expected
with tempfile.TemporaryDirectory() as directory:
    with zipfile.ZipFile(archive) as zipped:
        assert zipped.namelist() == ['swabble']
        info = zipped.infolist()[0]
        assert stat.S_ISREG(info.external_attr >> 16), 'Archive member must be a regular file'
        zipped.extractall(directory)
    binary = Path(directory) / 'swabble'
    binary.chmod(0o755)
    subprocess.run(['scripts/verify-macos-binary.sh', str(binary), proof['version']], check=True)
    subprocess.run([str(binary), '--help'], check=True)
    assert subprocess.check_output([str(binary), 'health'], text=True).strip() == 'ok'
print('Verified retained inventory, signature, notarization, version and native CLI smoke')

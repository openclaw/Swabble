#!/usr/bin/env python3
"""Check the shared release caller and its credential-free adapters."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent
WORKFLOW = json.loads(subprocess.check_output([
    'ruby', '-rpsych', '-rjson', '-e',
    'puts JSON.generate(Psych.safe_load(File.read(ARGV[0])))',
    str(ROOT / '.github/workflows/release.yml')], text=True))
CALLER = WORKFLOW['jobs']['release']
BINARY = CALLER['with']['binary-name']
VERSION = WORKFLOW['true']['workflow_dispatch']['inputs']['version']['default']


class ReleaseCallerTests(unittest.TestCase):
    def test_shared_boundary(self):
        self.assertEqual(CALLER['uses'], 'openclaw/release-workflows/.github/workflows/release-swift-cli.yml@v1')
        for name in ['include-helper', 'include-linux', 'require-resource-bundles']:
            self.assertIs(CALLER['with'][name], False)
        self.assertIs(CALLER['with']['require-signed-tag'], True)
        self.assertEqual(CALLER['with']['ci-check-events'], '["push"]')
        self.assertEqual(CALLER['with']['repository-type'], 'openclaw')
        self.assertEqual(CALLER['with']['binary-identifier'], 'com.steipete.' + BINARY)
        self.assertEqual(CALLER['with']['macos-archive-name'], BINARY + '-macos.zip')
        self.assertEqual(CALLER['with']['macos-runner'], 'xcode-27')
        self.assertEqual(CALLER['with']['verify-arm64-runner'], 'xcode-27')
        self.assertEqual(CALLER['with']['minimum-macos-version'], 26)
        self.assertTrue(WORKFLOW['true']['workflow_dispatch']['inputs']['dry_run']['default'])
        self.assertEqual(CALLER['needs'], 'policy')
        for obsolete in ['release-source.cjs', 'release-source.test.cjs', 'verify-ci-release.py',
                         'test-release-keychain.py', 'test-release-architecture.sh']:
            self.assertFalse((ROOT / 'scripts' / obsolete).exists(), obsolete)

    def test_dispatch_policy(self):
        source = WORKFLOW['jobs']['policy']['steps'][0]['run']
        for event, dry, expected in [('workflow_dispatch', 'true', 0),
                                     ('workflow_dispatch', 'false', 1), ('push', '', 0)]:
            result = subprocess.run(['bash', '-c', source], env=dict(os.environ, EVENT=event, DRY_RUN=dry),
                                    capture_output=True)
            self.assertEqual(result.returncode, expected)

    def test_version_metadata(self):
        script = str(ROOT / 'scripts/check-release-version.sh')
        self.assertEqual(subprocess.run([script, 'v' + VERSION], capture_output=True).returncode, 0)
        self.assertNotEqual(subprocess.run([script, 'v999.0.0'], capture_output=True).returncode, 0)

    def test_output_directory_adapter(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'scripts').mkdir()
            (root / 'tools').mkdir()
            shutil.copy(ROOT / 'scripts/build-release.sh', root / 'scripts/build-release.sh')
            builder = root / 'scripts/build-macos-universal.sh'
            builder.write_text('#!/bin/bash\nset -eu\n[[ "$MACOSX_DEPLOYMENT_TARGET" == 26.0 ]]\nprintf "synthetic" > "$1"\n')
            builder.chmod(0o755)
            xcode = root / 'tools/xcodebuild'
            xcode.write_text('#!/bin/bash\necho "Xcode ${TEST_XCODE_VERSION:-27.0}"\n')
            xcode.chmod(0o755)
            output = root / 'output with spaces'
            subprocess.run([str(root / 'scripts/build-release.sh')], check=True,
                           env=dict(os.environ, OUTPUT_DIR=str(output), PATH=str(root / 'tools') + ':' + os.environ['PATH']))
            binary = output / BINARY
            self.assertEqual(binary.read_text(), 'synthetic')
            self.assertTrue(os.access(binary, os.X_OK))
            result = subprocess.run([str(root / 'scripts/build-release.sh')], capture_output=True,
                                    env=dict(os.environ, OUTPUT_DIR=str(output), TEST_XCODE_VERSION='26.0',
                                             PATH=str(root / 'tools') + ':' + os.environ['PATH']))
            self.assertNotEqual(result.returncode, 0)


if __name__ == '__main__':
    unittest.main()

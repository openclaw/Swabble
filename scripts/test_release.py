import importlib.util
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('release', Path(__file__).with_name('release.py'))
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)


class ReleaseMetadataTests(unittest.TestCase):
    def test_notes_preserve_credits_and_stop_at_next_release(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'CHANGELOG.md').write_text(
                '# Changelog\n\n## Unreleased\n\n- Future work\n\n'
                '## 0.1.0 - 2026-09-13\n\n**Highlights:** First release.\n\n'
                '- Fixed unreadable config. (#10, thanks @SebTardif)\n\n'
                '## 0.0.9 - 2026-09-12\n\n- Old work\n')
            self.assertEqual(release.notes('0.1.0', root),
                             '**Highlights:** First release.\n\n'
                             '- Fixed unreadable config. (#10, thanks @SebTardif)\n')
            with self.assertRaises(ValueError):
                release.notes('0.1', root)

    def test_duplicate_or_empty_release_fails_closed(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for contents in ('## 0.1.0 - 2026-09-13\n',
                             '## 0.1.0 - 2026-09-13\n- A\n## 0.1.0 - 2026-09-14\n- B\n'):
                (root / 'CHANGELOG.md').write_text(contents)
                with self.assertRaises(ValueError):
                    release.notes('0.1.0', root)

    def test_version_requires_one_unambiguous_semver(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / 'Sources/swabble/Version.swift'
            source.parent.mkdir(parents=True)
            for contents in ('static let current = "0.1"',
                             'static let current = "0.1.0"\nstatic let current = "9.9.9"'):
                source.write_text(contents)
                with self.assertRaises(ValueError):
                    release.version(root)
            source.write_text('enum SwabbleVersion {\n    static let current = "0.1.0"\n}\n')
            self.assertEqual(release.version(root), '0.1.0')


if __name__ == '__main__':
    unittest.main()

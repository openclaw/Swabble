#!/usr/bin/env python3
"""Version metadata and changelog extraction for the local release scripts."""
import argparse
from pathlib import Path
import plistlib
import re

ROOT = Path(__file__).resolve().parent.parent


def version(root=ROOT):
    source = (root / "Sources/swabble/Version.swift").read_text()
    matches = re.findall(r'^\s*static let current = "([0-9]+\.[0-9]+\.[0-9]+)"\s*$', source, re.M)
    if len(matches) != 1:
        raise ValueError("Version.swift must declare exactly one release version")
    return matches[0]


def notes(release_version, root=ROOT):
    text = (root / "CHANGELOG.md").read_text()
    headings = list(re.finditer(r'^## (.+)$', text, re.M))
    matches = [i for i, heading in enumerate(headings)
               if re.fullmatch(re.escape(release_version) + r' - \d{4}-\d{2}-\d{2}', heading[1])]
    if len(matches) != 1:
        raise ValueError("Expected exactly one dated changelog section for " + release_version)
    index = matches[0]
    end = headings[index + 1].start() if index + 1 < len(headings) else len(text)
    section = text[headings[index].end():end].strip()
    if not section or not any(line.startswith('- ') for line in section.splitlines()):
        raise ValueError("Release notes must contain changelog entries")
    return section + '\n'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    sub.add_parser('version')
    extract = sub.add_parser('notes')
    extract.add_argument('version')
    extract.add_argument('output', type=Path)
    plist = sub.add_parser('plist')
    plist.add_argument('output', type=Path)
    args = parser.parse_args()
    if args.command == 'version':
        print(version())
    elif args.command == 'notes':
        args.output.write_text(notes(args.version))
    else:
        args.output.write_bytes(plistlib.dumps({
            'CFBundleIdentifier': 'com.steipete.swabble',
            'CFBundleName': 'swabble',
            'CFBundleVersion': version(),
            'CFBundleShortVersionString': version(),
            'LSMinimumSystemVersion': '26.0',
            'NSMicrophoneUsageDescription': 'Swabble listens for wake words and transcribes speech locally.',
            'NSSpeechRecognitionUsageDescription': 'Swabble transcribes speech on this Mac.',
        }, fmt=plistlib.FMT_XML))


if __name__ == '__main__':
    main()

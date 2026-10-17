#!/usr/bin/env bash
# Credential-free source metadata checks run by the archetype on Linux.
set -euo pipefail
[[ $# == 1 ]] || { echo "Usage: $0 vX.Y.Z" >&2; exit 2; }
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
python3 - "$1" <<'CHECK'
from pathlib import Path
import re
import sys
version = sys.argv[1].removeprefix('v')
assert re.fullmatch(r'[0-9]+\.[0-9]+\.[0-9]+', version), 'Expected stable release version'
sys.path.insert(0, 'scripts')
from release import version as source_version, notes
assert source_version() == version, 'Source version mismatch'
notes(version)
CHECK

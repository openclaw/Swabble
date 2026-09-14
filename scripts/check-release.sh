#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/release-config.sh
source "$ROOT/scripts/release-config.sh"
TAG=${1:-"v$MARKETING_VERSION"}
[[ "$TAG" == "v$MARKETING_VERSION" ]] || { echo "Tag does not match Version.swift" >&2; exit 1; }
work="$(mktemp -d "${TMPDIR:-/tmp}/swabble-preflight.XXXXXX")"
trap 'rm -rf "$work"' EXIT
"$ROOT/scripts/extract-release-notes.sh" "$MARKETING_VERSION" "$work/notes.md"
python3 "$ROOT/scripts/release.py" plist "$work/Info.plist"
plutil -lint "$work/Info.plist"
echo "Release metadata agrees for $TAG"

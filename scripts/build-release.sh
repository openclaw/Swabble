#!/usr/bin/env bash
# Adapt the local universal builder to the shared workflow's OUTPUT_DIR contract.
set -euo pipefail
: "${OUTPUT_DIR:?OUTPUT_DIR is required}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[[ "$(xcodebuild -version | head -n 1)" == 'Xcode 27'* ]] || { echo 'Xcode 27 is required for release builds' >&2; exit 1; }
export MACOSX_DEPLOYMENT_TARGET=26.0
mkdir -p "$OUTPUT_DIR"
"$ROOT/scripts/build-macos-universal.sh" "$OUTPUT_DIR/swabble"
chmod +x "$OUTPUT_DIR/swabble"

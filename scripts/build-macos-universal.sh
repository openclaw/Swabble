#!/usr/bin/env bash
# Adapted from remindctl's local universal builder.
set -euo pipefail
[[ $# == 1 ]] || { echo "Usage: $0 <output-binary>" >&2; exit 2; }
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
OUTPUT="$1"
mkdir -p "$(dirname "$OUTPUT")"
work="$(mktemp -d "${TMPDIR:-/tmp}/swabble-build.XXXXXX")"
trap 'rm -rf "$work"' EXIT
python3 scripts/release.py plist "$work/Info.plist"
binaries=()
for arch in arm64 x86_64; do
  args=(-c release --product swabble --arch "$arch" --scratch-path "$ROOT/.build/$arch"
    -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __info_plist -Xlinker "$work/Info.plist")
  swift build "${args[@]}" --disable-automatic-resolution
  bin_path="$(swift build "${args[@]}" --show-bin-path)"
  binaries+=("$bin_path/swabble")
done
lipo -create "${binaries[@]}" -output "$OUTPUT"
for arch in arm64 x86_64; do
  lipo "$OUTPUT" -verify_arch "$arch"
done
lipo -info "$OUTPUT"

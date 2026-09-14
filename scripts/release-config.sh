#!/usr/bin/env bash
# shellcheck disable=SC2034 # Constants are consumed by scripts that source this file.

RELEASE_REPOSITORY="openclaw/Swabble"
RELEASE_DEFAULT_BRANCH="main"
RELEASE_ARTIFACT="swabble-macos.zip"
RELEASE_CHECKSUMS="SHA256SUMS"
RELEASE_INVENTORY="release-inventory.json"
RELEASE_IDENTIFIER="com.steipete.swabble"
RELEASE_TEAM_ID="FWJYW4S8P8"
RELEASE_SIGNING_IDENTITY="Developer ID Application: OpenClaw Foundation (FWJYW4S8P8)"
RELEASE_ARCHITECTURES="arm64 x86_64"
RELEASE_DESIGNATED_REQUIREMENT='identifier "com.steipete.swabble" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] exists and certificate leaf[field.1.2.840.113635.100.6.1.13] exists and certificate leaf[subject.OU] = "FWJYW4S8P8"'

MARKETING_VERSION="$(python3 "$ROOT/scripts/release.py" version)"

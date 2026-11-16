---
title: Install
description: "Install the signed macOS release or build Swabble from source."
---

# Install

Swabble requires macOS 26 and the Speech.framework assets available on the target Mac. Building from source also requires Swift 6.2 or newer.

## Download a release

[GitHub Releases](https://github.com/openclaw/Swabble/releases/latest) provides `swabble-macos.zip`, a Developer ID-signed and notarized universal binary for Apple Silicon and Intel Macs, plus `SHA256SUMS`, `ASSET-INVENTORY.json`, `SIGNING-MANIFEST.json`, and `RELEASE-NOTES.md`.

```bash
for asset in swabble-macos.zip SHA256SUMS ASSET-INVENTORY.json SIGNING-MANIFEST.json RELEASE-NOTES.md; do
  curl -fLO "https://github.com/openclaw/Swabble/releases/download/v0.1.2/$asset"
done
shasum -a 256 -c SHA256SUMS
ditto -x -k swabble-macos.zip .
./swabble --version
./swabble health
install -m 755 swabble /usr/local/bin/swabble
```

Installing to `/usr/local/bin` may require `sudo`. The first release is distributed through GitHub; there is no Homebrew formula yet. Speech recognition depends on the locales and assets supported by Apple's Speech framework on the target Mac.


## Clone

```bash
git clone https://github.com/openclaw/swabble.git
cd swabble
```

## Tooling

The development checks use SwiftFormat and SwiftLint:

```bash
brew install swiftformat swiftlint
```

## Build

```bash
swift build
```

## Create config

```bash
swift run swabble setup
```

This writes the default JSON config to `~/.config/swabble/config.json`.
It refuses to replace an existing config unless you explicitly pass `--force`.

---
title: Install
description: "Build Swabble from source and prepare the local config."
---

# Install

Swabble currently builds from source. It requires macOS 26, Swift 6.2, and the Speech.framework assets available on the target Mac.

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

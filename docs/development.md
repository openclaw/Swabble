---
title: Development
description: "Format, lint, and test Swabble locally."
---

# Development

## Format

```bash
./scripts/format.sh
```

## Lint

```bash
./scripts/lint.sh
```

## Test

```bash
swift test
```

## Release build and smoke test

```bash
swift build -c release
.build/release/swabble health
.build/release/swabble --help
```

CI runs on `macos-26`, selects Xcode 26, installs SwiftFormat and SwiftLint, then runs formatting, linting, tests, a release build, and CLI smoke checks.

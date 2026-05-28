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

CI runs on `macos-26`, selects Xcode 26, installs SwiftFormat and SwiftLint, then runs formatting, linting, and tests.


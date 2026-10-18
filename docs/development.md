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

Run the docs-builder regression tests with Node 26:

```bash
node --test scripts/build-docs-site.test.mjs
```

## Release build and smoke test

```bash
swift build -c release
.build/release/swabble health
.build/release/swabble --help
python3 scripts/test-service-install.py .build/release/swabble
```

CI runs on `xcode-27` with the image's Xcode 27, runs the docs-builder regression tests with Node 26, installs SwiftFormat and SwiftLint, then runs formatting, linting, Swift tests, a release build, and CLI smoke checks. The deployment target remains macOS 26.

The service smoke check uses a temporary LaunchAgents directory and synthetic versioned binaries. It checks bare and relative invocations, symlink upgrades, and uninstall/status behavior without loading a launchd agent.

## Releases

See [Releasing](releasing.html) for the GitHub Actions signing, notarization, and publication workflow.

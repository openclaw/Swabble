---
title: Library
description: "Use Swabble as a SwiftPM library."
---

# Library

Swabble exposes the `Swabble` product for apps that want the Speech pipeline, config loader, hook runner, and transcript store without invoking the CLI.

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/openclaw/swabble.git", branch: "main"),
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [.product(name: "Swabble", package: "swabble")]
    ),
]
```

The package is macOS 26-only and uses Swift 6.2 language mode.


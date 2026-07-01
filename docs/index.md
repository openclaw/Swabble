---
title: Overview
permalink: /
description: "Swabble is a local macOS speech hook daemon: wake word in, shell hook out."
---

# Swabble

Swabble listens on your Mac, waits for a wake word, transcribes with Apple Speech.framework, and hands the cleaned transcript to your shell command. It is built for local automations where sending microphone audio to a cloud service would be the wrong default.

## What it does

- Runs on macOS 26 with Swift 6.2 and Apple's on-device speech APIs.
- Uses `clawd` by default, with `claude` as an alias.
- Runs any configured command after wake-gating, cooldown, and minimum-length checks.
- Persists recent transcripts locally for status and debugging.
- Transcribes audio files to plain text or SRT.

## First run

```bash
git clone https://github.com/openclaw/swabble.git
cd swabble
brew install swiftformat swiftlint
swift run swabble setup
swift run swabble serve
```

## Local by design

Swabble uses Speech.framework's on-device path. There are no Whisper binaries, no network transcription calls, and no hosted control plane. Audio stays on the Mac; macOS may download Apple's speech model assets on first use. Your hook can do whatever you configure.

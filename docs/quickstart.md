---
title: Quickstart
description: "Run the foreground daemon, test a hook, and transcribe a file."
---

# Quickstart

## Start the daemon

```bash
swift run swabble serve
```

On first run, macOS may ask for microphone and Speech recognition permissions. Swabble needs both before it can stream audio into Speech.framework.

## Test the hook

Set a hook command in `~/.config/swabble/config.json`, then run:

```bash
swift run swabble test-hook "hello from swabble"
```

Swabble invokes the configured command with the rendered text argument and injects `SWABBLE_TEXT` plus `SWABBLE_PREFIX` into the environment.

## Transcribe a file

```bash
swift run swabble transcribe /path/to/audio.m4a --format srt --output out.srt
```

Use `--format txt` for plain text output.


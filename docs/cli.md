---
title: CLI
description: "Swabble command reference."
---

# CLI

All commands accept Commander runtime flags such as `-v`, `--verbose`, `--json-output`, and `--log-level`. Commands that read config also accept `--config`.

## Commands

- `setup` writes the default config JSON.
- `serve` starts the foreground microphone loop.
- `transcribe <file>` emits `txt` or `srt` file transcription.
- `test-hook "text"` invokes the configured hook.
- `mic list` enumerates input devices.
- `mic set <index>` selects an input device.
- `doctor` checks Speech authorization and device availability.
- `health` prints `ok`.
- `tail-log` prints the last 10 transcripts.
- `status` shows wake state and recent transcripts.
- `service install|uninstall|status` prints user launchd commands.
- `start`, `stop`, and `restart` are placeholders until launchd wiring lands.

## Examples

```bash
swift run swabble doctor
swift run swabble mic list
swift run swabble status --json-output
```


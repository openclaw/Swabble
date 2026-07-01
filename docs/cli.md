---
title: CLI
description: "Swabble command reference."
---

# CLI

Run `swabble --help` or `swabble <command> --help` for the current command surface. `health` and `status` accept `--json`/`--json-output`. Commands that read config accept `--config`.

## Commands

- `setup` writes the default config JSON and refuses to replace an existing file unless passed `--force`.
- `serve` starts the foreground microphone loop.
- `transcribe <file>` emits `txt` or `srt` file transcription.
- `test-hook "text"` invokes the configured hook.
- `mic list` enumerates input devices.
- `mic set <index>` saves a preferred input device index; `serve` still uses the system default input.
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

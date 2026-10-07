---
title: CLI
description: "Swabble command reference."
---

# CLI

Run `swabble --help` or `swabble <command> --help` for the current command surface. `health` and `status` accept `--json`/`--json-output`. Commands that read config accept `--config`.

## Commands

- `setup` writes the default config JSON and refuses to replace an existing file unless passed `--force`.
- `serve` starts the foreground microphone loop. It writes a default config only when the file is missing; a corrupt or unreadable file is reported and left unchanged.
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

`service install` creates `~/Library/LaunchAgents/com.swabble.agent.plist` and prints the command to load it; it does not load the agent itself. The stored executable path is absolute, even for bare or relative invocations, and preserves a stable symlink so upgrades can replace the binary behind it.

`service uninstall` removes the plist before printing the bootout instruction. An already-missing plist is harmless; other removal failures are reported as errors.

Set `SWABBLE_LAUNCH_AGENTS_DIR` to use a different plist directory for `service install`, `uninstall`, and `status`, for example when testing without modifying your usual LaunchAgents directory. Installation creates the directory if needed.

## Examples

```bash
swift run swabble doctor
swift run swabble mic list
swift run swabble status --json-output
```

`swabble --version` prints the installed release version without loading config or requesting speech access.

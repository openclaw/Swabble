---
title: Configuration
description: "The JSON config fields Swabble reads at runtime."
---

# Configuration

Swabble reads `~/.config/swabble/config.json`. Use `--config /path/to/config.json` on commands that accept an alternate path.

```json
{
  "audio": {"deviceName": "", "deviceIndex": -1, "sampleRate": 16000, "channels": 1},
  "wake": {"enabled": true, "word": "clawd", "aliases": ["claude"]},
  "hook": {
    "command": "",
    "args": [],
    "prefix": "Voice swabble from ${hostname}: ",
    "cooldownSeconds": 1,
    "minCharacters": 24,
    "timeoutSeconds": 5,
    "env": {}
  },
  "logging": {"level": "info", "format": "text"},
  "transcripts": {"enabled": true, "maxEntries": 50},
  "speech": {"localeIdentifier": "en_US", "etiquetteReplacements": false}
}
```

## Audio

`deviceIndex` and `deviceName` select an input device. Leave both empty/default to use the system default input.

## Wake

`enabled` controls wake-gating. The default wake word is `clawd`, with `claude` as an alias. Commands may expose a `--no-wake` path for direct testing.

## Hook

`command` is the executable to run. `args` are passed before the final rendered transcript argument. `${hostname}` in `prefix` is replaced before execution.

`cooldownSeconds`, `minCharacters`, and `timeoutSeconds` keep noisy partial transcripts from spamming the hook.


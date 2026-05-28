---
title: Hooks
description: "How Swabble executes configured shell hooks."
---

# Hooks

After Swabble hears the wake word and receives enough transcript text, it runs the configured hook:

```text
<command> <args...> "<prefix><text>"
```

The hook environment includes:

- `SWABBLE_TEXT`: transcript text with the wake word removed.
- `SWABBLE_PREFIX`: rendered prefix with `${hostname}` substituted.
- Any extra key/value pairs from `hook.env`.

## Guardrails

Swabble applies the configured cooldown, minimum character count, and timeout before running the hook. Keep the hook command idempotent where possible: speech transcripts can be retried, partial, or corrected by the system recognizer.


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

The hook must exit successfully. Timeouts and nonzero exits are reported as errors. `SWABBLE_TEXT` and `SWABBLE_PREFIX` always describe the current invocation and cannot be overridden through `hook.env`.

`swabble test-hook` bypasses minimum-length and cooldown gating so short test phrases always exercise the configured command; daemon invocations still enforce both guardrails.

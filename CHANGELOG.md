# Changelog

## Unreleased

- Fixed installed and `swift run` CLI routing, added built-in command help, and restored documented option binding for custom config and transcript output paths.
- Kept `test-hook` as an explicit wiring probe by bypassing daemon-only minimum-length and cooldown gating.
- Enforced hook minimum length, cooldown, timeout, exit-status, and reserved-environment guardrails while preventing partial transcripts from recreating the cooldown state.
- Protected config and transcript files with private permissions, atomic writes, configured transcript retention, and newline-safe JSONL persistence.
- Added supported-locale validation and first-use installation for Apple Speech framework assets.
- Copied microphone tap buffers before asynchronous processing and surfaced speech-stream failures instead of silently ending the daemon.
- Added release-build CLI smoke coverage and regression tests for hook and local-data behavior.
- Pinned GitHub Actions dependencies to current immutable release commits.

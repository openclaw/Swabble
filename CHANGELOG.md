# Changelog

## Unreleased

- Updated the pinned Pages deployment action to 5.0.1 for bounded deployment-status polling with backoff and jitter.
- Stopped `swabble serve` from replacing an existing unreadable config with defaults. Only a missing file is treated as first-run. (#10, thanks @SebTardif)
- Surfaced launchd plist removal errors from `service uninstall` instead of printing bootout after a failed delete. (#9, thanks @SebTardif)
- Updated Commander to 0.2.4, moved the docs build to Node 26, and refreshed the pinned checkout and Node setup actions.
- Pinned SwiftFormat 0.62.1 in CI and applied its conditional-body formatting rules.
- Fixed hook timeouts being reported as ordinary process exits when termination and process-wait completion raced.
- Fixed installed and `swift run` CLI routing, added built-in command help, and restored documented option binding for custom config and transcript output paths.
- Kept `test-hook` as an explicit wiring probe by bypassing daemon-only minimum-length and cooldown gating.
- Enforced hook minimum length, cooldown, timeout, exit-status, and reserved-environment guardrails while preventing partial transcripts from recreating the cooldown state.
- Protected config and transcript files with private permissions, atomic writes, configured transcript retention, and newline-safe JSONL persistence.
- Added supported-locale validation and first-use installation for Apple Speech framework assets.
- Copied microphone tap buffers before asynchronous processing and surfaced speech-stream failures instead of silently ending the daemon.
- Added release-build CLI smoke coverage and regression tests for hook and local-data behavior.
- Added docs-builder regression tests to pull-request CI using Node 26, matching the Pages build runtime. (#5, thanks @vincentkoc)
- Pinned GitHub Actions dependencies to current immutable release commits.

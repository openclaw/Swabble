# Changelog

## 0.1.1 - 2026-10-06

**Highlights:** Updates Commander to 0.3.0, keeping Swabble on the same command-line parser as Peekaboo 4.9 and OpenClaw.

- Updated Commander to 0.3.0, whose parser fails closed on ambiguous or malformed invocations and requires non-optional options.
- Kept `swabble` commands routable under Commander 0.3.0 by resolving the argument tail from the `swabble` root command; the previous full-argv resolution would have reported every command as unknown.

## 0.1.0 - 2026-09-14

**Highlights:** First public release of Swabble brings on-device speech transcription, wake-word hooks, and safer config handling on macOS 26.

- Added supported-locale validation and first-use installation for Apple Speech framework assets.
- Fixed installed and `swift run` CLI routing, added built-in command help, and restored documented option binding for custom config and transcript output paths.
- Protected config and transcript files with private permissions, atomic writes, configured transcript retention, and newline-safe JSONL persistence.
- Copied microphone tap buffers before asynchronous processing and surfaced speech-stream failures instead of silently ending the daemon.
- Honored task cancellation during hook termination cleanup, including when the child exits between polls, by killing surviving hooks and reporting cancellation instead of a timeout. (#12, thanks @SebTardif)
- Fixed hook timeouts being reported as ordinary process exits when termination and process-wait completion raced.
- Stopped `swabble serve` from replacing an existing unreadable config with defaults. Only a missing file is treated as first-run. (#10, thanks @SebTardif)
- Surfaced launchd plist removal errors from `service uninstall` instead of printing bootout after a failed delete. (#9, thanks @SebTardif)
- Enforced hook minimum length, cooldown, timeout, exit-status, and reserved-environment guardrails while preventing partial transcripts from recreating the cooldown state.
- Kept `test-hook` as an explicit wiring probe by bypassing daemon-only minimum-length and cooldown gating.
- Added release-build CLI smoke coverage and regression tests for hook and local-data behavior.
- Added docs-builder regression tests to pull-request CI using Node 26, matching the Pages build runtime. (#5, thanks @vincentkoc)
- Updated Commander to 0.2.4, moved the docs build to Node 26, and refreshed the pinned checkout and Node setup actions.
- Updated the pinned Pages deployment action to 5.0.1 for bounded deployment-status polling with backoff and jitter.
- Pinned SwiftFormat 0.62.1 in CI and applied its conditional-body formatting rules.
- Pinned GitHub Actions dependencies to current immutable release commits.
- Added version reporting and locally signed, notarized universal macOS releases with independent GitHub Actions verification.

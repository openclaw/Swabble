---
title: Releasing
description: "Build, sign, notarize, and verify a Swabble release locally."
---

# Releasing

Official Swabble releases use the local release path adapted from `openclaw/remindctl`. GitHub Actions only downloads and verifies an existing draft or published release. It does not build, sign, notarize, publish, or update Homebrew, and needs no repository signing secrets.

## Identity and artifacts

- Version source: `Sources/swabble/Version.swift`. The CLI and release-generated embedded Info.plist use this value.
- Repository: `openclaw/Swabble`.
- Signing identifier: `com.steipete.swabble`.
- Developer ID: `Developer ID Application: OpenClaw Foundation (FWJYW4S8P8)`.
- Architectures: `arm64 x86_64`; minimum macOS: 26.0.
- Assets: `swabble-macos.zip`, `SHA256SUMS`, and `release-inventory.json`.

The inventory binds the ZIP checksum and size to the exact source commit and signed annotated tag object. The ZIP contains only the universal `swabble` executable. Apple does not support stapling a standalone Mach-O executable or ZIP. Each slice's online notarization constraint is verified with `codesign --check-notarization -R=notarized` instead.

## Prepare and land

Update `Version.swift`, finalize the changelog's dated release section without dropping contributor credits, and update versioned install and SwiftPM snippets. Keep the CLI, embedded metadata, tag, and changelog versions consistent.

```bash
./scripts/format.sh
./scripts/lint.sh
swift test --parallel
swift build -c release
.build/release/swabble --version
.build/release/swabble health
node --test scripts/build-docs-site.test.mjs
node scripts/build-docs-site.mjs
python3 -m unittest discover -s scripts -p 'test_release.py'
./scripts/check-release.sh v0.1.0
```

Use Node 26 for docs checks. Run independent review, land the preparation PR, and require green CI on the exact main commit before tagging. Recheck the live release list and remote tags immediately before making a new tag; stop if that version exists. Use an annotated signed tag, verify it locally and on GitHub, and push only after the release is authorized.

## Local packaging

Use the shared `release-mac-app` helper's managed-keychain `codesign-run` wrapper with the approved runtime keychain and `NOTARYTOOL_PROFILE`. `.mac-release.env.example` documents the non-secret identity settings; keep credentials and machine-specific locators out of the repository. If another release holds the helper's keychain lock, wait for it; never bypass the lock.

```bash
/path/to/release-mac-app/scripts/mac-release codesign-run -- \
  scripts/package-macos-release.sh v0.1.0
```

The packager requires clean main at the live remote head and a locally verified signed tag that matches the remote tag object. It builds both architectures, embeds the version and privacy usage descriptions, combines the binary before signing, submits the exact ZIP for notarization, and requires Accepted. It then verifies both signatures and online tickets, native `--version`, minimum macOS, checksum, archive contents, and source/tag stability. Outputs appear atomically in `dist/release-v0.1.0`.

## Draft, verify, publish

```bash
scripts/create-release-draft.sh v0.1.0
```

This rechecks the local assets, creates a draft with exactly the finalized changelog body and three assets, and dispatches the verification workflow from main. Wait for that exact run to succeed. The workflow uses a native Apple Silicon `macos-26` runner: both slices get signature and notarization checks; `--version` runs natively on arm64. Intel execution is not established by this workflow.

```bash
scripts/publish-release.sh v0.1.0
```

Publication downloads and verifies the draft again, checks its source proof against the local signed tag, and compares release metadata immediately before publishing. It then dispatches published verification. Wait for that exact run to pass before closeout. The verifier intentionally binds to the release commit at the current main head; complete it before reopening Unreleased.

## Download proof and closeout

Freshly download the published assets with curl, verify `SHA256SUMS`, and inspect `xattr -l`. Curl may not attach `com.apple.quarantine`, even with `--xattr`; report that honestly. An explicitly applied quarantine attribute may be used for an authorized host test, but is not evidence of a natural browser download.

Verify the extracted binary with `codesign --verify --deep --strict --verbose=4`, `spctl -a -vv -t open --context context:primary-signature`, the per-slice online notarization constraint, `--version`, and the read-only `health` command. Check both `LC_BUILD_VERSION` values are 26.0. Record exact outputs and distinguish host verification from clean-VM testing.

The first release does not update Homebrew. After published verification, open an empty `## Unreleased` section, review and land the closeout, leave main clean at origin/main, and remove task build outputs and credential windows.

---
title: Releasing
description: "Build, sign, notarize and publish Swabble through GitHub Actions."
---

# Releasing

`.github/workflows/release.yml` owns official releases. It builds the universal macOS CLI, signs with **OpenClaw Foundation (FWJYW4S8P8)**, notarizes the exact ZIP, verifies the retained assets on fresh runners, and then publishes GitHub Releases. Local scripts do not publish or sign official releases.

The shared `release-swift-cli.yml@v1` currently requires an imsg companion dylib and Linux archive and has no dry-run input. This project ships neither, so its self-contained workflow preserves the existing macOS-only distribution contract. There is no npm package or Sparkle feed.

## Prepare a release

Finalize one dated `## X.Y.Z - YYYY-MM-DD` section in `CHANGELOG.md`, preserving contributor credit. Synchronize `Sources/swabble/Version.swift` and versioned documentation. Land the preparation PR and wait for successful **push CI on that exact main commit**.

Only after release authorization, push a signed annotated `vX.Y.Z` tag at a commit reachable from protected main. The signature must verify against `.github/release-allowed-signers`. The pipeline never creates or moves tags and refuses any existing GitHub Release, including a draft. After a partial publish failure, inspect and resolve the existing draft explicitly; a rerun cannot overwrite it.

## Rehearse without publishing

Run from protected main after its push CI is green:

```sh
gh workflow run release.yml --repo openclaw/Swabble --ref main \
  -f version=0.1.1 -F dry_run=true
```

Dispatch defaults to `dry_run: true`; a live dispatch is refused. Rehearsals use the exact current main commit even when the version already has a tag. They validate the dated notes and metadata, build both architectures, import an ephemeral signing keychain, sign and notarize, check the exact archive/inventory/checksum, and run native CLI smoke tests. They upload only Actions artifacts and never create tags, drafts, releases, or Homebrew changes. Notarization does submit the candidate ZIP to Apple.

The signer never checks out or executes source. Build and verification jobs receive no signing secrets or release-write token. Artifact IDs bind source proof, raw binaries, and signed outputs within the run. Publication checks every retained asset against the verifier digest records, redownloads the draft, compares all bytes, and only then makes it public. Signing keychains and App Store Connect files are removed even after failure.

## Channels and verification

The GitHub release contains `swabble-macos.zip`, `SHA256SUMS`, and `release-inventory.json`. The ZIP contains only `swabble`. Inventory schema 2 records the exact source commit, tag object (null for dry runs), dry-run status, architectures, stable identifier `com.steipete.swabble`, Foundation team, ZIP size, and SHA-256.

Both architecture slices must pass strict signature, identity, hardened-runtime, secure-timestamp, embedded version, and online notarization checks. The microphone entitlement and macOS 26 deployment target are checked. A macos-26 arm64 runner executes the CLI; Intel execution is not claimed because no macOS 26 Intel hosted runner is configured. Standalone Mach-O files cannot be stapled; online `codesign --check-notarization -R=notarized` is the ticket check. CLI version/help smoke does not request microphone or Speech permissions.

There is no Homebrew formula to update.

Host tests do not replace a natural-download Gatekeeper and real microphone/Speech permission check.

## Repository secrets

Set `MACOS_SIGNING_P12`, `MACOS_SIGNING_P12_PASSWORD`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, and `ASC_PRIVATE_KEY_P8` from the release credentials in Molty. No tap credential is needed. Never commit private signing keys or credential locators. `.github/release-allowed-signers` contains only the public tag-signing key.

Keep local read-only metadata, artifact, and historical-release verification helpers for diagnosis. `scripts/verify-ci-release.py` verifies schema-2 retained CI assets with the expected SHA, tag, dry-run status, and runner architecture supplied by the workflow. Existing `verify-macos-release.sh` and download helpers remain readers for historical schema-1 releases.

After a successful authorized release, compare GitHub notes and checksums with the finalized changelog, then open the next `Unreleased` section in a separate reviewed change. Infrastructure migrations do not add product changelog entries.

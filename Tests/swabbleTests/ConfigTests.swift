import Darwin
import Foundation
import Testing
@testable import Swabble

@Test
func configRoundTrip() throws {
    var cfg = SwabbleConfig()
    cfg.wake.word = "robot"
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
    defer { try? FileManager.default.removeItem(at: url) }

    try ConfigLoader.save(cfg, at: url)
    let loaded = try ConfigLoader.load(at: url)
    #expect(loaded.wake.word == "robot")
    #expect(loaded.hook.prefix.contains("Voice swabble"))
}

@Test
func configMissingThrows() {
    #expect(throws: ConfigError.missingConfig) {
        _ = try ConfigLoader.load(at: FileManager.default.temporaryDirectory.appendingPathComponent("nope.json"))
    }
}

@Test
func configLoadOrCreateIfMissingWritesDefaultsWhenAbsent() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
    defer { try? FileManager.default.removeItem(at: url) }

    let loaded = try ConfigLoader.loadOrCreateIfMissing(at: url)
    #expect(loaded.wake.word == "clawd")
    #expect(FileManager.default.fileExists(atPath: url.path))
    let reloaded = try ConfigLoader.load(at: url)
    #expect(reloaded.wake.word == "clawd")
}

@Test
func configLoadOrCreateIfMissingDoesNotOverwriteCorruptJSON() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
    defer { try? FileManager.default.removeItem(at: url) }

    let corrupt = Data("{not-json".utf8)
    try corrupt.write(to: url)

    #expect(throws: DecodingError.self) {
        _ = try ConfigLoader.loadOrCreateIfMissing(at: url)
    }
    #expect(try Data(contentsOf: url) == corrupt)
}

@Test
func configLoadOrCreateIfMissingDoesNotOverwriteUndecodableJSON() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
    defer { try? FileManager.default.removeItem(at: url) }

    let undecodable = Data(#"{"wake":"not-an-object"}"#.utf8)
    try undecodable.write(to: url)

    #expect(throws: DecodingError.self) {
        _ = try ConfigLoader.loadOrCreateIfMissing(at: url)
    }
    #expect(try Data(contentsOf: url) == undecodable)
}

@Test
func configLoadOrCreateIfMissingDoesNotOverwriteEmptyFile() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
    defer { try? FileManager.default.removeItem(at: url) }

    try Data().write(to: url)

    #expect(throws: DecodingError.self) {
        _ = try ConfigLoader.loadOrCreateIfMissing(at: url)
    }
    #expect(try Data(contentsOf: url).isEmpty)
}

@Test
func configLoadOrCreateIfMissingReturnsExistingConfig() throws {
    var cfg = SwabbleConfig()
    cfg.wake.word = "robot"
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
    defer { try? FileManager.default.removeItem(at: url) }

    try ConfigLoader.save(cfg, at: url)
    let before = try Data(contentsOf: url)
    let loaded = try ConfigLoader.loadOrCreateIfMissing(at: url)
    #expect(loaded.wake.word == "robot")
    #expect(try Data(contentsOf: url) == before)
}

@Test
func configSaveUsesPrivatePermissions() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let url = directory.appendingPathComponent("config.json")
    defer { try? FileManager.default.removeItem(at: directory) }

    try ConfigLoader.save(SwabbleConfig(), at: url)

    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
    let permissions = attributes[.posixPermissions] as? NSNumber
    #expect(permissions?.intValue == 0o600)
}

@Test
func hookRunnerEnforcesMinimumLengthAndCooldown() async throws {
    var config = SwabbleConfig()
    config.hook.command = "/usr/bin/true"
    config.hook.minCharacters = 5
    config.hook.cooldownSeconds = 60
    let runner = HookRunner(config: config)

    let short = try await runner.run(job: HookJob(text: "tiny", timestamp: Date()))
    let first = try await runner.run(job: HookJob(text: "long enough", timestamp: Date()))
    let cooldown = try await runner.run(job: HookJob(text: "another message", timestamp: Date()))

    #expect(!short)
    #expect(first)
    #expect(!cooldown)
}

@Test
func hookRunnerProtectsReservedEnvironment() async throws {
    var config = SwabbleConfig()
    config.hook.command = "/bin/sh"
    config.hook.args = [
        "-c",
        "test \"$SWABBLE_TEXT\" = actual && test \"$SWABBLE_PREFIX\" != overridden",
        "swabble-hook",
    ]
    config.hook.prefix = "prefix: "
    config.hook.minCharacters = 0
    config.hook.env = ["SWABBLE_TEXT": "spoofed", "SWABBLE_PREFIX": "overridden"]
    let runner = HookRunner(config: config)

    #expect(try await runner.run(job: HookJob(text: "actual", timestamp: Date())))
}

@Test
func hookRunnerReportsTimeout() async {
    // Exercise both scheduler orders around process termination.
    for _ in 0..<10 {
        var config = SwabbleConfig()
        config.hook.command = "/bin/sh"
        config.hook.args = ["-c", "while :; do :; done", "swabble-hook"]
        config.hook.minCharacters = 0
        config.hook.timeoutSeconds = 0.1
        let runner = HookRunner(config: config)

        do {
            _ = try await runner.run(job: HookJob(text: "timeout", timestamp: Date()))
            Issue.record("Expected hook timeout")
        } catch let error as HookRunnerError {
            #expect(error == .timedOut)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}

@Test
func hookRunnerEscalatesWhenHookIgnoresTermination() async {
    var config = SwabbleConfig()
    config.hook.command = "/bin/sh"
    config.hook.args = ["-c", "trap '' TERM; while :; do :; done", "swabble-hook"]
    config.hook.minCharacters = 0
    config.hook.timeoutSeconds = 0.1
    let runner = HookRunner(config: config)
    let clock = ContinuousClock()
    let started = clock.now

    do {
        _ = try await runner.run(job: HookJob(text: "timeout", timestamp: Date()))
        Issue.record("Expected hook timeout")
    } catch let error as HookRunnerError {
        #expect(error == .timedOut)
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
    #expect(started.duration(to: clock.now) < .seconds(1))
}

@Test
func hookRunnerHonorsCancelDuringTerminateWait() async throws {
    let pidURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".pid")
    let terminatedURL = pidURL.appendingPathExtension("terminated")
    defer {
        try? FileManager.default.removeItem(at: pidURL)
        try? FileManager.default.removeItem(at: terminatedURL)
    }

    var config = SwabbleConfig()
    config.hook.command = "/bin/sh"
    config.hook.args = [
        "-c",
        "trap 'echo terminated > \"\(terminatedURL.path)\"' TERM; echo $$ > '\(pidURL.path)'; while :; do :; done",
        "swabble-hook",
    ]
    config.hook.minCharacters = 0
    config.hook.timeoutSeconds = 0.1
    let runner = HookRunner(config: config)

    let task = Task {
        try await runner.run(job: HookJob(text: "timeout", timestamp: Date()))
    }

    let started = ContinuousClock().now
    while !FileManager.default.fileExists(atPath: terminatedURL.path) {
        if started.duration(to: .now) > .seconds(1) {
            Issue.record("Hook did not receive SIGTERM")
            task.cancel()
            _ = try? await task.value
            return
        }
        try await Task.sleep(for: .milliseconds(5))
    }
    task.cancel()

    do {
        _ = try await task.value
        Issue.record("Expected cancellation")
    } catch is CancellationError {
    } catch {
        Issue.record("Unexpected error: \(error)")
    }

    let pidText = try String(contentsOf: pidURL, encoding: .utf8)
        .trimmingCharacters(in: .whitespacesAndNewlines)
    let pid = try #require(Int32(pidText))
    var stillAlive = true
    for _ in 0..<20 {
        if kill(pid, 0) != 0 {
            stillAlive = false
            break
        }
        try await Task.sleep(for: .milliseconds(10))
    }
    #expect(!stillAlive)
}

@Test
func hookRunnerHonorsCancelWhenTerminationPollingIsSkipped() async throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/true")
    try process.run()
    process.waitUntilExit()
    let runner = HookRunner(config: SwabbleConfig())

    let task = Task {
        withUnsafeCurrentTask { $0?.cancel() }
        // An exited child skips every polling sleep, so cleanup must check cancellation itself.
        try await runner.finishTimedOutProcess(process, clock: ContinuousClock())
    }
    do {
        try await task.value
        Issue.record("Expected cancellation")
    } catch is CancellationError {
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}

@Test
func transcriptsStorePreservesEntriesAndLimit() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let url = directory.appendingPathComponent("transcripts.log")
    defer { try? FileManager.default.removeItem(at: directory) }

    let store = TranscriptsStore(limit: 2, fileURL: url)
    try await store.append(text: "first")
    try await store.append(text: "second\nline")
    try await store.append(text: "third")
    #expect(await store.latest() == ["second\nline", "third"])

    let reloaded = TranscriptsStore(limit: 2, fileURL: url)
    #expect(await reloaded.latest() == ["second\nline", "third"])
    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
    let permissions = attributes[.posixPermissions] as? NSNumber
    #expect(permissions?.intValue == 0o600)
}

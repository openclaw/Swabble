import Foundation

public struct HookJob: Sendable {
    public let text: String
    public let timestamp: Date

    public init(text: String, timestamp: Date) {
        self.text = text
        self.timestamp = timestamp
    }
}

public enum HookRunnerError: Error, Equatable {
    case missingCommand
    case timedOut
    case unsuccessfulExit(Int32)
}

public actor HookRunner {
    private let config: SwabbleConfig
    private var lastRun: Date?
    private let hostname: String

    public init(config: SwabbleConfig) {
        self.config = config
        hostname = Host.current().localizedName ?? "host"
    }

    public func shouldRun() -> Bool {
        guard config.hook.cooldownSeconds > 0 else { return true }
        if let lastRun, Date().timeIntervalSince(lastRun) < config.hook.cooldownSeconds {
            return false
        }
        return true
    }

    @discardableResult
    public func run(job: HookJob) async throws -> Bool {
        guard shouldRun() else { return false }
        let text = job.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count >= max(config.hook.minCharacters, 0) else { return false }
        guard !config.hook.command.isEmpty else { throw HookRunnerError.missingCommand }

        let prefix = config.hook.prefix.replacingOccurrences(of: "${hostname}", with: hostname)
        let payload = prefix + text

        let process = Process()
        process.executableURL = URL(fileURLWithPath: config.hook.command)
        process.arguments = config.hook.args + [payload]

        var env = ProcessInfo.processInfo.environment
        for (k, v) in config.hook.env {
            env[k] = v
        }
        // Reserved values describe this invocation and cannot be shadowed by config.
        env["SWABBLE_TEXT"] = text
        env["SWABBLE_PREFIX"] = prefix
        process.environment = env

        try process.run()

        let timeoutNanos = UInt64(max(config.hook.timeoutSeconds, 0.1) * 1_000_000_000)
        let timedOut = try await withThrowingTaskGroup(of: Bool.self) { group in
            group.addTask {
                process.waitUntilExit()
                return false
            }
            group.addTask {
                try await Task.sleep(nanoseconds: timeoutNanos)
                if process.isRunning {
                    process.terminate()
                    return true
                }
                return false
            }
            let first = try await group.next() ?? false
            group.cancelAll()
            return first
        }

        if timedOut { throw HookRunnerError.timedOut }
        guard process.terminationStatus == 0 else {
            throw HookRunnerError.unsuccessfulExit(process.terminationStatus)
        }
        lastRun = Date()
        return true
    }
}

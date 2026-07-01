import Commander
import Foundation
import Swabble

@MainActor
struct TestHookCommand: ParsableCommand {
    @Argument(help: "Text to send to hook") var text: String
    @Option(name: .long("config"), help: "Path to config JSON") var configPath: String?

    static var commandDescription: CommandDescription {
        CommandDescription(commandName: "test-hook", abstract: "Invoke the configured hook with text")
    }

    init() {}

    init(parsed: ParsedValues) {
        self.init()
        if let positional = parsed.positional.first { text = positional }
        if let cfg = parsed.options["configPath"]?.last { configPath = cfg }
    }

    mutating func run() async throws {
        var cfg = try ConfigLoader.load(at: configURL)
        // This command validates hook wiring explicitly, independent of daemon gating.
        cfg.hook.minCharacters = 0
        cfg.hook.cooldownSeconds = 0
        let runner = HookRunner(config: cfg)
        _ = try await runner.run(job: HookJob(text: text, timestamp: Date()))
        print("hook invoked")
    }

    private var configURL: URL? {
        configPath.map { URL(fileURLWithPath: $0) }
    }
}

import Commander
import Foundation
import Swabble

@MainActor
struct SetupCommand: ParsableCommand {
    static var commandDescription: CommandDescription {
        CommandDescription(commandName: "setup", abstract: "Write default config")
    }

    @Option(name: .long("config"), help: "Path to config JSON") var configPath: String?
    @Flag(name: .long("force"), help: "Replace an existing config") var force = false

    init() {}
    init(parsed: ParsedValues) {
        self.init()
        if let cfg = parsed.options["configPath"]?.last { configPath = cfg }
        force = parsed.flags.contains("force")
    }

    mutating func run() async throws {
        let target = configURL ?? SwabbleConfig.defaultPath
        if FileManager.default.fileExists(atPath: target.path), !force {
            throw SetupError.configExists(target)
        }
        let cfg = SwabbleConfig()
        try ConfigLoader.save(cfg, at: configURL)
        print("wrote config to \(target.path)")
    }

    private var configURL: URL? {
        configPath.map { URL(fileURLWithPath: $0) }
    }
}

private enum SetupError: Error, CustomStringConvertible {
    case configExists(URL)

    var description: String {
        switch self {
        case let .configExists(url):
            "config already exists at \(url.path); use --force to replace it"
        }
    }
}

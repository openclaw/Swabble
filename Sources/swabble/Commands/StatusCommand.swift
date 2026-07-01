import Commander
import Foundation
import Swabble

@MainActor
struct StatusCommand: ParsableCommand {
    private struct Status: Codable {
        let wakeEnabled: Bool
        let wakeWord: String
        let transcripts: [String]
    }

    static var commandDescription: CommandDescription {
        CommandDescription(commandName: "status", abstract: "Show daemon state")
    }

    @Option(name: .long("config"), help: "Path to config JSON") var configPath: String?
    @Flag(
        names: [.long("json"), .short("j"), .long("json-output")],
        help: "Emit machine-readable JSON output",
    ) private var jsonOutput = false

    init() {}
    init(parsed: ParsedValues) {
        self.init()
        if let cfg = parsed.options["configPath"]?.last { configPath = cfg }
        jsonOutput = parsed.flags.contains("jsonOutput")
    }

    mutating func run() async throws {
        let cfg = try? ConfigLoader.load(at: configURL)
        let wake = cfg?.wake.word ?? "clawd"
        let wakeEnabled = cfg?.wake.enabled ?? false
        let latest = await Array(TranscriptsStore.shared.latest().suffix(3))
        if jsonOutput {
            let payload = Status(wakeEnabled: wakeEnabled, wakeWord: wake, transcripts: latest)
            let data = try JSONEncoder().encode(payload)
            guard let output = String(data: data, encoding: .utf8) else {
                throw CocoaError(.fileWriteInapplicableStringEncoding)
            }
            print(output)
            return
        }
        print("wake: \(wakeEnabled ? wake : "disabled")")
        if latest.isEmpty {
            print("transcripts: (none yet)")
        } else {
            print("last transcripts:")
            latest.forEach { print("- \($0)") }
        }
    }

    private var configURL: URL? {
        configPath.map { URL(fileURLWithPath: $0) }
    }
}

import Commander
import Foundation

@MainActor
struct HealthCommand: ParsableCommand {
    @Flag(
        names: [.long("json"), .short("j"), .long("json-output")],
        help: "Emit machine-readable JSON output",
    ) private var jsonOutput = false

    static var commandDescription: CommandDescription {
        CommandDescription(commandName: "health", abstract: "Health probe")
    }

    init() {}
    init(parsed: ParsedValues) {
        jsonOutput = parsed.flags.contains("jsonOutput")
    }

    mutating func run() async throws {
        print(jsonOutput ? #"{"status":"ok"}"# : "ok")
    }
}

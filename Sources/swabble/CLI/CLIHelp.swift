import Commander
import Foundation

enum CLIHelp {
    static func render(arguments: [String], descriptors: [CommandDescriptor]) -> String? {
        let requestedPath: [String]
        if arguments.first == "help" {
            requestedPath = Array(arguments.dropFirst())
        } else if arguments.last == "--help" || arguments.last == "-h" {
            requestedPath = Array(arguments.dropLast())
        } else if arguments.isEmpty {
            requestedPath = []
        } else {
            return nil
        }

        guard var descriptor = descriptors.first(where: { $0.name == "swabble" }) else { return nil }
        var path = [descriptor.name]
        for component in requestedPath {
            guard let child = descriptor.subcommands.first(where: { $0.name == component }) else { return nil }
            descriptor = child
            path.append(component)
        }
        return render(descriptor: descriptor, path: path)
    }

    private static func render(descriptor: CommandDescriptor, path: [String]) -> String {
        let signature = descriptor.signature.flattened()
        let arguments = signature.arguments.map { argument in
            argument.isOptional ? "[<\(argument.label)>]" : "<\(argument.label)>"
        }
        let suffix = descriptor.subcommands.isEmpty ? arguments : ["<command>"]
        // SwiftFormat's required collection comma conflicts with the lint preference.
        // swiftlint:disable trailing_comma
        var sections = [
            "Usage: \((path + suffix).joined(separator: " "))",
            "",
            descriptor.abstract,
        ]
        // swiftlint:enable trailing_comma

        if let discussion = descriptor.discussion, !discussion.isEmpty {
            sections += ["", discussion]
        }
        if !descriptor.subcommands.isEmpty {
            sections += ["", "Commands:"]
            sections += descriptor.subcommands.map { "  \($0.name)\t\($0.abstract)" }
        }

        let options = signature.options.compactMap { definition -> String? in
            guard let names = render(names: definition.names) else { return nil }
            return "  \(names) <value>\t\(definition.help ?? "")"
        }
        let flags = signature.flags.compactMap { definition -> String? in
            guard let names = render(names: definition.names) else { return nil }
            return "  \(names)\t\(definition.help ?? "")"
        }
        sections += ["", "Options:"]
        sections += options + flags + ["  -h, --help\tShow help"]
        return sections.joined(separator: "\n")
    }

    private static func render(names: [CommanderName]) -> String? {
        let visible = names.compactMap { name -> String? in
            switch name {
            case let .short(value): "-\(value)"
            case let .long(value): "--\(value)"
            case .aliasShort, .aliasLong: nil
            }
        }
        return visible.isEmpty ? nil : visible.joined(separator: ", ")
    }
}

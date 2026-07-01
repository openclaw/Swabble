import Foundation

public actor TranscriptsStore {
    private struct Record: Codable {
        let text: String
    }

    public static let shared = TranscriptsStore(limit: 50)

    private var entries: [String] = []
    private let limit: Int
    private let fileURL: URL

    public init(limit: Int = 50, fileURL: URL? = nil) {
        self.limit = max(limit, 0)
        let defaultDirectory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/swabble", isDirectory: true)
        self.fileURL = fileURL ?? defaultDirectory.appendingPathComponent("transcripts.log")
        let dir = self.fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(
            at: dir,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700],
        )
        if let data = try? Data(contentsOf: self.fileURL), let text = String(data: data, encoding: .utf8) {
            let decoder = JSONDecoder()
            entries = Array(text.split(separator: "\n").compactMap { line in
                let lineData = Data(line.utf8)
                if let record = try? decoder.decode(Record.self, from: lineData) {
                    return record.text
                }
                // Migrate newline-delimited files written by pre-release builds.
                return String(line)
            }.suffix(self.limit))
        }
    }

    public func append(text: String) throws {
        entries.append(text)
        if entries.count > limit {
            entries.removeFirst(entries.count - limit)
        }
        let encoder = JSONEncoder()
        let lines = try entries.map { entry in
            let data = try encoder.encode(Record(text: entry))
            guard let line = String(data: data, encoding: .utf8) else {
                throw CocoaError(.fileWriteInapplicableStringEncoding)
            }
            return line
        }
        let body = lines.isEmpty ? "" : lines.joined(separator: "\n") + "\n"
        try body.write(to: fileURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
    }

    public func latest() -> [String] {
        entries
    }
}

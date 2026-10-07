import Darwin
import Foundation

package nonisolated func absoluteExecutablePath() throws -> String {
    guard let raw = copyExecutablePath() else {
        throw CocoaError(.fileReadUnknown)
    }
    return absoluteExecutablePath(raw: raw)
}

package nonisolated func absoluteExecutablePath(raw: String) -> String {
    // Standardizing a path containing ".." can resolve the executable symlink
    // and pin launchd to a versioned target that an upgrade can delete.
    raw.hasPrefix("/") ? raw : FileManager.default.currentDirectoryPath + "/" + raw
}

private func copyExecutablePath() -> String? {
    var size = UInt32(PATH_MAX)
    var buffer = [CChar](repeating: 0, count: Int(size))
    if _NSGetExecutablePath(&buffer, &size) != 0 {
        let needed = Int(size)
        guard needed > 0 else { return nil }
        buffer = [CChar](repeating: 0, count: needed)
        guard _NSGetExecutablePath(&buffer, &size) == 0 else { return nil }
    }
    let end = buffer.firstIndex(of: 0) ?? buffer.endIndex
    let bytes = buffer[..<end].map { UInt8(bitPattern: $0) }
    guard let path = String(bytes: bytes, encoding: .utf8), !path.isEmpty else {
        return nil
    }
    return path
}

import Foundation
import Testing
@testable import Swabble

@Test
func absoluteExecutablePathKeepsAnAbsoluteSymlink() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("swabble-exe-\(UUID().uuidString)", isDirectory: true)
    let versionOne = root.appendingPathComponent("v1", isDirectory: true)
    let versionTwo = root.appendingPathComponent("v2", isDirectory: true)
    let bin = root.appendingPathComponent("bin", isDirectory: true)
    try FileManager.default.createDirectory(at: versionOne, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: versionTwo, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: bin, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let oldBinary = versionOne.appendingPathComponent("swabble")
    let newBinary = versionTwo.appendingPathComponent("swabble")
    let link = bin.appendingPathComponent("swabble")
    try Data("old".utf8).write(to: oldBinary)
    try FileManager.default.createSymbolicLink(at: link, withDestinationURL: oldBinary)

    let paths = [link.path, bin.path + "/../bin/swabble"]
    let stored = paths.map { absoluteExecutablePath(raw: $0) }
    #expect(stored == paths)

    try Data("new".utf8).write(to: newBinary)
    try FileManager.default.removeItem(at: link)
    try FileManager.default.createSymbolicLink(at: link, withDestinationURL: newBinary)
    try FileManager.default.removeItem(at: oldBinary)

    for path in stored {
        #expect(FileManager.default.fileExists(atPath: path))
        #expect(try String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8) == "new")
    }
}

@Test(arguments: ["bin/swabble", "../bin/swabble"])
func absoluteExecutablePathMakesRelativeInvocationAbsolute(raw: String) {
    let stored = absoluteExecutablePath(raw: raw)
    let expected = FileManager.default.currentDirectoryPath + "/" + raw
    #expect(stored == expected)
}

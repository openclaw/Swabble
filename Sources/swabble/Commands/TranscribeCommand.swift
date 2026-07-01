import AVFoundation
import Commander
import Foundation
import Speech
import Swabble

@MainActor
struct TranscribeCommand: ParsableCommand {
    @Argument(help: "Path to audio/video file") var inputFile: String = ""
    @Option(name: .long("locale"), help: "Locale identifier", parsing: .singleValue) var locale: String = Locale.current
        .identifier
    @Flag(help: "Censor etiquette-sensitive content") var censor: Bool = false
    @Option(name: .long("output"), help: "Output file path") var outputFile: String?
    @Option(name: .long("format"), help: "Output format txt|srt") var format: String = "txt"
    @Option(name: .long("max-length"), help: "Max sentence length for srt") var maxLength: Int = 40

    static var commandDescription: CommandDescription {
        CommandDescription(
            commandName: "transcribe",
            abstract: "Transcribe a media file locally",
        )
    }

    init() {}

    init(parsed: ParsedValues) {
        self.init()
        if let positional = parsed.positional.first { inputFile = positional }
        if let loc = parsed.options["locale"]?.last { locale = loc }
        if parsed.flags.contains("censor") { censor = true }
        if let out = parsed.options["outputFile"]?.last { outputFile = out }
        if let fmt = parsed.options["format"]?.last { format = fmt }
        if let len = parsed.options["maxLength"]?.last, let intVal = Int(len) { maxLength = intVal }
    }

    mutating func run() async throws {
        guard let outputFormat = OutputFormat(rawValue: format) else {
            throw TranscribeError.invalidFormat(format)
        }
        if outputFormat == .srt, maxLength <= 0 {
            throw TranscribeError.invalidMaxLength(maxLength)
        }
        let fileURL = URL(fileURLWithPath: inputFile)
        let audioFile = try AVAudioFile(forReading: fileURL)
        let requestedLocale = Locale(identifier: locale)
        guard let supportedLocale = await SpeechTranscriber.supportedLocale(equivalentTo: requestedLocale) else {
            throw TranscribeError.unsupportedLocale(locale)
        }
        let transcriber = SpeechTranscriber(
            locale: supportedLocale,
            transcriptionOptions: censor ? [.etiquetteReplacements] : [],
            reportingOptions: [],
            attributeOptions: outputFormat.needsAudioTimeRange ? [.audioTimeRange] : [],
        )
        try await SpeechAssets.ensureInstalled(for: [transcriber])
        let analyzer = SpeechAnalyzer(modules: [transcriber])
        try await analyzer.start(inputAudioFile: audioFile, finishAfterFile: true)

        var transcript: AttributedString = ""
        for try await result in transcriber.results {
            transcript += result.text
        }

        let output = outputFormat.text(for: transcript, maxLength: maxLength)
        if let path = outputFile {
            try output.write(to: URL(fileURLWithPath: path), atomically: false, encoding: .utf8)
        } else {
            print(output)
        }
    }
}

private enum TranscribeError: Error, CustomStringConvertible {
    case invalidFormat(String)
    case invalidMaxLength(Int)
    case unsupportedLocale(String)

    var description: String {
        switch self {
        case let .invalidFormat(format):
            "unsupported output format '\(format)'; expected txt or srt"
        case let .invalidMaxLength(length):
            "max length must be positive for srt output, got \(length)"
        case let .unsupportedLocale(locale):
            "unsupported speech locale '\(locale)'"
        }
    }
}

import AVFoundation
import Foundation
import Speech

public struct SpeechSegment: Sendable {
    public let text: String
    public let isFinal: Bool
}

public enum SpeechPipelineError: Error {
    case authorizationDenied
    case analyzerFormatUnavailable
    case transcriberUnavailable
    case unsupportedLocale(String)
}

/// Live microphone → SpeechAnalyzer → SpeechTranscriber pipeline.
public actor SpeechPipeline {
    private struct UnsafeBuffer: @unchecked Sendable { let buffer: AVAudioPCMBuffer }

    private var engine = AVAudioEngine()
    private var transcriber: SpeechTranscriber?
    private var analyzer: SpeechAnalyzer?
    private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?
    private var resultTask: Task<Void, Never>?
    private let converter = BufferConverter()

    public init() {}

    public func start(
        localeIdentifier: String,
        etiquette: Bool,
    ) async throws -> AsyncThrowingStream<SpeechSegment, Error> {
        guard await requestAuthorizationIfNeeded() == .authorized else { throw SpeechPipelineError.authorizationDenied }

        let transcriberModule = try await Self.makeTranscriber(
            localeIdentifier: localeIdentifier,
            etiquette: etiquette,
        )
        transcriber = transcriberModule

        guard let analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriberModule])
        else {
            throw SpeechPipelineError.analyzerFormatUnavailable
        }

        analyzer = SpeechAnalyzer(modules: [transcriberModule])
        let (stream, continuation) = AsyncStream<AnalyzerInput>.makeStream()
        inputContinuation = continuation

        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: inputFormat) { [weak self] buffer, _ in
            guard let self, let copy = Self.copy(buffer: buffer) else { return }
            let boxed = UnsafeBuffer(buffer: copy)
            Task { await self.handleBuffer(boxed.buffer, targetFormat: analyzerFormat) }
        }

        engine.prepare()
        do {
            try engine.start()
            try await analyzer?.start(inputSequence: stream)
        } catch {
            inputContinuation?.finish()
            inputNode.removeTap(onBus: 0)
            engine.stop()
            throw error
        }

        guard let transcriberForStream = transcriber else {
            throw SpeechPipelineError.transcriberUnavailable
        }

        return AsyncThrowingStream { continuation in
            self.resultTask = Task {
                do {
                    for try await result in transcriberForStream.results {
                        let seg = SpeechSegment(text: String(result.text.characters), isFinal: result.isFinal)
                        continuation.yield(seg)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                Task { await self.stop() }
            }
        }
    }

    public func stop() async {
        resultTask?.cancel()
        inputContinuation?.finish()
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        try? await analyzer?.finalizeAndFinishThroughEndOfInput()
    }

    private func handleBuffer(_ buffer: AVAudioPCMBuffer, targetFormat: AVAudioFormat) async {
        do {
            let converted = try converter.convert(buffer, to: targetFormat)
            let input = AnalyzerInput(buffer: converted)
            inputContinuation?.yield(input)
        } catch {
            // drop on conversion failure
        }
    }

    private static func makeTranscriber(localeIdentifier: String, etiquette: Bool) async throws -> SpeechTranscriber {
        let requestedLocale = Locale(identifier: localeIdentifier)
        guard let supportedLocale = await SpeechTranscriber.supportedLocale(equivalentTo: requestedLocale) else {
            throw SpeechPipelineError.unsupportedLocale(localeIdentifier)
        }
        let transcriber = SpeechTranscriber(
            locale: supportedLocale,
            transcriptionOptions: etiquette ? [.etiquetteReplacements] : [],
            reportingOptions: [.volatileResults],
            attributeOptions: [],
        )
        try await SpeechAssets.ensureInstalled(for: [transcriber])
        return transcriber
    }

    /// Tap buffers are only valid during the callback; copy before crossing actor isolation.
    private nonisolated static func copy(buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let copy = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: buffer.frameLength) else {
            return nil
        }
        copy.frameLength = buffer.frameLength
        let sourceBuffers = UnsafeMutableAudioBufferListPointer(buffer.mutableAudioBufferList)
        let destinationBuffers = UnsafeMutableAudioBufferListPointer(copy.mutableAudioBufferList)
        guard sourceBuffers.count == destinationBuffers.count else { return nil }
        for index in sourceBuffers.indices {
            let source = sourceBuffers[index]
            guard let sourceData = source.mData, let destinationData = destinationBuffers[index].mData else {
                return nil
            }
            memcpy(destinationData, sourceData, Int(source.mDataByteSize))
            destinationBuffers[index].mDataByteSize = source.mDataByteSize
        }
        return copy
    }

    private func requestAuthorizationIfNeeded() async -> SFSpeechRecognizerAuthorizationStatus {
        let current = SFSpeechRecognizer.authorizationStatus()
        guard current == .notDetermined else { return current }
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}

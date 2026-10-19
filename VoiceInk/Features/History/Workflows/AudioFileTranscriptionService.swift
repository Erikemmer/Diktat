import AVFoundation
import Foundation
import SwiftData
import SwiftUI
import os

struct AudioRetranscriptionResult {
    let transcription: Transcription
}

@MainActor
class AudioTranscriptionService: ObservableObject {
    @Published var isTranscribing = false
    @Published var currentError: TranscriptionError?

    private let modelContext: ModelContext
    private let logger = Logger(subsystem: "de.die-lithothek.diktat", category: "AudioTranscriptionService")
    private let serviceRegistry: TranscriptionServiceRegistry

    enum TranscriptionError: Error {
        case noAudioFile
        case transcriptionFailed
        case modelNotLoaded
        case invalidAudioFormat
    }

    init(modelContext: ModelContext, engine: VoiceInkEngine) {
        self.modelContext = modelContext
        self.serviceRegistry = TranscriptionServiceRegistry(
            modelProvider: engine.whisperModelManager, modelsDirectory: engine.whisperModelManager.modelsDirectory)
    }

    init(modelContext: ModelContext, serviceRegistry: TranscriptionServiceRegistry) {
        self.modelContext = modelContext
        self.serviceRegistry = serviceRegistry
    }

    func retranscribeAudio(from url: URL, using model: any TranscriptionModel) async throws
        -> AudioRetranscriptionResult
    {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw TranscriptionError.noAudioFile
        }

        await MainActor.run {
            isTranscribing = true
        }

        do {
            let language = TranscriptionLanguageSupport.validLanguageOrFallback(
                UserDefaults.standard.string(forKey: "SelectedLanguage"),
                for: model
            )
            let requestContext = TranscriptionRequestContext(
                language: language,
                prompt: model.provider == .whisper ? WhisperPrompt.resolvedPrompt(for: language) : nil
            )

            let transcriptionStart = Date()
            var text = try await serviceRegistry.transcribe(audioURL: url, model: model, context: requestContext)
            let transcriptionDuration = Date().timeIntervalSince(transcriptionStart)
            text = TranscriptionOutputFilter.filter(text)
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let formattingConfiguration = TranscriptionRuntimeResolver.transcriptionFormattingConfiguration()

            if formattingConfiguration.isTextFormattingEnabled {
                text = ParagraphFormatter.format(text)
            }

            text = WordReplacementService.shared.applyReplacements(to: text, using: modelContext)
            let cleanedText = text

            let audioAsset = AVURLAsset(url: url)
            let duration = CMTimeGetSeconds(try await audioAsset.load(.duration))
            let recordingsDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[
                0
            ]
            .appendingPathComponent("de.die-lithothek.diktat")
            .appendingPathComponent("Recordings")

            let fileName = "retranscribed_\(UUID().uuidString).wav"
            let permanentURL = recordingsDirectory.appendingPathComponent(fileName)

            do {
                try FileManager.default.copyItem(at: url, to: permanentURL)
            } catch {
                logger.error("❌ Failed to create permanent copy of audio: \(error, privacy: .public)")
                isTranscribing = false
                throw error
            }

            let permanentURLString = permanentURL.absoluteString

            let newTranscription = Transcription(
                text: cleanedText,
                duration: duration,
                audioFileURL: permanentURLString,
                transcriptionModelName: model.displayName,
                promptName: nil,
                transcriptionDuration: transcriptionDuration
            )
            modelContext.insert(newTranscription)
            do {
                try modelContext.save()
                NotificationCenter.default.post(name: .transcriptionCompleted, object: newTranscription)
            } catch {
                logger.error("❌ Failed to save transcription: \(error, privacy: .public)")
            }

            await MainActor.run {
                isTranscribing = false
            }

            return AudioRetranscriptionResult(transcription: newTranscription)
        } catch {
            logger.error("❌ Transcription failed: \(error, privacy: .public)")
            currentError = .transcriptionFailed
            isTranscribing = false
            throw error
        }
    }
}

import Foundation

struct TranscriptionRuntimeConfiguration {
    let model: any TranscriptionModel
    let language: String
    let isRealtimeEnabled: Bool

    var requestContext: TranscriptionRequestContext {
        TranscriptionRequestContext(
            language: language,
            prompt: model.provider == .whisper ? WhisperPrompt.resolvedPrompt(for: language) : nil
        )
    }
}

struct TranscriptionFormattingConfiguration {
    let isTextFormattingEnabled: Bool
}

struct OutputRuntimeConfiguration {
    let autoSendKey: FinishAndSendKey
}

/// Derives the runtime configuration directly from the selected model and the global settings.
@MainActor
enum TranscriptionRuntimeResolver {
    static func transcriptionConfiguration(
        transcriptionModelManager: TranscriptionModelManager
    ) -> TranscriptionRuntimeConfiguration? {
        guard let model = transcriptionModelManager.currentTranscriptionModel,
            transcriptionModelManager.usableModels.contains(where: { $0.selectionKey == model.selectionKey })
        else {
            return nil
        }

        let language = TranscriptionLanguageSupport.validLanguageOrFallback(
            UserDefaults.standard.string(forKey: "SelectedLanguage"),
            for: model
        )

        return TranscriptionRuntimeConfiguration(
            model: model,
            language: language,
            isRealtimeEnabled: TranscriptionRealtimeSupport.isEnabled(for: model)
        )
    }

    static func transcriptionFormattingConfiguration() -> TranscriptionFormattingConfiguration {
        TranscriptionFormattingConfiguration(
            isTextFormattingEnabled: UserDefaults.standard.bool(forKey: "IsTextFormattingEnabled")
        )
    }

    static func outputConfiguration() -> OutputRuntimeConfiguration {
        OutputRuntimeConfiguration(autoSendKey: .none)
    }
}

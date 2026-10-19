import AppKit
import SwiftData
import SwiftUI

struct HistoryDetailActionBar: View {
    let transcription: Transcription
    let audioURL: URL?
    let isInfoPresented: Bool
    let onToggleInfo: () -> Void
    let onTranscriptionUpdated: (Transcription) -> Void
    var onPaste: (() -> Void)? = nil

    @EnvironmentObject private var engine: VoiceInkEngine
    @Environment(\.modelContext) private var modelContext

    @State private var didCopy = false
    @State private var isWorking = false

    var body: some View {
        HStack(spacing: 8) {
            retryButton
            finderButton
            infoButton
            Spacer(minLength: 8)
            textActionButton
        }
        .padding(.horizontal, 10)
        .frame(height: HistoryLayout.actionBarHeight)
    }

    private var textActionButton: some View {
        HistoryCommandButton(
            onPaste == nil ? "Copy transcription" : "Paste Text",
            systemImage: onPaste == nil ? (didCopy ? "checkmark" : "doc.on.doc") : nil,
            shortcut: onPaste == nil ? nil : "↵",
            minimumWidth: 112,
            action: performTextAction
        )
        .help(
            onPaste == nil
                ? "Copy transcription"
                : "Paste the transcription"
        )
    }

    private func performTextAction() {
        if let onPaste {
            onPaste()
        } else {
            let _ = ClipboardManager.copyToClipboard(transcription.preferredHistoryText)
            didCopy = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                didCopy = false
            }
        }
    }

    private var retryButton: some View {
        HistoryIconButton(
            systemName: "arrow.clockwise",
            help: "Retranscribe with the selected model",
            isLoading: isWorking
        ) {
            retranscribe()
        }
        .disabled(isWorking || audioURL == nil)
    }

    private var finderButton: some View {
        HistoryIconButton(systemName: "folder", help: "Show recording in Finder") {
            guard let audioURL else { return }
            NSWorkspace.shared.selectFile(
                audioURL.path,
                inFileViewerRootedAtPath: audioURL.deletingLastPathComponent().path
            )
        }
        .disabled(audioURL == nil)
    }

    private var infoButton: some View {
        HistoryIconButton(
            systemName: "info.circle",
            help: isInfoPresented ? "Hide transcription info" : "Show transcription info",
            isSelected: isInfoPresented,
            action: onToggleInfo
        )
    }

    private func retranscribe() {
        guard let audioURL else {
            showError(String(localized: "Audio file is unavailable"))
            return
        }
        guard let configuration = TranscriptionRuntimeResolver.transcriptionConfiguration(
            transcriptionModelManager: engine.transcriptionModelManager
        ) else {
            showError(String(localized: "No transcription model selected"))
            return
        }

        isWorking = true
        let service = AudioTranscriptionService(modelContext: modelContext, engine: engine)

        Task {
            do {
                let result = try await service.retranscribeAudio(
                    from: audioURL,
                    using: configuration.model
                )
                await MainActor.run {
                    isWorking = false
                    NotificationManager.shared.showNotification(
                        title: String(localized: "Retranscription successful"),
                        type: .success,
                        duration: 1.0
                    )
                    onTranscriptionUpdated(result.transcription)
                }
            } catch {
                await MainActor.run {
                    isWorking = false
                    showError(
                        error.localizedDescription.isEmpty
                            ? String(localized: "Retranscription failed")
                            : error.localizedDescription
                    )
                }
            }
        }
    }

    private func showError(_ title: String) {
        NotificationManager.shared.showNotification(title: title, type: .error, duration: 3.0)
    }
}

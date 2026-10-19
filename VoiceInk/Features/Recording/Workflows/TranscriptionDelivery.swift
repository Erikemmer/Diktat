import AppKit
import Foundation
import os

@MainActor
final class TranscriptionDelivery {
    private let logger = Logger(subsystem: "de.die-lithothek.diktat", category: "TranscriptionDelivery")

    struct Request {
        let transcription: Transcription
        let text: String?
        let output: OutputRuntimeConfiguration
        let sendAfterPaste: Bool
    }

    struct Actions {
        let setState: (RecordingState) -> Void
        let dismiss: () async -> Void
    }

    func deliver(_ request: Request, actions: Actions) async {
        guard request.transcription.transcriptionStatus == TranscriptionStatus.completed.rawValue else {
            await actions.dismiss()
            return
        }

        if let text = request.text {
            let sendKey = request.sendAfterPaste ? FinishAndSendSettings.selectedKey : request.output.autoSendKey
            await paste(text, sendKey: sendKey, actions: actions)
        } else {
            await actions.dismiss()
        }
    }

    private func paste(_ text: String, sendKey: FinishAndSendKey, actions: Actions) async {
        let textToPaste = deliverableText(from: text)
        let appendSpace = UserDefaults.standard.bool(forKey: "AppendTrailingSpace")
        let pastedText = textToPaste + (appendSpace ? " " : "")
        actions.setState(.idle)
        SoundManager.shared.playStopSound()
        await actions.dismiss()

        let pasteTask = CursorPaster.startPasteAtCursor(pastedText)

        Task { @MainActor in
            let pasteOutcome = await pasteTask.value

            if sendKey.isEnabled && pasteOutcome.result.didPostPasteCommand {
                try? await Task.sleep(nanoseconds: 150_000_000)
                CursorPaster.performSendKey(sendKey)
            }
        }
    }

    private func deliverableText(from text: String) -> String {
        text
    }
}

import AVFoundation
import ApplicationServices
import SwiftUI

/// Minimal first-launch setup: microphone and accessibility permissions plus a hint about the default model.
struct FirstRunSetupView: View {
    let onFinish: () -> Void

    @EnvironmentObject private var fluidAudioModelManager: FluidAudioModelManager
    @State private var microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)
    @State private var accessibilityGranted = AXIsProcessTrusted()
    private let refreshTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var parakeetModel: FluidAudioModel? {
        TranscriptionModelRegistry.model(
            forSelectionKey: TranscriptionModelManager.defaultModelName,
            in: TranscriptionModelRegistry.models
        ) as? FluidAudioModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(verbatim: "Willkommen bei Diktat")
                .font(.title2.bold())
            Text(verbatim: "Zwei Berechtigungen werden benötigt, damit Diktat aufnehmen und den Text einfügen kann.")
                .foregroundColor(.secondary)

            permissionRow(
                title: "Mikrofon",
                detail: "Zum Aufnehmen deiner Stimme.",
                granted: microphoneStatus == .authorized,
                buttonTitle: microphoneStatus == .notDetermined ? "Zugriff erlauben" : "Einstellungen öffnen",
                action: requestMicrophone
            )
            permissionRow(
                title: "Bedienungshilfen",
                detail: "Zum Einfügen des Textes in die aktive App.",
                granted: accessibilityGranted,
                buttonTitle: "Zugriff erlauben",
                action: requestAccessibility
            )

            Text(verbatim: modelHint)
                .font(.callout)
                .foregroundColor(.secondary)

            HStack {
                Spacer()
                Button(action: onFinish) { Text(verbatim: "Fertig") }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 460)
        .onReceive(refreshTimer) { _ in
            microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)
            accessibilityGranted = AXIsProcessTrusted()
        }
    }

    private var modelHint: String {
        if let parakeetModel, let status = fluidAudioModelManager.downloadStatus(for: parakeetModel) {
            return "Parakeet v3 wird geladen: \(Int(status.fractionCompleted * 100)) %"
        }
        if let parakeetModel, fluidAudioModelManager.isFluidAudioModelDownloaded(parakeetModel) {
            return "Das Standardmodell Parakeet v3 ist geladen."
        }
        return "Das Standardmodell Parakeet v3 wird beim Start automatisch geladen."
    }

    private func permissionRow(
        title: String, detail: String, granted: Bool, buttonTitle: String, action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: granted ? "checkmark.circle.fill" : "exclamationmark.circle")
                .foregroundColor(granted ? .green : .orange)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: title).font(.headline)
                Text(verbatim: detail).font(.callout).foregroundColor(.secondary)
            }
            Spacer()
            if !granted {
                Button(action: action) { Text(verbatim: buttonTitle) }
            }
        }
    }

    private func requestMicrophone() {
        if microphoneStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { _ in
                DispatchQueue.main.async {
                    microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)
                }
            }
        } else if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }

    private func requestAccessibility() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        accessibilityGranted = AXIsProcessTrustedWithOptions(options)
    }
}

import SwiftUI

struct ModeConfigEditorView: View {
    let mode: ConfigurationMode
    let modeManager: ModeManager
    let onDismiss: () -> Void

    @EnvironmentObject private var transcriptionModelManager: TranscriptionModelManager
    @EnvironmentObject private var modeWarmupStore: ModeFormWarmupStore

    @State private var draft: ModeConfigDraft
    @State private var validationErrors: [ModeValidationError] = []
    @State private var showValidationAlert = false
    @State private var didSaveConfiguration = false

    init(mode: ConfigurationMode, modeManager: ModeManager, onDismiss: @escaping () -> Void) {
        self.mode = mode
        self.modeManager = modeManager
        self.onDismiss = onDismiss
        _draft = State(initialValue: ModeConfigDraft(mode: mode, modeManager: modeManager))
    }

    var body: some View {
        ModeConfigFormView(
            mode: mode,
            modeManager: modeManager,
            draft: $draft,
            validationErrors: $validationErrors,
            showValidationAlert: $showValidationAlert,
            onDismiss: onDismiss,
            onSave: saveConfiguration,
            onDelete: deleteConfiguration
        )
        .onAppear(perform: prepareView)
        .onDisappear(perform: cleanupUnsavedShortcutIfNeeded)
        .onExitCommand(perform: onDismiss)
    }

    private func prepareView() {
        modeWarmupStore.configure(transcriptionModelManager: transcriptionModelManager)

        let snapshot = modeWarmupStore.snapshot

        if case .add = mode {
            draft.inheritUsableTranscriptionModelSelection(from: snapshot)
        } else if let selectedModelName = draft.selectedTranscriptionModelName,
            !snapshot.hasUsableTranscriptionModel(named: selectedModelName)
        {
            draft.selectedTranscriptionModelName = nil
        }

        if let selectedModelName = draft.selectedTranscriptionModelName,
            let model = snapshot.transcriptionModel(named: selectedModelName)
        {
            draft.useCompatibleLanguage(for: model)
        }
    }

    private func saveConfiguration() {
        let config = draft.makeConfig(mode: mode)
        let validator = ModeValidator(modeManager: modeManager)
        validationErrors = validator.validateForSave(config: config, mode: mode)

        if !validationErrors.isEmpty {
            showValidationAlert = true
            return
        }

        switch mode {
        case .add:
            modeManager.addConfiguration(config)
        case .edit:
            modeManager.updateConfiguration(config)
        }

        didSaveConfiguration = true
        onDismiss()
    }

    private func deleteConfiguration() -> ModeRemovalResult {
        let result = modeManager.removeConfiguration(with: draft.id)
        switch result {
        case .removed, .notFound:
            onDismiss()
        case .blockedDefault:
            break
        }
        return result
    }

    private func cleanupUnsavedShortcutIfNeeded() {
        guard case .add = mode, !didSaveConfiguration else {
            return
        }

        ShortcutStore.removeShortcutStorage(for: .mode(draft.id))
    }
}

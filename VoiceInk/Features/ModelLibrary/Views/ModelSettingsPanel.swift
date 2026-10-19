import SwiftUI

struct ModelSettingsPanel: View {
    var body: some View {
        TranscriptionModelSettingsView()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct TranscriptionModelSettingsView: View {
    @EnvironmentObject private var whisperModelManager: WhisperModelManager

    var body: some View {
        Form {
            WhisperPromptSettingsSection(whisperPrompt: whisperModelManager.whisperPrompt)

            FillerWordsSettingsSection()

            AdvancedModelSettingsSection()
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct WhisperPromptSettingsSection: View {
    @ObservedObject var whisperPrompt: WhisperPrompt
    @State private var promptLanguage = "en"
    @State private var draftPrompt = ""
    @State private var isEditing = false

    private var supportedLanguages: [String: String] {
        LanguageDictionary.forProvider(isMultilingual: true, provider: .whisper)
    }

    private var savedPrompt: String {
        whisperPrompt.getLanguagePrompt(for: promptLanguage)
    }

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Picker("Language", selection: $promptLanguage) {
                    ForEach(sortedLanguages, id: \.key) { code, name in
                        Text(name).tag(code)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .accessibilityLabel("Language")
                .disabled(isEditing)

                if promptLanguage != "auto", isEditing {
                    TextEditor(text: $draftPrompt)
                        .font(.body)
                        .padding(6)
                        .frame(height: 72)
                        .scrollContentBackground(.hidden)
                        .background(AppTheme.Surface.control)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.secondary.opacity(0.18))
                        }
                        .accessibilityLabel("Whisper Prompt")

                    HStack(spacing: 10) {
                        Spacer()

                        Button("Cancel", role: .cancel) {
                            draftPrompt = savedPrompt
                            isEditing = false
                        }

                        Button("Save") {
                            whisperPrompt.setCustomPrompt(draftPrompt, for: promptLanguage)
                            isEditing = false
                        }
                        .keyboardShortcut(.defaultAction)
                    }
                    .controlSize(.small)
                } else if promptLanguage != "auto" {
                    if !savedPrompt.isEmpty {
                        Text(savedPrompt)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button("Edit") {
                        draftPrompt = savedPrompt
                        isEditing = true
                    }
                }
            }
            .padding(.vertical, 2)
        } header: {
            HStack(spacing: 4) {
                Text("Whisper Prompt")
                InfoTip(
                    LocalizedStringKey(
                        "Only local Whisper models use this. Add example text to guide spelling and style."
                    ),
                    learnMoreURL: "https://cookbook.openai.com/examples/whisper_prompting_guide#comparison-with-gpt-prompting"
                )
            }
        }
        .onAppear {
            selectCurrentTranscriptionLanguage()
        }
        .onChange(of: promptLanguage) { _, _ in
            draftPrompt = savedPrompt
            isEditing = false
        }
    }

    private var sortedLanguages: [(key: String, value: String)] {
        supportedLanguages.sorted { first, second in
            if first.key == "auto" { return true }
            if second.key == "auto" { return false }
            return first.value.localizedCaseInsensitiveCompare(second.value) == .orderedAscending
        }
    }

    private func selectCurrentTranscriptionLanguage() {
        let activeLanguage =
            ModeManager.shared.currentEffectiveConfiguration?.selectedLanguage
            ?? UserDefaults.standard.string(forKey: "SelectedLanguage")
            ?? "en"

        promptLanguage = supportedLanguages[activeLanguage] == nil ? "en" : activeLanguage
    }
}

private struct AdvancedModelSettingsSection: View {
    @AppStorage("IsVADEnabled") private var isVADEnabled = true
    @AppStorage("AppendTrailingSpace") private var appendTrailingSpace = true
    @AppStorage("PrewarmModelOnWake") private var prewarmModelOnWake = true

    var body: some View {
        Section {
            Toggle(isOn: $appendTrailingSpace) {
                HStack(spacing: 4) {
                    Text("Add Space After Paste")
                    InfoTip("Add a trailing space after pasted transcription output.")
                }
            }
            .toggleStyle(.switch)

            Toggle(isOn: $isVADEnabled) {
                HStack(spacing: 4) {
                    Text("Voice Activity Detection (VAD)")
                    InfoTip("Detect speech segments and filter out silence to improve accuracy of local models.")
                }
            }
            .toggleStyle(.switch)

            Toggle(isOn: $prewarmModelOnWake) {
                HStack(spacing: 4) {
                    Text("Prewarm model (Experimental)")
                    InfoTip(
                        "Turn this on if local transcriptions take longer than expected. It prepares the selected model in the background when the app launches or wakes."
                    )
                }
            }
            .toggleStyle(.switch)
        } header: {
            Text("Advanced")
        }
    }
}

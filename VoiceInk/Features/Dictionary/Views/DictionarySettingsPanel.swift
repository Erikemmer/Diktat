import SwiftUI

private struct DictionaryTransferAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

struct DictionarySettingsPanel: View {
    @Environment(\.modelContext) private var modelContext

    let onDismiss: () -> Void
    @State private var pendingImport: DictionaryImportPayload?
    @State private var transferAlert: DictionaryTransferAlert?

    var body: some View {
        QuickPanelScaffold {
            Form {
                Section {
                    LabeledContent("Quick Add to Dictionary") {
                        ShortcutRecorder(action: .quickAddToDictionary)
                            .controlSize(.small)
                    }
                } header: {
                    Text("Shortcut")
                }

                Section {
                    LabeledContent("Export Dictionary") {
                        Button("Export") {
                            exportDictionary()
                        }
                    }

                    LabeledContent("Import Dictionary") {
                        Button("Import") {
                            chooseDictionaryFile()
                        }
                    }
                } header: {
                    Text("Dictionary Data")
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .contentMargins(.top, 68, for: .scrollContent)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } header: {
            panelHeader
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .sheet(item: $pendingImport) { payload in
            DictionaryImportPreviewSheet(
                payload: payload,
                onCancel: {
                    pendingImport = nil
                },
                onImported: { _ in
                    pendingImport = nil
                }
            )
        }
        .alert(item: $transferAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .cancel(Text("OK"))
            )
        }
    }

    private var panelHeader: some View {
        HStack(spacing: 12) {
            Text("Dictionary Settings")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            AppIconButton(
                systemName: "xmark",
                help: "Close",
                size: 28,
                iconSize: 14,
                cornerRadius: AppTheme.Radius.control,
                action: onDismiss
            )
        }
        .padding(.horizontal, 20)
        .frame(height: QuickPanelMetrics.headerHeight)
    }

    @MainActor
    private func exportDictionary() {
        do {
            let archive = try DictionaryImportExportService.makeArchive(modelContext: modelContext)
            let data = try DictionaryImportExportService.encodeArchive(archive)
            guard let url = try DictionaryFilePanelService.saveDictionaryData(data) else {
                return
            }
            showTransferAlert(
                title: String(localized: "Dictionary Exported"),
                message: String(
                    format: String(localized: "Vocabulary and word replacements were exported to %@."),
                    url.lastPathComponent
                )
            )
        } catch {
            showTransferAlert(
                title: String(localized: "Export Failed"),
                message: error.localizedDescription
            )
        }
    }

    @MainActor
    private func chooseDictionaryFile() {
        do {
            guard let data = try DictionaryFilePanelService.chooseDictionaryData() else {
                return
            }
            pendingImport = try DictionaryImportExportService.decodeArchiveData(data)
        } catch {
            showTransferAlert(
                title: String(localized: "Import Failed"),
                message: error.localizedDescription
            )
        }
    }

    private func showTransferAlert(title: String, message: String) {
        transferAlert = DictionaryTransferAlert(title: title, message: message)
    }
}

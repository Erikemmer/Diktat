import SwiftUI

struct TranscriptionInfoSidePanel: View {
    let transcription: Transcription
    let onClose: () -> Void

    var body: some View {
        QuickPanelScaffold {
            TranscriptionInfoPanel(transcription: transcription)
        } header: {
            header
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("Info")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            AppIconButton(
                systemName: "xmark",
                help: "Close",
                size: 28,
                iconSize: 14,
                cornerRadius: AppTheme.Radius.control,
                action: onClose
            )
        }
        .padding(.horizontal, 20)
        .frame(height: QuickPanelMetrics.headerHeight)
    }
}

/// Reusable component that displays transcription details.
struct TranscriptionInfoPanel: View {
    let transcription: Transcription

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                detailsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, QuickPanelMetrics.topEdgeHeight)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.never)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        infoSection("Details") {
            VStack(spacing: 12) {
                TranscriptionMetadataRow(
                    icon: "calendar",
                    label: "Date",
                    value: transcription.timestamp.formatted(date: .abbreviated, time: .shortened)
                )

                TranscriptionMetadataRow(
                    icon: "hourglass",
                    label: "Duration",
                    value: transcription.duration.formatTiming()
                )

                if let modelName = transcription.transcriptionModelName {
                    TranscriptionMetadataRow(
                        icon: "cpu.fill",
                        label: "Transcription Model",
                        value: modelName
                    )

                    if let duration = transcription.transcriptionDuration {
                        TranscriptionMetadataRow(
                            icon: "clock.fill",
                            label: "Transcription Time",
                            value: duration.formatTiming()
                        )
                    }
                }

                if let modeName = transcription.modeName {
                    TranscriptionMetadataRow(
                        icon: "bolt.fill",
                        label: "Mode",
                        value: modeName
                    )
                }
            }
        }
    }

    // MARK: - Helpers

    private func infoSection<Content: View>(
        _ title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.Text.secondary)

            content()
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(HistoryCardBackground())
        }
    }
}

private struct TranscriptionMetadataRow: View {
    let icon: String
    let label: LocalizedStringKey
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 20, height: 20)

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(1)

            Spacer(minLength: 0)

            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
                .multilineTextAlignment(.trailing)
        }
    }
}

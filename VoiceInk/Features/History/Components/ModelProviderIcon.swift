import Foundation
import SwiftUI

struct ModelProviderIcon: View {
    let modelName: String
    let kind: ModelInsightKind
    var size: CGFloat = 24

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: max(7, size * 0.25))
                .fill(AppTheme.Surface.control)
                .overlay(
                    RoundedRectangle(cornerRadius: max(7, size * 0.25))
                        .stroke(AppTheme.Border.control.opacity(0.2), lineWidth: 1)
                )

            Image(systemName: "waveform")
                .font(.system(size: max(12, size * 0.54), weight: .semibold))
                .foregroundStyle(Color.secondary)
        }
        .frame(width: size, height: size)
        .help(modelName)
    }
}

enum ModelInsightKind: String, Codable, Sendable {
    case transcription
    case enhancement
}

import SwiftUI

struct DashboardInsightRowBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(AppTheme.Insights.elevated)
    }
}

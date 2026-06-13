import SwiftUI

/// Visible, non-dismissive safety notice. Crisis Forecaster is a predictive
/// early-warning and ER-handoff aid — not medical advice and not a diagnosis.
struct DisclaimerFooter: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
            Text("Informational early warning, not medical advice or a diagnosis. It surfaces your own self-management plan and prepares an ER handoff — it doesn't replace your care team. In an emergency, call 911 or your hematologist.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }
}

#Preview {
    DisclaimerFooter().padding()
}

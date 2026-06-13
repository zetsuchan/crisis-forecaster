import SwiftUI

/// The "why" in full: the score, window, and each driver as a card.
struct RiskDetailView: View {
    let risk: RiskSnapshot

    var body: some View {
        List {
            Section {
                LabeledContent("Risk", value: risk.riskLevel.title)
                LabeledContent("Score", value: "\(Int(risk.score)) / 100")
                LabeledContent("Window", value: "Next \(risk.windowHours) hours")
                LabeledContent("Generated") {
                    Text(risk.generatedAt, style: .relative)
                }
            }

            Section("Explanation") {
                Text(risk.explanation)
            }

            if !risk.drivers.isEmpty {
                Section("Signals") {
                    ForEach(risk.drivers) { driver in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: driver.direction.symbol)
                                .foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(driver.factor).font(.subheadline.bold())
                                Text(driver.detail).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            if !risk.actions.isEmpty {
                Section("What to do") {
                    ForEach(Array(risk.actions.enumerated()), id: \.offset) { _, action in
                        Label(action, systemImage: "checkmark.circle")
                    }
                }
            }
        }
        .navigationTitle("The full picture")
        .navigationBarTitleDisplayMode(.inline)
    }
}

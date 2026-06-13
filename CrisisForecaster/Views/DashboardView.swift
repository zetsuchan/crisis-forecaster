import SwiftUI

struct DashboardView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    GreetingHeader(name: model.profile.firstName, risk: model.risk)

                    if model.risk == nil && model.phase == .scoring {
                        ReadingSignalsState()
                    } else if let risk = model.risk {
                        if model.phase == .scoring {
                            RefreshingBanner()
                        }
                        RiskRing(risk: risk)
                        ExplanationCard(text: risk.explanation)
                        if !model.vitals.isEmpty {
                            card { TrendsSection(vitals: model.vitals) }
                        }
                        if !risk.drivers.isEmpty {
                            card { DriversSection(drivers: risk.drivers) }
                        }
                        if !risk.actions.isEmpty {
                            card { ActionsSection(actions: risk.actions) }
                        }
                        if model.passport != nil {
                            PassportStagedNote()
                        }
                        NavigationLink {
                            RiskDetailView(risk: risk)
                        } label: {
                            Label("See the full picture", systemImage: "chart.xyaxis.line")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    } else {
                        EmptyState { Task { await model.runScore() } }
                    }

                    if case .failed(let message) = model.phase {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    DisclaimerFooter()
                }
                .padding()
            }
            .navigationTitle("Today")
            .refreshable { await model.runScore() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await model.runScore() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(model.phase == .scoring)
                }
            }
        }
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct GreetingHeader: View {
    let name: String
    let risk: RiskSnapshot?

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let part = hour < 12 ? "Good morning" : (hour < 18 ? "Good afternoon" : "Good evening")
        return name.isEmpty ? part : "\(part), \(name)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(greeting).font(.title2.bold())
            if let risk {
                Text("Updated \(risk.generatedAt, style: .relative) ago")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ReadingSignalsState: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Reading your signals…")
                .font(.headline)
            Text("Looking at your last two weeks of vitals and the incoming weather.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }
}

private struct RefreshingBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
            Text("Updating your forecast…").font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct RiskRing: View {
    let risk: RiskSnapshot

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().stroke(.quaternary, lineWidth: 14)
                Circle()
                    .trim(from: 0, to: risk.score / 100)
                    .stroke(RiskStyle.color(risk.riskLevel), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack {
                    Image(systemName: RiskStyle.icon(risk.riskLevel))
                        .font(.title)
                        .foregroundStyle(RiskStyle.color(risk.riskLevel))
                    Text(risk.riskLevel.title).font(.title2.bold())
                    Text("\(Int(risk.score)) / 100").font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .frame(width: 200, height: 200)

            Text(risk.riskLevel.headline)
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("Next \(risk.windowHours) hours")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ExplanationCard: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.body)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct DriversSection: View {
    let drivers: [RiskDriver]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What's driving it").font(.headline)
            ForEach(drivers) { driver in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: driver.direction.symbol)
                        .foregroundStyle(.secondary).frame(width: 24)
                    VStack(alignment: .leading) {
                        Text(driver.factor).font(.subheadline.bold())
                        Text(driver.detail).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

private struct ActionsSection: View {
    let actions: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What to do").font(.headline)
            ForEach(Array(actions.enumerated()), id: \.offset) { _, action in
                Label(action, systemImage: "checkmark.circle").font(.subheadline)
            }
        }
    }
}

private struct PassportStagedNote: View {
    var body: some View {
        Label("Your Emergency Passport is staged and ready in the Passport tab.", systemImage: "cross.case.fill")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct EmptyState: View {
    let run: () -> Void
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 48)).foregroundStyle(.secondary)
            Text("No forecast yet").font(.headline)
            Text("Run a forecast to see your crisis risk for the next few days, and why.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button(action: run) {
                Label("Run forecast", systemImage: "sparkles")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(.vertical, 40)
    }
}

#Preview {
    DashboardView().environment(AppModel())
}

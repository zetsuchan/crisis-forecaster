import SwiftUI

struct DashboardView: View {
    @Environment(AppModel.self) private var model
    @State private var showProfile = false

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
                        RiskHero(risk: risk)
                        EngineBadges()
                        if let triage = model.lastTriage {
                            TriageNoteCard(triage: triage)
                        }
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
                        .buttonStyle(.glass)
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
                ToolbarItem(placement: .topBarLeading) {
                    ProfileAvatarButton(name: model.profile.fullName) { showProfile = true }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await model.runScore() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(model.phase == .scoring)
                }
            }
            .sheet(isPresented: $showProfile) { ProfileView() }
        }
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(16)
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

/// Premium hero card: the risk ring on a soft, risk-tinted gradient.
private struct RiskHero: View {
    let risk: RiskSnapshot
    private var tint: Color { RiskStyle.color(risk.riskLevel) }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().stroke(tint.opacity(0.15), lineWidth: 16)
                Circle()
                    .trim(from: 0, to: risk.score / 100)
                    .stroke(tint, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: tint.opacity(0.35), radius: 6)
                VStack(spacing: 2) {
                    Image(systemName: RiskStyle.icon(risk.riskLevel))
                        .font(.title)
                        .foregroundStyle(tint)
                    Text(risk.riskLevel.title)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Text("\(Int(risk.score)) / 100")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 196, height: 196)
            .padding(.top, 8)

            VStack(spacing: 4) {
                Text(risk.riskLevel.headline)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Label("Next \(risk.windowHours) hours", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            LinearGradient(
                colors: [tint.opacity(0.18), tint.opacity(0.04)],
                startPoint: .top, endPoint: .bottom
            ),
            in: RoundedRectangle(cornerRadius: 24)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24).stroke(tint.opacity(0.2), lineWidth: 1)
        )
    }
}

/// Shows the dual-model architecture: Apple's on-device model + Claude Opus 4.8.
private struct EngineBadges: View {
    var body: some View {
        HStack(spacing: 8) {
            badge("apple.logo", "Apple Intelligence", "on-device triage", .secondary)
            badge("sparkles", "Claude Opus 4.8", "forecast", .orange)
        }
        .frame(maxWidth: .infinity)
    }

    private func badge(_ icon: String, _ title: String, _ subtitle: String, _ tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.callout).foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 0) {
                Text(title).font(.caption.weight(.semibold))
                Text(subtitle).font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(12)
    }
}

/// The on-device triage of the latest self-report (Apple Intelligence).
private struct TriageNoteCard: View {
    let triage: TriageResult
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Read on-device", systemImage: "apple.logo")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("concern \(triage.concern)/10")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(triage.concern >= 6 ? .orange : .secondary)
            }
            Text(triage.summary).font(.subheadline)
            Text(triage.source.label).font(.caption2).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassCard(16)
    }
}

private struct ExplanationCard: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.body)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .glassCard(16)
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
            .glassCard(16)
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
            .buttonStyle(.glassProminent)
            .controlSize(.large)
        }
        .padding(.vertical, 40)
    }
}

#Preview {
    DashboardView().environment(AppModel())
}

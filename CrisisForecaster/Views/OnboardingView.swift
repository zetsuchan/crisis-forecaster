import SwiftUI

/// First-launch flow: warm framing, how it works, profile setup, data source.
/// On finish it persists everything and kicks off the first forecast.
struct OnboardingView: View {
    @Environment(AppModel.self) private var model

    private enum Step: Int, CaseIterable { case welcome, how, profile, data }
    @State private var step: Step = .welcome
    @State private var profile: PatientProfile = .demo
    @State private var demoMode = true
    @State private var finishing = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ProgressView(value: Double(step.rawValue + 1), total: Double(Step.allCases.count))
                    .padding(.horizontal)

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                footer
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { profile = model.profile }
    }

    private var title: String {
        switch step {
        case .welcome: "Welcome"
        case .how: "How it works"
        case .profile: "About you"
        case .data: "Your data"
        }
    }

    @ViewBuilder private var content: some View {
        switch step {
        case .welcome: WelcomeStep()
        case .how: HowItWorksStep()
        case .profile:
            Form { ProfileFormFields(profile: $profile) }
        case .data:
            DataSourceStep(demoMode: $demoMode)
        }
    }

    private var footer: some View {
        HStack {
            if step != .welcome {
                Button("Back") {
                    withAnimation { step = Step(rawValue: step.rawValue - 1) ?? .welcome }
                }
                .buttonStyle(.bordered)
            }
            Spacer()
            if step == .data {
                Button {
                    finishing = true
                    Task {
                        await model.completeOnboarding(profile: profile, demoMode: demoMode)
                    }
                } label: {
                    if finishing { ProgressView() } else { Text("Start forecasting") }
                }
                .buttonStyle(.borderedProminent)
                .disabled(finishing)
            } else {
                Button("Continue") {
                    withAnimation { step = Step(rawValue: step.rawValue + 1) ?? .data }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .controlSize(.large)
        .padding()
    }
}

private struct WelcomeStep: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)
                    .padding(.top, 40)
                Text("Crisis Forecaster")
                    .font(.largeTitle.bold())
                Text("A companion for living with sickle cell — built from decades of lived experience, not a clinical dashboard.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Text("Vaso-occlusive crises rarely come from nowhere. Your body and the weather leave signals first. We watch them with you, and explain what we see in plain language — so you can get ahead of it.")
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                DisclaimerFooter()
                    .padding(.top, 8)
            }
            .padding()
        }
    }
}

private struct HowItWorksStep: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                row("heart.fill", "We read your signals", "Resting heart rate, heart-rate variability, blood oxygen, and sleep — and how they're trending, not just today's number.")
                row("cloud.rain.fill", "We add the weather", "Falling barometric pressure, cold fronts, and low humidity are known triggers.")
                row("brain.head.profile", "Claude reasons over it", "It scores your crisis risk for the next 24–72 hours and tells you why — like a friend who understands.")
                row("cross.case.fill", "We stage your passport", "If risk climbs, your ER handoff packet is drafted ahead of time, so the handoff is already done.")
            }
            .padding()
        }
    }

    private func row(_ icon: String, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(body).foregroundStyle(.secondary)
            }
        }
    }
}

private struct DataSourceStep: View {
    @Binding var demoMode: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                choice(
                    title: "Use Demo data",
                    detail: "Replays a realistic 14-day decline. Great for trying it out — no permissions needed.",
                    icon: "play.circle.fill",
                    selected: demoMode
                ) { demoMode = true }

                choice(
                    title: "Connect Apple Health",
                    detail: "Reads your real heart rate, blood oxygen, and sleep. You'll be asked for permission.",
                    icon: "heart.text.square.fill",
                    selected: !demoMode
                ) { demoMode = false }
            }
            .padding()
        }
    }

    private func choice(title: String, detail: String, icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: icon).font(.title)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text(detail).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? Color.accentColor : Color.secondary)
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selected ? Color.accentColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OnboardingView().environment(AppModel())
}

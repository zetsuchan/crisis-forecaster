import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model
    @State private var selection = ProcessInfo.processInfo.arguments.contains("-openPassport") ? "passport" : "today"

    var body: some View {
        if model.hasOnboarded {
            TabView(selection: $selection) {
                Tab("Today", systemImage: "waveform.path.ecg", value: "today") {
                    DashboardView()
                }
                Tab("Check in", systemImage: "figure.mind.and.body", value: "checkin") {
                    CheckInView()
                }
                Tab("Passport", systemImage: "cross.case", value: "passport") {
                    PassportView()
                }
                Tab("Settings", systemImage: "gearshape", value: "settings") {
                    SettingsView()
                }
            }
        } else {
            OnboardingView()
        }
    }
}

#Preview {
    RootView().environment(AppModel())
}

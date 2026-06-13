import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        if model.hasOnboarded {
            TabView(selection: $model.selectedTab) {
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

import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var editingProfile = false
    @State private var confirmReset = false

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            Form {
                Section {
                    Toggle("Demo Mode", isOn: $model.demoMode)
                } header: {
                    Text("Data source")
                } footer: {
                    Text(model.demoMode
                         ? "Replaying a scripted 14-day decline. No HealthKit or WeatherKit needed."
                         : "Reading live HealthKit vitals and WeatherKit. Requires permissions and a real device for full data.")
                }

                Section("Patient") {
                    LabeledContent("Name", value: model.profile.fullName.isEmpty ? "—" : model.profile.fullName)
                    LabeledContent("Variant", value: model.profile.variant)
                    LabeledContent("Hematologist", value: model.profile.hematologistName.isEmpty ? "—" : model.profile.hematologistName)
                    Button("Edit profile") { editingProfile = true }
                }

                Section {
                    Button {
                        Task { await model.runScore() }
                    } label: {
                        Label("Run forecast now", systemImage: "sparkles")
                    }
                    .disabled(model.phase == .scoring)
                } footer: {
                    if case .failed(let message) = model.phase {
                        Text(message).foregroundStyle(.red)
                    }
                }

                Section {
                    Button("Start over (reset onboarding)", role: .destructive) {
                        confirmReset = true
                    }
                } footer: {
                    Text("Wipes your profile, check-ins, and forecasts on this device and returns to onboarding. Useful for a fresh demo recording.")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $editingProfile) {
                ProfileEditor()
            }
            .confirmationDialog("Start over?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset everything", role: .destructive) { model.resetAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears all on-device data and returns to onboarding.")
            }
        }
    }
}

/// Sheet wrapper so profile edits are committed only on Save.
private struct ProfileEditor: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var draft = PatientProfile.empty

    var body: some View {
        NavigationStack {
            Form { ProfileFormFields(profile: $draft) }
                .navigationTitle("Edit profile")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            model.profile = draft
                            dismiss()
                        }
                    }
                }
                .onAppear { draft = model.profile }
        }
    }
}

#Preview {
    SettingsView().environment(AppModel())
}

import SwiftUI

/// Dedicated, editable profile page opened from the Today nav bar. Edits commit on
/// Save and persist (feeding the Passport).
struct ProfileView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var draft = PatientProfile.empty

    var body: some View {
        NavigationStack {
            Form { ProfileFormFields(profile: $draft) }
                .navigationTitle("Your profile")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { model.profile = draft; dismiss() }
                    }
                }
                .onAppear { draft = model.profile }
        }
    }
}

/// Compact avatar button (initials) for the Today nav bar.
struct ProfileAvatarButton: View {
    let name: String
    let action: () -> Void

    private var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        let chars = parts.compactMap { $0.first }
        return chars.isEmpty ? "?" : String(chars).uppercased()
    }

    var body: some View {
        Button(action: action) {
            Text(initials)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(
                    LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: Circle()
                )
        }
        .accessibilityLabel("Your profile")
    }
}

#Preview {
    ProfileView().environment(AppModel())
}

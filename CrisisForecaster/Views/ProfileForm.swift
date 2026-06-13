import SwiftUI

/// Reusable patient-profile fields, shared by onboarding and Settings.
/// Array fields (meds, allergies) are edited as comma-separated text.
struct ProfileFormFields: View {
    @Binding var profile: PatientProfile

    var body: some View {
        Group {
            Section("You") {
                TextField("Full name", text: $profile.fullName)
                TextField("Variant (e.g. HbSS)", text: $profile.variant)
            }

            Section("Baseline vitals") {
                NumberField("Resting heart rate (bpm)", value: $profile.baselineRestingHR)
                PercentField("Baseline SpO2 (%)", fraction: $profile.baselineSpO2)
            }

            Section("Medications") {
                CSVField("Comma-separated", values: $profile.medications)
            }

            Section("Allergies") {
                CSVField("Comma-separated", values: $profile.allergies)
            }

            Section("Pain plan") {
                TextField("What works for you, and your ER triggers", text: $profile.painPlan, axis: .vertical)
                    .lineLimit(3...8)
            }

            Section("Care team") {
                TextField("Hematologist name", text: $profile.hematologistName)
                TextField("Hematologist phone", text: $profile.hematologistPhone)
                    .keyboardType(.phonePad)
                TextField("Emergency contact name", text: $profile.emergencyContactName)
                TextField("Emergency contact phone", text: $profile.emergencyContactPhone)
                    .keyboardType(.phonePad)
            }

            Section("Notes") {
                TextField("Anything else the ER should know", text: $profile.notes, axis: .vertical)
                    .lineLimit(2...6)
            }
        }
    }
}

private struct NumberField: View {
    let title: String
    @Binding var value: Double?
    init(_ title: String, value: Binding<Double?>) { self.title = title; self._value = value }

    var body: some View {
        TextField(title, value: $value, format: .number)
            .keyboardType(.decimalPad)
    }
}

/// Edits a 0–1 fraction as a whole-number percent.
private struct PercentField: View {
    let title: String
    @Binding var fraction: Double?
    init(_ title: String, fraction: Binding<Double?>) { self.title = title; self._fraction = fraction }

    private var percent: Binding<Double?> {
        Binding(
            get: { fraction.map { $0 * 100 } },
            set: { fraction = $0.map { $0 / 100 } }
        )
    }

    var body: some View {
        TextField(title, value: percent, format: .number)
            .keyboardType(.decimalPad)
    }
}

/// Edits a [String] as comma-separated text.
private struct CSVField: View {
    let title: String
    @Binding var values: [String]
    init(_ title: String, values: Binding<[String]>) { self.title = title; self._values = values }

    private var text: Binding<String> {
        Binding(
            get: { values.joined(separator: ", ") },
            set: { values = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
        )
    }

    var body: some View {
        TextField(title, text: text, axis: .vertical)
            .lineLimit(1...4)
    }
}

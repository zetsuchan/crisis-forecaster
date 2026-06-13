import SwiftUI

struct PassportView: View {
    @Environment(AppModel.self) private var model
    @State private var staging = false

    var body: some View {
        NavigationStack {
            Group {
                if let passport = model.passport {
                    ScrollView {
                        VStack(spacing: 16) {
                            PassportHeader(profile: passport.profile)
                            TriageCard(summary: passport.triageSummary, context: passport.riskContext)
                            if !passport.criticalFlags.isEmpty {
                                FlagsCard(flags: passport.criticalFlags, allergies: passport.profile.allergies)
                            }
                            VitalsCard(profile: passport.profile)
                            if !passport.profile.medications.isEmpty {
                                ListCard(title: "Medications", icon: "pills.fill", tint: .blue, items: passport.profile.medications)
                            }
                            if !passport.profile.allergies.isEmpty {
                                ListCard(title: "Allergies", icon: "exclamationmark.triangle.fill", tint: .red, items: passport.profile.allergies)
                            }
                            if !passport.profile.painPlan.isEmpty {
                                PainPlanCard(text: passport.profile.painPlan)
                            }
                            CareTeamCard(profile: passport.profile)
                            Text("Staged \(passport.generatedAt, style: .relative) ago")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            DisclaimerFooter()
                        }
                        .padding()
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            ShareLink(item: passport.shareText) {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                    }
                } else {
                    emptyState
                }
            }
            .navigationTitle("Passport")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "cross.case")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No passport staged yet")
                .font(.headline)
            Text("Your ER handoff packet is staged automatically when risk is elevated. You can also stage it now.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button {
                staging = true
                Task { await model.stagePassport(); staging = false }
            } label: {
                if staging { ProgressView() } else { Label("Stage passport now", systemImage: "cross.case.fill") }
            }
            .buttonStyle(.glassProminent)
            .disabled(model.risk == nil || staging)
            if model.risk == nil {
                Text("Run a forecast first.").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

// MARK: - Cards

private struct PassportHeader: View {
    let profile: PatientProfile
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "cross.case.fill")
                .font(.system(size: 34))
                .foregroundStyle(.white)
            Text(profile.fullName.isEmpty ? "Patient" : profile.fullName)
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text(profile.variant)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(.white.opacity(0.25), in: Capsule())
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            LinearGradient(colors: [.red, .pink], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }
}

private struct TriageCard: View {
    let summary: String
    let context: String
    var body: some View {
        SectionCard(title: "Triage summary", icon: "stethoscope", tint: .red) {
            VStack(alignment: .leading, spacing: 8) {
                Text(summary).font(.body)
                Text(context).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

private struct FlagsCard: View {
    let flags: [String]
    let allergies: [String]
    var body: some View {
        SectionCard(title: "Critical flags", icon: "flag.fill", tint: .orange) {
            FlowChips(items: flags) { flag in
                let isAllergy = allergies.contains { flag.localizedCaseInsensitiveContains($0) }
                return isAllergy ? .red : .orange
            }
        }
    }
}

private struct VitalsCard: View {
    let profile: PatientProfile
    var body: some View {
        SectionCard(title: "Baseline vitals", icon: "waveform.path.ecg", tint: .green) {
            HStack(spacing: 12) {
                StatTile(label: "Resting HR", value: profile.baselineRestingHR.map { "\(Int($0))" } ?? "—", unit: "bpm")
                StatTile(label: "SpO2", value: profile.baselineSpO2.map { "\(Int($0 * 100))" } ?? "—", unit: "%")
            }
        }
    }
}

private struct ListCard: View {
    let title: String
    let icon: String
    let tint: Color
    let items: [String]
    var body: some View {
        SectionCard(title: title, icon: icon, tint: tint) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "circle.fill").font(.system(size: 5)).foregroundStyle(tint).padding(.top, 7)
                        Text(item)
                    }
                }
            }
        }
    }
}

private struct PainPlanCard: View {
    let text: String
    var body: some View {
        SectionCard(title: "Pain plan", icon: "heart.text.square.fill", tint: .purple) {
            Text(text).font(.body)
        }
    }
}

private struct CareTeamCard: View {
    let profile: PatientProfile
    var body: some View {
        SectionCard(title: "Care team", icon: "person.2.fill", tint: .blue) {
            VStack(spacing: 12) {
                ContactRow(role: "Hematologist", name: profile.hematologistName, phone: profile.hematologistPhone)
                Divider()
                ContactRow(role: "Emergency contact", name: profile.emergencyContactName, phone: profile.emergencyContactPhone)
            }
        }
    }
}

private struct ContactRow: View {
    let role: String
    let name: String
    let phone: String
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(role).font(.caption).foregroundStyle(.secondary)
                Text(name.isEmpty ? "—" : name).font(.subheadline.weight(.medium))
            }
            Spacer()
            if let url = telURL {
                Link(destination: url) {
                    Label(phone, systemImage: "phone.fill").labelStyle(.iconOnly)
                        .padding(8).background(.blue.opacity(0.15), in: Circle()).foregroundStyle(.blue)
                }
            }
        }
    }
    private var telURL: URL? {
        let digits = phone.filter { $0.isNumber || $0 == "+" }
        return digits.isEmpty ? nil : URL(string: "tel://\(digits)")
    }
}

// MARK: - Reusable bits

private struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    let tint: Color
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(tint)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassCard(16)
    }
}

private struct StatTile: View {
    let label: String
    let value: String
    let unit: String
    var body: some View {
        VStack(spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value).font(.title2.bold())
                Text(unit).font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }
}

/// Simple wrapping chip layout using iOS 16+ Layout via a flexible HStack fallback.
private struct FlowChips: View {
    let items: [String]
    let color: (String) -> Color
    var body: some View {
        FlexibleWrap(items: items) { item in
            Text(item)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(color(item).opacity(0.15), in: Capsule())
                .foregroundStyle(color(item))
        }
    }
}

/// Lightweight wrapping layout for chips.
private struct FlexibleWrap<Item: Hashable, ItemView: View>: View {
    let items: [Item]
    @ViewBuilder let content: (Item) -> ItemView

    var body: some View {
        WrapLayout(spacing: 8) {
            ForEach(items, id: \.self) { content($0) }
        }
    }
}

private struct WrapLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    PassportView().environment(AppModel())
}

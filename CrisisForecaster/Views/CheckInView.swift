import SwiftUI

/// Patient self-report — "learn YOUR language for your body." Saving folds the
/// report into the next forecast and the Passport.
struct CheckInView: View {
    @Environment(AppModel.self) private var model

    @State private var painLevel: Double = 0
    @State private var locations: Set<String> = []
    @State private var hydration: CheckIn.Hydration = .ok
    @State private var notes = ""
    @State private var saving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("How's your pain right now?") {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("\(Int(painLevel))").font(.title.bold()).foregroundStyle(painColor)
                            Text("/ 10").foregroundStyle(.secondary)
                            Spacer()
                            Text(painWord).font(.subheadline).foregroundStyle(painColor)
                        }
                        Slider(value: $painLevel, in: 0...10, step: 1)
                            .tint(painColor)
                    }
                    .padding(.vertical, 4)
                }

                Section("Where?") {
                    WrapChips(options: CheckIn.bodyLocations, selection: $locations)
                }

                Section("Hydration today") {
                    Picker("Hydration", selection: $hydration) {
                        ForEach(CheckIn.Hydration.allCases, id: \.self) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Anything else?") {
                    TextField("In your own words", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section {
                    Button {
                        saving = true
                        let entry = CheckIn(
                            painLevel: Int(painLevel),
                            painLocations: Array(locations).sorted(),
                            hydration: hydration,
                            notes: notes
                        )
                        Task {
                            await model.addCheckIn(entry)
                            saving = false
                            reset()
                        }
                    } label: {
                        if saving {
                            HStack { ProgressView(); Text("Updating your forecast…") }
                        } else {
                            Label("Save check-in", systemImage: "checkmark.circle.fill")
                        }
                    }
                    .disabled(saving)
                } footer: {
                    Text("Your check-in is woven into your next forecast and your Emergency Passport.")
                }

                if !model.checkIns.isEmpty {
                    Section("Recent") {
                        ForEach(model.checkIns.prefix(7)) { entry in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text("Pain \(entry.painLevel)/10").font(.subheadline.bold())
                                    Spacer()
                                    Text(entry.date, style: .date).font(.caption).foregroundStyle(.secondary)
                                }
                                if !entry.painLocations.isEmpty {
                                    Text(entry.painLocations.joined(separator: ", ")).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Check in")
        }
    }

    private var painColor: Color {
        switch Int(painLevel) {
        case 0...2: .green
        case 3...5: .yellow
        case 6...7: .orange
        default: .red
        }
    }
    private var painWord: String {
        switch Int(painLevel) {
        case 0: "None"
        case 1...2: "Mild"
        case 3...5: "Moderate"
        case 6...7: "Bad"
        default: "Severe"
        }
    }
    private func reset() {
        painLevel = 0; locations = []; hydration = .ok; notes = ""
    }
}

/// Multi-select chips for body locations.
private struct WrapChips: View {
    let options: [String]
    @Binding var selection: Set<String>

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(options, id: \.self) { option in
                let on = selection.contains(option)
                Button {
                    if on { selection.remove(option) } else { selection.insert(option) }
                } label: {
                    Text(option)
                        .font(.subheadline)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(on ? Color.accentColor : Color(.secondarySystemBackground), in: Capsule())
                        .foregroundStyle(on ? .white : .primary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Minimal wrapping layout.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > maxW { x = 0; y += rowH + spacing; rowH = 0 }
            x += sz.width + spacing; rowH = max(rowH, sz.height)
        }
        return CGSize(width: maxW == .infinity ? x : maxW, height: y + rowH)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > bounds.maxX { x = bounds.minX; y += rowH + spacing; rowH = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(sz))
            x += sz.width + spacing; rowH = max(rowH, sz.height)
        }
    }
}

#Preview {
    CheckInView().environment(AppModel())
}

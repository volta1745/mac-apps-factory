import SwiftUI

struct AddSessionView: View {
    @EnvironmentObject var store: SessionStore
    @Environment(\.dismiss) private var dismiss

    @State private var type: MeditationType = .breath
    @State private var durationMinutes: Int = 10
    @State private var calmnessBefore: Int = 3
    @State private var calmnessAfter: Int = 3
    @State private var notes: String = ""
    @State private var date: Date = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(.green)
                Text("Log Meditation Session")
                    .font(.headline)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Date & Type
                    GroupBox("Session Details") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Date & Time")
                                    .frame(width: 110, alignment: .leading)
                                DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                    .labelsHidden()
                            }

                            HStack(alignment: .top) {
                                Text("Type")
                                    .frame(width: 110, alignment: .leading)
                                    .padding(.top, 4)
                                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 8) {
                                    ForEach(MeditationType.allCases, id: \.self) { t in
                                        TypeButton(meditationType: t, selected: type == t) {
                                            type = t
                                        }
                                    }
                                }
                            }
                        }
                        .padding(8)
                    }

                    // Duration
                    GroupBox("Duration") {
                        HStack(spacing: 16) {
                            Stepper("\(durationMinutes) min", value: $durationMinutes, in: 1...120)
                            Spacer()
                            DurationPresets(selected: $durationMinutes)
                        }
                        .padding(8)
                    }

                    // Calmness
                    GroupBox("Calmness Level (1 = low, 5 = high)") {
                        VStack(alignment: .leading, spacing: 12) {
                            CalmnessRow(label: "Before", value: $calmnessBefore)
                            CalmnessRow(label: "After ", value: $calmnessAfter)
                            let delta = calmnessAfter - calmnessBefore
                            HStack {
                                Text("Change")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                Text(delta == 0 ? "No change" : (delta > 0 ? "+\(delta) ↑" : "\(delta) ↓"))
                                    .font(.caption.bold())
                                    .foregroundStyle(delta > 0 ? .green : delta < 0 ? .orange : .secondary)
                            }
                            .padding(.leading, 80)
                        }
                        .padding(8)
                    }

                    // Notes
                    GroupBox("Notes (optional)") {
                        TextEditor(text: $notes)
                            .font(.body)
                            .frame(minHeight: 72)
                            .padding(4)
                    }
                }
                .padding()
            }

            Divider()

            HStack {
                Spacer()
                Button("Save Session") {
                    let session = MeditationSession(
                        date: date,
                        type: type,
                        durationMinutes: durationMinutes,
                        calmnessBefore: calmnessBefore,
                        calmnessAfter: calmnessAfter,
                        notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                    store.add(session)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 480, height: 560)
    }
}

// MARK: - Sub-components

private struct TypeButton: View {
    let meditationType: MeditationType
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: meditationType.symbol)
                Text(meditationType.rawValue)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(selected ? Color.accentColor.opacity(0.15) : Color(NSColor.controlBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(selected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

private struct DurationPresets: View {
    @Binding var selected: Int
    let presets = [5, 10, 15, 20, 30]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(presets, id: \.self) { p in
                Button("\(p)") { selected = p }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(selected == p ? .accentColor : nil)
            }
        }
    }
}

private struct CalmnessRow: View {
    let label: String
    @Binding var value: Int

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .foregroundStyle(.secondary)
                .font(.callout)
                .frame(width: 50, alignment: .trailing)
            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { i in
                    Button {
                        value = i
                    } label: {
                        Image(systemName: i <= value ? "circle.fill" : "circle")
                            .foregroundStyle(calmnessColor(i))
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                }
            }
            Text(calmnessLabel(value))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func calmnessColor(_ level: Int) -> Color {
        switch level {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .mint
        case 5: return .green
        default: return .gray
        }
    }

    private func calmnessLabel(_ v: Int) -> String {
        switch v {
        case 1: return "Anxious"
        case 2: return "Restless"
        case 3: return "Neutral"
        case 4: return "Calm"
        case 5: return "Serene"
        default: return ""
        }
    }
}

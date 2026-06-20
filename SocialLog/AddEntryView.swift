import SwiftUI

struct AddEntryView: View {
    @ObservedObject var store: SocialStore
    @Environment(\.dismiss) private var dismiss

    @State private var personName: String = ""
    @State private var interactionType: InteractionType = .inPerson
    @State private var durationMinutes: Int = 30
    @State private var energyImpact: Int = 3
    @State private var notes: String = ""
    @State private var date: Date = Date()

    private let durations = [5, 10, 15, 20, 30, 45, 60, 90, 120, 180]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Log Interaction")
                    .font(.title2).fontWeight(.semibold)
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Person / group name
                    Group {
                        Label("Who did you connect with?", systemImage: "person.fill")
                            .font(.headline)
                        TextField("Name or group (e.g. Alice, Team standup)", text: $personName)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Interaction type
                    Group {
                        Label("How?", systemImage: "bubble.left.and.bubble.right.fill")
                            .font(.headline)
                        Picker("Type", selection: $interactionType) {
                            ForEach(InteractionType.allCases) { t in
                                Label(t.rawValue, systemImage: t.icon).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Duration
                    Group {
                        Label("Duration", systemImage: "clock.fill")
                            .font(.headline)
                        Picker("Duration", selection: $durationMinutes) {
                            ForEach(durations, id: \.self) { min in
                                Text(min < 60
                                    ? "\(min) min"
                                    : "\(min / 60)h\(min % 60 > 0 ? " \(min % 60)m" : "")"
                                ).tag(min)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Energy impact
                    Group {
                        Label("How did it affect your energy?", systemImage: "bolt.heart.fill")
                            .font(.headline)

                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { level in
                                Button {
                                    energyImpact = level
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: level <= energyImpact
                                            ? "circle.fill" : "circle")
                                            .font(.title3)
                                            .foregroundColor(energyColor(level))
                                        Text(energyShortLabel(level))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.vertical, 4)

                        Text(energyFullLabel(energyImpact))
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }

                    // Date/time
                    Group {
                        Label("When", systemImage: "calendar")
                            .font(.headline)
                        DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                    }

                    // Notes
                    Group {
                        Label("Notes (optional)", systemImage: "note.text")
                            .font(.headline)
                        TextEditor(text: $notes)
                            .frame(height: 70)
                            .font(.body)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                .padding()
            }

            Divider()

            HStack {
                Spacer()
                Button("Log Interaction") {
                    let entry = SocialEntry(
                        date: date,
                        personName: personName.trimmingCharacters(in: .whitespaces),
                        interactionType: interactionType,
                        durationMinutes: durationMinutes,
                        energyImpact: energyImpact,
                        notes: notes.trimmingCharacters(in: .whitespaces)
                    )
                    store.add(entry)
                    dismiss()
                }
                .disabled(personName.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
        }
        .frame(width: 480, height: 620)
    }

    private func energyColor(_ level: Int) -> Color {
        switch level {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        case 5: return .teal
        default: return .yellow
        }
    }

    private func energyShortLabel(_ level: Int) -> String {
        switch level {
        case 1: return "Drained"
        case 2: return "Low"
        case 3: return "Neutral"
        case 4: return "Good"
        case 5: return "Energized"
        default: return ""
        }
    }

    private func energyFullLabel(_ level: Int) -> String {
        switch level {
        case 1: return "Very Drained — this took a lot out of me"
        case 2: return "Slightly Drained — I need a bit of recovery"
        case 3: return "Neutral — no real impact either way"
        case 4: return "Energized — I feel lifted up"
        case 5: return "Very Energized — this made my day!"
        default: return ""
        }
    }
}

import SwiftUI

struct AddSleepEntryView: View {
    let onSave: (SleepEntry) -> Void

    @Environment(\.dismiss) private var dismiss

    // Default: bedtime = yesterday 11 pm, wake = today 7 am
    @State private var bedtime: Date = {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        c.hour = 23; c.minute = 0; c.second = 0
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.date(from: c) ?? Date()) ?? Date()
        return yesterday
    }()

    @State private var wakeTime: Date = {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        c.hour = 7; c.minute = 0; c.second = 0
        return Calendar.current.date(from: c) ?? Date()
    }()

    @State private var quality: Int = 3
    @State private var notes: String = ""
    @State private var validationError: String? = nil

    private var durationMinutes: Int {
        max(0, Int(wakeTime.timeIntervalSince(bedtime) / 60))
    }

    private var durationText: String {
        let h = durationMinutes / 60
        let m = durationMinutes % 60
        switch (h, m) {
        case (0, _): return "\(m) min"
        case (_, 0): return "\(h) hr"
        default:     return "\(h) hr \(m) min"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("Log Sleep Session")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Times section
                    GroupBox("Sleep Times") {
                        VStack(spacing: 12) {
                            LabeledRow(label: "Bedtime") {
                                DatePicker("", selection: $bedtime, displayedComponents: [.date, .hourAndMinute])
                                    .labelsHidden()
                            }
                            Divider()
                            LabeledRow(label: "Wake Time") {
                                DatePicker("", selection: $wakeTime, displayedComponents: [.date, .hourAndMinute])
                                    .labelsHidden()
                            }
                            Divider()
                            LabeledRow(label: "Duration") {
                                Text(durationText)
                                    .foregroundColor(durationMinutes < 60 ? .red : .primary)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    // Quality section
                    GroupBox("Sleep Quality") {
                        VStack(spacing: 8) {
                            HStack {
                                ForEach(1...5, id: \.self) { i in
                                    Button {
                                        quality = i
                                    } label: {
                                        Image(systemName: i <= quality ? "star.fill" : "star")
                                            .font(.title)
                                            .foregroundColor(i <= quality ? .yellow : .secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                Spacer()
                                Text(qualityLabel)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    // Notes section
                    GroupBox("Notes (optional)") {
                        TextEditor(text: $notes)
                            .frame(minHeight: 72, maxHeight: 120)
                            .font(.body)
                    }

                    if let error = validationError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding()
            }

            Divider()

            // Buttons
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save Entry") { attemptSave() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .frame(width: 420, height: 520)
    }

    // MARK: - Helpers

    private var qualityLabel: String {
        switch quality {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Okay"
        case 4: return "Good"
        case 5: return "Great"
        default: return ""
        }
    }

    private func attemptSave() {
        guard durationMinutes >= 30 else {
            validationError = "Wake time must be at least 30 minutes after bedtime."
            return
        }
        let entry = SleepEntry(bedtime: bedtime, wakeTime: wakeTime, quality: quality, notes: notes.trimmingCharacters(in: .whitespacesAndNewlines))
        onSave(entry)
        dismiss()
    }
}

// MARK: - LabeledRow helper

struct LabeledRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            Spacer()
            content()
        }
    }
}

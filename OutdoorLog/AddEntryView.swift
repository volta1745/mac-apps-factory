import SwiftUI

struct AddEntryView: View {
    @ObservedObject var store: OutdoorStore
    @Environment(\.dismiss) private var dismiss

    @State private var durationMinutes: Int = 30
    @State private var activity: ActivityType = .walk
    @State private var weather: WeatherType = .sunny
    @State private var refreshmentRating: Int = 3
    @State private var notes: String = ""

    private let durationOptions: [Int] = [5, 10, 15, 20, 30, 45, 60, 90, 120]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Log Outdoor Time")
                .font(.title2).bold()

            // Duration
            VStack(alignment: .leading, spacing: 6) {
                Label("Duration", systemImage: "clock")
                    .font(.headline)
                Picker("Duration", selection: $durationMinutes) {
                    ForEach(durationOptions, id: \.self) { min in
                        Text(min < 60
                             ? "\(min) min"
                             : "\(min / 60)h \(min % 60 > 0 ? "\(min % 60)m" : "")"
                        ).tag(min)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Activity
            VStack(alignment: .leading, spacing: 6) {
                Label("Activity", systemImage: "figure.walk")
                    .font(.headline)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                    ForEach(ActivityType.allCases, id: \.self) { type in
                        Button {
                            activity = type
                        } label: {
                            VStack(spacing: 2) {
                                Text(type.emoji).font(.title3)
                                Text(type.rawValue)
                                    .font(.caption2)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(6)
                            .background(activity == type ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(activity == type ? Color.accentColor : Color.clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Weather
            VStack(alignment: .leading, spacing: 6) {
                Label("Weather", systemImage: "cloud.sun")
                    .font(.headline)
                HStack(spacing: 8) {
                    ForEach(WeatherType.allCases, id: \.self) { type in
                        Button {
                            weather = type
                        } label: {
                            VStack(spacing: 2) {
                                Text(type.emoji).font(.title3)
                                Text(type.rawValue)
                                    .font(.caption2)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(6)
                            .background(weather == type ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(weather == type ? Color.accentColor : Color.clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Refreshment rating
            VStack(alignment: .leading, spacing: 6) {
                Label("How refreshing was it?", systemImage: "leaf")
                    .font(.headline)
                HStack {
                    ForEach(1...5, id: \.self) { level in
                        Button {
                            refreshmentRating = level
                        } label: {
                            VStack(spacing: 2) {
                                Image(systemName: level <= refreshmentRating ? "leaf.fill" : "leaf")
                                    .foregroundColor(level <= refreshmentRating ? .green : .secondary)
                                    .font(.title3)
                                if level == refreshmentRating {
                                    Text(ratingLabel(level))
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Notes
            VStack(alignment: .leading, spacing: 6) {
                Label("Notes (optional)", systemImage: "note.text")
                    .font(.headline)
                TextEditor(text: $notes)
                    .frame(height: 60)
                    .padding(4)
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
            }

            // Buttons
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
                Spacer()
                Button("Log Entry") {
                    let entry = OutdoorEntry(
                        durationMinutes: durationMinutes,
                        activity: activity,
                        weather: weather,
                        refreshmentRating: refreshmentRating,
                        notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                    store.add(entry)
                    dismiss()
                }
                .keyboardShortcut(.return, modifiers: .command)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 540)
    }

    private func ratingLabel(_ level: Int) -> String {
        switch level {
        case 1: return "Draining"
        case 2: return "Neutral"
        case 3: return "Okay"
        case 4: return "Refreshing"
        case 5: return "Energizing"
        default: return ""
        }
    }
}

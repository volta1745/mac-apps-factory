import SwiftUI

struct AddNapView: View {
    @ObservedObject var store: NapStore
    @Environment(\.dismiss) var dismiss

    @State private var napType: NapType = .power
    @State private var duration: Int = 20
    @State private var sleepQuality: Int = 3
    @State private var alertnessAfter: Int = 3
    @State private var notes: String = ""
    @State private var napDate: Date = Date()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Log a Nap")
                    .font(.title2).bold()
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {

                    // Nap type
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Nap Type", systemImage: "bed.double.fill")
                            .font(.headline)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
                            ForEach(NapType.allCases, id: \.self) { type in
                                NapTypeCard(type: type, isSelected: napType == type)
                                    .onTapGesture {
                                        napType = type
                                        duration = type.idealMinutes
                                    }
                            }
                        }
                    }

                    // Time
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Nap Start Time", systemImage: "clock")
                            .font(.headline)
                        DatePicker("", selection: $napDate, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                    }

                    // Duration
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Duration", systemImage: "timer")
                            .font(.headline)
                        HStack {
                            Slider(value: Binding(
                                get: { Double(duration) },
                                set: { duration = Int($0) }
                            ), in: 1...120, step: 1)
                            Text("\(duration) min")
                                .font(.system(.body, design: .monospaced))
                                .frame(width: 60, alignment: .trailing)
                        }
                    }

                    // Sleep quality
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Ease of Falling Asleep", systemImage: "zzz")
                            .font(.headline)
                        HStack(spacing: 12) {
                            Text("Hard").font(.caption).foregroundColor(.secondary)
                            StarRow(value: $sleepQuality, color: .indigo)
                            Text("Easy").font(.caption).foregroundColor(.secondary)
                        }
                    }

                    // Alertness after
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Post-Nap Alertness", systemImage: "sun.max.fill")
                            .font(.headline)
                        HStack(spacing: 12) {
                            Text("Groggy").font(.caption).foregroundColor(.secondary)
                            StarRow(value: $alertnessAfter, color: .orange)
                            Text("Sharp").font(.caption).foregroundColor(.secondary)
                        }
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Notes (optional)", systemImage: "note.text")
                            .font(.headline)
                        TextEditor(text: $notes)
                            .frame(height: 60)
                            .padding(6)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3)))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }

            Divider()

            HStack {
                Spacer()
                Button("Save Nap") {
                    let entry = NapEntry(
                        date: napDate,
                        napType: napType,
                        durationMinutes: duration,
                        sleepQuality: sleepQuality,
                        alertnessAfter: alertnessAfter,
                        notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                    store.add(entry)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.indigo)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(width: 480, height: 580)
    }
}

struct NapTypeCard: View {
    let type: NapType
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: type.icon)
                .font(.title2)
                .foregroundColor(isSelected ? .white : .indigo)
            Text(type.rawValue)
                .font(.caption).bold()
                .foregroundColor(isSelected ? .white : .primary)
            Text("\(type.idealMinutes) min")
                .font(.caption2)
                .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(isSelected ? Color.indigo : Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? Color.clear : Color.secondary.opacity(0.25)))
    }
}

struct StarRow: View {
    @Binding var value: Int
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= value ? "star.fill" : "star")
                    .font(.title3)
                    .foregroundColor(i <= value ? color : .secondary.opacity(0.4))
                    .onTapGesture { value = i }
            }
        }
    }
}

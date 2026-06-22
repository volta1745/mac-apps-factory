import SwiftUI

struct AddSessionView: View {
    @ObservedObject var store: BreathStore
    @Environment(\.dismiss) private var dismiss

    @State private var technique: BreathTechnique = .boxBreathing
    @State private var rounds: Int = 3
    @State private var durationMinutes: Int = 5
    @State private var stressBefore: Int = 3
    @State private var calmAfter: Int = 4
    @State private var notes: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Log Breathing Session")
                    .font(.title2).bold()
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Technique
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Technique", systemImage: "wind")
                            .font(.headline)
                        Picker("Technique", selection: $technique) {
                            ForEach(BreathTechnique.allCases, id: \.self) { t in
                                Label(t.rawValue, systemImage: t.icon).tag(t)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        Text(technique.hint)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    }

                    Divider()

                    // Rounds & Duration
                    HStack(spacing: 32) {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Rounds / Cycles", systemImage: "repeat")
                                .font(.headline)
                            Stepper("\(rounds)", value: $rounds, in: 1...50)
                                .fixedSize()
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Duration (min)", systemImage: "clock")
                                .font(.headline)
                            Stepper("\(durationMinutes) min", value: $durationMinutes, in: 1...120)
                                .fixedSize()
                        }
                    }

                    Divider()

                    // Stress before
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Stress / Tension Before", systemImage: "bolt.fill")
                            .font(.headline)
                        HStack(spacing: 6) {
                            Text("Calm").font(.caption).foregroundStyle(.secondary)
                            DotRater(value: $stressBefore, color: .orange)
                            Text("Tense").font(.caption).foregroundStyle(.secondary)
                        }
                    }

                    // Calm after
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Calm / Clarity After", systemImage: "sparkles")
                            .font(.headline)
                        HStack(spacing: 6) {
                            Text("Low").font(.caption).foregroundStyle(.secondary)
                            DotRater(value: $calmAfter, color: .teal)
                            Text("High").font(.caption).foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    // Notes
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Notes (optional)", systemImage: "note.text")
                            .font(.headline)
                        TextEditor(text: $notes)
                            .frame(minHeight: 60, maxHeight: 100)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.3)))
                            .font(.body)
                    }
                }
                .padding()
            }

            Divider()

            HStack {
                Spacer()
                Button("Save Session") {
                    store.add(BreathSession(
                        technique: technique,
                        rounds: rounds,
                        durationMinutes: durationMinutes,
                        stressBefore: stressBefore,
                        calmAfter: calmAfter,
                        notes: notes
                    ))
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding()
        }
        .frame(width: 440, height: 540)
    }
}

// MARK: – Dot Rating Control

struct DotRater: View {
    @Binding var value: Int
    var color: Color
    var count: Int = 5

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...count, id: \.self) { i in
                Circle()
                    .fill(i <= value ? color : color.opacity(0.18))
                    .frame(width: 26, height: 26)
                    .onTapGesture { value = i }
                    .overlay(
                        Circle()
                            .stroke(i <= value ? color : color.opacity(0.3), lineWidth: 1)
                    )
                    .overlay(
                        Text("\(i)")
                            .font(.caption2.bold())
                            .foregroundStyle(i <= value ? .white : color.opacity(0.6))
                    )
            }
        }
    }
}

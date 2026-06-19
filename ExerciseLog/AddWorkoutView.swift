import SwiftUI

struct AddWorkoutView: View {
    @EnvironmentObject var store: WorkoutStore
    @Binding var isPresented: Bool

    @State private var workoutType: WorkoutEntry.WorkoutType = .running
    @State private var date: Date = Date()
    @State private var durationMinutes: Int = 30
    @State private var intensity: WorkoutEntry.Intensity = .moderate
    @State private var notes: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Log Workout")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding([.horizontal, .top], 20)
            .padding(.bottom, 12)

            Divider()

            Form {
                Picker("Type", selection: $workoutType) {
                    ForEach(WorkoutEntry.WorkoutType.allCases, id: \.self) { type in
                        Text("\(type.emoji)  \(type.rawValue)").tag(type)
                    }
                }

                DatePicker("Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute])

                Stepper("Duration: \(durationMinutes) min", value: $durationMinutes, in: 5...300, step: 5)

                Picker("Intensity", selection: $intensity) {
                    ForEach(WorkoutEntry.Intensity.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $notes)
                        .frame(minHeight: 60, maxHeight: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .formStyle(.grouped)

            Divider()

            // Buttons
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape, modifiers: [])

                Spacer()

                Button("Log Workout") {
                    logWorkout()
                }
                .keyboardShortcut(.return, modifiers: .command)
                .buttonStyle(.borderedProminent)
            }
            .padding(16)
        }
        .frame(width: 440)
    }

    private func logWorkout() {
        let entry = WorkoutEntry(
            date: date,
            workoutType: workoutType,
            durationMinutes: durationMinutes,
            intensity: intensity,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        store.add(entry)
        isPresented = false
    }
}

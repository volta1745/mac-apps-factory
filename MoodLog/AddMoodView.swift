import SwiftUI

struct AddMoodView: View {
    @ObservedObject var store: MoodStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMood: MoodLevel = .neutral
    @State private var note: String = ""

    var body: some View {
        VStack(spacing: 24) {
            Text("How are you feeling?")
                .font(.title2.bold())

            HStack(spacing: 16) {
                ForEach(MoodLevel.allCases, id: \.self) { level in
                    Button {
                        selectedMood = level
                    } label: {
                        VStack(spacing: 6) {
                            Text(level.emoji)
                                .font(.system(size: 36))
                            Text(level.label)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedMood == level
                                      ? Color.accentColor.opacity(0.2)
                                      : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(selectedMood == level
                                              ? Color.accentColor
                                              : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Note (optional)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextEditor(text: $note)
                    .frame(height: 80)
                    .padding(6)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save Entry") {
                    store.add(mood: selectedMood, note: note)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 480)
    }
}

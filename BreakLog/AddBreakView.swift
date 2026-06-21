import SwiftUI

struct AddBreakView: View {
    @EnvironmentObject var store: BreakStore
    @Environment(\.dismiss) var dismiss

    @State private var breakType: BreakType = .screenFree
    @State private var duration: Int = 10
    @State private var refreshment: Int = 3
    @State private var note: String = ""

    private let durationPresets = [5, 10, 15, 20, 30, 45, 60]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Log a Break")
                .font(.title2.bold())
                .padding(.bottom, 4)

            // Break type
            VStack(alignment: .leading, spacing: 8) {
                Label("Break Type", systemImage: "timer")
                    .font(.headline)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                    ForEach(BreakType.allCases, id: \.self) { type in
                        BreakTypeButton(type: type, isSelected: breakType == type) {
                            breakType = type
                        }
                    }
                }
            }

            // Duration
            VStack(alignment: .leading, spacing: 8) {
                Label("Duration: \(duration) min", systemImage: "clock")
                    .font(.headline)
                HStack(spacing: 6) {
                    ForEach(durationPresets, id: \.self) { preset in
                        Button("\(preset)m") {
                            duration = preset
                        }
                        .buttonStyle(.bordered)
                        .tint(duration == preset ? .accentColor : .secondary)
                        .controlSize(.small)
                    }
                    Stepper("", value: $duration, in: 1...120)
                        .labelsHidden()
                }
            }

            // Refreshment level
            VStack(alignment: .leading, spacing: 8) {
                Label("How refreshed afterwards?", systemImage: "bolt.heart")
                    .font(.headline)
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { level in
                        Button {
                            refreshment = level
                        } label: {
                            Image(systemName: level <= refreshment ? "star.fill" : "star")
                                .foregroundColor(level <= refreshment ? .yellow : .secondary)
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                    }
                    Text(refreshmentLabel)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.leading, 6)
                }
            }

            // Note
            VStack(alignment: .leading, spacing: 8) {
                Label("Note (optional)", systemImage: "pencil")
                    .font(.headline)
                TextField("What did you do? How do you feel?", text: $note)
                    .textFieldStyle(.roundedBorder)
            }

            Spacer()

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save Break") {
                    let entry = BreakEntry(
                        breakType: breakType,
                        durationMinutes: duration,
                        refreshmentLevel: refreshment,
                        note: note
                    )
                    store.add(entry)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 440)
    }

    private var refreshmentLabel: String {
        switch refreshment {
        case 1: return "Still drained"
        case 2: return "Slightly better"
        case 3: return "Decent"
        case 4: return "Refreshed"
        case 5: return "Fully recharged"
        default: return ""
        }
    }
}

struct BreakTypeButton: View {
    let type: BreakType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: type.icon)
                    .font(.title3)
                Text(type.rawValue)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .foregroundColor(isSelected ? .accentColor : .primary)
    }
}

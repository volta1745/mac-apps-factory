import SwiftUI

struct LogEnergyView: View {
    @EnvironmentObject var store: DataStore
    @State private var level: Int = 3
    @State private var selectedFactors: Set<String> = []
    @State private var note: String = ""
    @State private var showConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerView
                energyPickerCard
                factorsCard
                noteCard
                submitArea
            }
            .padding()
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Log Energy")
    }

    private var headerView: some View {
        VStack(spacing: 4) {
            Text("How's your energy right now?")
                .font(.title2.bold())
            Text("Record your current vitality level")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }

    private var energyPickerCard: some View {
        VStack(spacing: 14) {
            Text("Energy Level")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { i in
                    EnergyLevelButton(value: i, isSelected: level == i) {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            level = i
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                let c = EnergyEntry.color(for: level)
                Text(emojiFor(level))
                    .font(.title3)
                Text(labelFor(level))
                    .font(.title3.bold())
                    .foregroundStyle(Color(red: c.r, green: c.g, blue: c.b))
            }
            .animation(.easeInOut(duration: 0.2), value: level)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var factorsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Contributing Factors")
                    .font(.headline)
                Text("What's affecting your energy? (select all that apply)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 118))], spacing: 8) {
                ForEach(allFactors, id: \.self) { factor in
                    FactorChip(
                        label: factor,
                        isSelected: selectedFactors.contains(factor),
                        isPositive: positiveFactors.contains(factor)
                    ) {
                        if selectedFactors.contains(factor) {
                            selectedFactors.remove(factor)
                        } else {
                            selectedFactors.insert(factor)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Note (optional)")
                .font(.headline)
            TextEditor(text: $note)
                .frame(height: 68)
                .scrollContentBackground(.hidden)
                .padding(6)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var submitArea: some View {
        VStack(spacing: 10) {
            Button(action: logEntry) {
                Label("Log Energy Now", systemImage: "bolt.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            if showConfirmation {
                Label("Energy logged!", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.subheadline)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private func logEntry() {
        let entry = EnergyEntry(
            level: level,
            factors: Array(selectedFactors).sorted(),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        store.addEntry(entry)
        note = ""
        selectedFactors = []
        withAnimation { showConfirmation = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showConfirmation = false }
        }
    }

    func labelFor(_ v: Int) -> String {
        switch v {
        case 1: return "Exhausted"
        case 2: return "Low"
        case 3: return "Moderate"
        case 4: return "High"
        case 5: return "Peak"
        default: return ""
        }
    }

    func emojiFor(_ v: Int) -> String {
        switch v {
        case 1: return "😴"
        case 2: return "😔"
        case 3: return "😐"
        case 4: return "😊"
        case 5: return "⚡️"
        default: return ""
        }
    }
}

struct EnergyLevelButton: View {
    let value: Int
    let isSelected: Bool
    let action: () -> Void

    private var rgb: (r: Double, g: Double, b: Double) { EnergyEntry.color(for: value) }
    private var color: Color { Color(red: rgb.r, green: rgb.g, blue: rgb.b) }

    private var emoji: String {
        switch value {
        case 1: return "😴"
        case 2: return "😔"
        case 3: return "😐"
        case 4: return "😊"
        case 5: return "⚡️"
        default: return ""
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(emoji).font(.title2)
                Text("\(value)").font(.headline)
                    .foregroundStyle(isSelected ? color : .secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(isSelected ? color.opacity(0.15) : Color(.controlBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

struct FactorChip: View {
    let label: String
    let isSelected: Bool
    let isPositive: Bool
    let action: () -> Void

    private var activeColor: Color { isPositive ? .green : .red }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity)
                .background(isSelected ? activeColor.opacity(0.12) : Color(.controlBackgroundColor))
                .foregroundStyle(isSelected ? activeColor : .primary)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isSelected ? activeColor : Color.clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

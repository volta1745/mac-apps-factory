import SwiftUI

struct AddChoreView: View {
    @ObservedObject var store: ChoreStore
    @Environment(\.dismiss) private var dismiss

    @State private var taskName: String = ""
    @State private var category: ChoreCategory = .general
    @State private var durationMinutes: Int = 15
    @State private var effortLevel: Int = 3
    @State private var notes: String = ""
    @State private var showingQuickPick = true

    private let durations = [5, 10, 15, 20, 30, 45, 60, 90, 120]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Log a Chore")
                    .font(.title2.bold())
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Quick pick or custom
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Pick from common chores", isOn: $showingQuickPick)
                            .toggleStyle(.switch)
                            .font(.subheadline)

                        if showingQuickPick {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 8) {
                                ForEach(commonChores.keys.sorted(), id: \.self) { name in
                                    Button {
                                        taskName = name
                                        category = commonChores[name] ?? .general
                                    } label: {
                                        Text(name)
                                            .font(.subheadline)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 7)
                                            .background(taskName == name ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                                            .foregroundColor(taskName == name ? .accentColor : .primary)
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(taskName == name ? Color.accentColor : Color.clear, lineWidth: 1.5)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        } else {
                            TextField("Task name (e.g. Clean fridge)", text: $taskName)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    // Category
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Category", systemImage: "tag")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                        Picker("Category", selection: $category) {
                            ForEach(ChoreCategory.allCases, id: \.self) { cat in
                                Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Duration
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Time spent", systemImage: "clock")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                        HStack(spacing: 8) {
                            ForEach(durations, id: \.self) { min in
                                Button {
                                    durationMinutes = min
                                } label: {
                                    Text(min >= 60 ? "\(min/60)h\(min%60 == 0 ? "" : "\(min%60)m")" : "\(min)m")
                                        .font(.subheadline)
                                        .frame(width: 44, height: 32)
                                        .background(durationMinutes == min ? Color.accentColor : Color.secondary.opacity(0.1))
                                        .foregroundColor(durationMinutes == min ? .white : .primary)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Effort level
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Effort level", systemImage: "bolt")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                        HStack(spacing: 4) {
                            ForEach(1...5, id: \.self) { level in
                                Button {
                                    effortLevel = level
                                } label: {
                                    VStack(spacing: 2) {
                                        Image(systemName: "bolt.fill")
                                            .foregroundColor(effortLevel >= level ? .orange : .secondary.opacity(0.3))
                                        if level == 1 {
                                            Text("Easy").font(.caption2).foregroundColor(.secondary)
                                        } else if level == 5 {
                                            Text("Hard").font(.caption2).foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Notes (optional)", systemImage: "note.text")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                        TextField("Any observations or details…", text: $notes)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(24)
            }

            Divider()

            HStack {
                Spacer()
                Button("Log Chore") {
                    let entry = ChoreEntry(
                        taskName: taskName.trimmingCharacters(in: .whitespacesAndNewlines),
                        category: category,
                        durationMinutes: durationMinutes,
                        effortLevel: effortLevel,
                        notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                        completedAt: Date()
                    )
                    store.add(entry)
                    dismiss()
                }
                .disabled(taskName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(width: 560)
    }
}

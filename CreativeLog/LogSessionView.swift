import SwiftUI

struct LogSessionView: View {
    @ObservedObject var store: SessionStore

    @State private var selectedType: CreativeType = .writing
    @State private var project: String = ""
    @State private var durationMinutes: Int = 30
    @State private var flowLevel: Int = 3
    @State private var notes: String = ""
    @State private var showConfirmation = false

    private let durations = stride(from: 5, through: 300, by: 5).map { $0 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Header
                HStack {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(.purple)
                    Text("Log Creative Session")
                        .font(.title2).fontWeight(.semibold)
                }
                .padding(.bottom, 4)

                // Creative Type
                GroupBox("Creative Type") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        ForEach(CreativeType.allCases) { type in
                            Button(action: { selectedType = type }) {
                                VStack(spacing: 4) {
                                    Text(type.emoji).font(.title2)
                                    Text(type.rawValue)
                                        .font(.caption)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    selectedType == type
                                        ? Color.accentColor.opacity(0.15)
                                        : Color(nsColor: .quaternaryLabelColor).opacity(0.3)
                                )
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedType == type ? Color.accentColor : Color.clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(6)
                }

                // Project Name
                GroupBox("Project / Work") {
                    TextField("What did you work on? (e.g. \"Chapter 3\", \"Guitar solo\")", text: $project)
                        .textFieldStyle(.plain)
                        .padding(6)
                }

                // Duration
                GroupBox {
                    HStack {
                        Text("Duration")
                            .fontWeight(.medium)
                        Spacer()
                        Text(formatDuration(durationMinutes))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    HStack {
                        Text("5m").font(.caption).foregroundStyle(.secondary)
                        Slider(
                            value: Binding(
                                get: { Double(durationMinutes) },
                                set: { durationMinutes = Int($0) }
                            ),
                            in: 5...300,
                            step: 5
                        )
                        Text("5h").font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                // Flow Level
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Creative Flow")
                                .fontWeight(.medium)
                            Spacer()
                            Text(flowLabelFor(flowLevel))
                                .foregroundStyle(flowColor(flowLevel))
                                .fontWeight(.semibold)
                                .font(.callout)
                        }
                        HStack(spacing: 10) {
                            ForEach(1...5, id: \.self) { level in
                                Button(action: { flowLevel = level }) {
                                    VStack(spacing: 3) {
                                        Image(systemName: level <= flowLevel ? "bolt.fill" : "bolt")
                                            .font(.title3)
                                            .foregroundStyle(level <= flowLevel ? flowColor(level) : Color.secondary)
                                        Text("\(level)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(
                                        level <= flowLevel
                                            ? flowColor(level).opacity(0.1)
                                            : Color.clear
                                    )
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        HStack {
                            Text("Blocked").font(.caption2).foregroundStyle(.secondary)
                            Spacer()
                            Text("In the Zone").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    .padding(4)
                }

                // Notes
                GroupBox("Notes (optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 70, maxHeight: 100)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .padding(4)
                }

                // Log Button
                Button(action: logSession) {
                    HStack {
                        Image(systemName: showConfirmation ? "checkmark.circle.fill" : "plus.circle.fill")
                        Text(showConfirmation ? "Session Logged!" : "Log Session")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .disabled(project.trimmingCharacters(in: .whitespaces).isEmpty)
                .tint(showConfirmation ? .green : .accentColor)
                .animation(.easeInOut(duration: 0.2), value: showConfirmation)

                Spacer(minLength: 20)
            }
            .padding(24)
        }
        .navigationTitle("Log Session")
    }

    private func logSession() {
        let session = CreativeSession(
            type: selectedType,
            project: project.trimmingCharacters(in: .whitespaces),
            durationMinutes: durationMinutes,
            flowLevel: flowLevel,
            notes: notes.trimmingCharacters(in: .whitespaces)
        )
        store.add(session)
        withAnimation { showConfirmation = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation { showConfirmation = false }
            project = ""
            notes = ""
            durationMinutes = 30
            flowLevel = 3
        }
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) min" }
        let h = minutes / 60; let m = minutes % 60
        return m == 0 ? "\(h) hr" : "\(h) hr \(m) min"
    }

    private func flowLabelFor(_ level: Int) -> String {
        switch level {
        case 1: return "Blocked"
        case 2: return "Sluggish"
        case 3: return "Steady"
        case 4: return "Flowing"
        case 5: return "In the Zone"
        default: return "—"
        }
    }

    private func flowColor(_ level: Int) -> Color {
        switch level {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        case 5: return .purple
        default: return .gray
        }
    }
}

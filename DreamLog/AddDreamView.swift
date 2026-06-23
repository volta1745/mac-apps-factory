import SwiftUI

struct AddDreamView: View {
    @EnvironmentObject var store: DreamStore
    @Environment(\.dismiss) var dismiss

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var dreamType: DreamType = .normal
    @State private var emotion: DreamEmotion = .neutral
    @State private var clarity: Int = 3
    @State private var sleepQuality: Int = 3
    @State private var date: Date = Date()

    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Record a Dream")
                    .font(.title2).bold()
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save Dream") {
                    save()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Date picker
                    HStack {
                        Label("Dream date", systemImage: "calendar")
                            .font(.headline)
                        Spacer()
                        DatePicker("", selection: $date, displayedComponents: [.date])
                            .labelsHidden()
                    }
                    .padding(.horizontal)

                    Divider().padding(.horizontal)

                    // Title
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Title", systemImage: "text.cursor")
                            .font(.headline)
                        TextField("Give your dream a name…", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.horizontal)

                    // Notes
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Dream notes", systemImage: "doc.text")
                            .font(.headline)
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(nsColor: .textBackgroundColor))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color(nsColor: .separatorColor))
                                )
                            if notes.isEmpty {
                                Text("Describe what happened in the dream…")
                                    .foregroundStyle(.tertiary)
                                    .padding(8)
                            }
                            TextEditor(text: $notes)
                                .scrollContentBackground(.hidden)
                                .background(.clear)
                                .padding(4)
                        }
                        .frame(minHeight: 110)
                    }
                    .padding(.horizontal)

                    Divider().padding(.horizontal)

                    // Dream type
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Dream type", systemImage: "sparkles")
                            .font(.headline)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                            ForEach(DreamType.allCases, id: \.self) { type in
                                TypeButton(
                                    label: "\(type.emoji) \(type.rawValue)",
                                    isSelected: dreamType == type,
                                    color: type.color
                                ) { dreamType = type }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Emotion
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Emotional tone", systemImage: "face.smiling")
                            .font(.headline)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                            ForEach(DreamEmotion.allCases, id: \.self) { e in
                                TypeButton(
                                    label: "\(e.emoji) \(e.rawValue)",
                                    isSelected: emotion == e,
                                    color: e.color
                                ) { emotion = e }
                            }
                        }
                    }
                    .padding(.horizontal)

                    Divider().padding(.horizontal)

                    // Sliders
                    VStack(alignment: .leading, spacing: 16) {
                        RatingRow(
                            label: "Dream clarity",
                            icon: "eye",
                            value: $clarity,
                            lowLabel: "Fuzzy",
                            highLabel: "Crystal clear"
                        )
                        RatingRow(
                            label: "Sleep quality",
                            icon: "moon.stars",
                            value: $sleepQuality,
                            lowLabel: "Terrible",
                            highLabel: "Excellent"
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding(.top, 16)
            }
        }
        .frame(width: 520, height: 680)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func save() {
        let entry = DreamEntry(
            date: date,
            title: title.trimmingCharacters(in: .whitespaces),
            notes: notes,
            dreamType: dreamType,
            emotion: emotion,
            clarity: clarity,
            sleepQuality: sleepQuality
        )
        store.add(entry)
        dismiss()
    }
}

// MARK: - Subviews

private struct TypeButton: View {
    let label: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(isSelected ? color.opacity(0.25) : Color(nsColor: .controlBackgroundColor))
                .foregroundStyle(isSelected ? color : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? color : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct RatingRow: View {
    let label: String
    let icon: String
    @Binding var value: Int
    let lowLabel: String
    let highLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon).font(.headline)
            HStack(spacing: 6) {
                Text(lowLabel).font(.caption).foregroundStyle(.secondary).frame(width: 80, alignment: .trailing)
                ForEach(1...5, id: \.self) { i in
                    Circle()
                        .fill(i <= value ? Color.accentColor : Color(nsColor: .separatorColor))
                        .frame(width: 26, height: 26)
                        .overlay(Text("\(i)").font(.caption2).foregroundStyle(i <= value ? .white : .secondary))
                        .onTapGesture { value = i }
                }
                Text(highLabel).font(.caption).foregroundStyle(.secondary).frame(width: 80, alignment: .leading)
            }
        }
    }
}

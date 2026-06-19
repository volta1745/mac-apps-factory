import SwiftUI

struct ContentView: View {
    @StateObject private var store = GratitudeStore()
    @State private var showingAdd = false
    @State private var selectedCategory: GratitudeCategory? = nil

    var groups: [(label: String, entries: [GratitudeEntry])] {
        store.groupedByDay(filtered: selectedCategory)
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            categoryFilterBar
            Divider()
            entriesArea
        }
        .sheet(isPresented: $showingAdd) {
            AddEntrySheet(store: store, isPresented: $showingAdd)
        }
        .frame(minWidth: 700, minHeight: 500)
    }

    // MARK: - Subviews

    private var headerBar: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("GratitudeLog")
                    .font(.title2).bold()
                Text("What are you grateful for today?")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            StatBadge(value: store.todayCount,    label: "Today")
            StatBadge(value: store.currentStreak, label: "Day Streak")
            StatBadge(value: store.entries.count, label: "All Time")
            Button {
                showingAdd = true
            } label: {
                Label("Add Gratitude", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All \(store.entries.count > 0 ? "(\(store.entries.count))" : "")",
                           isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(GratitudeCategory.allCases) { cat in
                    let count = store.entries.filter { $0.category == cat }.count
                    FilterChip(label: "\(cat.emoji) \(cat.rawValue)\(count > 0 ? " (\(count))" : "")",
                               isSelected: selectedCategory == cat) {
                        selectedCategory = selectedCategory == cat ? nil : cat
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private var entriesArea: some View {
        Group {
            if groups.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(groups, id: \.label) { group in
                        Section {
                            ForEach(group.entries) { entry in
                                EntryRow(entry: entry)
                                    .contextMenu {
                                        Button("Delete Entry", role: .destructive) {
                                            store.delete(entry)
                                        }
                                    }
                            }
                        } header: {
                            Text(group.label)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textCase(nil)
                        }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 52))
                .foregroundColor(.secondary.opacity(0.4))
            Text(selectedCategory == nil ? "No entries yet" : "No \(selectedCategory!.rawValue) entries")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Click \"Add Gratitude\" to record your first entry.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Supporting views

struct StatBadge: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 1) {
            Text("\(value)")
                .font(.title3).fontWeight(.semibold)
                .foregroundColor(.accentColor)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(8)
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct EntryRow: View {
    let entry: GratitudeEntry

    var accentColor: Color {
        switch entry.category {
        case .family:   return .orange
        case .friends:  return .blue
        case .work:     return .purple
        case .health:   return .green
        case .nature:   return .teal
        case .learning: return .indigo
        case .other:    return .gray
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(entry.category.emoji)
                .font(.title2)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.text)
                    .font(.body)
                    .fontWeight(.medium)
                    .fixedSize(horizontal: false, vertical: true)

                if !entry.reflection.isEmpty {
                    Text(entry.reflection)
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 6) {
                    Text(entry.category.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(accentColor.opacity(0.15))
                        .foregroundColor(accentColor)
                        .cornerRadius(4)

                    Text(entry.date, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Entry Sheet

struct AddEntrySheet: View {
    @ObservedObject var store: GratitudeStore
    @Binding var isPresented: Bool

    @State private var text = ""
    @State private var category: GratitudeCategory = .other
    @State private var reflection = ""

    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Sheet toolbar
            HStack {
                Text("Add Gratitude")
                    .font(.headline)
                Spacer()
                Button("Cancel") { isPresented = false }
                    .keyboardShortcut(.escape, modifiers: [])
                Button("Save") { save() }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSave)
                    .keyboardShortcut(.return, modifiers: .command)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Gratitude text
                    VStack(alignment: .leading, spacing: 6) {
                        Label("I'm grateful for…", systemImage: "heart.fill")
                            .font(.subheadline).fontWeight(.medium)
                            .foregroundColor(.secondary)
                        TextEditor(text: $text)
                            .font(.body)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    }

                    // Category
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Category", systemImage: "tag")
                            .font(.subheadline).fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Picker("Category", selection: $category) {
                            ForEach(GratitudeCategory.allCases) { cat in
                                Text("\(cat.emoji)  \(cat.rawValue)").tag(cat)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 200)
                    }

                    // Optional reflection
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Why does this matter? (optional)", systemImage: "text.bubble")
                            .font(.subheadline).fontWeight(.medium)
                            .foregroundColor(.secondary)
                        TextEditor(text: $reflection)
                            .font(.body)
                            .frame(minHeight: 60)
                            .padding(8)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
                .padding()
            }
        }
        .frame(width: 480, height: 380)
    }

    private func save() {
        store.add(
            text: text.trimmingCharacters(in: .whitespaces),
            category: category,
            reflection: reflection.trimmingCharacters(in: .whitespaces)
        )
        isPresented = false
    }
}

import SwiftUI

struct ContentView: View {
    @StateObject private var store = ReadingStore()
    @State private var showingAdd = false

    private static let rowFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        NavigationSplitView {
            SidebarView(store: store, showingAdd: $showingAdd)
                .navigationSplitViewColumnWidth(min: 210, ideal: 220, max: 260)
        } detail: {
            if store.sessions.isEmpty {
                EmptyStateView()
            } else {
                List {
                    ForEach(store.sessions) { session in
                        SessionRow(session: session, formatter: Self.rowFormatter)
                    }
                    .onDelete(perform: store.delete)
                }
                .navigationTitle("ReadLog")
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddSessionView(store: store)
        }
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @ObservedObject var store: ReadingStore
    @Binding var showingAdd: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("This Week")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 12)

            VStack(spacing: 10) {
                StatCard(label: "Sessions", value: "\(store.sessionsThisWeek)",
                         icon: "book.fill", color: .orange)
                StatCard(label: "Pages Read", value: "\(store.totalPagesThisWeek)",
                         icon: "doc.text.fill", color: .blue)
                StatCard(label: "Reading Time", value: formatMinutes(store.totalMinutesThisWeek),
                         icon: "clock.fill", color: .green)
            }
            .padding(.horizontal)

            Spacer()

            Divider()

            Button(action: { showingAdd = true }) {
                Label("Log Session", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
        }
    }

    private func formatMinutes(_ m: Int) -> String {
        guard m > 0 else { return "0m" }
        let h = m / 60, rem = m % 60
        if h == 0 { return "\(rem)m" }
        return rem == 0 ? "\(h)h" : "\(h)h \(rem)m"
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title3.bold())
            }
            Spacer()
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: ReadingSession
    let formatter: DateFormatter

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.bookTitle)
                        .font(.headline)
                    if !session.author.isEmpty {
                        Text("by \(session.author)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text(formatter.string(from: session.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                Label(
                    session.pagesRead == 1
                        ? "1 page (p. \(session.startPage))"
                        : "\(session.pagesRead) pages (pp. \(session.startPage)–\(session.endPage))",
                    systemImage: "book"
                )
                .font(.caption)
                .foregroundStyle(.blue)

                Label("\(session.durationMinutes) min", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.green)
            }

            if !session.notes.isEmpty {
                Text(session.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 56))
                .foregroundStyle(.secondary.opacity(0.6))
            Text("No Sessions Yet")
                .font(.title2.bold())
            Text("Press "Log Session" to record your first reading session.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("ReadLog")
    }
}

// MARK: - Add Session Sheet

struct AddSessionView: View {
    @ObservedObject var store: ReadingStore
    @Environment(\.dismiss) private var dismiss

    @State private var bookTitle = ""
    @State private var author = ""
    @State private var startPage = ""
    @State private var endPage = ""
    @State private var durationMinutes = ""
    @State private var notes = ""

    private var isValid: Bool {
        !bookTitle.trimmingCharacters(in: .whitespaces).isEmpty &&
        Int(startPage) != nil &&
        Int(endPage) != nil &&
        (Int(endPage) ?? 0) >= (Int(startPage) ?? 0) &&
        (Int(durationMinutes) ?? 0) > 0
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Log Reading Session")
                    .font(.title2.bold())
                Spacer()
            }
            .padding()

            Divider()

            Form {
                Section("Book") {
                    TextField("Title *", text: $bookTitle)
                    TextField("Author (optional)", text: $author)
                }

                Section("Pages") {
                    HStack {
                        TextField("Start page", text: $startPage)
                            .frame(maxWidth: .infinity)
                        Text("→")
                            .foregroundStyle(.secondary)
                        TextField("End page", text: $endPage)
                            .frame(maxWidth: .infinity)
                    }
                }

                Section("Duration") {
                    HStack {
                        TextField("Minutes spent reading", text: $durationMinutes)
                        Text("min")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Notes (optional)") {
                    TextEditor(text: $notes)
                        .frame(height: 72)
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save Session") {
                    let session = ReadingSession(
                        bookTitle: bookTitle.trimmingCharacters(in: .whitespaces),
                        author: author.trimmingCharacters(in: .whitespaces),
                        startPage: Int(startPage) ?? 0,
                        endPage: Int(endPage) ?? 0,
                        durationMinutes: Int(durationMinutes) ?? 0,
                        notes: notes.trimmingCharacters(in: .whitespaces),
                        date: Date()
                    )
                    store.add(session)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 440, height: 500)
    }
}

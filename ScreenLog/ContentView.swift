import SwiftUI

// MARK: - Root

struct ContentView: View {
    @EnvironmentObject var store: SessionStore
    @State private var tab: Int = 0

    var body: some View {
        TabView(selection: $tab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }
                .tag(0)
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.fill") }
                .tag(1)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(2)
        }
        .frame(minWidth: 680, minHeight: 500)
    }
}

// MARK: - Today

struct TodayView: View {
    @EnvironmentObject var store: SessionStore
    @State private var showAdd = false

    var body: some View {
        HSplitView {
            // Left: stats panel
            VStack(alignment: .leading, spacing: 20) {
                Text("Today")
                    .font(.title2.bold())

                // Usage ring summary
                UsageRingView()
                    .frame(height: 160)

                Divider()

                // Per-category breakdown
                VStack(alignment: .leading, spacing: 10) {
                    Text("By Category")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(ScreenCategory.allCases) { cat in
                        let mins = store.todayMinutes(for: cat)
                        if mins > 0 {
                            CategoryRow(category: cat, minutes: mins)
                        }
                    }
                    if store.todaySessions.isEmpty {
                        Text("No sessions yet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding()
            .frame(minWidth: 220, maxWidth: 260)

            // Right: session list + add
            VStack(spacing: 0) {
                HStack {
                    Text("Sessions")
                        .font(.headline)
                    Spacer()
                    Button {
                        showAdd = true
                    } label: {
                        Label("Log Session", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding()

                Divider()

                if store.todaySessions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "laptopcomputer")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No screen sessions logged today")
                            .foregroundStyle(.secondary)
                        Button("Log a Session") { showAdd = true }
                            .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(store.todaySessions) { s in
                            SessionRow(session: s)
                        }
                        .onDelete { offsets in
                            let ids = offsets.map { store.todaySessions[$0].id }
                            let globalOffsets = IndexSet(
                                ids.compactMap { id in store.sessions.firstIndex(where: { $0.id == id }) }
                            )
                            store.delete(at: globalOffsets)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddSessionView()
        }
    }
}

// MARK: - Usage Ring

struct UsageRingView: View {
    @EnvironmentObject var store: SessionStore

    var progress: Double {
        guard store.dailyLimitMinutes > 0 else { return 0 }
        return min(Double(store.todayTotalMinutes) / Double(store.dailyLimitMinutes), 1.0)
    }

    var ringColor: Color {
        progress < 0.6 ? .green : progress < 0.85 ? .orange : .red
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.5), value: progress)
                VStack(spacing: 2) {
                    Text(formatMins(store.todayTotalMinutes))
                        .font(.title3.bold())
                    Text("of \(formatMins(store.dailyLimitMinutes))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 120, height: 120)

            HStack(spacing: 16) {
                MiniStat(label: "Mindful", value: formatMins(store.todayMindfulMinutes), color: .green)
                MiniStat(label: "Mindless", value: formatMins(store.todayMindlessMinutes), color: .orange)
            }
        }
        .frame(maxWidth: .infinity)
    }

    func formatMins(_ m: Int) -> String {
        m >= 60 ? "\(m / 60)h \(m % 60)m" : "\(m)m"
    }
}

struct MiniStat: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.subheadline.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Category Row

struct CategoryRow: View {
    let category: ScreenCategory
    let minutes: Int

    var color: Color {
        switch category.color {
        case "blue": return .blue
        case "indigo": return .indigo
        case "orange": return .orange
        case "purple": return .purple
        case "gray": return .gray
        case "green": return .green
        case "pink": return .pink
        default: return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: category.icon)
                .foregroundStyle(color)
                .frame(width: 18)
            Text(category.rawValue)
                .font(.caption)
            Spacer()
            Text(minutes >= 60 ? "\(minutes/60)h \(minutes%60)m" : "\(minutes)m")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: ScreenSession

    var color: Color {
        switch session.category.color {
        case "blue": return .blue
        case "indigo": return .indigo
        case "orange": return .orange
        case "purple": return .purple
        case "gray": return .gray
        case "green": return .green
        case "pink": return .pink
        default: return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: session.category.icon)
                .foregroundStyle(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(session.appName)
                        .font(.subheadline.bold())
                    Spacer()
                    Text(session.durationMinutes >= 60
                         ? "\(session.durationMinutes/60)h \(session.durationMinutes%60)m"
                         : "\(session.durationMinutes) min")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 6) {
                    Text(session.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Label(session.purpose.rawValue, systemImage: session.purpose.icon)
                        .font(.caption)
                        .foregroundStyle(session.purpose == .mindful ? .green : .orange)
                    if !session.note.isEmpty {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(session.note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Text(session.date, style: .time)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Session

struct AddSessionView: View {
    @EnvironmentObject var store: SessionStore
    @Environment(\.dismiss) var dismiss

    @State private var appName = ""
    @State private var category: ScreenCategory = .social
    @State private var durationMinutes: Int = 15
    @State private var purpose: Purpose = .mindful
    @State private var note = ""
    @State private var error = ""

    let durations = [5, 10, 15, 20, 30, 45, 60, 90, 120]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Log Screen Session")
                    .font(.headline)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding()

            Divider()

            Form {
                Section("App or Website") {
                    TextField("e.g. Twitter, YouTube, VS Code…", text: $appName)
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(ScreenCategory.allCases) { c in
                            Label(c.rawValue, systemImage: c.icon).tag(c)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Duration") {
                    Picker("Duration", selection: $durationMinutes) {
                        ForEach(durations, id: \.self) { m in
                            Text(m >= 60 ? "\(m/60)h \(m%60 == 0 ? "" : "\(m%60)m")" : "\(m) min")
                                .tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Purpose") {
                    Picker("Purpose", selection: $purpose) {
                        ForEach(Purpose.allCases) { p in
                            Label(p.rawValue, systemImage: p.icon).tag(p)
                        }
                    }
                    .pickerStyle(.radioGroup)
                }

                Section("Note (optional)") {
                    TextField("What were you doing?", text: $note)
                }

                if !error.isEmpty {
                    Text(error).foregroundStyle(.red).font(.caption)
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Spacer()
                Button("Log Session") {
                    guard !appName.trimmingCharacters(in: .whitespaces).isEmpty else {
                        error = "Please enter an app or website name."
                        return
                    }
                    let session = ScreenSession(
                        appName: appName.trimmingCharacters(in: .whitespaces),
                        category: category,
                        durationMinutes: durationMinutes,
                        purpose: purpose,
                        note: note.trimmingCharacters(in: .whitespaces)
                    )
                    store.add(session)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 440, height: 480)
    }
}

// MARK: - History

struct HistoryView: View {
    @EnvironmentObject var store: SessionStore
    @State private var filterCategory: ScreenCategory? = nil
    @State private var filterPurpose: Purpose? = nil
    @State private var search = ""

    var filtered: [ScreenSession] {
        store.sessions.filter { s in
            (filterCategory == nil || s.category == filterCategory) &&
            (filterPurpose == nil || s.purpose == filterPurpose) &&
            (search.isEmpty || s.appName.localizedCaseInsensitiveContains(search) || s.note.localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 12) {
                TextField("Search…", text: $search)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 200)

                Picker("Category", selection: $filterCategory) {
                    Text("All Categories").tag(Optional<ScreenCategory>.none)
                    ForEach(ScreenCategory.allCases) { c in
                        Text(c.rawValue).tag(Optional(c))
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 160)

                Picker("Purpose", selection: $filterPurpose) {
                    Text("All").tag(Optional<Purpose>.none)
                    ForEach(Purpose.allCases) { p in
                        Text(p.rawValue).tag(Optional(p))
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 130)

                Spacer()

                Text("\(filtered.count) sessions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

            Divider()

            if filtered.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("No sessions match")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(groupedDays(filtered), id: \.0) { (day, daySessions) in
                        Section(header: Text(dayLabel(day)).font(.caption.bold())) {
                            ForEach(daySessions) { s in
                                SessionRow(session: s)
                            }
                            .onDelete { offsets in
                                let ids = offsets.map { daySessions[$0].id }
                                let globalOffsets = IndexSet(
                                    ids.compactMap { id in store.sessions.firstIndex(where: { $0.id == id }) }
                                )
                                store.delete(at: globalOffsets)
                            }
                        }
                    }
                }
            }
        }
    }

    func groupedDays(_ sessions: [ScreenSession]) -> [(Date, [ScreenSession])] {
        let cal = Calendar.current
        var dict: [Date: [ScreenSession]] = [:]
        for s in sessions {
            let day = cal.startOfDay(for: s.date)
            dict[day, default: []].append(s)
        }
        return dict.sorted { $0.key > $1.key }
    }

    func dayLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}

// MARK: - Settings

struct SettingsView: View {
    @EnvironmentObject var store: SessionStore
    @State private var limitText: String = ""
    @State private var saved = false

    var body: some View {
        Form {
            Section("Daily Screen Time Limit") {
                HStack {
                    TextField("Minutes", text: $limitText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    Text("minutes")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Save") {
                        if let val = Int(limitText), val > 0 {
                            store.saveLimit(val)
                            saved = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { saved = false }
                        }
                    }
                    .buttonStyle(.bordered)
                    if saved {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                Text("Current limit: \(store.dailyLimitMinutes) min (\(store.dailyLimitMinutes / 60)h \(store.dailyLimitMinutes % 60)m)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("About") {
                LabeledContent("App", value: "ScreenLog")
                LabeledContent("Purpose", value: "Log and reflect on your daily screen time")
                LabeledContent("Data stored at", value: "~/Library/Application Support/ScreenLog/")
            }
        }
        .formStyle(.grouped)
        .onAppear {
            limitText = "\(store.dailyLimitMinutes)"
        }
    }
}

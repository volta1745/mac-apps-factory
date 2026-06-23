import SwiftUI

struct ContentView: View {
    @StateObject private var store = DreamStore()
    @State private var showingAdd = false
    @State private var selectedType: DreamType? = nil
    @State private var selectedEmotion: DreamEmotion? = nil
    @State private var searchText: String = ""
    @State private var selectedTab: Tab = .journal

    enum Tab: String, CaseIterable {
        case journal = "Journal"
        case insights = "Insights"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top toolbar
            HStack(spacing: 12) {
                // Moon icon + app title
                HStack(spacing: 8) {
                    Image(systemName: "moon.stars.fill")
                        .font(.title2)
                        .foregroundStyle(.indigo)
                    Text("DreamLog")
                        .font(.title2).bold()
                }

                Spacer()

                // Tab picker
                Picker("", selection: $selectedTab) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)

                Spacer()

                Button {
                    showingAdd = true
                } label: {
                    Label("Record Dream", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("n", modifiers: .command)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            if selectedTab == .journal {
                journalView
            } else {
                insightsView
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddDreamView().environmentObject(store)
        }
        .environmentObject(store)
    }

    // MARK: - Journal Tab

    private var journalView: some View {
        HSplitView {
            // Sidebar: filters
            filterSidebar
                .frame(minWidth: 160, idealWidth: 180, maxWidth: 200)

            // Main list
            VStack(spacing: 0) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Search dreams…", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }.buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider()

                if filteredEntries.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(groupedEntries, id: \.0) { day, dayEntries in
                            Section(header: Text(dayLabel(day)).font(.caption).foregroundStyle(.secondary)) {
                                ForEach(dayEntries) { entry in
                                    DreamRow(entry: entry)
                                }
                                .onDelete { offsets in
                                    let ids = offsets.map { dayEntries[$0].id }
                                    store.entries.removeAll { ids.contains($0.id) }
                                }
                            }
                        }
                    }
                    .listStyle(.inset(alternatesRowBackgrounds: true))
                }
            }
        }
    }

    // MARK: - Filter Sidebar

    private var filterSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                Text("FILTER BY TYPE")
                    .font(.caption2).bold().foregroundStyle(.secondary)
                    .padding(.horizontal, 12).padding(.top, 14).padding(.bottom, 4)

                filterRow(label: "All Dreams", emoji: "🌙", isSelected: selectedType == nil) {
                    selectedType = nil
                }
                ForEach(DreamType.allCases, id: \.self) { type in
                    filterRow(
                        label: type.rawValue,
                        emoji: type.emoji,
                        count: store.entries.filter { $0.dreamType == type }.count,
                        isSelected: selectedType == type
                    ) { selectedType = selectedType == type ? nil : type }
                }
            }

            Divider().padding(.vertical, 8)

            Group {
                Text("FILTER BY EMOTION")
                    .font(.caption2).bold().foregroundStyle(.secondary)
                    .padding(.horizontal, 12).padding(.bottom, 4)

                filterRow(label: "All Emotions", emoji: "💫", isSelected: selectedEmotion == nil) {
                    selectedEmotion = nil
                }
                ForEach(DreamEmotion.allCases, id: \.self) { e in
                    filterRow(
                        label: e.rawValue,
                        emoji: e.emoji,
                        count: store.entries.filter { $0.emotion == e }.count,
                        isSelected: selectedEmotion == e
                    ) { selectedEmotion = selectedEmotion == e ? nil : e }
                }
            }

            Spacer()

            Divider()
            VStack(spacing: 2) {
                HStack {
                    Text("Total dreams").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text("\(store.totalEntries)").font(.caption).bold()
                }
                HStack {
                    Text("Avg clarity").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text(store.totalEntries > 0 ? String(format: "%.1f / 5", store.averageClarity) : "—")
                        .font(.caption).bold()
                }
            }
            .padding(12)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    @ViewBuilder
    private func filterRow(label: String, emoji: String, count: Int? = nil, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(emoji).frame(width: 18)
                Text(label).font(.callout)
                Spacer()
                if let count, count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(Color(nsColor: .separatorColor))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Insights Tab

    private var insightsView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                // Top stats strip
                HStack(spacing: 16) {
                    StatCard(value: "\(store.totalEntries)", label: "Dreams logged", icon: "moon.fill", color: .indigo)
                    StatCard(
                        value: store.totalEntries > 0 ? String(format: "%.1f", store.averageClarity) : "—",
                        label: "Avg clarity / 5",
                        icon: "eye.fill",
                        color: .blue
                    )
                    StatCard(
                        value: store.totalEntries > 0 ? String(format: "%.1f", store.averageSleepQuality) : "—",
                        label: "Avg sleep / 5",
                        icon: "moon.stars.fill",
                        color: .purple
                    )
                    if let type = store.mostCommonType {
                        StatCard(value: "\(type.emoji) \(type.rawValue)", label: "Most common type", icon: "sparkles", color: type.color)
                    }
                }
                .padding(.horizontal)

                // Dream type breakdown
                if !store.typeCounts.isEmpty {
                    InsightSection(title: "Dream Types") {
                        ForEach(store.typeCounts, id: \.0) { type, count in
                            BreakdownRow(
                                label: "\(type.emoji)  \(type.rawValue)",
                                count: count,
                                total: store.totalEntries,
                                color: type.color
                            )
                        }
                    }
                }

                // Emotion breakdown
                if !store.emotionCounts.isEmpty {
                    InsightSection(title: "Emotional Tone") {
                        ForEach(store.emotionCounts, id: \.0) { emotion, count in
                            BreakdownRow(
                                label: "\(emotion.emoji)  \(emotion.rawValue)",
                                count: count,
                                total: store.totalEntries,
                                color: emotion.color
                            )
                        }
                    }
                }

                // Recent 7-day streak
                InsightSection(title: "Last 7 Nights") {
                    HStack(spacing: 8) {
                        ForEach(last7Days, id: \.self) { day in
                            let count = store.entries.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }.count
                            VStack(spacing: 4) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(count > 0 ? Color.indigo.opacity(0.3) : Color(nsColor: .separatorColor).opacity(0.4))
                                        .frame(width: 36, height: 36)
                                    if count > 0 {
                                        Text("\(count)").font(.headline).foregroundStyle(.indigo)
                                    } else {
                                        Image(systemName: "minus").foregroundStyle(.secondary)
                                    }
                                }
                                Text(shortDay(day)).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                }

                if store.totalEntries == 0 {
                    VStack(spacing: 10) {
                        Image(systemName: "moon.zzz")
                            .font(.system(size: 48)).foregroundStyle(.indigo.opacity(0.5))
                        Text("No dreams logged yet")
                            .font(.title3).foregroundStyle(.secondary)
                        Text("Tap "Record Dream" right after waking for best recall.")
                            .font(.callout).foregroundStyle(.tertiary).multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                }
            }
            .padding(.vertical, 20)
        }
    }

    // MARK: - Helpers

    private var filteredEntries: [DreamEntry] {
        store.entries.filter { entry in
            let typeMatch = selectedType == nil || entry.dreamType == selectedType
            let emotionMatch = selectedEmotion == nil || entry.emotion == selectedEmotion
            let searchMatch = searchText.isEmpty ||
                entry.title.localizedCaseInsensitiveContains(searchText) ||
                entry.notes.localizedCaseInsensitiveContains(searchText)
            return typeMatch && emotionMatch && searchMatch
        }
    }

    private var groupedEntries: [(Date, [DreamEntry])] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: filteredEntries) { entry in
            cal.startOfDay(for: entry.date)
        }
        return grouped.sorted { $0.key > $1.key }.map { ($0.key, $0.value) }
    }

    private func dayLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private var last7Days: [Date] {
        let cal = Calendar.current
        return (0..<7).compactMap { cal.date(byAdding: .day, value: -6 + $0, to: cal.startOfDay(for: Date())) }
    }

    private func shortDay(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 52))
                .foregroundStyle(.indigo.opacity(0.5))
            Text(store.totalEntries == 0 ? "No dreams yet" : "No matching dreams")
                .font(.title3).bold()
            Text(store.totalEntries == 0
                 ? "Record your first dream using the button above."
                 : "Try a different filter or search.")
                .font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Dream Row

struct DreamRow: View {
    let entry: DreamEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(entry.dreamType.emoji)
                Text(entry.title)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text(entry.emotion.emoji + " " + entry.emotion.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(entry.emotion.color.opacity(0.18))
                    .foregroundStyle(entry.emotion.color)
                    .clipShape(Capsule())
                Text(timeString(entry.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !entry.notes.isEmpty {
                Text(entry.notes)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            HStack(spacing: 12) {
                clarityDots(entry.clarity, icon: "eye", color: .blue)
                clarityDots(entry.sleepQuality, icon: "moon.stars", color: .purple)
                Spacer()
                Text(entry.dreamType.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(entry.dreamType.color.opacity(0.15))
                    .foregroundStyle(entry.dreamType.color)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func clarityDots(_ value: Int, icon: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.caption2).foregroundStyle(color)
            ForEach(1...5, id: \.self) { i in
                Circle()
                    .fill(i <= value ? color : Color(nsColor: .separatorColor))
                    .frame(width: 6, height: 6)
            }
        }
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}

// MARK: - Insight Helpers

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon).foregroundStyle(color).font(.caption)
                Text(label).font(.caption).foregroundStyle(.secondary)
            }
            Text(value).font(.title2).bold()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct InsightSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            VStack(spacing: 6) { content }
                .padding(.horizontal)
        }
    }
}

struct BreakdownRow: View {
    let label: String
    let count: Int
    let total: Int
    let color: Color

    private var fraction: Double { total > 0 ? Double(count) / Double(total) : 0 }

    var body: some View {
        HStack(spacing: 10) {
            Text(label).font(.callout).frame(width: 150, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(nsColor: .separatorColor).opacity(0.5))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.6))
                        .frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 14)
            Text("\(count)").font(.callout).bold().frame(width: 28, alignment: .trailing)
            Text(String(format: "%.0f%%", fraction * 100))
                .font(.caption).foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)
        }
    }
}

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: SkillStore
    @State private var selectedSkill: Skill?
    @State private var showAddSkill = false
    @State private var showLogSession = false

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedSkill: $selectedSkill, showAddSkill: $showAddSkill)
        } detail: {
            if let skill = selectedSkill {
                SkillDetailView(skill: skill, showLogSession: $showLogSession)
            } else {
                OverviewView(showLogSession: $showLogSession, selectedSkill: $selectedSkill)
            }
        }
        .sheet(isPresented: $showAddSkill) {
            AddSkillSheet()
        }
        .sheet(isPresented: $showLogSession) {
            LogSessionSheet(preselectedSkill: selectedSkill)
        }
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @EnvironmentObject var store: SkillStore
    @Binding var selectedSkill: Skill?
    @Binding var showAddSkill: Bool

    var body: some View {
        List(selection: $selectedSkill) {
            Section {
                Label("All Activity", systemImage: "square.grid.2x2")
                    .tag(Skill?.none)
            }
            Section("My Skills") {
                ForEach(store.skills) { skill in
                    SkillRowView(skill: skill)
                        .tag(Optional(skill))
                        .contextMenu {
                            Button(role: .destructive) {
                                if selectedSkill == skill { selectedSkill = nil }
                                store.deleteSkill(skill)
                            } label: {
                                Label("Delete \(skill.name)", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("SkillLog")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddSkill = true } label: {
                    Image(systemName: "plus")
                }
                .help("Add a new skill")
            }
        }
    }
}

struct SkillRowView: View {
    @EnvironmentObject var store: SkillStore
    let skill: Skill

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: skill.category.systemImage)
                .foregroundStyle(skill.category.color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(skill.name).font(.body)
                let mins = store.totalMinutes(for: skill)
                Text(formatMinutes(mins))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            let streak = store.streak(for: skill)
            if streak > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill").foregroundStyle(.orange).font(.caption2)
                    Text("\(streak)").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func formatMinutes(_ m: Int) -> String {
        if m == 0 { return "No sessions yet" }
        if m < 60 { return "\(m) min total" }
        return "\(m / 60)h \(m % 60)m total"
    }
}

// MARK: - Overview

struct OverviewView: View {
    @EnvironmentObject var store: SkillStore
    @Binding var showLogSession: Bool
    @Binding var selectedSkill: Skill?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Activity Overview")
                            .font(.largeTitle).bold()
                        Text(store.skills.isEmpty
                             ? "Add your first skill to get started"
                             : "\(store.skills.count) skill\(store.skills.count == 1 ? "" : "s") · \(store.sessions.count) session\(store.sessions.count == 1 ? "" : "s") logged")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        showLogSession = true
                    } label: {
                        Label("Log Session", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(store.skills.isEmpty)
                }

                if store.skills.isEmpty {
                    EmptyStateView()
                } else {
                    // Skill cards
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 12)], spacing: 12) {
                        ForEach(store.skills) { skill in
                            SkillCardView(skill: skill)
                                .onTapGesture { selectedSkill = skill }
                        }
                    }

                    // Recent activity
                    let recent = store.recentActivity()
                    if !recent.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recent Sessions")
                                .font(.headline)
                            ForEach(recent.prefix(8), id: \.1.id) { (skill, session) in
                                RecentSessionRow(skill: skill, session: session)
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(.quaternary)
            Text("No skills yet")
                .font(.title2).bold()
                .foregroundStyle(.secondary)
            Text("Click + in the sidebar to add a skill you're practicing.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(48)
    }
}

struct SkillCardView: View {
    @EnvironmentObject var store: SkillStore
    let skill: Skill

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: skill.category.systemImage)
                    .foregroundStyle(skill.category.color)
                    .font(.title2)
                Spacer()
                let streak = store.streak(for: skill)
                if streak > 0 {
                    Label("\(streak)d", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            Text(skill.name)
                .font(.headline)
            let mins = store.totalMinutes(for: skill)
            let count = store.sessions(for: skill).count
            Text("\(count) session\(count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(formatMinutes(mins))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(skill.category.color.opacity(0.25), lineWidth: 1.5))
    }

    private func formatMinutes(_ m: Int) -> String {
        if m == 0 { return "0 min" }
        if m < 60 { return "\(m) min" }
        return "\(m / 60)h \(m % 60)m"
    }
}

struct RecentSessionRow: View {
    let skill: Skill
    let session: PracticeSession

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: skill.category.systemImage)
                .foregroundStyle(skill.category.color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(skill.name).font(.callout)
                Text(session.date, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(session.durationMinutes) min")
                .font(.caption)
                .foregroundStyle(.secondary)
            DifficultyBadge(level: session.difficulty)
        }
        .padding(.vertical, 4)
        Divider()
    }
}

// MARK: - Skill Detail

struct SkillDetailView: View {
    @EnvironmentObject var store: SkillStore
    let skill: Skill
    @Binding var showLogSession: Bool

    var sessions: [PracticeSession] { store.sessions(for: skill) }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .top) {
                HStack(spacing: 10) {
                    Image(systemName: skill.category.systemImage)
                        .foregroundStyle(skill.category.color)
                        .font(.title)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(skill.name).font(.largeTitle).bold()
                        Text(skill.category.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button {
                    showLogSession = true
                } label: {
                    Label("Log Session", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding([.horizontal, .top], 24)
            .padding(.bottom, 16)

            // Stats bar
            HStack(spacing: 0) {
                StatCell(label: "Sessions", value: "\(sessions.count)")
                Divider().frame(height: 40)
                StatCell(label: "Total Time", value: formatMins(store.totalMinutes(for: skill)))
                Divider().frame(height: 40)
                StatCell(label: "Streak", value: "\(store.streak(for: skill))d")
                Divider().frame(height: 40)
                StatCell(label: "Avg Difficulty",
                         value: sessions.isEmpty ? "—"
                            : String(format: "%.1f", Double(sessions.map(\.difficulty).reduce(0,+)) / Double(sessions.count)))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            Divider()

            // Session list
            if sessions.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 36))
                        .foregroundStyle(.quaternary)
                    Text("No sessions yet")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("Tap \"Log Session\" to record your first practice.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(sessions) { session in
                        SessionRowView(session: session)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    store.deleteSession(session)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.inset)
            }
        }
    }

    private func formatMins(_ m: Int) -> String {
        if m == 0 { return "0 min" }
        if m < 60 { return "\(m)m" }
        return "\(m / 60)h \(m % 60)m"
    }
}

struct StatCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.title2).bold()
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SessionRowView: View {
    let session: PracticeSession

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.date, style: .date)
                    .font(.callout)
                Text(session.date, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 90, alignment: .leading)

            Divider().frame(height: 32)

            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Text("\(session.durationMinutes) min")
                    .font(.callout)
            }
            .frame(width: 70, alignment: .leading)

            DifficultyBadge(level: session.difficulty)

            if !session.notes.isEmpty {
                Text(session.notes)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct DifficultyBadge: View {
    let level: Int

    private var label: String {
        switch level {
        case 1: return "Easy"
        case 2: return "Mild"
        case 3: return "Medium"
        case 4: return "Hard"
        default: return "Max"
        }
    }
    private var color: Color {
        switch level {
        case 1: return .green
        case 2: return .teal
        case 3: return .orange
        case 4: return .red
        default: return .purple
        }
    }

    var body: some View {
        Text(label)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.15)))
            .foregroundStyle(color)
    }
}

// MARK: - Add Skill Sheet

struct AddSkillSheet: View {
    @EnvironmentObject var store: SkillStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: SkillCategory = .other

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Add New Skill")
                .font(.title2).bold()

            VStack(alignment: .leading, spacing: 6) {
                Text("Skill Name").font(.caption).foregroundStyle(.secondary)
                TextField("e.g. Guitar, Spanish, Sketching…", text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Category").font(.caption).foregroundStyle(.secondary)
                Picker("Category", selection: $category) {
                    ForEach(SkillCategory.allCases) { cat in
                        Label(cat.rawValue, systemImage: cat.systemImage).tag(cat)
                    }
                }
                .pickerStyle(.segmented)
                // show icon preview
                HStack {
                    Image(systemName: category.systemImage)
                        .foregroundStyle(category.color)
                    Text(category.rawValue)
                        .foregroundStyle(category.color)
                }
                .font(.caption)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Add Skill") {
                    let skill = Skill(name: name.trimmingCharacters(in: .whitespaces),
                                      category: category)
                    store.addSkill(skill)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}

// MARK: - Log Session Sheet

struct LogSessionSheet: View {
    @EnvironmentObject var store: SkillStore
    @Environment(\.dismiss) private var dismiss

    let preselectedSkill: Skill?

    @State private var selectedSkillId: UUID?
    @State private var durationMinutes: Int = 30
    @State private var difficulty: Int = 3
    @State private var notes: String = ""
    @State private var date: Date = Date()

    private let durations = [5, 10, 15, 20, 25, 30, 45, 60, 90, 120]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Log Practice Session")
                .font(.title2).bold()

            // Skill picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Skill").font(.caption).foregroundStyle(.secondary)
                Picker("Skill", selection: $selectedSkillId) {
                    Text("Select a skill…").tag(UUID?.none)
                    ForEach(store.skills) { skill in
                        Label(skill.name, systemImage: skill.category.systemImage)
                            .tag(Optional(skill.id))
                    }
                }
                .labelsHidden()
            }

            // Duration
            VStack(alignment: .leading, spacing: 6) {
                Text("Duration").font(.caption).foregroundStyle(.secondary)
                HStack {
                    Picker("Duration", selection: $durationMinutes) {
                        ForEach(durations, id: \.self) { min in
                            Text(min < 60 ? "\(min) min" : "\(min / 60)h\(min % 60 > 0 ? " \(min % 60)m" : "")")
                                .tag(min)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 120)
                    Text("minutes").foregroundStyle(.secondary)
                }
            }

            // Difficulty
            VStack(alignment: .leading, spacing: 6) {
                Text("How hard was it?  (\(difficultyLabel))").font(.caption).foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { level in
                        Button {
                            difficulty = level
                        } label: {
                            Image(systemName: level <= difficulty ? "circle.fill" : "circle")
                                .foregroundStyle(difficultyColor(level))
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Date
            VStack(alignment: .leading, spacing: 6) {
                Text("Date & Time").font(.caption).foregroundStyle(.secondary)
                DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
            }

            // Notes
            VStack(alignment: .leading, spacing: 6) {
                Text("Notes (optional)").font(.caption).foregroundStyle(.secondary)
                TextEditor(text: $notes)
                    .font(.body)
                    .frame(height: 64)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.3)))
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save Session") {
                    let session = PracticeSession(
                        skillId: selectedSkillId!,
                        date: date,
                        durationMinutes: durationMinutes,
                        difficulty: difficulty,
                        notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                    store.addSession(session)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedSkillId == nil)
            }
        }
        .padding(24)
        .frame(width: 400)
        .onAppear {
            selectedSkillId = preselectedSkill?.id ?? store.skills.first?.id
        }
    }

    private var difficultyLabel: String {
        switch difficulty {
        case 1: return "Easy"
        case 2: return "Mild"
        case 3: return "Medium"
        case 4: return "Hard"
        default: return "Max"
        }
    }

    private func difficultyColor(_ level: Int) -> Color {
        if level > difficulty { return .secondary.opacity(0.3) }
        switch difficulty {
        case 1: return .green
        case 2: return .teal
        case 3: return .orange
        case 4: return .red
        default: return .purple
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SkillStore())
}

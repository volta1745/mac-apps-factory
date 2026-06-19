import SwiftUI

struct ContentView: View {
    @StateObject private var store = FocusStore()
    @StateObject private var timerVM = FocusTimerManager()
    @State private var topic: String = ""
    @State private var showCompletion: Bool = false

    private var todaySessions: [FocusSession] {
        store.sessions.filter { Calendar.current.isDateInToday($0.startDate) }
    }

    private var todayMinutes: Int {
        todaySessions.reduce(0) { $0 + $1.actualMinutes }
    }

    var body: some View {
        VStack(spacing: 0) {
            statsBar
            Divider()
            timerSection
            Divider()
            historySection
        }
        .frame(minWidth: 480, idealWidth: 520, minHeight: 580, idealHeight: 650)
        .onReceive(timerVM.$state) { newState in
            if newState == .finished {
                showCompletion = true
            }
        }
        .sheet(isPresented: $showCompletion, onDismiss: {
            timerVM.reset()
            topic = ""
        }) {
            CompletionView(
                initialTopic: topic,
                plannedMinutes: timerVM.plannedMinutes,
                sessionStart: timerVM.sessionStart,
                wasCompleted: timerVM.sessionCompleted,
                store: store
            )
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: 0) {
            statCell(value: "\(todaySessions.count)", label: "sessions today")
            Divider()
            statCell(value: "\(todayMinutes)m", label: "focused today")
            Divider()
            statCell(value: "\(store.sessions.count)", label: "all time")
        }
        .frame(maxWidth: .infinity)
        .frame(height: 64)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Timer Section

    private var timerSection: some View {
        VStack(spacing: 16) {
            if timerVM.state == .idle {
                TextField("What are you working on?", text: $topic)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 360)

                Picker("Duration", selection: $timerVM.plannedMinutes) {
                    Text("15m").tag(15)
                    Text("25m").tag(25)
                    Text("30m").tag(30)
                    Text("45m").tag(45)
                    Text("60m").tag(60)
                    Text("90m").tag(90)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 360)
                .labelsHidden()
            } else {
                Text(topic.isEmpty ? "Focus Session" : topic)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            timerRing

            controlButtons
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
    }

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.15), lineWidth: 10)
            Circle()
                .trim(from: 0, to: timerVM.progress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: timerVM.progress)

            VStack(spacing: 4) {
                Text(timerVM.timeString)
                    .font(.system(size: 52, weight: .thin, design: .monospaced))
                if timerVM.state != .idle {
                    Text(statusLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 200, height: 200)
    }

    private var ringColor: Color {
        switch timerVM.state {
        case .idle:     return .accentColor.opacity(0.3)
        case .running:  return .accentColor
        case .paused:   return .orange
        case .finished: return .green
        }
    }

    private var statusLabel: String {
        switch timerVM.state {
        case .idle:     return ""
        case .running:  return "Focus"
        case .paused:   return "Paused"
        case .finished: return "Done!"
        }
    }

    @ViewBuilder
    private var controlButtons: some View {
        switch timerVM.state {
        case .idle:
            Button("Start Focus Session") {
                timerVM.start()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(topic.trimmingCharacters(in: .whitespaces).isEmpty)

        case .running:
            HStack(spacing: 12) {
                Button("Pause") { timerVM.pause() }
                    .buttonStyle(.bordered)
                Button("Stop & Log") { timerVM.stop() }
                    .buttonStyle(.bordered)
                    .foregroundStyle(.red)
            }

        case .paused:
            HStack(spacing: 12) {
                Button("Resume") { timerVM.resume() }
                    .buttonStyle(.borderedProminent)
                Button("Stop & Log") { timerVM.stop() }
                    .buttonStyle(.bordered)
                    .foregroundStyle(.red)
            }

        case .finished:
            Button("Log This Session") { showCompletion = true }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }

    // MARK: - History Section

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Session History")
                    .font(.headline)
                Spacer()
                if !store.sessions.isEmpty {
                    Text("\(store.sessions.count) sessions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            if store.sessions.isEmpty {
                VStack {
                    Spacer()
                    Text("No sessions yet.")
                        .foregroundStyle(.secondary)
                    Text("Start a focus session above to get started.")
                        .foregroundStyle(.tertiary)
                        .font(.caption)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(store.sessions) { session in
                        SessionRow(session: session)
                    }
                    .onDelete { store.delete(at: $0) }
                }
                .listStyle(.inset)
            }
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Session Row

private struct SessionRow: View {
    let session: FocusSession

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: session.completed ? "checkmark.circle.fill" : "stop.circle.fill")
                .foregroundStyle(session.completed ? .green : .orange)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.topic)
                    .font(.subheadline.weight(.medium))
                if !session.notes.isEmpty {
                    Text(session.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Text("\(session.actualMinutes)m")
                        .font(.subheadline.bold())
                    if session.actualMinutes < session.plannedMinutes {
                        Text("/ \(session.plannedMinutes)m")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(session.startDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Completion Sheet

struct CompletionView: View {
    @Environment(\.dismiss) private var dismiss

    @State var topic: String
    let plannedMinutes: Int
    let sessionStart: Date
    let wasCompleted: Bool
    @ObservedObject var store: FocusStore
    @State private var notes: String = ""

    private var actualMinutes: Int {
        max(1, Int(Date().timeIntervalSince(sessionStart) / 60))
    }

    init(initialTopic: String, plannedMinutes: Int, sessionStart: Date,
         wasCompleted: Bool, store: FocusStore)
    {
        _topic = State(initialValue: initialTopic)
        self.plannedMinutes = plannedMinutes
        self.sessionStart = sessionStart
        self.wasCompleted = wasCompleted
        self.store = store
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: wasCompleted ? "checkmark.circle.fill" : "stop.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(wasCompleted ? .green : .orange)

            Text(wasCompleted ? "Session Complete!" : "Session Ended")
                .font(.title2.bold())

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Topic")
                            .foregroundStyle(.secondary)
                            .frame(width: 72, alignment: .leading)
                        TextField("Topic", text: $topic)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack {
                        Text("Duration")
                            .foregroundStyle(.secondary)
                            .frame(width: 72, alignment: .leading)
                        Text("\(actualMinutes) min")
                            .fontWeight(.medium)
                        if actualMinutes < plannedMinutes {
                            Text("of \(plannedMinutes) planned")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }

                    HStack(alignment: .top) {
                        Text("Notes")
                            .foregroundStyle(.secondary)
                            .frame(width: 72, alignment: .leading)
                            .padding(.top, 4)
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $notes)
                                .frame(height: 72)
                                .scrollContentBackground(.hidden)
                                .background(Color(nsColor: .textBackgroundColor))
                                .cornerRadius(6)
                            if notes.isEmpty {
                                Text("Optional notes…")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 5)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                }
                .padding(4)
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 12) {
                Button("Discard") { dismiss() }
                    .buttonStyle(.bordered)

                Button("Save Session") {
                    let session = FocusSession(
                        topic: topic.trimmingCharacters(in: .whitespaces),
                        startDate: sessionStart,
                        plannedMinutes: plannedMinutes,
                        actualMinutes: actualMinutes,
                        notes: notes.trimmingCharacters(in: .whitespaces),
                        completed: wasCompleted
                    )
                    store.add(session)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(topic.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}

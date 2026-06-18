import SwiftUI

struct AddDrinkView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss

    @State private var selectedType: DrinkType = .coffee
    @State private var customName: String = ""
    @State private var caffeineMg: Int = 95
    @State private var notes: String = ""
    @State private var timestamp: Date = Date()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Log a Drink")
                    .font(.title2).bold()
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape)
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            Form {
                Section("Drink Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(DrinkType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedType) { newType in
                        caffeineMg = newType.defaultCaffeine
                        if newType != .custom { customName = "" }
                    }

                    if selectedType == .custom {
                        TextField("Custom drink name", text: $customName)
                    }
                }

                Section("Caffeine") {
                    HStack {
                        Slider(value: Binding(
                            get: { Double(caffeineMg) },
                            set: { caffeineMg = Int($0) }
                        ), in: 0...500, step: 5)
                        Text("\(caffeineMg) mg")
                            .frame(width: 60, alignment: .trailing)
                            .monospacedDigit()
                    }
                }

                Section("When") {
                    DatePicker("Time", selection: $timestamp, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Notes (optional)") {
                    TextField("Any notes…", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Spacer()
                Button("Add Drink") {
                    let entry = DrinkEntry(
                        timestamp: timestamp,
                        drinkType: selectedType,
                        customName: customName,
                        caffeineMg: caffeineMg,
                        notes: notes
                    )
                    store.add(entry)
                    dismiss()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .disabled(selectedType == .custom && customName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(width: 420, height: 460)
    }
}

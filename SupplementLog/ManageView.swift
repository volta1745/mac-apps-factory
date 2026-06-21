import SwiftUI

struct ManageView: View {
    @EnvironmentObject var store: SupplementStore
    @State private var showingAdd = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("My Supplement Stack")
                    .font(.headline)
                Spacer()
                Button {
                    showingAdd = true
                } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                        .font(.body.weight(.medium))
                }
                .buttonStyle(.borderless)
            }
            .padding()

            if store.supplements.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 46))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("Your stack is empty")
                        .foregroundColor(.secondary)
                    Button("Add First Supplement") {
                        showingAdd = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                List {
                    ForEach(store.supplements) { supplement in
                        HStack(spacing: 12) {
                            Image(systemName: "capsule.fill")
                                .foregroundColor(.accentColor)
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(supplement.name)
                                    .font(.body)
                                Text(supplement.dosage)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 3)
                    }
                    .onDelete { store.deleteSupplement(at: $0) }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))

                Text("Swipe left on a row to delete")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 6)
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddSupplementView(isPresented: $showingAdd)
        }
    }
}

// MARK: - Add Sheet

private let presets: [(name: String, dosage: String)] = [
    ("Vitamin D3",          "2000 IU"),
    ("Vitamin B12",         "1000 mcg"),
    ("Magnesium Glycinate", "400 mg"),
    ("Omega-3 Fish Oil",    "1000 mg"),
    ("Zinc",                "30 mg"),
    ("Vitamin C",           "500 mg"),
    ("Iron",                "18 mg"),
    ("Calcium",             "600 mg"),
    ("Probiotics",          "10 billion CFU"),
    ("Multivitamin",        "1 tablet"),
    ("Vitamin K2",          "100 mcg"),
    ("Ashwagandha",         "300 mg"),
]

struct AddSupplementView: View {
    @EnvironmentObject var store: SupplementStore
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var dosage = ""
    @State private var selectedPreset: String? = nil

    private var canAdd: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Supplement")
                .font(.title3.bold())
                .padding(.top, 4)

            // Presets grid
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick presets")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 145))], spacing: 8) {
                    ForEach(presets, id: \.name) { preset in
                        Button {
                            selectedPreset = preset.name
                            name = preset.name
                            dosage = preset.dosage
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.name)
                                    .font(.caption.bold())
                                    .lineLimit(1)
                                    .foregroundColor(.primary)
                                Text(preset.dosage)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(selectedPreset == preset.name
                                          ? Color.accentColor.opacity(0.15)
                                          : Color.secondary.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 7)
                                            .stroke(selectedPreset == preset.name
                                                    ? Color.accentColor : Color.clear,
                                                    lineWidth: 1.5)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider()

            // Custom entry
            VStack(alignment: .leading, spacing: 8) {
                Text("Custom / override")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("Supplement name", text: $name)
                    .textFieldStyle(.roundedBorder)
                TextField("Dosage  (e.g. 500 mg, 1 capsule)", text: $dosage)
                    .textFieldStyle(.roundedBorder)
            }

            Spacer(minLength: 4)

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)

                Spacer()

                Button("Add to Stack") {
                    store.addSupplement(name: name.trimmingCharacters(in: .whitespaces), dosage: dosage)
                    isPresented = false
                }
                .keyboardShortcut(.return)
                .disabled(!canAdd)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 420, height: 500)
    }
}

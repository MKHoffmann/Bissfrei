import SwiftUI
import UIKit
import SwiftData

/// Eigene Situationen anlegen, umbenennen, sortieren und löschen.
struct SituationsEditor: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SituationTag.sortOrder) private var tags: [SituationTag]

    @State private var editing: SituationTag?
    @State private var showAdd = false

    var body: some View {
        List {
            Section {
                ForEach(tags) { tag in
                    Button {
                        editing = tag
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: tag.symbol)
                                .foregroundStyle(Palette.practice)
                                .frame(width: 28)
                            Text(tag.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .onMove(perform: move)
                .onDelete(perform: delete)
            } footer: {
                Text("Situationen erscheinen als Schnellwahl unter dem großen Knopf und lassen sich als Modus starten. Gelöschte Situationen bleiben in alten Einträgen erhalten.")
            }

            Section {
                Button {
                    showAdd = true
                } label: {
                    Label("Situation hinzufügen", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle("Situationen & Modi")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .sheet(item: $editing) { tag in
            SituationForm(tag: tag)
        }
        .sheet(isPresented: $showAdd) {
            SituationForm(tag: nil)
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        var reordered = tags
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, tag) in reordered.enumerated() {
            tag.sortOrder = index
        }
        try? context.save()
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(tags[index])
        }
        try? context.save()
    }
}

struct SituationForm: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \SituationTag.sortOrder) private var tags: [SituationTag]

    let tag: SituationTag?
    @State private var name: String
    @State private var symbol: String

    init(tag: SituationTag?) {
        self.tag = tag
        _name = State(initialValue: tag?.name ?? "")
        _symbol = State(initialValue: tag?.symbol ?? "tag.fill")
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isDuplicate: Bool {
        tags.contains { other in
            other.persistentModelID != tag?.persistentModelID
                && other.name.caseInsensitiveCompare(trimmedName) == .orderedSame
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: symbol)
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Palette.practice.gradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        TextField("z. B. Coding", text: $name)
                            .font(.headline)
                    }
                } footer: {
                    if isDuplicate {
                        Text("Diesen Namen gibt es schon.")
                            .foregroundStyle(.red)
                    } else if tag != nil {
                        Text("Beim Umbenennen werden alle bisherigen Einträge und Modus-Zeiten mit umbenannt.")
                    }
                }

                Section("Symbol") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 10) {
                        ForEach(Defaults.situationSymbols, id: \.self) { option in
                            Button {
                                symbol = option
                            } label: {
                                Image(systemName: option)
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                                    .foregroundStyle(symbol == option ? Color.white : Color.primary)
                                    .background(
                                        symbol == option ? AnyShapeStyle(Palette.practice) : AnyShapeStyle(Color(.tertiarySystemFill)),
                                        in: Circle()
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle(tag == nil ? "Neue Situation" : "Situation bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") { save() }
                        .disabled(trimmedName.isEmpty || isDuplicate)
                }
            }
        }
    }

    private func save() {
        if let tag {
            let oldName = tag.name
            tag.name = trimmedName
            tag.symbol = symbol
            try? context.save()
            DataStore.renameSituation(from: oldName, to: trimmedName)
        } else {
            DataStore.addSituation(name: trimmedName, symbol: symbol)
        }
        dismiss()
    }
}

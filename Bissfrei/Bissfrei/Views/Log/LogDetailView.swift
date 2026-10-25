import SwiftUI
import UIKit
import SwiftData

struct LogDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var event: BiteEvent
    var isNew: Bool = false

    @Query(sort: \SituationTag.sortOrder) private var tags: [SituationTag]

    @State private var confirmDelete = false
    @State private var showNewSituation = false
    @State private var newSituationName = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    section("Wann?") {
                        DatePicker(
                            "Zeitpunkt",
                            selection: $event.timestamp,
                            in: ...Date(),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .labelsHidden()
                    }

                    section("Bewusst oder in Gedanken?") {
                        VStack(spacing: 8) {
                            ForEach(Awareness.allCases) { awareness in
                                awarenessRow(awareness)
                            }
                        }
                    }

                    section("Situation") {
                        FlowLayout {
                            ForEach(situationOptions, id: \.name) { option in
                                Chip(
                                    title: option.name,
                                    symbol: option.symbol,
                                    isSelected: event.situationName == option.name,
                                    tint: tint
                                ) {
                                    event.situationName = (event.situationName == option.name) ? "" : option.name
                                }
                            }
                            Chip(title: "Neu", symbol: "plus", isSelected: false, tint: tint) {
                                newSituationName = ""
                                showNewSituation = true
                            }
                        }
                        if !event.modeName.isEmpty {
                            Label("Erfasst im Modus „\(event.modeName)“", systemImage: "play.circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    section("Welche Hand?") {
                        FlowLayout {
                            ForEach(Hand.allCases) { hand in
                                Chip(title: hand.title, isSelected: event.hand == hand, tint: tint) {
                                    event.hand = (event.hand == hand) ? nil : hand
                                }
                            }
                        }
                    }

                    section("Welche Finger?", hint: "Mehrfachauswahl möglich") {
                        FlowLayout {
                            ForEach(Finger.allCases) { finger in
                                Chip(title: finger.title, isSelected: event.fingers.contains(finger), tint: tint) {
                                    var selection = event.fingers
                                    if selection.contains(finger) {
                                        selection.remove(finger)
                                    } else {
                                        selection.insert(finger)
                                    }
                                    event.fingers = selection
                                }
                            }
                        }
                    }

                    section("Gefühl davor") {
                        FlowLayout {
                            ForEach(Emotion.allCases) { emotion in
                                Chip(title: emotion.title, isSelected: event.emotion == emotion, tint: tint) {
                                    event.emotion = (event.emotion == emotion) ? nil : emotion
                                }
                            }
                        }
                    }

                    section("Stärke des Drangs") {
                        intensityPicker
                    }

                    section("Notiz") {
                        TextField(
                            "Was war los? Was hast du kurz davor gespürt?",
                            text: $event.note,
                            axis: .vertical
                        )
                        .lineLimit(3...8)
                        .padding(12)
                        .background(
                            Color(.secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                    }

                    if event.kind == .resisted {
                        NavigationLink {
                            CompetingResponseView()
                        } label: {
                            Label("Jetzt 1 Minute Gegenreaktion", systemImage: "timer")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(Palette.practice)
                        .controlSize(.large)
                    }

                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        Label("Eintrag löschen", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 8)
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(event.kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        try? context.save()
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Eintrag löschen?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Löschen", role: .destructive) {
                    deleteEvent()
                }
                Button("Abbrechen", role: .cancel) {}
            }
            .alert("Neue Situation", isPresented: $showNewSituation) {
                TextField("z. B. Coding", text: $newSituationName)
                Button("Hinzufügen") {
                    if let tag = DataStore.addSituation(name: newSituationName) {
                        event.situationName = tag.name
                    }
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Sie erscheint künftig auch als Schnellwahl unter dem großen Knopf.")
            }
        }
    }

    private struct SituationOption {
        let name: String
        let symbol: String
    }

    /// Eigene Situationen plus ggf. eine ältere, inzwischen gelöschte Situation dieses Eintrags.
    private var situationOptions: [SituationOption] {
        var options = tags.map { SituationOption(name: $0.name, symbol: $0.symbol) }
        let current = event.situationLabel
        if !current.isEmpty && !options.contains(where: { $0.name == current }) {
            options.insert(SituationOption(name: current, symbol: "clock.arrow.circlepath"), at: 0)
        }
        return options
    }

    private var tint: Color {
        event.kind == .bitten ? Palette.biteDeep : Palette.resistDeep
    }

    // MARK: - Kopfbereich

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: event.kind == .bitten ? "checkmark.circle.fill" : "star.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(event.kind.color)
            VStack(alignment: .leading, spacing: 4) {
                Text(headline)
                    .font(.title3.bold())
                Text(subline)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var headline: String {
        if !isNew { return event.kind == .bitten ? "Eintrag bearbeiten" : "Widerstanden" }
        return event.kind == .bitten ? "Gut bemerkt – gespeichert." : "Stark – du hast widerstanden!"
    }

    private var subline: String {
        if event.kind == .bitten {
            return "Ausrutscher gehören dazu. Je mehr du ergänzt, desto besser erkennst du deine Auslöser. Alles ist optional."
        }
        return "Du hast den Drang bemerkt und nicht nachgegeben – genau das trainiert die neue Gewohnheit."
    }

    // MARK: - Bausteine

    @ViewBuilder
    private func section<Content: View>(_ title: String, hint: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.headline)
                if let hint {
                    Text(hint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            content()
        }
    }

    private func awarenessRow(_ awareness: Awareness) -> some View {
        let selected = event.awareness == awareness
        return Button {
            event.awareness = selected ? nil : awareness
        } label: {
            HStack(spacing: 12) {
                Image(systemName: awareness.symbol)
                    .font(.title3)
                    .foregroundStyle(selected ? tint : Color.secondary)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(awareness.title)
                        .font(.subheadline.weight(.semibold))
                    Text(awareness.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selected ? tint : Color.secondary.opacity(0.5))
            }
            .padding(12)
            .background(
                selected ? AnyShapeStyle(tint.opacity(0.14)) : AnyShapeStyle(Color(.secondarySystemGroupedBackground)),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selected)
    }

    private var intensityPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                ForEach(1...10, id: \.self) { value in
                    Button {
                        event.intensity = (event.intensity == value) ? 0 : value
                    } label: {
                        Text("\(value)")
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .foregroundStyle(value <= event.intensity ? Color.white : Color.primary)
                            .background(
                                value <= event.intensity ? AnyShapeStyle(intensityColor(value)) : AnyShapeStyle(Color(.tertiarySystemFill)),
                                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .sensoryFeedback(.selection, trigger: event.intensity)

            HStack {
                Text("schwach")
                Spacer()
                Text(event.intensity == 0 ? "nicht angegeben" : "\(event.intensity) von 10")
                    .fontWeight(.medium)
                Spacer()
                Text("stark")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private func intensityColor(_ value: Int) -> Color {
        let fraction = Double(value - 1) / 9.0
        return Color(
            red: 0.98,
            green: 0.78 - 0.5 * fraction,
            blue: 0.35 - 0.05 * fraction
        )
    }

    // MARK: - Löschen

    private func deleteEvent() {
        let target = event
        let modelContext = context
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            modelContext.delete(target)
            try? modelContext.save()
        }
    }
}

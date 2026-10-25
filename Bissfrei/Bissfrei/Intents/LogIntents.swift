import AppIntents
import SwiftData

// MARK: - Situation/Modus als Kurzbefehl-Parameter

struct ModeEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Situation"
    static var defaultQuery = ModeQuery()

    /// Der Name dient zugleich als Kennung.
    var id: String

    var name: String { id }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(id)")
    }
}

struct ModeQuery: EntityQuery {
    init() {}

    @MainActor
    func entities(for identifiers: [String]) async throws -> [ModeEntity] {
        let names = Set(DataStore.situationTags().map { $0.name })
        return identifiers.filter { names.contains($0) }.map { ModeEntity(id: $0) }
    }

    @MainActor
    func suggestedEntities() async throws -> [ModeEntity] {
        DataStore.situationTags().map { ModeEntity(id: $0.name) }
    }
}

// MARK: - Erfassen

struct LogBiteIntent: AppIntent {
    static var title: LocalizedStringResource = "Gekaut erfassen"
    static var description: IntentDescription? = IntentDescription("Erfasst, dass du gerade an den Nägeln gekaut hast. Ohne Situation wird der aktive Modus übernommen.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Situation")
    var situation: ModeEntity?

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let event = DataStore.log(.bitten, situation: situation?.name)
        let label = event.situationLabel
        let text = label.isEmpty
            ? "Erfasst. Gut, dass du es bemerkt hast."
            : "Erfasst (\(label)). Gut, dass du es bemerkt hast."
        return .result(dialog: IntentDialog(stringLiteral: text))
    }
}

struct LogResistedIntent: AppIntent {
    static var title: LocalizedStringResource = "Drang widerstanden erfassen"
    static var description: IntentDescription? = IntentDescription("Erfasst, dass du einem Drang zum Nägelkauen widerstanden hast.")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        DataStore.log(.resisted)
        return .result(dialog: "Stark! Widerstanden ist erfasst.")
    }
}

// MARK: - Modi

struct StartModeIntent: AppIntent {
    static var title: LocalizedStringResource = "Bissfrei-Modus starten"
    static var description: IntentDescription? = IntentDescription("Startet einen Modus wie „Coding“. Bissfrei misst die Zeit darin und warnt bei Risikomodi.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Modus")
    var mode: ModeEntity

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        ModeManager.start(mode.name, source: .shortcut)
        return .result(dialog: IntentDialog(stringLiteral: "Modus „\(mode.name)“ gestartet."))
    }
}

struct StopModeIntent: AppIntent {
    static var title: LocalizedStringResource = "Bissfrei-Modus beenden"
    static var description: IntentDescription? = IntentDescription("Beendet den aktiven Modus.")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        ModeManager.stop()
        return .result(dialog: "Modus beendet.")
    }
}

// MARK: - Fokusfilter

/// Wird in iOS unter Einstellungen › Fokus › (Fokus) › Fokusfilter an einen Fokus gehängt.
/// Beim Aktivieren startet der gewählte Modus, beim Beenden des Fokus endet er wieder.
struct BissfreiFocusFilter: SetFocusFilterIntent {
    static var title: LocalizedStringResource = "Bissfrei-Modus"
    static var description: IntentDescription? = IntentDescription("Startet beim Aktivieren dieses Fokus automatisch einen Bissfrei-Modus.")

    @Parameter(title: "Modus")
    var mode: ModeEntity?

    var displayRepresentation: DisplayRepresentation {
        let name = mode?.name ?? "Kein Modus"
        return DisplayRepresentation(title: "\(name)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        ModeManager.focusChanged(to: mode?.name)
        return .result()
    }
}

// MARK: - App-Kurzbefehle (Siri, Kurzbefehle-App, Aktionstaste)

struct BissfreiShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogBiteIntent(),
            phrases: [
                "Gekaut in \(.applicationName)",
                "\(.applicationName) gekaut",
                "Nägelkauen in \(.applicationName) erfassen"
            ],
            shortTitle: "Gekaut",
            systemImageName: "hand.raised.fingers.spread.fill"
        )
        AppShortcut(
            intent: LogResistedIntent(),
            phrases: [
                "Widerstanden in \(.applicationName)",
                "\(.applicationName) widerstanden"
            ],
            shortTitle: "Widerstanden",
            systemImageName: "hand.thumbsup.fill"
        )
        AppShortcut(
            intent: StartModeIntent(),
            phrases: [
                "Modus starten in \(.applicationName)",
                "\(.applicationName) Modus starten"
            ],
            shortTitle: "Modus starten",
            systemImageName: "play.circle.fill"
        )
        AppShortcut(
            intent: StopModeIntent(),
            phrases: [
                "Modus beenden in \(.applicationName)",
                "\(.applicationName) Modus beenden"
            ],
            shortTitle: "Modus beenden",
            systemImageName: "stop.circle.fill"
        )
    }
}

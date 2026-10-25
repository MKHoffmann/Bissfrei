import Foundation
import SwiftData

/// Gemeinsamer Datenspeicher für App, Kurzbefehle, Fokusfilter und Mitteilungs-Aktionen.
@MainActor
enum DataStore {
    static let container: ModelContainer = {
        let schema = Schema([
            BiteEvent.self,
            PracticeSession.self,
            IfThenPlan.self,
            SituationTag.self,
            ModeSession.self,
            RiskWarning.self
        ])
        let configuration = ModelConfiguration(schema: schema)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Datenbank konnte nicht geöffnet werden: \(error)")
        }
    }()

    static var context: ModelContext {
        container.mainContext
    }

    /// Speichert einen Eintrag. Ohne ausdrückliche Situation wird der aktive Modus übernommen.
    @discardableResult
    static func log(_ kind: EventKind, situation: String? = nil, at date: Date = Date()) -> BiteEvent {
        let event = BiteEvent(kind: kind, timestamp: date)
        let active = ModeManager.activeSession()
        event.modeName = active?.name ?? ""
        event.situationName = situation ?? active?.name ?? ""
        context.insert(event)
        try? context.save()
        return event
    }

    // MARK: - Abfragen

    static func situationTags() -> [SituationTag] {
        let descriptor = FetchDescriptor<SituationTag>(
            sortBy: [SortDescriptor(\SituationTag.sortOrder), SortDescriptor(\SituationTag.createdAt)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    static func allEvents() -> [BiteEvent] {
        let descriptor = FetchDescriptor<BiteEvent>(sortBy: [SortDescriptor(\BiteEvent.timestamp)])
        return (try? context.fetch(descriptor)) ?? []
    }

    static func allModeSessions() -> [ModeSession] {
        let descriptor = FetchDescriptor<ModeSession>(sortBy: [SortDescriptor(\ModeSession.startedAt)])
        return (try? context.fetch(descriptor)) ?? []
    }

    static func allWarnings() -> [RiskWarning] {
        let descriptor = FetchDescriptor<RiskWarning>(sortBy: [SortDescriptor(\RiskWarning.date)])
        return (try? context.fetch(descriptor)) ?? []
    }

    static func allPlans() -> [IfThenPlan] {
        let descriptor = FetchDescriptor<IfThenPlan>(sortBy: [SortDescriptor(\IfThenPlan.createdAt)])
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Situationen verwalten

    @discardableResult
    static func addSituation(name: String, symbol: String = "tag.fill") -> SituationTag? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let existing = situationTags()
        if let match = existing.first(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return match
        }
        let tag = SituationTag(name: trimmed, symbol: symbol, sortOrder: (existing.map { $0.sortOrder }.max() ?? -1) + 1)
        context.insert(tag)
        try? context.save()
        return tag
    }

    /// Benennt eine Situation um und passt alle Einträge und Modus-Sitzungen an.
    static func renameSituation(from oldName: String, to newName: String) {
        guard oldName != newName else { return }
        for event in allEvents() {
            if event.situationName == oldName { event.situationName = newName }
            if event.modeName == oldName { event.modeName = newName }
        }
        for session in allModeSessions() where session.name == oldName {
            session.name = newName
        }
        for warning in allWarnings() where warning.modeName == oldName {
            warning.modeName = newName
        }
        try? context.save()
    }

    // MARK: - Start

    static func bootstrap() {
        seedSituationsIfNeeded()
        migrateLegacySituations()
        ModeManager.closeStaleSessions()
    }

    private static func seedSituationsIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Keys.didSeedSituations) else { return }
        if situationTags().isEmpty {
            for (index, seed) in Defaults.seedSituations.enumerated() {
                context.insert(SituationTag(name: seed.name, symbol: seed.symbol, sortOrder: index))
            }
            try? context.save()
        }
        defaults.set(true, forKey: Keys.didSeedSituations)
    }

    private static func migrateLegacySituations() {
        let legacy = allEvents().filter { $0.situationName.isEmpty && !$0.situationRaw.isEmpty }
        guard !legacy.isEmpty else { return }
        for event in legacy {
            event.situationName = Situation(rawValue: event.situationRaw)?.title ?? ""
        }
        try? context.save()
    }
}

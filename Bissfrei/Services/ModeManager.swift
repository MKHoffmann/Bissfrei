import Foundation
import SwiftData

/// Verwaltet den aktuell aktiven Modus (z. B. „Coding“) und dessen Zeiträume.
@MainActor
enum ModeManager {
    static func activeSession() -> ModeSession? {
        DataStore.allModeSessions().last(where: { $0.isActive })
    }

    /// Startet einen Modus. Ein bereits aktiver anderer Modus wird beendet.
    static func start(_ name: String, source: ModeSource) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let now = Date()

        if let current = activeSession() {
            if current.name == trimmed { return }
            current.endedAt = now
        }

        DataStore.context.insert(ModeSession(name: trimmed, source: source, startedAt: now))
        try? DataStore.context.save()

        Task { @MainActor in
            await ReminderManager.modeStarted(trimmed)
        }
    }

    /// Beendet den aktiven Modus. Mit `source` nur dann, wenn er aus dieser Quelle stammt
    /// (ein endender Fokus beendet z. B. keinen manuell gestarteten Modus).
    static func stop(source: ModeSource? = nil) {
        guard let current = activeSession() else { return }
        if let source, current.source != source { return }
        current.endedAt = Date()
        try? DataStore.context.save()
        ReminderManager.cancelModeNotifications()
    }

    /// Wird vom Fokusfilter aufgerufen: mit Name beim Aktivieren, ohne Name beim Beenden.
    static func focusChanged(to name: String?) {
        if let name, !name.isEmpty {
            start(name, source: .focus)
        } else {
            stop(source: .focus)
        }
    }

    /// Schließt vergessene Sitzungen, die länger als die Höchstdauer laufen.
    static func closeStaleSessions() {
        let now = Date()
        var changed = false
        for session in DataStore.allModeSessions() where session.isActive {
            if now.timeIntervalSince(session.startedAt) > ModeLimits.maxDuration {
                session.endedAt = session.startedAt.addingTimeInterval(ModeLimits.maxDuration)
                changed = true
            }
        }
        if changed { try? DataStore.context.save() }
    }
}

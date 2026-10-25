import Foundation
import SwiftData

@Model
final class BiteEvent {
    var timestamp: Date = Date()
    var kindRaw: String = "bitten"
    var handRaw: String = ""
    var fingersRaw: String = ""
    /// Alte, feste Situation aus Version 1.0 (wird beim Start in `situationName` übernommen).
    var situationRaw: String = ""
    /// Name der (eigenen) Situation, z. B. „Coding“.
    var situationName: String = ""
    /// Modus, der beim Erfassen aktiv war (leer, wenn keiner aktiv war).
    var modeName: String = ""
    var emotionRaw: String = ""
    var awarenessRaw: String = ""
    var intensity: Int = 0
    var note: String = ""

    init(kind: EventKind, timestamp: Date = Date()) {
        self.kindRaw = kind.rawValue
        self.timestamp = timestamp
    }

    var kind: EventKind {
        get { EventKind(rawValue: kindRaw) ?? .bitten }
        set { kindRaw = newValue.rawValue }
    }

    var hand: Hand? {
        get { Hand(rawValue: handRaw) }
        set { handRaw = newValue?.rawValue ?? "" }
    }

    var fingers: Set<Finger> {
        get {
            Set(fingersRaw.split(separator: ",").compactMap { Finger(rawValue: String($0)) })
        }
        set {
            fingersRaw = Finger.allCases
                .filter { newValue.contains($0) }
                .map { $0.rawValue }
                .joined(separator: ",")
        }
    }

    /// Anzeigename der Situation (eigene Situation oder Wert aus Version 1.0).
    var situationLabel: String {
        if !situationName.isEmpty { return situationName }
        return Situation(rawValue: situationRaw)?.title ?? ""
    }

    var emotion: Emotion? {
        get { Emotion(rawValue: emotionRaw) }
        set { emotionRaw = newValue?.rawValue ?? "" }
    }

    var awareness: Awareness? {
        get { Awareness(rawValue: awarenessRaw) }
        set { awarenessRaw = newValue?.rawValue ?? "" }
    }

    /// Kurze Zusammenfassung für Listen, z. B. „Rechts · Coding · Gestresst“.
    var summary: String {
        var parts: [String] = []
        if let hand { parts.append(hand.title) }
        let situation = situationLabel
        if !situation.isEmpty { parts.append(situation) }
        if let awareness { parts.append(awareness.title) }
        if let emotion { parts.append(emotion.title) }
        if intensity > 0 { parts.append("Drang \(intensity)/10") }
        return parts.joined(separator: " · ")
    }
}

@Model
final class PracticeSession {
    var date: Date = Date()
    var typeRaw: String = "competing"
    var durationSeconds: Int = 0
    var repetitions: Int = 0

    init(type: PracticeType, durationSeconds: Int = 0, repetitions: Int = 0, date: Date = Date()) {
        self.typeRaw = type.rawValue
        self.durationSeconds = durationSeconds
        self.repetitions = repetitions
        self.date = date
    }

    var type: PracticeType {
        PracticeType(rawValue: typeRaw) ?? .competing
    }
}

@Model
final class IfThenPlan {
    var createdAt: Date = Date()
    var trigger: String = ""
    var action: String = ""

    init(trigger: String, action: String) {
        self.trigger = trigger
        self.action = action
        self.createdAt = Date()
    }
}

/// Eine selbst definierte Situation, die zugleich als Modus dienen kann.
@Model
final class SituationTag {
    var name: String = ""
    var symbol: String = "tag.fill"
    var sortOrder: Int = 0
    var createdAt: Date = Date()

    init(name: String, symbol: String, sortOrder: Int) {
        self.name = name
        self.symbol = symbol
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }
}

enum ModeSource: String {
    case manual
    case focus
    case shortcut

    var title: String {
        switch self {
        case .manual: return "manuell"
        case .focus: return "per Fokus"
        case .shortcut: return "per Kurzbefehl"
        }
    }
}

enum ModeLimits {
    /// Längere Sitzungen gelten als vergessen und werden auf diese Dauer gekappt.
    static let maxDuration: TimeInterval = 8 * 3600
}

/// Zeitraum, in dem ein Modus aktiv war. Liefert die „Expositionszeit“ für das Risikomodell.
@Model
final class ModeSession {
    var name: String = ""
    var startedAt: Date = Date()
    var endedAt: Date? = nil
    var sourceRaw: String = "manual"

    init(name: String, source: ModeSource, startedAt: Date = Date()) {
        self.name = name
        self.sourceRaw = source.rawValue
        self.startedAt = startedAt
    }

    var source: ModeSource {
        ModeSource(rawValue: sourceRaw) ?? .manual
    }

    var isActive: Bool {
        endedAt == nil
    }

    /// Ende für Auswertungen: tatsächliches Ende, höchstens `maxDuration` nach Start.
    func effectiveEnd(now: Date) -> Date {
        min(endedAt ?? now, startedAt.addingTimeInterval(ModeLimits.maxDuration), now)
    }
}

enum WarningKind: String {
    case scheduled
    case mode
}

/// Protokoll ausgegebener Risiko-Warnungen (für die Auswertung, ob sie helfen).
@Model
final class RiskWarning {
    var date: Date = Date()
    var kindRaw: String = "scheduled"
    var modeName: String = ""
    var multiplier: Double = 1

    init(date: Date, kind: WarningKind, modeName: String = "", multiplier: Double) {
        self.date = date
        self.kindRaw = kind.rawValue
        self.modeName = modeName
        self.multiplier = multiplier
    }

    var kind: WarningKind {
        WarningKind(rawValue: kindRaw) ?? .scheduled
    }
}

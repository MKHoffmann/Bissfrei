import Foundation
import SwiftUI

// MARK: - Ergebnistypen

enum RiskLevel {
    case unknown
    case low
    case elevated
    case high

    var title: String {
        switch self {
        case .unknown: return "Noch offen"
        case .low: return "Niedrig"
        case .elevated: return "Erhöht"
        case .high: return "Hoch"
        }
    }

    var color: Color {
        switch self {
        case .unknown: return .gray
        case .low: return Palette.resist
        case .elevated: return .orange
        case .high: return Palette.biteDeep
        }
    }

    var symbol: String {
        switch self {
        case .unknown: return "questionmark.circle.fill"
        case .low: return "checkmark.shield.fill"
        case .elevated: return "exclamationmark.triangle.fill"
        case .high: return "flame.fill"
        }
    }
}

struct RiskFactor: Identifiable {
    let label: String
    let multiplier: Double
    var id: String { label }
}

struct RiskAssessment {
    let multiplier: Double
    let level: RiskLevel
    let factors: [RiskFactor]
}

struct ModeStat: Identifiable {
    let name: String
    let hours: Double
    let bites: Int
    /// Geglättete Rate in Bissen pro Stunde.
    let rate: Double
    /// Rate im Verhältnis zum Durchschnitt pro wacher Stunde.
    let factor: Double
    var id: String { name }
}

struct RiskSlot: Identifiable {
    let hour: Int
    let multiplier: Double
    var id: Int { hour }
}

struct HourFactor: Identifiable {
    let hour: Int
    let factor: Double
    var id: Int { hour }
}

struct WarningEffect {
    let warnings: Int
    let observed: Int
    let expected: Double
    let resisted: Int

    /// Beobachtete Bisse im Verhältnis zur Erwartung (unter 1 = weniger als sonst).
    var ratio: Double {
        expected > 0 ? Double(observed) / expected : 1
    }
}

// MARK: - Modell

/// Einfaches, nachvollziehbares Ratenmodell.
///
/// Es schätzt, wie viele Bisse pro Stunde zu erwarten sind – abhängig von Uhrzeit, Wochenende/Werktag
/// und aktivem Modus – und setzt das ins Verhältnis zu deinem Durchschnitt. Alle Raten werden zum
/// Durchschnitt hin „geglättet“ (Bayes-Schätzung mit schwachem Vorwissen), damit wenige Einträge
/// keine Ausreißer erzeugen. Grundlage sind die letzten 60 Tage.
struct RiskModel {
    static let windowDays = 60
    static let wakingHours = 16.0
    static let minBites = 10
    static let minDays = 5

    /// Stärke des Vorwissens: wie viele „Durchschnittstage“ bzw. „Durchschnittsstunden“ einfließen.
    private static let priorDays = 3.0
    private static let priorWeekDays = 2.0
    private static let priorModeHours = 2.0

    let biteCount: Int
    let daysObserved: Int
    /// Erwartete Bisse pro Stunde (je Uhrzeit), ohne Wochentag/Modus.
    let hourlyRates: [Double]
    let hourFactors: [Double]
    let weekendFactor: Double
    let weekdayFactor: Double
    let meanHourlyRate: Double
    let modeStats: [ModeStat]

    var isReady: Bool {
        biteCount >= Self.minBites && daysObserved >= Self.minDays
    }

    init(events: [BiteEvent], sessions: [ModeSession], now: Date = Date()) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let windowStart = calendar.date(byAdding: .day, value: -(Self.windowDays - 1), to: today) ?? today
        let firstActivity = (events.map { $0.timestamp } + sessions.map { $0.startedAt }).min() ?? now
        let start = max(windowStart, calendar.startOfDay(for: firstActivity))
        let dayCount = max(1, (calendar.dateComponents([.day], from: start, to: today).day ?? 0) + 1)

        let bites = events.filter { $0.kind == .bitten && $0.timestamp >= start && $0.timestamp <= now }
        let total = Double(bites.count)
        let days = Double(dayCount)
        let perDay = total / days
        let mean = max(perDay / Self.wakingHours, 0.000_1)

        biteCount = bites.count
        daysObserved = dayCount
        meanHourlyRate = mean

        // Uhrzeit: Zählungen mit Nachbarstunden glätten, dann zum Durchschnitt hin schrumpfen.
        var counts = Array(repeating: 0.0, count: 24)
        for bite in bites {
            counts[calendar.component(.hour, from: bite.timestamp)] += 1
        }
        var rates = Array(repeating: 0.0, count: 24)
        var factors = Array(repeating: 1.0, count: 24)
        for hour in 0..<24 {
            let smoothed = 0.25 * counts[(hour + 23) % 24] + 0.5 * counts[hour] + 0.25 * counts[(hour + 1) % 24]
            let rate = (smoothed + Self.priorDays * mean) / (days + Self.priorDays)
            rates[hour] = rate
            factors[hour] = rate / mean
        }
        hourlyRates = rates
        hourFactors = factors

        // Wochenende vs. Werktag
        var weekendDays = 0
        var weekdayDays = 0
        var cursor = start
        while cursor <= today {
            if calendar.isDateInWeekend(cursor) {
                weekendDays += 1
            } else {
                weekdayDays += 1
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        let weekendBites = Double(bites.filter { calendar.isDateInWeekend($0.timestamp) }.count)
        let weekdayBites = total - weekendBites
        let baseline = max(perDay, 0.000_1)
        weekendFactor = ((weekendBites + Self.priorWeekDays * perDay) / (Double(weekendDays) + Self.priorWeekDays)) / baseline
        weekdayFactor = ((weekdayBites + Self.priorWeekDays * perDay) / (Double(weekdayDays) + Self.priorWeekDays)) / baseline

        // Modi: Bisse pro Stunde im Modus, bezogen auf die tatsächlich verbrachte Zeit.
        var hoursByMode: [String: Double] = [:]
        for session in sessions {
            let begin = max(session.startedAt, start)
            let end = session.effectiveEnd(now: now)
            guard end > begin else { continue }
            hoursByMode[session.name, default: 0] += end.timeIntervalSince(begin) / 3600
        }
        var bitesByMode: [String: Int] = [:]
        for bite in bites where !bite.modeName.isEmpty {
            bitesByMode[bite.modeName, default: 0] += 1
        }
        var stats: [ModeStat] = []
        for (name, hours) in hoursByMode {
            let count = bitesByMode[name] ?? 0
            let rate = (Double(count) + Self.priorModeHours * mean) / (hours + Self.priorModeHours)
            stats.append(ModeStat(name: name, hours: hours, bites: count, rate: rate, factor: rate / mean))
        }
        modeStats = stats.sorted { $0.factor > $1.factor }
    }

    /// Lädt alle Daten aus dem Speicher und baut das Modell.
    @MainActor
    static func current() -> RiskModel {
        RiskModel(events: DataStore.allEvents(), sessions: DataStore.allModeSessions())
    }

    // MARK: - Abfragen

    func dayFactor(for date: Date) -> Double {
        Calendar.current.isDateInWeekend(date) ? weekendFactor : weekdayFactor
    }

    func modeStat(named name: String?) -> ModeStat? {
        guard let name, !name.isEmpty else { return nil }
        return modeStats.first(where: { $0.name == name && $0.hours >= 1 })
    }

    func assess(at date: Date = Date(), mode: String? = nil) -> RiskAssessment {
        guard isReady else {
            return RiskAssessment(multiplier: 1, level: .unknown, factors: [])
        }
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let hourFactor = hourFactors[hour]
        let weekFactor = self.dayFactor(for: date)

        var factors = [
            RiskFactor(label: "Uhrzeit \(hour)–\((hour + 1) % 24) Uhr", multiplier: hourFactor),
            RiskFactor(label: calendar.isDateInWeekend(date) ? "Wochenende" : "Werktag", multiplier: weekFactor)
        ]
        var combined = hourFactor * weekFactor

        if let stat = modeStat(named: mode) {
            // Uhrzeit und Modus hängen oft zusammen (z. B. abends Fernsehen).
            // Damit derselbe Effekt nicht doppelt zählt, geht die Uhrzeit nur gedämpft ein.
            combined = sqrt(hourFactor) * weekFactor * stat.factor
            factors.append(RiskFactor(label: "Modus \(stat.name)", multiplier: stat.factor))
        }

        combined = min(max(combined, 0.05), 10)
        let level: RiskLevel
        if combined >= 2 {
            level = .high
        } else if combined >= 1.25 {
            level = .elevated
        } else {
            level = .low
        }
        let sorted = factors.sorted { abs(log($0.multiplier)) > abs(log($1.multiplier)) }
        return RiskAssessment(multiplier: combined, level: level, factors: sorted)
    }

    /// Erwartete Bisse in der Stunde ab `date` (für die Auswertung der Warnungen).
    func expectedBites(inHourFrom date: Date, mode: String? = nil) -> Double {
        if let stat = modeStat(named: mode) {
            return stat.rate
        }
        let hour = Calendar.current.component(.hour, from: date)
        return hourlyRates[hour] * dayFactor(for: date)
    }

    /// Die riskantesten Stunden eines Tages, mindestens drei Stunden auseinander.
    func riskySlots(on day: Date, activeHours: ClosedRange<Int>, threshold: Double, maxCount: Int) -> [RiskSlot] {
        guard isReady, maxCount > 0 else { return [] }
        let weekFactor = self.dayFactor(for: day)
        let candidates = activeHours
            .map { RiskSlot(hour: $0, multiplier: hourFactors[$0] * weekFactor) }
            .filter { $0.multiplier >= threshold }
            .sorted { $0.multiplier > $1.multiplier }

        var chosen: [RiskSlot] = []
        for candidate in candidates where chosen.count < maxCount {
            if chosen.allSatisfy({ abs($0.hour - candidate.hour) >= 3 }) {
                chosen.append(candidate)
            }
        }
        return chosen.sorted { $0.hour < $1.hour }
    }

    var hourProfile: [HourFactor] {
        hourFactors.enumerated().map { HourFactor(hour: $0.offset, factor: $0.element) }
    }

    /// Vergleicht die Stunde nach jeder vergangenen Warnung mit dem, was das Modell erwartet hätte.
    func warningEffect(warnings: [RiskWarning], events: [BiteEvent], now: Date = Date()) -> WarningEffect? {
        let past = warnings.filter { $0.date.addingTimeInterval(3600) < now }
        guard past.count >= 5 else { return nil }
        var observed = 0
        var resisted = 0
        var expected = 0.0
        for warning in past {
            let end = warning.date.addingTimeInterval(3600)
            let inWindow = events.filter { $0.timestamp >= warning.date && $0.timestamp < end }
            observed += inWindow.filter { $0.kind == .bitten }.count
            resisted += inWindow.filter { $0.kind == .resisted }.count
            expected += expectedBites(inHourFrom: warning.date, mode: warning.modeName)
        }
        return WarningEffect(warnings: past.count, observed: observed, expected: expected, resisted: resisted)
    }
}

// MARK: - Formatierung

enum RiskFormat {
    static func multiplier(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1))) + "×"
    }

    static func hours(_ value: Double) -> String {
        if value < 1 {
            return "\(Int((value * 60).rounded())) Min."
        }
        return value.formatted(.number.precision(.fractionLength(1))) + " Std."
    }
}

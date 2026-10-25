import Foundation

struct CountItem: Identifiable {
    let label: String
    let count: Int
    var id: String { label }
}

struct DayCount: Identifiable {
    let day: Date
    let kind: String
    let count: Int
    var id: String { "\(day.timeIntervalSince1970)-\(kind)" }
}

struct HourCount: Identifiable {
    let hour: Int
    let count: Int
    var id: Int { hour }
}

enum Stats {
    static func startOfRange(days: Int, now: Date = Date()) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: now)) ?? now
    }

    /// Einträge der letzten `days` Tage (inkl. heute).
    static func events(_ events: [BiteEvent], lastDays days: Int, kind: EventKind? = nil, now: Date = Date()) -> [BiteEvent] {
        let start = startOfRange(days: days, now: now)
        return events.filter { event in
            event.timestamp >= start && (kind.map { $0 == event.kind } ?? true)
        }
    }

    /// Einträge im gleich langen Zeitraum davor (für den Vergleich).
    static func previousEvents(_ events: [BiteEvent], days: Int, kind: EventKind? = nil, now: Date = Date()) -> [BiteEvent] {
        let calendar = Calendar.current
        let end = startOfRange(days: days, now: now)
        let start = calendar.date(byAdding: .day, value: -days, to: end) ?? end
        return events.filter { event in
            event.timestamp >= start && event.timestamp < end && (kind.map { $0 == event.kind } ?? true)
        }
    }

    static func perDay(_ events: [BiteEvent], days: Int, now: Date = Date()) -> [DayCount] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        var result: [DayCount] = []
        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            for kind in EventKind.allCases {
                let count = events.filter { $0.kind == kind && calendar.isDate($0.timestamp, inSameDayAs: day) }.count
                result.append(DayCount(day: day, kind: kind.title, count: count))
            }
        }
        return result
    }

    static func perHour(_ events: [BiteEvent]) -> [HourCount] {
        let calendar = Calendar.current
        var counts = Array(repeating: 0, count: 24)
        for event in events {
            let hour = calendar.component(.hour, from: event.timestamp)
            if hour >= 0 && hour < 24 { counts[hour] += 1 }
        }
        return counts.enumerated().map { HourCount(hour: $0.offset, count: $0.element) }
    }

    static func counts(_ events: [BiteEvent], key: (BiteEvent) -> String?) -> [CountItem] {
        var dict: [String: Int] = [:]
        for event in events {
            if let value = key(event), !value.isEmpty {
                dict[value, default: 0] += 1
            }
        }
        return dict
            .map { CountItem(label: $0.key, count: $0.value) }
            .sorted { lhs, rhs in
                lhs.count == rhs.count ? lhs.label < rhs.label : lhs.count > rhs.count
            }
    }

    /// Anzahl aufeinanderfolgender Tage ohne „Gekaut“-Eintrag, heute eingeschlossen.
    static func biteFreeDayStreak(_ events: [BiteEvent], now: Date = Date()) -> Int {
        let calendar = Calendar.current
        guard let first = events.map({ $0.timestamp }).min() else { return 0 }
        let firstDay = calendar.startOfDay(for: first)
        let bittenDays = Set(events.filter { $0.kind == .bitten }.map { calendar.startOfDay(for: $0.timestamp) })

        var day = calendar.startOfDay(for: now)
        var streak = 0
        while day >= firstDay && !bittenDays.contains(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    /// Häufigstes Zwei-Stunden-Fenster, z. B. „21–23 Uhr“.
    static func peakWindow(_ events: [BiteEvent]) -> String? {
        let hours = perHour(events)
        guard hours.contains(where: { $0.count > 0 }) else { return nil }
        var bestStart = 0
        var bestCount = -1
        for start in 0..<24 {
            let count = hours[start].count + hours[(start + 1) % 24].count
            if count > bestCount {
                bestCount = count
                bestStart = start
            }
        }
        return "\(bestStart)–\((bestStart + 2) % 24) Uhr"
    }

    static func percentChange(current: Int, previous: Int) -> Int? {
        guard previous > 0 else { return nil }
        return Int((Double(current - previous) / Double(previous) * 100).rounded())
    }
}

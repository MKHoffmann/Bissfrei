import Foundation

enum CSVExporter {
    static func makeFile(events: [BiteEvent], sessions: [PracticeSession], modeSessions: [ModeSession]) -> URL? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "dd.MM.yyyy HH:mm"

        var lines: [String] = []
        lines.append("Zeitpunkt;Art;Situation;Modus;Bewusstheit;Hand;Finger;Gefühl;Drangstärke;Notiz")

        let sortedEvents = events.sorted(by: { $0.timestamp < $1.timestamp })
        for event in sortedEvents {
            let fingers = Finger.allCases
                .filter { event.fingers.contains($0) }
                .map { $0.title }
                .joined(separator: ", ")
            let columns: [String] = [
                formatter.string(from: event.timestamp),
                event.kind.title,
                event.situationLabel,
                event.modeName,
                event.awareness?.title ?? "",
                event.hand?.title ?? "",
                fingers,
                event.emotion?.title ?? "",
                event.intensity > 0 ? String(event.intensity) : "",
                event.note
            ]
            lines.append(columns.map(escape).joined(separator: ";"))
        }

        lines.append("")
        lines.append("Modus;Beginn;Ende;Dauer (Min.);Quelle")
        let sortedModes = modeSessions.sorted(by: { $0.startedAt < $1.startedAt })
        let now = Date()
        for session in sortedModes {
            let end = session.effectiveEnd(now: now)
            let columns: [String] = [
                session.name,
                formatter.string(from: session.startedAt),
                session.endedAt.map { formatter.string(from: $0) } ?? "läuft",
                String(Int(max(0, end.timeIntervalSince(session.startedAt)) / 60)),
                session.source.title
            ]
            lines.append(columns.map(escape).joined(separator: ";"))
        }

        lines.append("")
        lines.append("Übung;Zeitpunkt;Dauer (s);Wiederholungen")
        let sortedSessions = sessions.sorted(by: { $0.date < $1.date })
        for session in sortedSessions {
            let columns: [String] = [
                session.type.title,
                formatter.string(from: session.date),
                String(session.durationSeconds),
                String(session.repetitions)
            ]
            lines.append(columns.map(escape).joined(separator: ";"))
        }

        let text = "\u{FEFF}" + lines.joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Bissfrei-Export.csv")
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    private static func escape(_ value: String) -> String {
        "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}

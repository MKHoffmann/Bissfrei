import Foundation
import SwiftData
import UserNotifications

@MainActor
enum ReminderManager {
    static let checkInCategory = "AWARENESS_CHECK"
    static let practiceCategory = "PRACTICE"

    enum ActionID {
        static let bitten = "LOG_BITTEN"
        static let resisted = "LOG_RESISTED"
        static let fine = "ALL_GOOD"
    }

    private enum ID {
        static let practice = "practice"
        static let checkInPrefix = "checkin-"
        static let riskPrefix = "risk-"
        static let modeStart = "mode-start"
        static let modeFollowUp = "mode-followup"
    }

    // MARK: - Einrichtung

    nonisolated static func registerCategories() {
        let fine = UNNotificationAction(identifier: ActionID.fine, title: "Alles gut", options: [])
        let resisted = UNNotificationAction(identifier: ActionID.resisted, title: "Drang widerstanden", options: [])
        let bitten = UNNotificationAction(identifier: ActionID.bitten, title: "Habe gekaut", options: [])

        let check = UNNotificationCategory(
            identifier: checkInCategory,
            actions: [fine, resisted, bitten],
            intentIdentifiers: [],
            options: []
        )
        let practice = UNNotificationCategory(
            identifier: practiceCategory,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([check, practice])
    }

    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    private static func add(_ request: UNNotificationRequest) async {
        try? await UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Alle wiederkehrenden Erinnerungen neu planen

    /// Plant Übungs-Erinnerung, Achtsamkeits-Checks und Risiko-Warnungen neu.
    /// Modus-Mitteilungen bleiben unberührt.
    static func reschedule() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let managed = pending
            .map { $0.identifier }
            .filter { $0 == ID.practice || $0.hasPrefix(ID.checkInPrefix) || $0.hasPrefix(ID.riskPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: managed)

        let defaults = UserDefaults.standard

        // Tägliche Übungs-Erinnerung
        if defaults.bool(forKey: Keys.practiceReminderOn) {
            let minutes = (defaults.object(forKey: Keys.practiceReminderMinutes) as? Int) ?? Defaults.practiceReminderMinutes
            var components = DateComponents()
            components.hour = minutes / 60
            components.minute = minutes % 60

            let content = UNMutableNotificationContent()
            content.title = "Zeit zum Üben"
            content.body = "Zwei Minuten reichen: eine Runde Decoupling oder deine Gegenreaktion."
            content.sound = .default
            content.categoryIdentifier = practiceCategory

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            await add(UNNotificationRequest(identifier: ID.practice, content: content, trigger: trigger))
        }

        let startHour = (defaults.object(forKey: Keys.checkInStartHour) as? Int) ?? Defaults.checkInStartHour
        let endHour = max(startHour, (defaults.object(forKey: Keys.checkInEndHour) as? Int) ?? Defaults.checkInEndHour)

        // Achtsamkeits-Checks über den Tag verteilt
        if defaults.bool(forKey: Keys.checkInOn) {
            let interval = max(1, (defaults.object(forKey: Keys.checkInInterval) as? Int) ?? Defaults.checkInInterval)
            let messages = [
                "Wo sind deine Hände gerade?",
                "Kurzer Check: Spürst du gerade einen Drang?",
                "Wie fühlen sich deine Hände an? Angespannt oder locker?",
                "Atme einmal tief durch. Was machen deine Finger?"
            ]
            var index = 0
            for hour in stride(from: startHour, through: endHour, by: interval) {
                var components = DateComponents()
                components.hour = hour
                components.minute = 0

                let content = UNMutableNotificationContent()
                content.title = "Achtsamkeits-Check"
                content.body = messages[index % messages.count]
                content.sound = .default
                content.categoryIdentifier = checkInCategory

                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                await add(UNNotificationRequest(identifier: "\(ID.checkInPrefix)\(hour)", content: content, trigger: trigger))
                index += 1
            }
        }

        await scheduleRiskWarnings(activeHours: startHour...endHour)
    }

    // MARK: - Risiko-Warnungen zu riskanten Uhrzeiten

    private static func scheduleRiskWarnings(activeHours: ClosedRange<Int>) async {
        let defaults = UserDefaults.standard
        let context = DataStore.context
        let now = Date()

        // Noch nicht erreichte Planungen verwerfen – sie werden gleich neu berechnet.
        for warning in DataStore.allWarnings() where warning.kind == .scheduled && warning.date > now {
            context.delete(warning)
        }

        guard defaults.bool(forKey: Keys.riskWarningsOn) else {
            try? context.save()
            return
        }

        let model = RiskModel.current()
        guard model.isReady else {
            try? context.save()
            return
        }

        let threshold = (defaults.object(forKey: Keys.riskThreshold) as? Double) ?? Defaults.riskThreshold
        let maxPerDay = (defaults.object(forKey: Keys.riskMaxPerDay) as? Int) ?? Defaults.riskMaxPerDay
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)

        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let slots = model.riskySlots(on: day, activeHours: activeHours, threshold: threshold, maxCount: maxPerDay)
            for slot in slots {
                guard let hourStart = calendar.date(bySettingHour: slot.hour, minute: 0, second: 0, of: day) else { continue }
                let fireDate = hourStart.addingTimeInterval(-5 * 60)
                guard fireDate > now else { continue }

                let content = UNMutableNotificationContent()
                content.title = "Gleich beginnt eine Risikozeit"
                content.body = "Zwischen \(slot.hour) und \((slot.hour + 1) % 24) Uhr kaust du sonst \(RiskFormat.multiplier(slot.multiplier)) so oft wie im Schnitt. Halte die Hände beschäftigt oder deine Gegenreaktion bereit."
                content.sound = .default
                content.categoryIdentifier = checkInCategory

                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let identifier = "\(ID.riskPrefix)\(Int(fireDate.timeIntervalSince1970))"
                await add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))

                context.insert(RiskWarning(date: fireDate, kind: .scheduled, multiplier: slot.multiplier))
            }
        }
        try? context.save()
    }

    // MARK: - Modus-Warnungen

    /// Prüft beim Start eines Modus das Risiko und warnt gegebenenfalls sofort
    /// sowie mit einem späteren Achtsamkeits-Check.
    static func modeStarted(_ name: String) async {
        cancelModeNotifications()

        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: Keys.modeStartWarningOn) else { return }

        let model = RiskModel.current()
        guard model.isReady, let stat = model.modeStat(named: name) else { return }

        let threshold = (defaults.object(forKey: Keys.riskThreshold) as? Double) ?? Defaults.riskThreshold
        let assessment = model.assess(at: Date(), mode: name)
        guard assessment.multiplier >= threshold || stat.factor >= threshold else { return }

        // Nicht öfter als alle 90 Minuten warnen.
        let now = Date()
        let last = defaults.double(forKey: Keys.lastModeWarning)
        guard now.timeIntervalSince1970 - last > 90 * 60 else { return }
        defaults.set(now.timeIntervalSince1970, forKey: Keys.lastModeWarning)

        let plan = DataStore.allPlans().first { plan in
            plan.trigger.localizedCaseInsensitiveContains(name)
        }

        let content = UNMutableNotificationContent()
        content.title = "Risikomodus: \(name)"
        var body = "In diesem Modus kaust du sonst \(RiskFormat.multiplier(stat.factor)) so oft wie im Schnitt."
        if let plan {
            body += " Dein Plan: Wenn \(plan.trigger), dann \(plan.action)."
        } else {
            body += " Leg dir jetzt etwas für die Hände bereit."
        }
        content.body = body
        content.sound = .default
        content.categoryIdentifier = checkInCategory
        await add(UNNotificationRequest(identifier: ID.modeStart, content: content, trigger: nil))

        DataStore.context.insert(RiskWarning(date: now, kind: .mode, modeName: name, multiplier: assessment.multiplier))
        try? DataStore.context.save()

        let minutes = (defaults.object(forKey: Keys.modeFollowUpMinutes) as? Int) ?? Defaults.modeFollowUpMinutes
        if minutes > 0 {
            let followUp = UNMutableNotificationContent()
            followUp.title = "Noch im Modus „\(name)“"
            followUp.body = "Wo sind deine Hände gerade? Spürst du einen Drang?"
            followUp.sound = .default
            followUp.categoryIdentifier = checkInCategory
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
            await add(UNNotificationRequest(identifier: ID.modeFollowUp, content: followUp, trigger: trigger))
        }
    }

    static func cancelModeNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [ID.modeFollowUp])
    }
}

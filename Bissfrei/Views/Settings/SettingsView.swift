import SwiftUI
import UIKit
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \BiteEvent.timestamp) private var events: [BiteEvent]
    @Query(sort: \PracticeSession.date) private var sessions: [PracticeSession]
    @Query(sort: \ModeSession.startedAt) private var modeSessions: [ModeSession]
    @Query(sort: \SituationTag.sortOrder) private var tags: [SituationTag]

    @AppStorage(Keys.competingResponse) private var competingResponse = Defaults.competingResponse
    @AppStorage(Keys.competingDuration) private var competingDuration = Defaults.competingDuration

    @AppStorage(Keys.practiceReminderOn) private var practiceReminderOn = false
    @AppStorage(Keys.practiceReminderMinutes) private var practiceReminderMinutes = Defaults.practiceReminderMinutes
    @AppStorage(Keys.checkInOn) private var checkInOn = false
    @AppStorage(Keys.checkInStartHour) private var checkInStartHour = Defaults.checkInStartHour
    @AppStorage(Keys.checkInEndHour) private var checkInEndHour = Defaults.checkInEndHour
    @AppStorage(Keys.checkInInterval) private var checkInInterval = Defaults.checkInInterval

    @AppStorage(Keys.riskWarningsOn) private var riskWarningsOn = false
    @AppStorage(Keys.riskThreshold) private var riskThreshold = Defaults.riskThreshold
    @AppStorage(Keys.riskMaxPerDay) private var riskMaxPerDay = Defaults.riskMaxPerDay
    @AppStorage(Keys.modeStartWarningOn) private var modeStartWarningOn = false
    @AppStorage(Keys.modeFollowUpMinutes) private var modeFollowUpMinutes = Defaults.modeFollowUpMinutes

    @State private var exportURL: URL?
    @State private var confirmDeleteAll = false
    @State private var notificationsDenied = false
    @State private var showResponsePicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink {
                        SituationsEditor()
                    } label: {
                        LabeledContent("Situationen & Modi", value: "\(tags.count)")
                    }
                    Button {
                        showResponsePicker = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Gegenreaktion")
                                    .foregroundStyle(.primary)
                                Text("\(competingResponse) · \(competingDuration) s")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                } header: {
                    Text("Erfassen & Üben")
                }

                Section {
                    Stepper("Ab \(checkInStartHour) Uhr", value: $checkInStartHour, in: 5...23)
                    Stepper("Bis \(checkInEndHour) Uhr", value: $checkInEndHour, in: 5...23)
                } header: {
                    Text("Aktive Zeit")
                } footer: {
                    Text("Nur in diesem Zeitraum gibt es Achtsamkeits-Checks und Warnungen zu Risikozeiten.")
                }

                Section {
                    Toggle("Warnen zu Risikozeiten", isOn: $riskWarningsOn)
                    Toggle("Warnen beim Start riskanter Modi", isOn: $modeStartWarningOn)
                    if riskWarningsOn || modeStartWarningOn {
                        Picker("Warnen ab", selection: $riskThreshold) {
                            Text("1,5× Durchschnitt").tag(1.5)
                            Text("2× Durchschnitt").tag(2.0)
                            Text("3× Durchschnitt").tag(3.0)
                        }
                    }
                    if riskWarningsOn {
                        Stepper("Höchstens \(riskMaxPerDay)× pro Tag", value: $riskMaxPerDay, in: 1...4)
                    }
                    if modeStartWarningOn {
                        Picker("Nachfragen im Risikomodus", selection: $modeFollowUpMinutes) {
                            Text("Aus").tag(0)
                            Text("nach 30 Min.").tag(30)
                            Text("nach 45 Min.").tag(45)
                            Text("nach 60 Min.").tag(60)
                        }
                    }
                } header: {
                    Text("Risiko-Warnungen")
                } footer: {
                    Text("Bissfrei schätzt aus deinen Einträgen, zu welchen Uhrzeiten und in welchen Modi du deutlich häufiger kaust als im Schnitt, und meldet sich kurz vorher. Das funktioniert, sobald genug Daten da sind (mind. \(RiskModel.minBites) Bisse an \(RiskModel.minDays) Tagen). Öffne die App ab und zu, damit die Warnungen der nächsten Tage neu geplant werden.")
                }

                Section {
                    Toggle("Tägliche Übungs-Erinnerung", isOn: $practiceReminderOn)
                    if practiceReminderOn {
                        DatePicker("Uhrzeit", selection: practiceTime, displayedComponents: .hourAndMinute)
                    }
                    Toggle("Achtsamkeits-Checks", isOn: $checkInOn)
                    if checkInOn {
                        Stepper("Alle \(checkInInterval) Stunden", value: $checkInInterval, in: 1...6)
                    }
                } header: {
                    Text("Erinnerungen")
                } footer: {
                    Text("Achtsamkeits-Checks fragen, wo deine Hände gerade sind. Direkt in jeder Mitteilung kannst du „Habe gekaut“ oder „Drang widerstanden“ antippen.")
                }

                if notificationsDenied {
                    Section {
                        Label("Mitteilungen sind für Bissfrei ausgeschaltet. Erlaube sie in den iOS-Einstellungen.", systemImage: "bell.slash.fill")
                            .foregroundStyle(.orange)
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            Link("iOS-Einstellungen öffnen", destination: url)
                        }
                    }
                }

                Section {
                    HelpRow(
                        symbol: "moon.circle.fill",
                        title: "Mit iOS-Fokus verknüpfen",
                        text: "Einstellungen › Fokus › z. B. „Arbeiten“ › unter „Fokusfilter“ auf „Filter hinzufügen“ › Bissfrei › Modus wählen (z. B. Coding). Startet der Fokus, startet der Modus – endet er, endet auch der Modus."
                    )
                    HelpRow(
                        symbol: "square.2.layers.3d.fill",
                        title: "Kurzbefehle, Siri & Aktionstaste",
                        text: "„Gekaut“, „Widerstanden“, „Modus starten“ und „Modus beenden“ stehen in der Kurzbefehle-App bereit. Leg „Gekaut“ z. B. auf die Aktionstaste oder unter Bedienungshilfen › Tippen › „Auf Rückseite tippen“."
                    )
                    HelpRow(
                        symbol: "clock.arrow.2.circlepath",
                        title: "Automationen",
                        text: "In der Kurzbefehle-App unter „Automation“ kannst du Modi z. B. beim Öffnen von Xcode, einer Streaming-App oder beim Verbinden mit CarPlay starten lassen."
                    )
                } header: {
                    Text("Modi automatisch starten")
                }

                Section {
                    if let exportURL {
                        ShareLink(item: exportURL) {
                            Label("Daten als CSV exportieren", systemImage: "square.and.arrow.up")
                        }
                    }
                    Button(role: .destructive) {
                        confirmDeleteAll = true
                    } label: {
                        Label("Alle Daten löschen", systemImage: "trash")
                    }
                } header: {
                    Text("Daten")
                } footer: {
                    Text("\(events.count) Einträge, \(sessions.count) Übungen und \(modeSessions.count) Modus-Zeiträume – gespeichert nur auf diesem iPhone. Die CSV-Datei lässt sich mit Numbers oder Excel öffnen, z. B. um sie mit einer Therapeutin zu besprechen.")
                }

                Section {
                    LabeledContent("Version", value: appVersion)
                    Text("Bissfrei ist eine Selbsthilfe-App und ersetzt keine ärztliche oder psychotherapeutische Behandlung.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Über")
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
            .onAppear {
                exportURL = CSVExporter.makeFile(events: events, sessions: sessions, modeSessions: modeSessions)
            }
            .onChange(of: reminderSignature) { _, _ in
                updateReminders()
            }
            .confirmationDialog(
                "Wirklich alle Einträge, Übungen, Modus-Zeiten und Pläne löschen?",
                isPresented: $confirmDeleteAll,
                titleVisibility: .visible
            ) {
                Button("Alles löschen", role: .destructive) {
                    deleteAll()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Deine Situationen bleiben erhalten. Das Löschen kann nicht rückgängig gemacht werden – exportiere vorher die CSV, wenn du die Daten behalten möchtest.")
            }
            .sheet(isPresented: $showResponsePicker) {
                ResponsePickerView()
                    .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: - Hilfen

    private var practiceTime: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: practiceReminderMinutes / 60,
                    minute: practiceReminderMinutes % 60,
                    second: 0,
                    of: Date()
                ) ?? Date()
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                practiceReminderMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
            }
        )
    }

    private var reminderSignature: String {
        [
            "\(practiceReminderOn)", "\(practiceReminderMinutes)",
            "\(checkInOn)", "\(checkInStartHour)", "\(checkInEndHour)", "\(checkInInterval)",
            "\(riskWarningsOn)", "\(riskThreshold)", "\(riskMaxPerDay)",
            "\(modeStartWarningOn)", "\(modeFollowUpMinutes)"
        ].joined(separator: "-")
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func updateReminders() {
        if checkInEndHour < checkInStartHour {
            checkInEndHour = checkInStartHour
        }
        let wantsNotifications = practiceReminderOn || checkInOn || riskWarningsOn || modeStartWarningOn
        Task { @MainActor in
            if wantsNotifications {
                let granted = await ReminderManager.requestAuthorization()
                notificationsDenied = !granted
            } else {
                notificationsDenied = false
            }
            await ReminderManager.reschedule()
        }
    }

    private func deleteAll() {
        ModeManager.stop()
        try? context.delete(model: BiteEvent.self)
        try? context.delete(model: PracticeSession.self)
        try? context.delete(model: IfThenPlan.self)
        try? context.delete(model: ModeSession.self)
        try? context.delete(model: RiskWarning.self)
        try? context.save()
        exportURL = CSVExporter.makeFile(events: [], sessions: [], modeSessions: [])
    }
}

private struct HelpRow: View {
    let symbol: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Palette.practice)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(text)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}

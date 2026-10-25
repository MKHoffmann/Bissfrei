import SwiftUI
import UIKit
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \BiteEvent.timestamp) private var allEvents: [BiteEvent]
    @Query(sort: \PracticeSession.date) private var sessions: [PracticeSession]
    @Query(sort: \ModeSession.startedAt) private var modeSessions: [ModeSession]
    @Query(sort: \RiskWarning.date) private var warnings: [RiskWarning]
    @AppStorage(Keys.riskThreshold) private var riskThreshold = Defaults.riskThreshold

    @State private var range = 14

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Zeitraum", selection: $range) {
                        Text("7 Tage").tag(7)
                        Text("14 Tage").tag(14)
                        Text("30 Tage").tag(30)
                        Text("90 Tage").tag(90)
                    }
                    .pickerStyle(.segmented)

                    if allEvents.isEmpty {
                        ContentUnavailableView(
                            "Noch keine Daten",
                            systemImage: "chart.bar.xaxis",
                            description: Text("Sobald du ein paar Einträge hast, siehst du hier deine Muster.")
                        )
                        .padding(.top, 40)
                    } else {
                        summaryCard
                        dailyCard
                        hourCard
                        rankingCard(
                            title: "Situationen",
                            symbol: "mappin.circle.fill",
                            items: Stats.counts(bitten) { $0.situationLabel },
                            tint: Palette.bite
                        )
                        rankingCard(
                            title: "Gefühle davor",
                            symbol: "heart.circle.fill",
                            items: Stats.counts(bitten) { $0.emotion?.title },
                            tint: Palette.practice
                        )
                        handCard
                        awarenessCard
                        riskProfileCard
                        modeCard
                        warningCard
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Einblicke")
        }
    }

    // MARK: - Daten

    private var rangeEvents: [BiteEvent] {
        Stats.events(allEvents, lastDays: range)
    }

    private var bitten: [BiteEvent] {
        rangeEvents.filter { $0.kind == .bitten }
    }

    private var resisted: [BiteEvent] {
        rangeEvents.filter { $0.kind == .resisted }
    }

    // MARK: - Karten

    private var summaryCard: some View {
        let previousBitten = Stats.previousEvents(allEvents, days: range, kind: .bitten).count
        let change = Stats.percentChange(current: bitten.count, previous: previousBitten)
        let total = bitten.count + resisted.count
        let resistRate = total > 0 ? Int((Double(resisted.count) / Double(total) * 100).rounded()) : 0
        let start = Stats.startOfRange(days: range)
        let practiceCount = sessions.filter { $0.date >= start }.count

        return VStack(spacing: 10) {
            HStack(spacing: 10) {
                StatTile(value: "\(bitten.count)", label: "Mal gekaut", tint: Palette.bite)
                StatTile(value: "\(resisted.count)", label: "Mal widerstanden", tint: Palette.resist)
            }
            HStack(spacing: 10) {
                StatTile(value: "\(resistRate) %", label: "Widerstandsquote", tint: Palette.resistDeep)
                StatTile(value: "\(practiceCount)", label: "Übungen", tint: Palette.practice)
            }
            if let change {
                Card {
                    HStack(spacing: 10) {
                        Image(systemName: change <= 0 ? "arrow.down.right.circle.fill" : "arrow.up.right.circle.fill")
                            .font(.title2)
                            .foregroundStyle(change <= 0 ? Palette.resist : Palette.bite)
                        Text(change <= 0
                             ? "\(abs(change)) % weniger Kauen als in den \(range) Tagen davor."
                             : "\(change) % mehr Kauen als in den \(range) Tagen davor. Das passiert – schau dir unten an, was sich verändert hat.")
                            .font(.subheadline)
                    }
                }
            }
        }
    }

    private var dailyCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                CardTitle(title: "Verlauf pro Tag", symbol: "calendar", tint: Palette.practice)
                Chart(Stats.perDay(rangeEvents, days: range)) { item in
                    BarMark(
                        x: .value("Tag", item.day, unit: .day),
                        y: .value("Anzahl", item.count)
                    )
                    .foregroundStyle(by: .value("Art", item.kind))
                    .cornerRadius(3)
                }
                .chartForegroundStyleScale([
                    EventKind.bitten.title: Palette.bite,
                    EventKind.resisted.title: Palette.resist
                ])
                .chartLegend(position: .bottom)
                .frame(height: 200)
            }
        }
    }

    private var hourCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                CardTitle(title: "Tageszeit (Kauen)", symbol: "clock.fill", tint: Palette.bite)
                if bitten.isEmpty {
                    Text("Im gewählten Zeitraum kein Kauen erfasst. 🎉")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Chart(Stats.perHour(bitten)) { item in
                        BarMark(
                            x: .value("Stunde", item.hour),
                            y: .value("Anzahl", item.count)
                        )
                        .foregroundStyle(Palette.bite.gradient)
                        .cornerRadius(2)
                    }
                    .chartXAxisLabel("Uhrzeit (Stunde)")
                    .frame(height: 170)

                    if let window = Stats.peakWindow(bitten) {
                        Text("Am häufigsten zwischen \(window). Plane für diese Zeit eine Gegenreaktion oder halte die Hände beschäftigt.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func rankingCard(title: String, symbol: String, items: [CountItem], tint: Color) -> some View {
        let top = Array(items.prefix(6))
        return Card {
            VStack(alignment: .leading, spacing: 12) {
                CardTitle(title: title, symbol: symbol, tint: tint)
                if top.isEmpty {
                    Text("Noch keine Angaben. Ergänze sie beim Erfassen – das ist der Kern des Awareness-Trainings.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Chart(top) { item in
                        BarMark(
                            x: .value("Anzahl", item.count),
                            y: .value("Kategorie", item.label)
                        )
                        .foregroundStyle(tint.gradient)
                        .cornerRadius(4)
                        .annotation(position: .trailing) {
                            Text("\(item.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .chartXAxis(.hidden)
                    .frame(height: CGFloat(top.count) * 36 + 8)
                }
            }
        }
    }

    private var handCard: some View {
        let items = Stats.counts(bitten) { $0.hand?.title }
        let fingerItems = fingerCounts

        return Card {
            VStack(alignment: .leading, spacing: 12) {
                CardTitle(title: "Hand & Finger", symbol: "hand.raised.fill", tint: Palette.biteDeep)
                if items.isEmpty {
                    Text("Noch keine Angaben zur Hand.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    HStack(spacing: 16) {
                        Chart(items) { item in
                            SectorMark(
                                angle: .value("Anzahl", item.count),
                                innerRadius: .ratio(0.6),
                                angularInset: 2
                            )
                            .foregroundStyle(by: .value("Hand", item.label))
                            .cornerRadius(4)
                        }
                        .chartForegroundStyleScale([
                            Hand.left.title: Palette.practice,
                            Hand.right.title: Palette.bite,
                            Hand.both.title: Palette.resistDeep
                        ])
                        .chartLegend(.hidden)
                        .frame(width: 120, height: 120)

                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(items) { item in
                                HStack {
                                    Circle()
                                        .fill(handColor(item.label))
                                        .frame(width: 10, height: 10)
                                    Text(item.label)
                                    Spacer()
                                    Text("\(item.count)×")
                                        .monospacedDigit()
                                        .foregroundStyle(.secondary)
                                }
                                .font(.subheadline)
                            }
                        }
                    }
                }

                if !fingerItems.isEmpty {
                    Divider()
                    Text("Häufigste Finger")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    FlowLayout {
                        ForEach(fingerItems) { item in
                            Text("\(item.label) · \(item.count)")
                                .font(.footnote.weight(.medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(.tertiarySystemFill), in: Capsule())
                        }
                    }
                }
            }
        }
    }

    private var fingerCounts: [CountItem] {
        var dict: [String: Int] = [:]
        for event in bitten {
            for finger in event.fingers {
                dict[finger.title, default: 0] += 1
            }
        }
        return dict
            .map { CountItem(label: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    private func handColor(_ label: String) -> Color {
        switch label {
        case Hand.left.title: return Palette.practice
        case Hand.right.title: return Palette.bite
        default: return Palette.resistDeep
        }
    }

    private var awarenessCard: some View {
        let automatic = bitten.filter { $0.awareness == .automatic }.count
        let focused = bitten.filter { $0.awareness == .focused }.count
        let total = automatic + focused

        return Card {
            VStack(alignment: .leading, spacing: 12) {
                CardTitle(title: "Bewusst oder in Gedanken?", symbol: "scope", tint: Palette.practice)
                if total == 0 {
                    Text("Gib beim Erfassen an, ob es bewusst oder in Gedanken passiert ist – davon hängt ab, welche Strategie am besten hilft.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    let automaticShare = Double(automatic) / Double(total)
                    GeometryReader { proxy in
                        HStack(spacing: 3) {
                            if automatic > 0 {
                                Rectangle()
                                    .fill(Palette.practice.gradient)
                                    .frame(width: max(8, proxy.size.width * automaticShare - 1.5))
                            }
                            if focused > 0 {
                                Rectangle()
                                    .fill(Palette.bite.gradient)
                            }
                        }
                        .clipShape(Capsule())
                    }
                    .frame(height: 14)

                    HStack {
                        Label("In Gedanken \(Int((automaticShare * 100).rounded())) %", systemImage: "moon.zzz.fill")
                            .foregroundStyle(Palette.practice)
                        Spacer()
                        Label("Bewusst \(Int(((1 - automaticShare) * 100).rounded())) %", systemImage: "scope")
                            .foregroundStyle(Palette.bite)
                    }
                    .font(.caption.weight(.semibold))

                    Text(automaticShare >= 0.5
                         ? "Meist in Gedanken: Achtsamkeits-Checks, Erinnerungen und Barrieren (z. B. Pflaster, Handschuhe in Risikosituationen) helfen dir, es früher zu bemerken."
                         : "Meist bewusst: Halte die Nägel kurz und glatt gefeilt und pflege Niednägel – so fehlen die Kanten, die zum Kauen verleiten.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Risikomodell

    private var riskModel: RiskModel {
        RiskModel(events: allEvents, sessions: modeSessions)
    }

    private var riskProfileCard: some View {
        let model = riskModel
        return Card {
            VStack(alignment: .leading, spacing: 12) {
                CardTitle(title: "Dein Risikoprofil", symbol: "waveform.path.ecg", tint: Palette.biteDeep)
                if !model.isReady {
                    Text("Ab \(RiskModel.minBites) Bissen an mindestens \(RiskModel.minDays) Tagen berechnet Bissfrei, zu welchen Uhrzeiten dein Risiko über dem Durchschnitt liegt. Bisher: \(model.biteCount) Bisse an \(model.daysObserved) Tagen.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Chart {
                        ForEach(model.hourProfile) { item in
                            BarMark(
                                x: .value("Stunde", item.hour),
                                y: .value("Faktor", item.factor)
                            )
                            .foregroundStyle(barColor(item.factor))
                            .cornerRadius(2)
                        }
                        RuleMark(y: .value("Durchschnitt", 1.0))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                            .foregroundStyle(Color.secondary)
                        RuleMark(y: .value("Warnschwelle", riskThreshold))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 2]))
                            .foregroundStyle(Palette.biteDeep)
                    }
                    .chartXAxisLabel("Uhrzeit (Stunde)")
                    .chartYAxisLabel("× Durchschnitt")
                    .frame(height: 180)

                    HStack(spacing: 14) {
                        Label("Werktag \(RiskFormat.multiplier(model.weekdayFactor))", systemImage: "briefcase")
                        Label("Wochenende \(RiskFormat.multiplier(model.weekendFactor))", systemImage: "sun.max")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                    Text("Gestrichelt: dein Durchschnitt (1×) und die Warnschwelle (\(RiskFormat.multiplier(riskThreshold))). Grundlage sind die letzten \(RiskModel.windowDays) Tage; seltene Uhrzeiten werden zum Durchschnitt hin geglättet, damit Einzelfälle nicht überbewertet werden.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func barColor(_ factor: Double) -> Color {
        if factor >= riskThreshold { return Palette.biteDeep }
        if factor >= 1.25 { return Palette.bite }
        return Palette.practice.opacity(0.45)
    }

    private var modeCard: some View {
        let model = riskModel
        let stats = model.modeStats
        return Card {
            VStack(alignment: .leading, spacing: 12) {
                CardTitle(title: "Risiko nach Modus", symbol: "play.circle.fill", tint: Palette.practice)
                if stats.isEmpty {
                    Text("Starte auf „Heute“ einen Modus (z. B. Coding) oder verknüpfe ihn mit einem iOS-Fokus. Dann misst Bissfrei, wie viel Zeit du darin verbringst – und wie oft du dabei kaust. Erst damit lässt sich sagen, ob eine Situation wirklich riskant ist oder nur häufig vorkommt.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(stats) { stat in
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(stat.name)
                                    .font(.subheadline.weight(.semibold))
                                Text("\(RiskFormat.hours(stat.hours)) · \(stat.bites) Bisse")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if stat.hours >= 1 && model.isReady {
                                FactorBadge(factor: RiskFactor(label: "", multiplier: stat.factor))
                            } else {
                                Text("zu wenig Zeit")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if stat.id != stats.last?.id {
                            Divider()
                        }
                    }
                    Text("Faktor = Bisse pro Stunde im Modus im Vergleich zu deinem Durchschnitt pro wacher Stunde.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var warningCard: some View {
        let effect = riskModel.warningEffect(warnings: warnings, events: allEvents)
        let pastCount = warnings.filter { $0.date < Date() }.count
        return Card {
            VStack(alignment: .leading, spacing: 10) {
                CardTitle(title: "Helfen die Warnungen?", symbol: "bell.badge.fill", tint: .orange)
                if let effect {
                    let change = Int(((effect.ratio - 1) * 100).rounded())
                    Text(change <= 0
                         ? "In der Stunde nach einer Warnung kaust du \(abs(change)) % weniger, als dein Modell sonst erwarten würde."
                         : "In der Stunde nach einer Warnung kaust du \(change) % mehr, als dein Modell erwarten würde. Probiere eine andere Gegenreaktion oder einen Wenn-Dann-Plan für diese Zeiten.")
                        .font(.subheadline)
                    Text("\(effect.warnings) Warnungen · \(effect.observed) Bisse statt erwartet \(effect.expected.formatted(.number.precision(.fractionLength(1)))) · \(effect.resisted)× widerstanden")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Grobe Schätzung: Sie vergleicht mit dem Modell, nicht mit einer echten Kontrollgruppe.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Nach mindestens fünf Warnungen vergleicht Bissfrei hier, ob du in der Stunde danach seltener kaust als erwartet. Bisher: \(pastCount). Warnungen schaltest du in den Einstellungen ein.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

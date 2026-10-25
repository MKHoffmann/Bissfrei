import SwiftUI
import UIKit
import SwiftData

struct TodayView: View {
    @Query(sort: \BiteEvent.timestamp, order: .reverse) private var events: [BiteEvent]
    @Query(sort: \PracticeSession.date, order: .reverse) private var sessions: [PracticeSession]
    @Query(sort: \IfThenPlan.createdAt) private var plans: [IfThenPlan]
    @Query(sort: \SituationTag.sortOrder) private var tags: [SituationTag]
    @Query(sort: \ModeSession.startedAt, order: .reverse) private var modeSessions: [ModeSession]

    @State private var editingEvent: BiteEvent?
    @State private var quickEvent: BiteEvent?
    @State private var toastToken = 0
    @State private var showSettings = false
    @State private var showSituationEditor = false
    @State private var biteFeedback = 0
    @State private var resistFeedback = 0

    private var activeMode: ModeSession? {
        modeSessions.first(where: { $0.isActive })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    modeBar
                    TimelineView(.everyMinute) { timeline in
                        riskCard(now: timeline.date)
                    }
                    logButtons
                    sinceCard
                    todayTiles
                    insightCard
                    practiceLinks
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .safeAreaInset(edge: .bottom) {
                if let quickEvent {
                    toast(for: quickEvent)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Heute")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Einstellungen")
                }
            }
            .sheet(item: $editingEvent) { event in
                LogDetailView(event: event, isNew: true)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showSituationEditor) {
                NavigationStack {
                    SituationsEditor()
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Fertig") { showSituationEditor = false }
                            }
                        }
                }
            }
            .task(id: toastToken) {
                guard quickEvent != nil else { return }
                try? await Task.sleep(for: .seconds(8))
                if !Task.isCancelled {
                    withAnimation(.snappy) { quickEvent = nil }
                }
            }
            .sensoryFeedback(.impact(weight: .heavy), trigger: biteFeedback)
            .sensoryFeedback(.success, trigger: resistFeedback)
        }
    }

    // MARK: - Modusleiste

    private var modeBar: some View {
        HStack(spacing: 12) {
            Image(systemName: activeSymbol)
                .font(.title3)
                .foregroundStyle(activeMode == nil ? Color.secondary : Color.white)
                .frame(width: 42, height: 42)
                .background(
                    activeMode == nil
                        ? AnyShapeStyle(Color(.tertiarySystemFill))
                        : AnyShapeStyle(LinearGradient(colors: [Palette.practice, Palette.practiceDeep], startPoint: .topLeading, endPoint: .bottomTrailing)),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 2) {
                if let activeMode {
                    Text("Modus: \(activeMode.name)")
                        .font(.headline)
                    HStack(spacing: 4) {
                        Text("seit")
                        Text(activeMode.startedAt, style: .timer)
                            .monospacedDigit()
                        Text("· \(activeMode.source.title)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                } else {
                    Text("Kein Modus aktiv")
                        .font(.headline)
                    Text("Modi messen, wie riskant eine Situation wirklich ist.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 4)

            Menu {
                ForEach(tags) { tag in
                    Button {
                        ModeManager.start(tag.name, source: .manual)
                    } label: {
                        Label(tag.name, systemImage: tag.symbol)
                    }
                }
                Divider()
                Button {
                    showSituationEditor = true
                } label: {
                    Label("Situationen bearbeiten", systemImage: "pencil")
                }
                if activeMode != nil {
                    Button(role: .destructive) {
                        ModeManager.stop()
                    } label: {
                        Label("Modus beenden", systemImage: "stop.circle")
                    }
                }
            } label: {
                Text(activeMode == nil ? "Starten" : "Wechseln")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 4)
            }
            .buttonStyle(.glass)
        }
        .padding(12)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .padding(.top, 4)
    }

    private var activeSymbol: String {
        guard let activeMode else { return "circle.dashed" }
        return tags.first(where: { $0.name == activeMode.name })?.symbol ?? "tag.fill"
    }

    // MARK: - Risiko

    private func riskCard(now: Date) -> some View {
        let model = RiskModel(events: events, sessions: modeSessions, now: now)
        let assessment = model.assess(at: now, mode: activeMode?.name)
        let level = assessment.level

        return Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: level.symbol)
                        .font(.title2)
                        .foregroundStyle(level.color)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Risiko gerade")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(level.title)
                            .font(.title3.bold())
                            .foregroundStyle(level.color)
                    }
                    Spacer()
                    if level != .unknown {
                        Text(RiskFormat.multiplier(assessment.multiplier))
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(level.color)
                    }
                }

                if level == .unknown {
                    let needed = max(0, RiskModel.minBites - model.biteCount)
                    let neededDays = max(0, RiskModel.minDays - model.daysObserved)
                    Text(unknownText(bites: needed, days: neededDays))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    ProgressView(value: Double(min(model.biteCount, RiskModel.minBites)), total: Double(RiskModel.minBites))
                        .tint(Palette.practice)
                } else {
                    Text("im Vergleich zu deinem Durchschnitt")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    FlowLayout(spacing: 6) {
                        ForEach(assessment.factors) { factor in
                            FactorBadge(factor: factor)
                        }
                    }
                    if level == .high {
                        Text(highRiskTip)
                            .font(.footnote.weight(.medium))
                            .padding(.top, 2)
                    }
                }
            }
        }
    }

    private func unknownText(bites: Int, days: Int) -> String {
        var parts: [String] = []
        if bites > 0 { parts.append("\(bites) weitere Einträge") }
        if days > 0 { parts.append("\(days) weitere Tage") }
        if parts.isEmpty { return "Gleich ist genug beisammen." }
        return "Noch \(parts.joined(separator: " und ")), dann schätzt Bissfrei dein Risiko aus Uhrzeit, Wochentag und Modus."
    }

    private var highRiskTip: String {
        if let activeMode, let plan = plans.first(where: { $0.trigger.localizedCaseInsensitiveContains(activeMode.name) }) {
            return "Dein Plan: Wenn \(plan.trigger), dann \(plan.action)."
        }
        return "Jetzt ist eine gute Zeit, die Hände zu beschäftigen oder eine Gegenreaktion bereitzuhalten."
    }

    // MARK: - Erfassen

    private var logButtons: some View {
        VStack(spacing: 12) {
            Button {
                quickLog(.bitten, situation: nil)
            } label: {
                VStack(spacing: 10) {
                    Image(systemName: "hand.raised.fingers.spread.fill")
                        .font(.system(size: 46, weight: .semibold))
                        .symbolEffect(.bounce, value: biteFeedback)
                    Text("Gerade gekaut")
                        .font(.title2.bold())
                    Text(activeMode.map { "wird dem Modus „\($0.name)“ zugeordnet" } ?? "Ein Tipp genügt – Details danach optional")
                        .font(.footnote)
                        .opacity(0.9)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .background(
                    LinearGradient(colors: [Palette.bite, Palette.biteDeep], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 30, style: .continuous)
                )
                .shadow(color: Palette.biteDeep.opacity(0.35), radius: 18, y: 10)
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityHint("Speichert sofort einen Eintrag mit der aktuellen Uhrzeit.")

            situationChips

            Button {
                quickLog(.resisted, situation: nil)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.title2)
                        .symbolEffect(.bounce, value: resistFeedback)
                    Text("Drang widerstanden")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .frame(height: 60)
                .background(
                    LinearGradient(colors: [Palette.resist, Palette.resistDeep], startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                )
                .shadow(color: Palette.resistDeep.opacity(0.25), radius: 12, y: 6)
            }
            .buttonStyle(PressableButtonStyle())
        }
    }

    /// Ein-Tipp-Erfassung mit eigener Situation, z. B. „Gekaut beim Coding“.
    private var situationChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gekaut bei …")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(orderedTags) { tag in
                        Chip(
                            title: tag.name,
                            symbol: tag.symbol,
                            isSelected: activeMode?.name == tag.name,
                            tint: Palette.biteDeep
                        ) {
                            quickLog(.bitten, situation: tag.name)
                        }
                        .contextMenu {
                            Button {
                                quickLog(.bitten, situation: tag.name)
                            } label: {
                                Label("Gekaut bei \(tag.name)", systemImage: "hand.raised.fingers.spread.fill")
                            }
                            Button {
                                quickLog(.resisted, situation: tag.name)
                            } label: {
                                Label("Widerstanden bei \(tag.name)", systemImage: "hand.thumbsup.fill")
                            }
                            if activeMode?.name == tag.name {
                                Button(role: .destructive) {
                                    ModeManager.stop()
                                } label: {
                                    Label("Modus beenden", systemImage: "stop.circle")
                                }
                            } else {
                                Button {
                                    ModeManager.start(tag.name, source: .manual)
                                } label: {
                                    Label("Als Modus starten", systemImage: "play.circle")
                                }
                            }
                        }
                    }
                    Chip(title: "Bearbeiten", symbol: "pencil", isSelected: false) {
                        showSituationEditor = true
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
        }
    }

    /// Aktiver Modus zuerst, danach die eigene Reihenfolge.
    private var orderedTags: [SituationTag] {
        guard let name = activeMode?.name, let index = tags.firstIndex(where: { $0.name == name }) else { return tags }
        var result = tags
        let active = result.remove(at: index)
        result.insert(active, at: 0)
        return result
    }

    private func quickLog(_ kind: EventKind, situation: String?) {
        let event = DataStore.log(kind, situation: situation)
        switch kind {
        case .bitten: biteFeedback += 1
        case .resisted: resistFeedback += 1
        }
        withAnimation(.snappy) {
            quickEvent = event
        }
        toastToken += 1
    }

    // MARK: - Bestätigung mit Schnellangaben

    private func toast(for event: BiteEvent) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: event.kind.symbol)
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(event.kind.color.gradient, in: Circle())
                VStack(alignment: .leading, spacing: 1) {
                    Text(event.kind == .bitten ? "Gekaut erfasst" : "Widerstanden erfasst")
                        .font(.subheadline.weight(.semibold))
                    Text(toastSubtitle(event))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Button("Rückgängig") {
                    undo(event)
                }
                .font(.footnote.weight(.semibold))
            }

            HStack(spacing: 8) {
                if event.kind == .bitten {
                    ForEach(Awareness.allCases) { awareness in
                        Chip(
                            title: awareness.title,
                            symbol: awareness.symbol,
                            isSelected: event.awareness == awareness,
                            tint: Palette.biteDeep
                        ) {
                            event.awareness = (event.awareness == awareness) ? nil : awareness
                            try? DataStore.context.save()
                            toastToken += 1
                        }
                    }
                }
                Chip(title: "Details", symbol: "square.and.pencil", isSelected: false) {
                    editingEvent = event
                    withAnimation(.snappy) { quickEvent = nil }
                }
            }
        }
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
    }

    private func toastSubtitle(_ event: BiteEvent) -> String {
        let time = event.timestamp.formatted(date: .omitted, time: .shortened)
        let situation = event.situationLabel
        if situation.isEmpty {
            return "\(time) · Bewusst oder in Gedanken?"
        }
        return "\(time) · \(situation)"
    }

    private func undo(_ event: BiteEvent) {
        quickEvent = nil
        DispatchQueue.main.async {
            DataStore.context.delete(event)
            try? DataStore.context.save()
        }
    }

    // MARK: - Statistik

    private var lastBite: BiteEvent? {
        events.first(where: { $0.kind == .bitten })
    }

    private var sinceCard: some View {
        Card {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    if let lastBite {
                        Text("Ohne Kauen seit")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(lastBite.timestamp, style: .relative)
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .monospacedDigit()
                    } else {
                        Text("Noch kein Biss erfasst")
                            .font(.headline)
                        Text("Erfasse ehrlich jedes Mal – genau das schärft deine Wahrnehmung.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
                VStack(spacing: 2) {
                    Text("\(Stats.biteFreeDayStreak(events))")
                        .font(.system(.title, design: .rounded, weight: .heavy))
                        .foregroundStyle(Palette.resist)
                        .contentTransition(.numericText())
                    Text("bissfreie\nTage")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .frame(minWidth: 70)
            }
        }
    }

    private var todayTiles: some View {
        let calendar = Calendar.current
        let today = events.filter { calendar.isDateInToday($0.timestamp) }
        let bitten = today.filter { $0.kind == .bitten }.count
        let resisted = today.filter { $0.kind == .resisted }.count
        let practiced = sessions.filter { calendar.isDateInToday($0.date) }.count

        return HStack(spacing: 10) {
            StatTile(value: "\(bitten)", label: "heute gekaut", tint: Palette.bite)
            StatTile(value: "\(resisted)", label: "widerstanden", tint: Palette.resist)
            StatTile(value: "\(practiced)", label: "Übungen", tint: Palette.practice)
        }
    }

    @ViewBuilder
    private var insightCard: some View {
        let recentBites = Stats.events(events, lastDays: 14, kind: .bitten)
        let thisWeek = Stats.events(events, lastDays: 7, kind: .bitten).count
        let lastWeek = Stats.previousEvents(events, days: 7, kind: .bitten).count

        Card {
            VStack(alignment: .leading, spacing: 12) {
                CardTitle(title: "Dein Muster", symbol: "sparkles", tint: Palette.practice)

                if recentBites.count >= 5 {
                    let topSituation = Stats.counts(recentBites) { $0.situationLabel }.first
                    let topEmotion = Stats.counts(recentBites) { $0.emotion?.title }.first
                    let rated = recentBites.filter { $0.awareness != nil }
                    let unaware = rated.filter { $0.awareness == .automatic }.count

                    if let window = Stats.peakWindow(recentBites) {
                        InsightLine(symbol: "clock.fill", text: "Kritischste Zeit: \(window)")
                    }
                    if let topSituation {
                        InsightLine(symbol: "mappin.circle.fill", text: "Häufigste Situation: \(topSituation.label)")
                    }
                    if let topEmotion {
                        InsightLine(symbol: "heart.circle.fill", text: "Häufigstes Gefühl: \(topEmotion.label)")
                    }
                    if !rated.isEmpty {
                        InsightLine(symbol: "moon.zzz.fill", text: "In Gedanken: \(Int((Double(unaware) / Double(rated.count) * 100).rounded())) % der eingeordneten Bisse")
                    }
                    InsightLine(symbol: "calendar", text: weekComparison(thisWeek: thisWeek, lastWeek: lastWeek))
                } else {
                    Text("Erfasse ein paar Tage lang jedes Kauen – auch kleine Momente. Ab fünf Einträgen siehst du hier, wann und warum es passiert.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let plan = plans.first {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dein Wenn-Dann-Plan")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text("Wenn \(plan.trigger), dann \(plan.action).")
                            .font(.subheadline.weight(.medium))
                    }
                }
            }
        }
    }

    private var practiceLinks: some View {
        VStack(spacing: 10) {
            NavigationLink {
                CompetingResponseView()
            } label: {
                ActionTile(
                    title: "Gegenreaktion",
                    subtitle: "1 Minute – wenn der Drang kommt",
                    symbol: PracticeType.competing.symbol,
                    colors: [Palette.practice, Palette.practiceDeep]
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                DecouplingView()
            } label: {
                ActionTile(
                    title: "Decoupling üben",
                    subtitle: "Bewegung umlenken – ein paar Runden täglich",
                    symbol: PracticeType.decoupling.symbol,
                    colors: [Palette.resist, Palette.resistDeep]
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func weekComparison(thisWeek: Int, lastWeek: Int) -> String {
        if let change = Stats.percentChange(current: thisWeek, previous: lastWeek) {
            if change < 0 {
                return "Letzte 7 Tage: \(thisWeek)× – \(abs(change)) % weniger als davor"
            } else if change > 0 {
                return "Letzte 7 Tage: \(thisWeek)× – \(change) % mehr als davor"
            }
            return "Letzte 7 Tage: \(thisWeek)× – gleich wie davor"
        }
        return "Letzte 7 Tage: \(thisWeek)×"
    }
}

// MARK: - Bausteine

private struct InsightLine: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(Palette.practice)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
        }
    }
}

struct FactorBadge: View {
    let factor: RiskFactor

    var body: some View {
        let up = factor.multiplier >= 1.1
        let down = factor.multiplier <= 0.9
        HStack(spacing: 4) {
            Image(systemName: up ? "arrow.up" : (down ? "arrow.down" : "equal"))
                .font(.caption2.bold())
            Text(factor.label.isEmpty
                 ? RiskFormat.multiplier(factor.multiplier)
                 : "\(factor.label) \(RiskFormat.multiplier(factor.multiplier))")
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(up ? Palette.biteDeep : (down ? Palette.resistDeep : Color.secondary))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(.tertiarySystemFill), in: Capsule())
    }
}

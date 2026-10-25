import SwiftUI
import UIKit
import SwiftData

struct PracticeView: View {
    @Query(sort: \PracticeSession.date, order: .reverse) private var sessions: [PracticeSession]
    @AppStorage(Keys.competingResponse) private var competingResponse = Defaults.competingResponse

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    weekCard

                    sectionHeader("Habit Reversal Training")
                    NavigationLink {
                        CompetingResponseView()
                    } label: {
                        ActionTile(
                            title: "Gegenreaktion",
                            subtitle: "„\(competingResponse)“ – 1 Minute halten",
                            symbol: PracticeType.competing.symbol,
                            colors: [Palette.practice, Palette.practiceDeep]
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        PlansView()
                    } label: {
                        ActionTile(
                            title: "Wenn-Dann-Pläne",
                            subtitle: "Für deine Risikosituationen vorsorgen",
                            symbol: "arrow.triangle.branch",
                            colors: [Color.orange, Palette.biteDeep]
                        )
                    }
                    .buttonStyle(.plain)

                    sectionHeader("Decoupling")
                    NavigationLink {
                        DecouplingView()
                    } label: {
                        ActionTile(
                            title: "Decoupling üben",
                            subtitle: "Die gewohnte Bewegung umlenken",
                            symbol: PracticeType.decoupling.symbol,
                            colors: [Palette.resist, Palette.resistDeep]
                        )
                    }
                    .buttonStyle(.plain)

                    sectionHeader("Hintergrund")
                    NavigationLink {
                        TipsView()
                    } label: {
                        ActionTile(
                            title: "Hilfreiche Maßnahmen",
                            subtitle: "Umgebung und Alltag so gestalten, dass Kauen schwerer fällt",
                            symbol: "checklist",
                            colors: [Color.teal, Color.blue]
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        KnowledgeView()
                    } label: {
                        ActionTile(
                            title: "So funktioniert's",
                            subtitle: "Was die Forschung zu den Methoden sagt",
                            symbol: "book.closed.fill",
                            colors: [Color.gray, Color(white: 0.35)]
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Üben")
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 6)
            .padding(.leading, 4)
    }

    private var weekCard: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days: [Date] = (0..<7).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
        let weekSessions = sessions.filter { $0.date >= (days.first ?? today) }

        return Card {
            VStack(alignment: .leading, spacing: 14) {
                CardTitle(title: "Diese Woche geübt", symbol: "flame.fill", tint: .orange)
                HStack(spacing: 0) {
                    ForEach(days, id: \.self) { day in
                        let practiced = sessions.contains { calendar.isDate($0.date, inSameDayAs: day) }
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(practiced ? AnyShapeStyle(Palette.practice.gradient) : AnyShapeStyle(Color(.tertiarySystemFill)))
                                    .frame(width: 34, height: 34)
                                if practiced {
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                }
                            }
                            Text(day.formatted(.dateTime.weekday(.narrow)))
                                .font(.caption2)
                                .foregroundStyle(calendar.isDateInToday(day) ? Color.primary : Color.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                Text(weekText(weekSessions))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func weekText(_ weekSessions: [PracticeSession]) -> String {
        let competing = weekSessions.filter { $0.type == .competing }.count
        let decoupling = weekSessions.filter { $0.type == .decoupling }
        let reps = decoupling.reduce(0) { $0 + $1.repetitions }
        if weekSessions.isEmpty {
            return "Regelmäßiges Üben – auch ohne akuten Drang – macht die neue Reaktion automatisch."
        }
        return "\(competing)× Gegenreaktion · \(decoupling.count)× Decoupling (\(reps) Wiederholungen)"
    }
}

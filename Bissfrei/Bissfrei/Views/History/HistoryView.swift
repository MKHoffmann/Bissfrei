import SwiftUI
import UIKit
import SwiftData

private struct DayGroup: Identifiable {
    let day: Date
    let items: [BiteEvent]
    var id: Date { day }
}

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \BiteEvent.timestamp, order: .reverse) private var events: [BiteEvent]

    @State private var selected: BiteEvent?
    @State private var filter: EventKind?

    private var groups: [DayGroup] {
        let calendar = Calendar.current
        let filtered = events.filter { event in
            filter.map { $0 == event.kind } ?? true
        }
        let dict = Dictionary(grouping: filtered) { calendar.startOfDay(for: $0.timestamp) }
        return dict.keys
            .sorted(by: >)
            .map { DayGroup(day: $0, items: dict[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if events.isEmpty {
                    ContentUnavailableView(
                        "Noch keine Einträge",
                        systemImage: "list.bullet.clipboard",
                        description: Text("Tippe unter „Heute“ auf den großen Knopf, sobald du gekaut oder einem Drang widerstanden hast.")
                    )
                } else {
                    List {
                        Section {
                            Picker("Filter", selection: $filter) {
                                Text("Alle").tag(EventKind?.none)
                                ForEach(EventKind.allCases) { kind in
                                    Text(kind.title).tag(EventKind?.some(kind))
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())

                        ForEach(groups) { group in
                            Section {
                                ForEach(group.items) { event in
                                    Button {
                                        selected = event
                                    } label: {
                                        EventRow(event: event)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .onDelete { offsets in
                                    for index in offsets {
                                        context.delete(group.items[index])
                                    }
                                    try? context.save()
                                }
                            } header: {
                                HStack {
                                    Text(DateText.dayTitle(group.day))
                                    Spacer()
                                    Text(daySummary(group.items))
                                        .monospacedDigit()
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Verlauf")
            .sheet(item: $selected) { event in
                LogDetailView(event: event)
            }
        }
    }

    private func daySummary(_ items: [BiteEvent]) -> String {
        let bitten = items.filter { $0.kind == .bitten }.count
        let resisted = items.filter { $0.kind == .resisted }.count
        return "\(bitten) gekaut · \(resisted) widerstanden"
    }
}

struct EventRow: View {
    let event: BiteEvent

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: event.kind.symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(event.kind.color.gradient, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(event.kind.title)
                        .font(.body.weight(.semibold))
                    Spacer()
                    Text(event.timestamp, format: .dateTime.hour().minute())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                if !event.summary.isEmpty {
                    Text(event.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                if !event.note.isEmpty {
                    Text(event.note)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

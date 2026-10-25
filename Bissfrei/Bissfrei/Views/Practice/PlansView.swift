import SwiftUI
import UIKit
import SwiftData

struct PlansView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \IfThenPlan.createdAt) private var plans: [IfThenPlan]
    @State private var showAdd = false

    var body: some View {
        List {
            Section {
                Text("Wenn-Dann-Pläne verknüpfen eine Risikosituation fest mit einer Alternative. Vorab entschieden, musst du im Moment selbst nicht mehr nachdenken – das hilft nachweislich, Vorsätze umzusetzen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if plans.isEmpty {
                Section {
                    Button {
                        showAdd = true
                    } label: {
                        Label("Ersten Plan erstellen", systemImage: "plus.circle.fill")
                    }
                }
            } else {
                Section("Deine Pläne") {
                    ForEach(plans) { plan in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text("WENN")
                                    .font(.caption2.bold())
                                    .foregroundStyle(Palette.bite)
                                Text(plan.trigger)
                                    .font(.subheadline.weight(.medium))
                            }
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text("DANN")
                                    .font(.caption2.bold())
                                    .foregroundStyle(Palette.resistDeep)
                                Text(plan.action)
                                    .font(.subheadline.weight(.medium))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            context.delete(plans[index])
                        }
                        try? context.save()
                    }
                }
            }
        }
        .navigationTitle("Wenn-Dann-Pläne")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Plan hinzufügen")
            }
        }
        .sheet(isPresented: $showAdd) {
            AddPlanView()
                .presentationDetents([.large])
        }
    }
}

private struct AddPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage(Keys.competingResponse) private var competingResponse = Defaults.competingResponse

    @State private var trigger = ""
    @State private var action = ""

    private let triggerSuggestions = [
        "ich am Handy oder PC sitze",
        "ich fernsehe",
        "ich im Auto oder Zug sitze",
        "ich gestresst bin",
        "ich mich langweile",
        "ich eine unebene Nagelkante spüre",
        "meine Hand Richtung Mund wandert"
    ]

    private var actionSuggestions: [String] {
        [
            "mache ich eine Minute lang meine Gegenreaktion: \(competingResponse)",
            "lenke ich die Hand per Decoupling um",
            "nehme ich meinen Stressball oder Stift in die Hand",
            "feile ich die Kante glatt, statt zu kauen",
            "atme ich dreimal tief durch",
            "erfasse ich den Drang in Bissfrei"
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Wenn …")
                            .font(.headline)
                        TextField("z. B. ich am Schreibtisch sitze", text: $trigger, axis: .vertical)
                            .lineLimit(1...3)
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        FlowLayout {
                            ForEach(triggerSuggestions, id: \.self) { suggestion in
                                Chip(title: suggestion, isSelected: trigger == suggestion, tint: Palette.bite) {
                                    trigger = suggestion
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("… dann")
                            .font(.headline)
                        TextField("z. B. lege ich die Hände flach auf den Tisch", text: $action, axis: .vertical)
                            .lineLimit(1...3)
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        FlowLayout {
                            ForEach(actionSuggestions, id: \.self) { suggestion in
                                Chip(title: suggestion, isSelected: action == suggestion, tint: Palette.resistDeep) {
                                    action = suggestion
                                }
                            }
                        }
                    }

                    if !trigger.isEmpty || !action.isEmpty {
                        Card {
                            Text("Wenn \(trigger.isEmpty ? "…" : trigger), dann \(action.isEmpty ? "…" : action).")
                                .font(.subheadline.weight(.medium))
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Neuer Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") {
                        let plan = IfThenPlan(
                            trigger: trigger.trimmingCharacters(in: .whitespacesAndNewlines),
                            action: action.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        context.insert(plan)
                        try? context.save()
                        dismiss()
                    }
                    .disabled(trigger.trimmingCharacters(in: .whitespaces).isEmpty || action.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

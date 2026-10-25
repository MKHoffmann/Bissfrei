import SwiftUI
import UIKit

struct ContentView: View {
    @AppStorage(Keys.hasOnboarded) private var hasOnboarded = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            Tab("Heute", systemImage: "sun.max.fill") {
                TodayView()
            }
            Tab("Verlauf", systemImage: "list.bullet") {
                HistoryView()
            }
            Tab("Einblicke", systemImage: "chart.bar.xaxis") {
                InsightsView()
            }
            Tab("Üben", systemImage: "figure.mind.and.body") {
                PracticeView()
            }
        }
        .sheet(isPresented: showWelcome) {
            WelcomeView()
                .interactiveDismissDisabled()
        }
        .task {
            DataStore.bootstrap()
            await ReminderManager.reschedule()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                ModeManager.closeStaleSessions()
                Task { await ReminderManager.reschedule() }
            }
        }
    }

    private var showWelcome: Binding<Bool> {
        Binding(
            get: { !hasOnboarded },
            set: { newValue in
                if !newValue { hasOnboarded = true }
            }
        )
    }
}

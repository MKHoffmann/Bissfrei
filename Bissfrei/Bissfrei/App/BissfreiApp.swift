import SwiftUI
import SwiftData

@main
struct BissfreiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(DataStore.container)
    }
}

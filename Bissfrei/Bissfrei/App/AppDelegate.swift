import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        ReminderManager.registerCategories()
        return true
    }

    // Mitteilungen auch anzeigen, wenn die App geöffnet ist.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // Aktionen aus der Mitteilung („Habe gekaut“, „Drang widerstanden“) direkt speichern.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let action = response.actionIdentifier
        Task { @MainActor in
            switch action {
            case ReminderManager.ActionID.bitten:
                DataStore.log(.bitten)
            case ReminderManager.ActionID.resisted:
                DataStore.log(.resisted)
            default:
                break
            }
            completionHandler()
        }
    }
}

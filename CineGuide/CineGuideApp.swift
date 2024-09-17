import SwiftUI
import FirebaseCore

// Firebase AppDelegate for initialization
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure() // Initialize Firebase
        return true
    }
}

@main
struct CineGuideApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var authManager = AuthManager() // StateObject to manage auth

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager) // Pass the auth manager
        }
    }
}

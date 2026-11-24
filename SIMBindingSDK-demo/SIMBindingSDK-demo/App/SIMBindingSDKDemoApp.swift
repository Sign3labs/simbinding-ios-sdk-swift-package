import SwiftUI

@main
struct SIMBindingSDKDemoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            AuthView()
        }
    }
}

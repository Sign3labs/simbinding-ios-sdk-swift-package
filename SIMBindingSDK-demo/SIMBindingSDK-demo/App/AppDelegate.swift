import UIKit
import Sign3Intelligence

final class AppDelegate: NSObject, UIApplicationDelegate {
    
    //sdk init
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let options = Options.OptionBuilder()
            .setClientId(SDKConfig.clientId)
            .setClientSecret(SDKConfig.clientSecret)
            .setBaseUrl(SDKConfig.baseUrl)
            .build()

        Sign3SDK.getInstance().initAsync(options: options) { isInitialized in
            print("Sign3SDK initialized: \(isInitialized)")
        }
        return true
    }
}

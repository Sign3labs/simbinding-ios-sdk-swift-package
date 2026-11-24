# SIMBindingSDK-demo

SwiftUI demo app for testing Sign3 SIM binding on iOS.

Enter a mobile number with country code (e.g. `919876543210`) → **Authenticate** →
the app calls `getIntelligence` with `UserEventType.AUTH`, polls the status API every 2s,
and shows **SIM Binding Successful / Failed** with the status API response.
Every SDK call, API response and error is logged in the Xcode console (filter: `[SIMBinding]`).

## Setup

`App/SDKConfig.swift` is git-ignored (it holds credentials). Create it at
`SIMBindingSDK-demo/App/SDKConfig.swift`:

```swift
import Foundation

enum SDKConfig {
    static let clientId = "<SIGN3_CLIENT_ID>"
    static let clientSecret = "<SIGN3_CLIENT_SECRET>"
    static let baseUrl = "https://intelligence-internal.sign3.in/"
}
```

Then open `SIMBindingSDK-demo.xcodeproj` and run on a **real iPhone** with mobile data on.

## Structure

```
App/            SIMBindingSDKDemoApp, AppDelegate (SDK init), SDKConfig (git-ignored)
Services/       SimBindingService (SDK), SimBindingStatusService (status API), Log
Features/Auth/  AuthView, AuthViewModel
DesignSystem/   Components
```

## SDKs

- **SimBinding**: this repo's package (`master`).
- **Sign3Intelligence**: `LocalPackages/Sign3Intelligence`, a local build from the
  `feature-simbinding-module` branch, because the published 2.0.0 has no
  `UserEventType.AUTH` / `snaRequestId`. Swap to the remote package once that ships.

> The status API is called from the app for testing only. In production your backend
> must call it; the credentials must not ship in the app.

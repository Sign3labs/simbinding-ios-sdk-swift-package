# Sign3 SIM Binding SDK Integration Guide for iOS

The Sign3 SIM Binding SDK verifies that the phone number a user claims is the number of the SIM in the device they are holding. It does this carrier-side, over the cellular data interface, through Silent Network Authentication (SNA): nothing is sent to the user. When the carrier cannot answer, the flow falls back to an SMS OTP. iOS apps cannot read an SMS, so the code the user types is the one thing your app hands back to the SDK.

The SDK is headless and is driven by the Sign3 Intelligence SDK. Apart from that OTP fallback there is nothing to call and nothing to handle on the device; you only read the transaction id off the intelligence response and, from your backend, ask the Sign3 status API what became of it.

<br>

## Recommended
- iOS 15.0 or higher
- Cellular data on the device. SNA runs over the mobile network, not Wi-Fi.
- [Access WiFi Information entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_networking_wifi-info)
- [Location permission](https://developer.apple.com/documentation/corelocation/)
- [iCloud](https://developer.apple.com/documentation/CloudKit)

> __NOTE:__ If the listed permissions are unavailable for the application, the corresponding values will not be collected, potentially limiting the reliability of Device Intelligence. We recommend enabling as many permissions as possible based on your use case to enhance the accuracy and completeness of the data collected.

<br>

## Installation

SIM binding is driven by the Sign3 Intelligence SDK, so both SDKs go into the app.

#### Using CocoaPods

1. To integrate the SDKs into your Xcode project using CocoaPods, specify them in your Podfile.
2. Sign3 Intelligence: checkout the [latest_version](https://github.com/Sign3labs/sign3intelligence-ios-sdk-swift-package/tree/main?tab=readme-ov-file#changelog)
3. Sign3 SIM Binding: checkout the [latest version](#changelog)

```
pod 'Sign3Intelligence', '~> <latest_version>'
pod 'SimBinding', '~> <latest_version>'
```

#### Using Swift package manager

URL for the repository: https://github.com/Sign3labs/sign3intelligence-ios-sdk-swift-package

#### Using the framework directly

Add `SimBinding.xcframework` to your app target under **Frameworks, Libraries, and Embedded Content**, with **Embed & Sign**, next to `Sign3Intelligence.xcframework`. The framework carries its own dependencies, so nothing else is needed.

<br>

## App Transport Security

SIM binding talks to the carrier endpoints over plain HTTP, which App Transport Security blocks by default. Add the following block to your app's `Info.plist`. If `NSAppTransportSecurity` is already present, add the listed domains one by one under `NSExceptionDomains`.

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>api-csp.airtel.in</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
        <key>v4-api-csp.airtel.in</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
        <key>in-vil.ipification.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
        <key>partnerapi.jio.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>
```

<br>

## Integration

The SDKs can be imported like any other library:

### For Swift
``` swift
import Sign3Intelligence
import SimBinding
```

### For Objective-C
``` objective-c
#import "Sign3Intelligence/Sign3Intelligence-Swift.h"
@import SimBinding;
```

<br>

## Initializing the SDK

1. Initialize the SDK in your **AppDelegate** class within the **application(_:didFinishLaunchingWithOptions:)** method.
2. Use the ClientID and Client Secret shared with the credentials document.

### For Swift
``` swift
if #available(iOS 15.0, *) {
    let options = Options.OptionBuilder()
        .setClientId("<SIGN3_CLIENT_ID>")
        .setClientSecret("<SIGN3_CLIENT_SECRET>")
        .setEnvironment(Environment.PROD) // For Prod: Environment.PROD, For Dev: Environment.DEV
        .build()

    Sign3SDK.getInstance().initAsync(options: options){isInitialize in
        // To check if the SDK is initialized correctly or not
    }
}
```

### For Objective-C
``` objective-c
if #available(iOS 15.0, *) {
    OptionBuilder *builder = [[OptionBuilder alloc] init];
    builder = [builder setClientId:@"<SIGN3_CLIENT_ID>"];
    builder = [builder setClientSecret:@"<SIGN3_CLIENT_SECRET>"];
    builder = [builder setEnvironment:EnvironmentPROD];
    Options *options = [builder build];

    [[Sign3SDK getInstance] initAsyncWithOptions:options completion:^(
        BOOL isInitialize
    ) {
        // Handle initialization result
        NSLog(@"TAG_Initialization status: %@", isInitialize ? @"YES" : @"NO");
    }];
}
```

<br>

## Starting SIM Binding

You do not call the SIM binding SDK yourself. The Sign3 Intelligence SDK runs SIM binding as part of a login or signup score:

1. Ask Sign3 to enable SIM binding for your tenant.
2. Set the user's phone number through `updateOptions`, **with the country code and no `+` or spaces** (`919876543210`), and a `LOGIN` or `SIGNUP` event type. SIM binding does not run for `TRANSACTION` or `OTHERS`.
3. Call `getIntelligence()`.

On that score the Intelligence SDK brings the SIM binding engine up and binds the SIM under the transaction the backend opened. The score response carries the transaction id as `IntelligenceResponse.snaRequestID` — hold on to it, it is what the status API is asked about, and what the OTP fallback is verified under.

Options are reset after every score, so update them again before each login or signup.

### For Swift

```swift
if #available(iOS 15.0, *) {
    let updateOption = UpdateOption.UpdateOptionBuilder()
        .setPhoneNumber("919876543210")        // country code + number, digits only
        .setUserEventType(UserEventType.LOGIN) // LOGIN or SIGNUP
        .build()

    Sign3SDK.getInstance().updateOptions(updateOption: updateOption)

    Sign3SDK.getInstance().getIntelligence(listener: Sign3())

    class Sign3: IntelligenceResponseListener {

        func onSuccess(response: IntelligenceResponse) {
            guard let snaRequestId = response.snaRequestID, !snaRequestId.isEmpty else {
                // SIM binding did not start for this score
                return
            }
            // SIM binding is running. Send this id to your backend for the status check.
            print("SIM binding under \(snaRequestId)")
        }

        func onError(error: IntelligenceError) {
            // Something went wrong, handle the error message
        }
    }
}
```

### For Objective-C

```objective-c
if #available(iOS 15.0, *) {
    UpdateOptionBuilder *builder = [[UpdateOptionBuilder alloc] init];
    builder = [builder setPhoneNumber:@"919876543210"];   // country code + number, digits only
    builder = [builder setUserEventType:UserEventTypeLOGIN]; // LOGIN or SIGNUP
    UpdateOption *updateOption = [builder build];

    [[Sign3SDK getInstance] updateOptionsWithUpdateOption:updateOption];

    [[Sign3SDK getInstance] getIntelligenceWithListener:self.listener];

    // - (void)onSuccessWithResponse:(IntelligenceResponse * _Nonnull)response {
    //     NSString *snaRequestId = response.snaRequestID;
    //     if (snaRequestId.length == 0) {
    //         // SIM binding did not start for this score
    //     } else {
    //         // SIM binding is running. Send this id to your backend for the status check.
    //     }
    // }
}
```

<br>

## Verifying the OTP Fallback

When the carrier cannot answer, the transaction falls back to an SMS OTP. Android reads and verifies that code by itself; iOS has no OTP auto-read, so collect the code from the user and pass it with the `snaRequestID` from the score response. The engine is already up from the score.

### For Swift

```swift
Sign3SimBindingSDK.verifyOtp(otp: otpField.text ?? "", snaRequestID: snaRequestID)
```

### For Objective-C

```objective-c
[Sign3SimBindingSDK verifyOtp:otpField.text snaRequestID:snaRequestID];
```

The outcome of the code is not returned on the device; ask the status API about the same `snaRequestID`.

<br>

## Checking the SIM Binding Status

The score returns as soon as the transaction is open; the binding itself finishes afterwards. Ask the status API what became of the `snaRequestID`.

**Call this from your backend.** The credentials below are your tenant id and tenant secret, and they must not ship in the app. The sample app calls it from the device only so the flow can be demonstrated on one screen.

### Request

```bash
curl --location 'https://intelligence.sign3.in/auth/v1/status?requestId=ARID_411A767110E0422FA06F9CF14F2B8E34' \
--header 'Content-Type: application/json' \
--header 'Authorization: Basic <base64(tenantId:tenantSecret)>'
```

| | |
|---|---|
| Base URL | `https://intelligence.sign3.in` |
| Method | `GET` |
| Path | `/auth/v1/status` |
| Query | `requestId` — the `snaRequestID` from `IntelligenceResponse` |
| `Authorization` | `Basic` over `<tenantId>:<tenantSecret>`, both provided by Sign3 |

### Response

<details open>
<summary><b>&nbsp;<code>200</code> &nbsp;·&nbsp; The transaction is known</b></summary>

<details>
<summary>🟡 &nbsp;<b><code>PENDING</code></b> &nbsp;— the carrier has not answered yet</summary>

```json
{
  "auths": [
    {
      "identityType": "MOBILE",
      "identityValue": "917069914791",
      "channel": "SILENT_AUTH",
      "methods": [
        "SILENT_AUTH"
      ],
      "status": "PENDING",
      "type": "PRIMARY"
    }
  ],
  "derivedOperator": "AIRTEL",
  "phoneDetail": {
    "countryCode": "91",
    "country": "IN",
    "type": "MOBILE",
    "homeOperator": "VI",
    "location": "India",
    "timeZones": [
      "Asia/Calcutta"
    ]
  },
  "simDetail": {
    "operator": "AIRTEL",
    "mcc": 405,
    "mnc": 51
  },
  "networkDetail": {
    "ip": "2401:4900:1c50:1a3b::1",
    "ipType": "IPV6",
    "operator": "AIRTEL"
  }
}
```

</details>

<details>
<summary>✅ &nbsp;<b><code>SUCCESS</code></b> &nbsp;— the SIM is bound</summary>

```json
{
  "auths": [
    {
      "identityType": "MOBILE",
      "identityValue": "917069914791",
      "channel": "SILENT_AUTH",
      "methods": [
        "SILENT_AUTH"
      ],
      "status": "SUCCESS",
      "verifiedTimestamp": 1781091069000,
      "type": "PRIMARY"
    }
  ],
  "derivedOperator": "AIRTEL",
  "phoneDetail": {
    "countryCode": "91",
    "country": "IN",
    "type": "MOBILE",
    "homeOperator": "VI",
    "location": "India",
    "timeZones": [
      "Asia/Calcutta"
    ]
  },
  "simDetail": {
    "operator": "AIRTEL",
    "mcc": 405,
    "mnc": 51
  },
  "networkDetail": {
    "ip": "2401:4900:1c50:1a3b::1",
    "ipType": "IPV6",
    "operator": "AIRTEL",
    "callback": {
      "ip": "2401:4900:aabb:f09e::68fa:fe37",
      "operator": "AIRTEL",
      "userAgent": "Chrome/147.0.0.0 Mobile Safari/537.36"
    }
  }
}
```

</details>

<details>
<summary>❌ &nbsp;<b><code>FAILED</code></b> &nbsp;— the SIM could not be bound</summary>

```json
{
  "auths": [
    {
      "identityType": "MOBILE",
      "identityValue": "917069914791",
      "channel": "SILENT_AUTH",
      "methods": [
        "SILENT_AUTH"
      ],
      "status": "FAILED",
      "type": "PRIMARY",
      "error": {
        "errorCode": "SP40005",
        "message": "Operator not supported",
        "description": "This operator is not supported for verification. Please try with a different network."
      }
    }
  ],
  "derivedOperator": "JIO",
  "phoneDetail": {
    "countryCode": "91",
    "country": "IN",
    "type": "MOBILE",
    "homeOperator": "VI",
    "location": "India",
    "timeZones": [
      "Asia/Calcutta"
    ]
  },
  "simDetail": {
    "operator": "JIO",
    "mcc": 405,
    "mnc": 872
  },
  "networkDetail": {
    "ip": "49.204.148.177",
    "ipType": "IPV4"
  }
}
```

</details>

</details>

<details>
<summary><b>&nbsp;<code>400</code> &nbsp;·&nbsp; The request was not accepted</b></summary>

<details>
<summary>⚠️ &nbsp;<b><code>7170</code></b> &nbsp;— Auth not started yet</summary>

```json
{
  "message": "Invalid Request",
  "errorCode": "7170",
  "description": "Auth not started yet. Please initiate authentication first."
}
```

</details>

<details>
<summary>⚠️ &nbsp;<b><code>7119</code></b> &nbsp;— Invalid request Id</summary>

```json
{
  "message": "Invalid Request",
  "errorCode": "7119",
  "description": "Request error: Invalid request Id"
}
```

</details>

</details>

<details>
<summary><b>&nbsp;<code>401</code> &nbsp;·&nbsp; The caller was not authorised</b></summary>

<details>
<summary>🔒 &nbsp;<b><code>7012</code></b> &nbsp;— Merchant credentials are empty</summary>

```json
{
  "message": "Access blocked",
  "errorCode": "7012",
  "description": "Authorization error: Merchant credentials are empty"
}
```

</details>

<details>
<summary>🔒 &nbsp;<b><code>7002</code></b> &nbsp;— Invalid credentials</summary>

```json
{
  "message": "Access blocked",
  "errorCode": "7002",
  "description": "Authorization error: Invalid credentials"
}
```

</details>

<details>
<summary>🔒 &nbsp;<b><code>7019</code></b> &nbsp;— Merchant blocked</summary>

```json
{
  "message": "Merchant Blocked",
  "errorCode": "7019",
  "description": "Your account has been temporarily Blocked. Please contact support for assistance."
}
```

</details>

</details>

<br>

## Changelog
### 1.0.0
- Silent Network Authentication over the carrier network, with fallback to an SMS OTP verified through `verifyOtp`.
- Driven by the Sign3 Intelligence SDK on login and signup scores; one API to call, only for the OTP fallback.
- `IntelligenceResponse.snaRequestID` carries the transaction id for the `/auth/v1/status` check.

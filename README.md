# Sign3 SIM Binding SDK Integration Guide for iOS

The Sign3 SIM Binding SDK verifies that the phone number a user claims is the number of the SIM in the device they are holding. It does this carrier-side, over the cellular data interface, through Silent Network Authentication (SNA): nothing is sent to the user. When the carrier cannot answer, the flow falls back to an SMS OTP, which the SDK reads and verifies on its own.

The SDK is headless and is driven entirely by the Sign3 Intelligence SDK. There is nothing to call and nothing to handle on the device; you only read the transaction id off the intelligence response and, from your backend, ask the Sign3 status API what became of it.
<br>

## Installation

SIM binding is driven by the Sign3 Intelligence SDK, so both SDKs go into the app.

#### Using CocoaPods

1. To integrate the SDKs into your Xcode project using CocoaPods, specify them in your Podfile.
2. Sign3 Intelligence: checkout the [latest_version](https://github.com/Sign3labs/sign3intelligence-ios-sdk-swift-package/releases)
3. Sign3 SIM Binding: checkout the [latest version](https://github.com/Sign3labs/simbinding-ios-sdk-swift-package/releases)
```
pod 'Sign3Intelligence', '~> <latest_version>'
pod 'SimBinding', '~> <latest_version>'
```

#### Using Swift package manager

```
URL for the repository: https://github.com/Sign3labs/sign3intelligence-ios-sdk-swift-package
URL for the repository: https://github.com/Sign3labs/simbinding-ios-sdk-swift-package
```
<br>

## Configure Info.plist for SNA

Add the following block to your Info.plist only if you are using the SNA feature.
 - If the NSAppTransportSecurity key is not already present, add the entire block below.
 - If the NSAppTransportSecurity key is already present, add the listed domains one by one under NSExceptionDomains.


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
#import "SimBinding/SimBinding-Swift.h"
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

Ask Sign3 to enable SIM binding for your tenant. Once SIM binding is enabled, you do not need to call the SIM binding SDK separately. The Sign3 Intelligence SDK internally handles the SNA and SMS flow.

1. Based on your requirements, we will create a `templateID` for SNA, SMS, or SNA + SMS authentication and use that template ID for authentication.
2. Set the user's phone number using updateOptions, including the country code without + or spaces (e.g., 919876543210), and set the UserEventType to AUTH. SIM binding runs only for the AUTH event type; it is not triggered for LOGIN, SIGNUP, TRANSACTION or OTHERS.
3. Call `getIntelligence()`.
4. On success, `onSuccess` receives an `IntelligenceResponse` whose `snaRequestId` holds the SNA request id. On failure, `onError` receives an `IntelligenceError` whose `errorMessage` carries the error code, message and description. Once you receive the `snaRequestId`, you need to poll the `Status Check API` to check the status of the SNA request. You can poll the Status Check API from your backend through the `Login API` until the SNA request reaches a final status. The recommended approach is to make a backend-to-backend call to perform the status check.


NOTE: Options are reset after every getIntelligence call, so update them again before each AUTH score.


### For Swift

```swift
if #available(iOS 15.0, *) {
    let updateOption = UpdateOption.UpdateOptionBuilder()
        .setPhoneNumber("919876543210")        // Pass the phone number with the country code
        .setUserEventType(UserEventType.AUTH)  // Set UserEventType.AUTH to initiate SIM binding
        .build()

    Sign3SDK.getInstance().updateOptions(updateOption: updateOption)

    Sign3SDK.getInstance().getIntelligence(listener: Sign3())

    class Sign3: IntelligenceResponseListener {

        func onSuccess(response: IntelligenceResponse) {
            // ⭐ Recommended: Poll the Status Check API from your backend to check whether SIM binding is pending, successful, or failed.
            let snaRequestId = response.snaRequestId
            print("SIM binding under \(snaRequestId)")
        }

        func onError(error: IntelligenceError) {
            // SIM binding could not be started or failed. Check IntelligenceError for the error code, message, and description.
            print("Sign3SimBinding: requestId=\(error.requestId) \(error.errorMessage)")
        }
    }
}
```

### For Objective-C

```objective-c
if #available(iOS 15.0, *) {
    UpdateOptionBuilder *builder = [[UpdateOptionBuilder alloc] init];
    builder = [builder setPhoneNumber:@"919876543210"];      // Pass the phone number with the country code
    builder = [builder setUserEventType:UserEventTypeAUTH];  // Set UserEventType.AUTH to initiate SIM binding
    UpdateOption *updateOption = [builder build];
    [[Sign3SDK getInstance] updateOptionsWithUpdateOption:updateOption];

    Sign3 *listener = [[Sign3 alloc] init];
    [[Sign3SDK getInstance] getIntelligenceWithListener:listener];

    @interface Sign3 : NSObject <IntelligenceResponseListener>
    @end

    @implementation Sign3

    - (void)onSuccessWithResponse:(IntelligenceResponse * _Nonnull)response {
        dispatch_async(dispatch_get_main_queue(), ^{
            // ⭐ Recommended: Poll the Status Check API from your backend to check whether SIM binding is pending, successful, or failed.
            NSString *snaRequestId = response.snaRequestId;
            NSLog(@"Sign3SimBinding: snaRequestId=%@", snaRequestId);
        });
    }

    - (void)onErrorWithError:(IntelligenceError * _Nonnull)error {
        // SIM binding could not be started or failed. Check IntelligenceError for the error code, message, and description.
        NSLog(@"Sign3SimBinding: requestId=%@ %@", error.requestId, error.errorMessage);
    }

    @end
}
```

> [!IMPORTANT]
> **Recommended:** Once you receive the snaRequestId, poll the Status Check API from your backend login/signup API to check whether SIM binding is PENDING, SUCCESS, or FAILED. Continue polling until the status reaches SUCCESS or FAILED. Never call the Status Check API from the app, as device-side checks can be tampered with and expose credentials.
<br>

<br>

## Verifying the OTP Fallback

When the carrier cannot answer, the transaction falls back to an SMS OTP. Android reads and verifies that code by itself; iOS has no OTP auto-read, so collect the code from the user and pass it with the `snaRequestId` from the response.

### For Swift

```swift
Sign3SimBindingSDK.verifyOtp(otp: otpField.text ?? "", snaRequestID: snaRequestId)
```

### For Objective-C

```objective-c
[Sign3SimBindingSDK verifyOtp:otpField.text snaRequestID:snaRequestID];
```

The outcome of the code is not returned on the device; ask the status API about the same `snaRequestID`.

<br>




### SIM Binding Result

The HTTP status below is the one the SIM binding backend returned to the Intelligence SDK when it opened the transaction. On `200` the SDK calls `onSuccess` with an `IntelligenceResponse` carrying the `snaRequestId`. On `400` and `401` the SDK calls `onError` with an `IntelligenceError` whose `errorMessage` is `<errorCode>: <errorMessage> - <errorDescription>` and whose `requestId` is the Sign3 request id.

#### Status code `200` — The transaction was opened

<table>
<tr>
<th align="left" width="495">✅ SNA request id received</th>
</tr>
<tr>
<td valign="top" width="495">

```json
{
  "snaRequestId": "ARID_A1B2C3D4E5F6"
}
```

</td>
</tr>
</table>

#### Status code `400` — The request was not accepted

<table>
<tr>
<th align="left" width="330">⚠️ 7119 · Invalid request Id</th>
<th align="left" width="330">⚠️ 7106 · Invalid phoneNumber or email</th>
<th align="left" width="330">⚠️ 7102 · Invalid phone number</th>
<th align="left" width="330">⚠️ 7104 · Invalid email</th>
<th align="left" width="330">⚠️ 7113 · Invalid expiry</th>
</tr>
<tr>
<td valign="top" width="330">

```json
{
  "requestId": "6f1c2a7e-3b9d-4c58-a1e2-9d7b5f0c4e21",
  "errorMessage": "7119: Invalid Request - Request error: Invalid request Id"
}
```

</td>
<td valign="top" width="330">

```json
{
  "requestId": "6f1c2a7e-3b9d-4c58-a1e2-9d7b5f0c4e21",
  "errorMessage": "7106: Invalid Request - Request error: Invalid phoneNumber or email."
}
```

</td>
<td valign="top" width="330">

```json
{
  "requestId": "6f1c2a7e-3b9d-4c58-a1e2-9d7b5f0c4e21",
  "errorMessage": "7102: Invalid Request - Request error: Invalid phone number"
}
```

</td>
<td valign="top" width="330">

```json
{
  "requestId": "6f1c2a7e-3b9d-4c58-a1e2-9d7b5f0c4e21",
  "errorMessage": "7104: Invalid Request - Request error: Invalid email"
}
```

</td>
<td valign="top" width="330">

```json
{
  "requestId": "6f1c2a7e-3b9d-4c58-a1e2-9d7b5f0c4e21",
  "errorMessage": "7113: Invalid Request - Request error: Invalid expiry"
}
```

</td>
</tr>
<tr>
<th align="left" width="330">⏱️ 9001 · Timeout Error</th>
<th align="left" width="330">⚠️ 9003 · Invalid phone number format</th>
<th align="left" width="330">⚠️ 9004 · Template id not configured</th>
</tr>
<tr>
<td valign="top" width="330">

```json
{
  "requestId": "6f1c2a7e-3b9d-4c58-a1e2-9d7b5f0c4e21",
  "errorMessage": "9001: Timeout Error - Sign3 SIM binding creation timed out."
}
```

</td>
<td valign="top" width="330">

```json
{
  "requestId": "6f1c2a7e-3b9d-4c58-a1e2-9d7b5f0c4e21",
  "errorMessage": "9003: Invalid Request - Sign3 SIM binding requires a phone number containing the country code followed by the subscriber number."
}
```

</td>
<td valign="top" width="330">

```json
{
  "requestId": "6f1c2a7e-3b9d-4c58-a1e2-9d7b5f0c4e21",
  "errorMessage": "9004: Invalid Request - The SIM binding template ID is not configured for this tenant."
}
```

</td>
</tr>
</table>

#### Status code `401` — The tenant was not authorised

<table>
<tr>
<th align="left" width="330">🔒 7012 · Credentials empty</th>
<th align="left" width="330">🔒 7002 · Invalid credentials</th>
<th align="left" width="330">🔒 7019 · Merchant blocked</th>
</tr>
<tr>
<td valign="top" width="330">

```json
{
  "requestId": "6f1c2a7e-3b9d-4c58-a1e2-9d7b5f0c4e21",
  "errorMessage": "7012: Access blocked - Authorization error: Merchant credentials are empty"
}
```

</td>
<td valign="top" width="330">

```json
{
  "requestId": "6f1c2a7e-3b9d-4c58-a1e2-9d7b5f0c4e21",
  "errorMessage": "7002: Access blocked - Authorization error: Invalid credentials"
}
```

</td>
<td valign="top" width="330">

```json
{
  "requestId": "6f1c2a7e-3b9d-4c58-a1e2-9d7b5f0c4e21",
  "errorMessage": "7019: Merchant Blocked - Your account has been temporarily Blocked. Please contact support for assistance."
}
```

</td>
</tr>
<tr>
<th align="left" width="330">🔒 9002 · Tenant credentials not configured</th>
<th align="left" width="330">🔒 9005 · SIM binding not enabled</th>
</tr>
<tr>
<td valign="top" width="330">

```json
{
  "requestId": "6f1c2a7e-3b9d-4c58-a1e2-9d7b5f0c4e21",
  "errorMessage": "9002: Access blocked - Sign3 SIM binding tenantId or tenantSecret is not configured for this tenant."
}
```

</td>
<td valign="top" width="330">

```json
{
  "requestId": "6f1c2a7e-3b9d-4c58-a1e2-9d7b5f0c4e21",
  "errorMessage": "9005: Access blocked - Sign3 SIM binding is not enabled for this tenant."
}
```

</td>
</tr>
</table>

<br>


## Checking the SIM Binding Status

The score returns as soon as the transaction is open; the binding itself finishes afterwards. Ask the status API what became of the `snaRequestId`.

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
| Query | `requestId` — the `snaRequestId` from `IntelligenceResponse` |
| `Authorization` | `Basic` over `<tenantId>:<tenantSecret>`, both provided by Sign3 |

### Response

#### Status code `200` — The transaction is known

<table>
<tr>
<th align="left" width="330">✅ SUCCESS</th>
<th align="left" width="330">🟡 PENDING</th>
<th align="left" width="330">❌ FAILED</th>
</tr>
<tr>
<td valign="top" width="330">

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

</td>
<td valign="top" width="330">

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

</td>
<td valign="top" width="330">

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
        "description": "This operator isn’t supported. Please try a different network."
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

</td>
</tr>
</table>

#### Status code `400` — The request was not accepted

<table>
<tr>
<th align="left" width="495">⚠️ 7170 · Auth not started yet</th>
<th align="left" width="495">⚠️ 7119 · Invalid request Id</th>
</tr>
<tr>
<td valign="top" width="495">

```json
{
  "message": "Invalid Request",
  "errorCode": "7170",
  "description": "Auth not started yet. Please initiate authentication first."
}
```

</td>
<td valign="top" width="495">

```json
{
  "message": "Invalid Request",
  "errorCode": "7119",
  "description": "Request error: Invalid request Id"
}
```

</td>
</tr>
</table>

#### Status code `401` — The caller was not authorised

<table>
<tr>
<th align="left" width="330">🔒 7012 · Credentials empty</th>
<th align="left" width="330">🔒 7002 · Invalid credentials</th>
<th align="left" width="330">🔒 7019 · Merchant blocked</th>
</tr>
<tr>
<td valign="top" width="330">

```json
{
  "message": "Access blocked",
  "errorCode": "7012",
  "description": "Authorization error: Merchant credentials are empty"
}
```

</td>
<td valign="top" width="330">

```json
{
  "message": "Access blocked",
  "errorCode": "7002",
  "description": "Authorization error: Invalid credentials"
}
```

</td>
<td valign="top" width="330">

```json
{
  "message": "Merchant Blocked",
  "errorCode": "7019",
  "description": "Your account has been temporarily Blocked. Please contact support for assistance."
}
```

</td>
</tr>
</table>

<br>

## Flow Diagram

SIM binding in four simple steps: Sign3 switches it on, your app asks for a score, you get an id, and your backend checks what happened to it.

```mermaid
flowchart TD
    A["1. Sign3 enables SIM binding for your tenant"]
    B["2. Your app sets the phone number and the AUTH event, then calls getIntelligence()"]
    C{"3. Did the response carry an snaRequestId?"}
    NO["No &nbsp;→&nbsp; onError gives you the error code and message. Show it or retry."]
    YES["Yes &nbsp;→&nbsp; SIM binding has started. Send the snaRequestId to your backend and expect a verdict for it."]
    D["4. Your backend calls the Status Check API with that ID until the status is SUCCESS or FAILED"]

    A --> B --> C
    C -- No --> NO
    C -- Yes --> YES --> D

    style A fill:none,stroke:#2e7d32,stroke-width:2px
    style B fill:none,stroke:#1565c0,stroke-width:2px
    style C fill:none,stroke:#1565c0,stroke-width:2px
    style NO fill:none,stroke:#c62828,stroke-width:2px
    style YES fill:none,stroke:#1565c0,stroke-width:2px
    style D fill:none,stroke:#ef6c00,stroke-width:2px
```

<br>

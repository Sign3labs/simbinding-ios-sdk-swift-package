import Foundation

final class SimBindingStatusService {
    static let shared = SimBindingStatusService()
    private init() {}

    private let baseURL = SDKConfig.baseUrl
    private let tenantId = SDKConfig.clientId
    private let tenantSecret = SDKConfig.clientSecret

    func fetchStatus(snaRequestId: String) async throws -> SimBindingStatus {
        var components = URLComponents(string: baseURL + "auth/v1/status")!
        components.queryItems = [URLQueryItem(name: "requestId", value: snaRequestId)]

        var request = URLRequest(url: components.url!)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let credentials = Data("\(tenantId):\(tenantSecret)".utf8).base64EncodedString()
        request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")

        Log.print("Status", "➡️ GET \(request.url!.absoluteString)")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            // Network blip (common while switching to cellular) -> try again next poll.
            let ns = error as NSError
            Log.print("Status", "❌ network error domain=\(ns.domain) code=\(ns.code) \(ns.localizedDescription)\n\(ns.userInfo)")
            return .pending(message: ns.localizedDescription)
        }

        let http = response as? HTTPURLResponse
        let code = http?.statusCode ?? 0
        Log.print("Status", """
        ⬅️ HTTP \(code)
        headers: \(http?.allHeaderFields ?? [:])
        body:
        \(Log.pretty(data))
        """)

        guard code == 200 else {
            let apiError = try? JSONDecoder().decode(StatusAPIError.self, from: data)
            Log.print("Status", "❌ HTTP \(code) error: \(apiError?.errorDescription ?? "(could not decode error body)")")
            // 401 = wrong credentials, polling again won't help.
            if code == 401 {
                return .failed(message: "HTTP 401\n\(Log.pretty(data))")
            }
            // Anything else (e.g. 7170 auth not started yet) -> not ready, keep polling.
            return .pending(message: "HTTP \(code)\n\(Log.pretty(data))")
        }

        let body: StatusResponse
        do {
            body = try JSONDecoder().decode(StatusResponse.self, from: data)
        } catch {
            Log.print("Status", "❌ decode error: \(error)")
            return .pending(message: Log.pretty(data))
        }
        guard let auths = body.auths, !auths.isEmpty else {
            Log.print("Status", "no auths yet -> pending")
            return .pending(message: Log.pretty(data))
        }
        Log.print("Status", "auths: " + auths.map { "\($0.channel ?? "?")=\($0.status ?? "?")" }.joined(separator: ", "))

        // The alert shows the full status API response.
        let responseText = Log.pretty(data)
        if auths.contains(where: { $0.status == "SUCCESS" }) {
            return .success(message: responseText)
        }
        if auths.allSatisfy({ $0.status == "FAILED" }) {
            return .failed(message: responseText)
        }
        return .pending(message: responseText)
    }
}

// MARK: - Models

enum SimBindingStatus: Equatable {
    case pending(message: String)
    case success(message: String)
    case failed(message: String)
}

private struct StatusResponse: Decodable {
    struct Auth: Decodable {
        let status: String?
        let channel: String?
        let error: StatusAPIError?
    }
    let auths: [Auth]?
}

struct StatusAPIError: Decodable, LocalizedError {
    let message: String?
    let errorCode: String?
    let description: String?

    var errorDescription: String? {
        [errorCode, message, description].compactMap { $0 }.joined(separator: " · ")
    }
}

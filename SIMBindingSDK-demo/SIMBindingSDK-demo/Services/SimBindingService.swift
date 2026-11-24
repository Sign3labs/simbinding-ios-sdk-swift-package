import Foundation
import Sign3Intelligence
import SimBinding

final class SimBindingService {
    static let shared = SimBindingService()
    private init() {}

    func startSimBinding(phoneNumber: String) async throws -> String {
        let updateOption = UpdateOption.UpdateOptionBuilder()
            .setPhoneNumber(phoneNumber)
            .setUserEventType(.AUTH)
            .build()
        Sign3SDK.getInstance().updateOptions(updateOption: updateOption)
        Log.print("SDK", "updateOptions phoneNumber=\(phoneNumber) userEventType=AUTH")
        Log.print("SDK", "getIntelligence called")

        return try await withCheckedThrowingContinuation { continuation in
            Sign3SDK.getInstance().getIntelligence(listener: Listener(continuation: continuation))
        }
    }
}

// MARK: - Errors

struct SimBindingError: LocalizedError {
    let requestId: String
    let message: String

    var errorDescription: String? { message }
}

// MARK: - Listener

private final class Listener: IntelligenceResponseListener {
    private let continuation: CheckedContinuation<String, Error>

    init(continuation: CheckedContinuation<String, Error>) {
        self.continuation = continuation
    }

    func onSuccess(response: IntelligenceResponse) {
        Log.print("SDK", "onSuccess snaRequestId=\(response.snaRequestId ?? "nil")\n\(Log.pretty(response))")
        if let id = response.snaRequestId, !id.isEmpty {
            continuation.resume(returning: id)
        } else {
            continuation.resume(throwing: SimBindingError(
                requestId: response.requestId ?? "",
                message: "No snaRequestId in the response. Is SIM binding enabled for this tenant?"
            ))
        }
    }

    func onError(error: IntelligenceError) {
        Log.print("SDK", "❌ onError requestId=\(error.requestId) errorMessage=\(error.errorMessage)")
        continuation.resume(throwing: SimBindingError(requestId: error.requestId, message: error.errorMessage))
    }
}

import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    struct ResultAlert: Identifiable {
        let id = UUID()
        let isSuccess: Bool
        let message: String
    }

    @Published var mobileNumber = ""
    @Published var isLoading = false
    @Published var statusText = ""
    @Published var alert: ResultAlert?

    private let simBinding: SimBindingService
    private let statusService: SimBindingStatusService

    private let pollInterval: UInt64 = 2_000_000_000
    private let maxAttempts = 15
                        

    init(simBinding: SimBindingService = .shared, statusService: SimBindingStatusService = .shared) {
        self.simBinding = simBinding
        self.statusService = statusService
    }

    var isValid: Bool {
        !mobileNumber.isEmpty
    }

    /// 1. Start SIM binding via the SDK  2. Poll status  3. Show success / failure.
    func authenticate() async {
        guard isValid else {
            alert = ResultAlert(isSuccess: false, message: "Enter a mobile number")
            return
        }
        isLoading = true
        defer { isLoading = false; statusText = "" }

        do {
            statusText = "Starting SIM binding…"
            let snaRequestId = try await simBinding.startSimBinding(phoneNumber: mobileNumber) // sent exactly as typed
            Log.print("Flow", "snaRequestId: \(snaRequestId)")

            statusText = "Verifying your SIM…"
            alert = try await pollStatus(snaRequestId: snaRequestId)
        } catch {
            Log.print("Flow", "❌ error: \(error)")
            alert = ResultAlert(isSuccess: false, message: error.localizedDescription)
        }
        if let alert {
            Log.print("Flow", "\(alert.isSuccess ? "✅ SUCCESS" : "❌ FAILED"): \(alert.message)")
        }
    }
//backend msgs
    private func pollStatus(snaRequestId: String) async throws -> ResultAlert {
        var lastMessage = ""
        for attempt in 1...maxAttempts {
            Log.print("Flow", "status check \(attempt)/\(maxAttempts)")
            switch try await statusService.fetchStatus(snaRequestId: snaRequestId) {
            case .success(let message):
                return ResultAlert(isSuccess: true, message: message)
            case .failed(let message):
                return ResultAlert(isSuccess: false, message: message)
            case .pending(let message):
                lastMessage = message
                try await Task.sleep(nanoseconds: pollInterval)
            }
        }
        return ResultAlert(isSuccess: false, message: lastMessage)
    }
}

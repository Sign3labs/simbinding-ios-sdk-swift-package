import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        VStack(spacing: 0) {
            Text("SIM Binding")
                .font(.system(size: 34))

            Text("Enter your mobile number with country code")
                .foregroundStyle(.secondary)
                .padding(.top, 12)

            OutlinedTextField(
                label: "Mobile number",
                text: $viewModel.mobileNumber,
                keyboard: .phonePad
            )
            .padding(.top, 40)
            .onChange(of: viewModel.mobileNumber) { value in
                let digits = String(value.filter(\.isNumber).prefix(15))
                if digits != value { viewModel.mobileNumber = digits }
            }

            PrimaryButton(title: "Authenticate", isLoading: viewModel.isLoading) {
                Task { await viewModel.authenticate() }
            }
            .padding(.top, 36)

            Text(viewModel.statusText)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 16)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.screenBackground.ignoresSafeArea())
        .tint(.brand)
        .alert(item: $viewModel.alert) { result in
            Alert(
                title: Text(result.isSuccess ? "SIM Binding Successful" : "SIM Binding Failed"),
                message: Text(result.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

#Preview {
    AuthView()
}

import SwiftUI

extension Color {
    static let brand = Color(red: 0x4F / 255, green: 0x5B / 255, blue: 0x87 / 255)
    static let screenBackground = Color(red: 0.976, green: 0.976, blue: 0.984)
}

struct OutlinedTextField: View {
    let label: String
    var prefix: String? = nil
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 6) {
            if let prefix {
                Text(prefix).foregroundStyle(.secondary)
            }
            TextField("", text: $text)
                .keyboardType(keyboard)
                .textContentType(keyboard == .numberPad ? .oneTimeCode : nil)
        }
        .font(.title3)
        .padding(.horizontal, 16)
        .frame(height: 56)
        .overlay(
            RoundedRectangle(cornerRadius: 6).stroke(Color.brand, lineWidth: 2)
        )
        .overlay(alignment: .topLeading) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.brand)
                .padding(.horizontal, 4)
                .background(Color.screenBackground)
                .offset(x: 12, y: -10)
        }
    }
}

/// loading state
struct PrimaryButton: View {
    let title: String
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title).opacity(isLoading ? 0 : 1)
                if isLoading { ProgressView().tint(.white) }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.brand, in: Capsule())
        }
        .disabled(isLoading)
    }
}

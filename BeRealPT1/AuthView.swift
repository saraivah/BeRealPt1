import SwiftUI

struct AuthView: View {
    @EnvironmentObject var session: SessionStore

    @State private var isSignUp = false
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isWorking = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("BeReal.")
                .font(.system(size: 44, weight: .heavy))
                .padding(.bottom, 24)

            field("Username", text: $username)
            if isSignUp {
                field("Email", text: $email)
                    .keyboardType(.emailAddress)
            }
            SecureField("Password", text: $password)
                .padding()
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button(action: submit) {
                Group {
                    if isWorking { ProgressView().tint(.black) }
                    else { Text(isSignUp ? "Sign up" : "Log in").bold() }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isWorking)

            Button(isSignUp ? "Have an account? Log in" : "New here? Sign up") {
                isSignUp.toggle()
                errorMessage = nil
            }
            .font(.footnote)
            .foregroundStyle(.gray)

            Spacer()
        }
        .padding(24)
        .background(Color.black.ignoresSafeArea())
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding()
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func submit() {
        guard !username.isEmpty, !password.isEmpty, !isSignUp || !email.isEmpty else {
            errorMessage = "Fill in every field to continue."
            return
        }
        isWorking = true
        errorMessage = nil
        Task {
            do {
                if isSignUp {
                    try await session.signUp(username: username, email: email, password: password)
                } else {
                    try await session.logIn(username: username, password: password)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isWorking = false
        }
    }
}

import SwiftUI
import Combine
import ParseSwift

@main
struct BeRealCloneApp: App {
    @StateObject private var session = SessionStore()

    init() {
        
        ParseSwift.initialize(
            applicationId: "DKSiEJhm6wZbGaJc0GaR5dFmSrHTcU2EaNjT9vxz",
            clientKey: "4BdXf0QnJJtxXJQytynQdhN65nHPfcVrDnGHEXNq",
            serverURL: URL(string: "https://parseapi.back4app.com")!
        )
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if session.isLoggedIn {
                    FeedView()
                } else {
                    AuthView()
                }
            }
            .environmentObject(session)
            .preferredColorScheme(.dark)
        }
    }
}


@MainActor
final class SessionStore: ObservableObject {
    @Published var isLoggedIn: Bool = User.current != nil

    func signUp(username: String, email: String, password: String) async throws {
        var newUser = User()
        newUser.username = username
        newUser.email = email
        newUser.password = password
        _ = try await newUser.signup()
        isLoggedIn = true
    }

    func logIn(username: String, password: String) async throws {
        _ = try await User.login(username: username, password: password)
        isLoggedIn = true
    }

    func logOut() async {
        try? await User.logout()
        isLoggedIn = false
    }
}

import Foundation
import Combine

class AuthManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    var username: String?

    func login(username: String) {
        self.isLoggedIn = true
        self.username = username
        print("Logged in as \(username)")
    }

    func logout() {
        self.isLoggedIn = false
        self.username = nil
    }
}

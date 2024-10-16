import SwiftUI

struct BurgerMenu: View {
    @Binding var showMenu: Bool
    @Binding var navigateToLogin: Bool
    @Binding var navigateToRegister: Bool
    @Binding var navigateToFavorites: Bool // Added binding for navigating to favorites
    @Binding var showLogoutMessage: Bool
    @EnvironmentObject var authManager: AuthManager // Use shared auth manager

    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            if authManager.isLoggedIn {
                // Display welcome message with username
                VStack {
                    Text("👋 Welcome, \(authManager.username ?? "User")!")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Enjoy browsing!")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, 20)
                
                // Show favorites button
                Button(action: {
                    navigateToFavorites = true
                    showMenu = false
                }) {
                    Text("Favorites")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 10)
                
                // Show logout button
                Button(action: {
                    authManager.logout()
                    showMenu = false
                    showLogoutMessage = true
                }) {
                    Text("Logout")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)  // Red color for logout
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                }
            } else {
                // Show login and register options if the user is not logged in
                Button(action: {
                    navigateToLogin = true
                    showMenu = false
                }) {
                    Text("Login")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 10)

                Button(action: {
                    navigateToRegister = true
                    showMenu = false
                }) {
                    Text("Register")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                }
            }
            Spacer()
        }
        .frame(maxWidth: UIScreen.main.bounds.width / 2)
        .background(Color.gray.opacity(0.9))
        .edgesIgnoringSafeArea(.all)
    }
}

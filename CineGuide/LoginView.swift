import SwiftUI
import Firebase
import FirebaseFirestore
import CryptoKit  // Import CryptoKit for password hashing

struct LoginView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var isLoading = false  // For loading state
    @EnvironmentObject var authManager: AuthManager  // Access to auth manager for login handling
    @Environment(\.presentationMode) var presentationMode  // To dismiss the view after login

    var body: some View {
        VStack(alignment: .leading) {
            Text("Login")
                .font(.largeTitle)
                .padding(.bottom, 20)
            
            // Username Field
            Text("Username")
                .font(.headline)
            TextField("Enter your username", text: $username)
                .autocapitalization(.none)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom, 10)
            
            // Password Field
            Text("Password")
                .font(.headline)
            SecureField("Enter your password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom, 10)
            
            // Error message display
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.bottom, 10)
            }

            // Loading indicator
            if isLoading {
                ProgressView()
                    .padding(.bottom, 10)
            }

            // Login Button
            Button(action: login) {
                Text("Login")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
            .disabled(isLoading)  // Disable button while loading

            Spacer()
        }
        .padding()
        .navigationTitle("Login")
    }

    // Login action with Firestore validation
    func login() {
        // Ensure fields are not empty
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in both fields."
            return
        }
        
        // Clear error message and start loading state
        errorMessage = nil
        isLoading = true

        // Hash the input password to compare with the stored hashed password
        let hashedPassword = hashPassword(password)
        
        // Fetch the user from Firestore
        let db = Firestore.firestore()
        let usersRef = db.collection("users").whereField("username", isEqualTo: username)
        
        usersRef.getDocuments { (querySnapshot, error) in
            isLoading = false  // Stop loading state
            if let error = error {
                errorMessage = "Login failed: \(error.localizedDescription)"
                return
            }

            if let documents = querySnapshot?.documents, !documents.isEmpty {
                let userData = documents.first?.data()
                let storedPassword = userData?["password"] as? String ?? ""
                
                // Compare hashed password
                if storedPassword == hashedPassword {
                    // Successful login
                    authManager.login(username: username)
                    presentationMode.wrappedValue.dismiss()  // Dismiss login view
                } else {
                    errorMessage = "Invalid credentials. Please try again."
                }
            } else {
                errorMessage = "No user found with this username."
            }
        }
    }

    // Hash password using SHA-256
    func hashPassword(_ password: String) -> String {
        let inputData = Data(password.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

#Preview {
    LoginView()
}

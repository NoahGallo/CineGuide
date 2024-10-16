import SwiftUI
import Firebase
import FirebaseFirestore
import CryptoKit  // Import CryptoKit for password hashing

struct RegisterView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String?
    @State private var isLoading = false  // For loading state
    @EnvironmentObject var authManager: AuthManager  // Access to auth manager for login handling
    @Environment(\.presentationMode) var presentationMode  // To dismiss the view after registration

    var body: some View {
        VStack(alignment: .leading) {
            Text("Register")
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
            
            // Confirm Password Field
            Text("Confirm Password")
                .font(.headline)
            SecureField("Re-enter your password", text: $confirmPassword)
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

            // Register Button
            Button(action: register) {
                Text("Register")
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
        .navigationTitle("Register")
    }

    // Register action with basic password validation
    func register() {
        // Check if passwords match
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        
        // Password validation
        guard validatePassword(password) else {
            errorMessage = "Password must be at least 6 characters long and include at least one uppercase letter, one lowercase letter, and one number."
            return
        }

        // Clear error message if validation is successful
        errorMessage = nil
        isLoading = true  // Start loading state

        // Hash the password
        let hashedPassword = hashPassword(password)

        // Insert user into Firestore
        let db = Firestore.firestore()
        let newUser: [String: Any] = [
//            "uuid": UUID().uuidString,
            "username": username,
            "password": hashedPassword,
            "created_at": FieldValue.serverTimestamp()  // Set server timestamp for user creation
        ]

        // Add the user to Firestore
        db.collection("users").addDocument(data: newUser) { error in
            isLoading = false  // Stop loading state
            if let error = error {
                errorMessage = "Failed to register: \(error.localizedDescription)"
            } else {
                // Successful registration
                authManager.login(username: username)
                presentationMode.wrappedValue.dismiss()  // Dismiss register view
            }
        }
    }

    // Password validation function
    func validatePassword(_ password: String) -> Bool {
        let passwordRegex = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).{6,}$"
        return NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: password)
    }

    // Hash password using SHA-256
    func hashPassword(_ password: String) -> String {
        let inputData = Data(password.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

#Preview {
    RegisterView()
}

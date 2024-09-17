import SwiftUI
import Firebase
import FirebaseFirestore

struct Movie: Identifiable, Codable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case posterPath = "poster_path"
    }
    
    var posterURL: URL? {
        URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }
}

struct MovieResponse: Codable {
    let results: [Movie]
}

struct ContentView: View {
    @State private var movies: [Movie] = []  // State variable to hold movie data
    @State private var showMenu = false
    @State private var navigateToLogin = false
    @State private var navigateToRegister = false
    @State private var showLogoutMessage = false  // Show message after logout
    @State private var showErrorAlert = false     // To trigger alert for errors
    @State private var errorMessage = ""          // Error message to display
    @EnvironmentObject var authManager: AuthManager // Use shared auth manager
    
    let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    // Top bar with project name and burger menu button
                    HStack {
                        Button(action: {
                            withAnimation { showMenu.toggle() }
                        }) {
                            Image(systemName: showMenu ? "xmark" : "line.horizontal.3")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding(.leading)
                        }
                        Spacer()
                        Text("CineGuide")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding()
                        Spacer()
                    }
                    .background(Color.blue)
                    .foregroundColor(.white)
                    
                    // Movie title section
                    HStack {
                        Text("Hot Right Now 🔥")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.leading)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    
                    // Directly display the movie list view instead of Fetch button
                    List(movies) { movie in
                        HStack {
                            if let posterURL = movie.posterURL {
                                AsyncImage(url: posterURL) { image in
                                    image.resizable().aspectRatio(contentMode: .fit)
                                        .frame(width: 100, height: 150)
                                } placeholder: {
                                    ProgressView()
                                }
                            }
                            VStack(alignment: .leading, spacing: 10) {
                                Text(movie.title).font(.headline)
                                Text(movie.overview)
                                    .font(.subheadline)
                                    .lineLimit(4)
                                    .padding(.top, 5)
                            }
                        }
                    }
                }
                .onAppear {
                    // Automatically fetch movies when the view appears
                    Task {
                        await getMovies()
                    }
                }
                .alert(isPresented: $showErrorAlert) {
                    Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
                }

                // Burger menu overlay with animation
                if showMenu {
                    ZStack(alignment: .leading) {
                        Color.black.opacity(0.3)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                withAnimation { showMenu = false }
                            }

                        HStack {
                            BurgerMenu(showMenu: $showMenu, navigateToLogin: $navigateToLogin, navigateToRegister: $navigateToRegister, showLogoutMessage: $showLogoutMessage)
                                .frame(width: UIScreen.main.bounds.width / 2)
                                .background(Color.gray.opacity(0.9))
                                .transition(.move(edge: .leading))
                            Spacer()
                        }
                    }

                    // Keep the X button on top and in the same position as the burger icon
                    VStack {
                        HStack {
                            Button(action: {
                                withAnimation { showMenu.toggle() }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .padding(.leading)
                                    .padding(.top, 60)
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                }

                // Navigation links for login and register
                NavigationLink("", destination: LoginView(), isActive: $navigateToLogin)
                NavigationLink("", destination: RegisterView(), isActive: $navigateToRegister)
            }
            .alert(isPresented: $showLogoutMessage) {
                Alert(title: Text("Logged Out"), message: Text("You have successfully logged out."), dismissButton: .default(Text("OK")))
            }
        }
    }

    // Fetch movie data (TMDB API)
    func getMovies() async {
        guard let bearerToken = loadEnv()?["API_TMDB_TOKEN"] else {
            errorMessage = "Bearer Token is not loaded."
            showErrorAlert = true
            return
        }

        do {
            let urlString = "https://api.themoviedb.org/3/movie/popular?language=en-US&page=1"
            guard let url = URL(string: urlString) else {
                errorMessage = "Invalid URL."
                showErrorAlert = true
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 401 {
                    errorMessage = "Unauthorized: Bearer token might be incorrect or expired."
                    showErrorAlert = true
                    return
                }
                if httpResponse.statusCode != 200 {
                    errorMessage = "Unexpected response: \(httpResponse.statusCode)"
                    showErrorAlert = true
                    return
                }
            }

            let decoder = JSONDecoder()
            let movieResponse = try decoder.decode(MovieResponse.self, from: data)
            self.movies = movieResponse.results
        } catch {
            errorMessage = "Request failed with error: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }

    // Load .env file
    func loadEnv() -> [String: String]? {
        guard let path = Bundle.main.path(forResource: ".env.xcconfig", ofType: nil) else {
            errorMessage = ".env file not found."
            showErrorAlert = true
            return nil
        }

        do {
            let data = try String(contentsOfFile: path, encoding: .utf8)
            var envDict = [String: String]()
            let lines = data.split { $0.isNewline }
            for line in lines {
                let parts = line.split(separator: "=", maxSplits: 1).map { String($0) }
                if parts.count == 2 {
                    envDict[parts[0]] = parts[1]
                }
            }
            return envDict
        } catch {
            errorMessage = "Error reading .env file: \(error.localizedDescription)"
            showErrorAlert = true
            return nil
        }
    }
}

// Define the modified BurgerMenu view

struct BurgerMenu: View {
    @Binding var showMenu: Bool
    @Binding var navigateToLogin: Bool
    @Binding var navigateToRegister: Bool
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

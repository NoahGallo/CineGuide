import SwiftUI
import Firebase
import FirebaseFirestore
import ModalView

struct MovieResponse: Codable {
    let results: [Movie]
    let totalPages: Int
    
    enum CodingKeys: String, CodingKey {
        case results
        case totalPages = "total_pages"
    }
}

struct ContentView: View {
    @State private var movies: [Movie] = []  // State variable to hold movie data
    @State private var favoriteMovieIDs: [Int] = []
    @State private var selectedMovie: Movie?
    @State private var showModal = false
    @State private var currentPage = 1
    @State private var totalPages = 1
    @State private var showMenu = false
    @State private var navigateToLogin = false
    @State private var navigateToRegister = false
    @State private var navigateToFavorites = false
    @State private var showLogoutMessage = false  // Show message after logout
    @State private var showErrorAlert = false     // To trigger alert for errors
    @State private var errorMessage = ""          // Error message to display
    @State private var searchText = ""            // State for search bar
    @State private var isSearching = false        // Track if user is searching
    @EnvironmentObject var authManager: AuthManager // Use shared auth manager

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
                    
                    // Search bar
                    HStack {
                        TextField("🍿 Find your favorite movie...", text: $searchText)
                            .onChange(of: searchText, perform: { newValue in
                                if !newValue.isEmpty {
                                    isSearching = true
                                    Task {
                                        await searchMovies(query: newValue)
                                    }
                                } else {
                                    isSearching = false
                                    Task {
                                        await getMovies(currentPage: currentPage)
                                    }
                                }
                            })
                        .padding(.leading, 15)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 10)

                    // Movie title section (Hide if searching)
                    if !isSearching {
                        HStack {
                            Text("Hot Right Now 🔥")
                                .font(.title)
                                .fontWeight(.bold)
                                .padding(.leading)
                            Spacer()
                        }
                        .padding(.vertical, 10)
                    }

                    // Movie list display
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(movies) { movie in
                                HStack(alignment: .top) {
                                    ZStack {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 100, height: 150)
                                        if let posterURL = movie.posterURL {
                                            AsyncImage(url: posterURL) { image in
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 100, height: 150)
                                                    .cornerRadius(8)
                                            } placeholder: {
                                                ProgressView()
                                                    .frame(width: 100, height: 150)
                                            }
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text(movie.title)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                            .padding(.top, 10)

                                        Text(movie.overview)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .lineLimit(4)
                                            .padding(.bottom, 5)
                                        
                                        HStack {
                                            Image(systemName: "info.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(.blue)
                                            
                                            if authManager.isLoggedIn { // Show heart only if logged in
                                                Image(systemName: isFavorite(movie: movie) ? "heart.fill" : "heart") // Fill heart if it's a favorite
                                                    .font(.title2)
                                                    .foregroundColor(.red)
                                                    .onTapGesture {
                                                        toggleFavorite(movie: movie) // Add or remove from favorites
                                                    }
                                            }
                                        }
                                        .padding(.leading, 10)
                                        .frame(maxWidth: .infinity, alignment: .topLeading)
                                    }
                                    .padding(.leading, 10)
                                    .frame(maxWidth: .infinity, alignment: .topLeading)
                                }
                                .frame(width: 350, height: 150)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                                .shadow(radius: 4)
                                .onTapGesture {
                                    onClickCard(movie: movie)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // Pagination Controls
                    BottomBar(
                        currentPage: currentPage,
                        totalPages: totalPages,
                        onPageChange: { page in
                            currentPage = page
                            Task {
                                await getMovies(currentPage: currentPage)
                            }
                        },
                        onPrevious: {
                            if currentPage > 1 {
                                currentPage -= 1
                                Task {
                                    await getMovies(currentPage: currentPage)
                                }
                            }
                        },
                        onNext: {
                            if currentPage < totalPages {
                                currentPage += 1
                                Task {
                                    await getMovies(currentPage: currentPage)
                                }
                            }
                        }
                    )
                    .padding()
                }
                .onAppear {
                    Task {
                        await getMovies(currentPage: currentPage)
                        if authManager.isLoggedIn {
                            await fetchFavoriteMovies() // Fetch favorite movies if logged in
                        }
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
                            BurgerMenu(
                                showMenu: $showMenu,
                                navigateToLogin: $navigateToLogin,
                                navigateToRegister: $navigateToRegister,
                                navigateToFavorites: $navigateToFavorites,  // Add this line
                                showLogoutMessage: $showLogoutMessage
                            )
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
                NavigationLink("", destination: FavoritesPage(), isActive: $navigateToFavorites)

            }
            .alert(isPresented: $showLogoutMessage) {
                Alert(title: Text("Logged Out"), message: Text("You have successfully logged out."), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showModal){
                if let selectedMovie = selectedMovie{
                    MovieDetailView(movie: selectedMovie)
                }
            }
        }
    }
    
    // Fetch popular movies (TMDB API)
    func getMovies(currentPage: Int) async {
        guard let bearerToken = loadEnv()?["API_TMDB_TOKEN"] else {
            errorMessage = "Bearer Token is not loaded."
            showErrorAlert = true
            return
        }

        do {
            let urlString = "https://api.themoviedb.org/3/movie/popular?language=en-US&page=\(currentPage)"
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
                print("HTTP Status Code: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 401 {
                    errorMessage = "Unauthorized: Bearer token might be incorrect or expired."
                    showErrorAlert = true
                    return
                }
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let decoder = JSONDecoder()
                let movieResponse = try decoder.decode(MovieResponse.self, from: data)
                self.movies = movieResponse.results
                self.totalPages = movieResponse.totalPages  // Update total pages
                print("Movies loaded successfully")
            }

        } catch {
            errorMessage = "Request failed with error: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }

    // Search for movies (TMDB API)
    func searchMovies(query: String) async {
        guard !query.isEmpty else { return }
        guard let bearerToken = loadEnv()?["API_TMDB_TOKEN"] else {
            errorMessage = "Bearer Token is not loaded."
            showErrorAlert = true
            return
        }

        do {
            let urlString = "https://api.themoviedb.org/3/search/movie?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&language=en-US&page=1"
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
            }

            let decoder = JSONDecoder()
            let movieResponse = try decoder.decode(MovieResponse.self, from: data)
            self.movies = movieResponse.results
            print("Search response: \(movieResponse.results)")
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
            errorMessage = "Error reading .env file: \(error)"
            showErrorAlert = true
            return nil
        }
    }
    
    func fetchFavoriteMovies() async {
        guard let username = authManager.username else {
            errorMessage = "User not logged in."
            showErrorAlert = true
            return
        }

        let db = Firestore.firestore()
        let userFavoritesRef = db.collection("favorites").document(username)

        do {
            let document = try await userFavoritesRef.getDocument()
            guard let data = document.data(), let movieIDs = data["movies"] as? [Int] else {
                errorMessage = "No favorite movies found."
                showErrorAlert = true
                return
            }

            // Store the favorite movie IDs
            self.favoriteMovieIDs = movieIDs
        } catch {
            errorMessage = "Failed to load favorite movies: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }


    func onClickCard(movie: Movie) {
        selectedMovie = movie
        showModal = true
    }
    
    func isFavorite(movie: Movie) -> Bool {
        return favoriteMovieIDs.contains(movie.id)
    }

    
    func toggleFavorite(movie: Movie) {
        if isFavorite(movie: movie) {
            // Remove from favorites
            removeFromFavorites(movie: movie)
        } else {
            // Add to favorites
            addToFavorites(movie: movie)
        }
    }
    
    func addToFavorites(movie: Movie) {
        guard let username = authManager.username else {
            errorMessage = "User not logged in."
            showErrorAlert = true
            return
        }
        
        let db = Firestore.firestore()
        
        // Create the reference to the user's document inside the 'favorites' collection
        let userFavoritesRef = db.collection("favorites").document(username)

        // Add or merge the movie ID to the user's favorites
        userFavoritesRef.updateData([
            "movies": FieldValue.arrayUnion([movie.id])
        ]) { error in
            if let error = error {
                errorMessage = "Error adding to favorites: \(error.localizedDescription)"
                showErrorAlert = true
            } else {
                favoriteMovieIDs.append(movie.id) // Add to local favorite IDs
                print("Movie added to favorites!")
            }
        }
    }

    func removeFromFavorites(movie: Movie) {
        guard let username = authManager.username else {
            errorMessage = "User not logged in."
            showErrorAlert = true
            return
        }

        let db = Firestore.firestore()
        let userFavoritesRef = db.collection("favorites").document(username)

        userFavoritesRef.updateData([
            "movies": FieldValue.arrayRemove([movie.id])
        ]) { error in
            if let error = error {
                errorMessage = "Error removing from favorites: \(error.localizedDescription)"
                showErrorAlert = true
            } else {
                if let index = favoriteMovieIDs.firstIndex(of: movie.id) {
                    favoriteMovieIDs.remove(at: index) // Remove from local favorite IDs
                }
                print("Movie removed from favorites!")
            }
        }

    }
}

// Detailed view for the selected movie
struct MovieDetailView: View {
    let movie: Movie

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            if let posterURL = movie.posterURL {
                AsyncImage(url: posterURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(10)
                } placeholder: {
                    ProgressView()
                }
                .padding(.bottom, 10)
            }
            
            Text(movie.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 5)
            
            Text(movie.overview)
                .font(.body)
                .lineLimit(nil)
                .padding(.bottom, 20)
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 10)
        .padding()
    }
}

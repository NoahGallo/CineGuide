import SwiftUI
import Firebase
import FirebaseFirestore

struct FavoritesPage: View {
    @State private var favoriteMovies: [Movie] = []  // List of favorite movies
    @State private var showErrorAlert = false        // Alert for errors
    @State private var errorMessage = ""             // Error message to display
    @EnvironmentObject var authManager: AuthManager  // Use shared auth manager

    var body: some View {
        NavigationView {
            VStack {
                if favoriteMovies.isEmpty {
                    Text("No favorite movies yet!")
                        .font(.title)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(favoriteMovies) { movie in
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
                                    }
                                    .padding(.leading, 10)
                                    .frame(maxWidth: .infinity, alignment: .topLeading)
                                }
                                .frame(width: 350, height: 150)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                                .shadow(radius: 4)
                            }
                        }
                        .padding()
                    }
                }
            }
            .onAppear {
                Task {
                    await fetchFavoriteMovies()
                }
            }
            .alert(isPresented: $showErrorAlert) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
            .navigationTitle("Your Favorites")
        }
    }
    
    // Fetch the favorite movies from Firestore and then get movie details from TMDB API
    func fetchFavoriteMovies() async {
        guard let username = authManager.username else {
            errorMessage = "User not logged in."
            showErrorAlert = true
            return
        }

        let db = Firestore.firestore()
        let userFavoritesRef = db.collection("favorites").document(username)
        
        do {
            // Get the document with user's favorite movies
            let document = try await userFavoritesRef.getDocument()
            
            guard let data = document.data(), let movieIDs = data["movies"] as? [Int] else {
                errorMessage = "No favorite movies found."
                showErrorAlert = true
                return
            }
            
            // Fetch movie details for each movie ID
            favoriteMovies = try await fetchMoviesByIDs(movieIDs: movieIDs)
        } catch {
            errorMessage = "Failed to load favorites: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }

    // Fetch movies' details from TMDB API using their IDs
    func fetchMoviesByIDs(movieIDs: [Int]) async throws -> [Movie] {
        var movies: [Movie] = []
        guard let bearerToken = loadEnv()?["API_TMDB_TOKEN"] else {
            errorMessage = "Bearer Token is not loaded."
            showErrorAlert = true
            return []
        }
        
        for movieID in movieIDs {
            do {
                let urlString = "https://api.themoviedb.org/3/movie/\(movieID)?language=en-US"
                guard let url = URL(string: urlString) else {
                    errorMessage = "Invalid URL."
                    showErrorAlert = true
                    continue
                }

                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    let decoder = JSONDecoder()
                    let movie = try decoder.decode(Movie.self, from: data)
                    movies.append(movie)  // Add the movie to the list
                }
            } catch {
                errorMessage = "Failed to load movie with ID \(movieID): \(error.localizedDescription)"
                showErrorAlert = true
            }
        }
        return movies
    }

    // Load .env file for API keys
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
}

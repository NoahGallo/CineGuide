import SwiftUI
import Firebase
import FirebaseFirestore

// Movie model to represent the TMDB movie data
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
    
    // Computed property to get the full poster URL
    var posterURL: URL? {
        URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }
}

struct ContentView: View {
    @State private var movies: [Movie] = []  // State variable to hold movie data
    let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            VStack {
                if movies.isEmpty {
                    // If no movies are loaded, show the buttons
                    Button(action: {
                        Task {
                            await getMovies()
                        }
                    }, label: {
                        Text("Fetch Movies")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    })
                    
                    Button(action: {
                        Task {
                            await fetchFirestoreData()
                        }
                    }, label: {
                        Text("Fetch Firestore Data")
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    })
                } else {
                    // Display the fetched movies
                    List(movies) { movie in
                        HStack {
                            // Display movie poster
                            if let posterURL = movie.posterURL {
                                AsyncImage(url: posterURL) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100, height: 150)
                                } placeholder: {
                                    ProgressView()
                                }
                            }
                            // Display movie details
                            VStack(alignment: .leading, spacing: 10) {
                                Text(movie.title)
                                    .font(.headline)
                                Text(movie.overview)
                                    .font(.subheadline)
                                    .lineLimit(4)  // Limit the number of lines for the overview
                                    .padding(.top, 5)
                            }
                        }
                    }
                    .navigationTitle("Popular Movies")
                }
            }
        }
    }

    // Fetch movie data (TMDB API)
    func getMovies() async {
        // Load Bearer token from the .env file
        guard let bearerToken = loadEnv()?["API_TMDB_TOKEN"] else {
            print("Bearer Token is not loaded")
            return
        }

        do {
            // URL without API key query parameter
            let urlString = "https://api.themoviedb.org/3/movie/popular?language=en-US&page=1"
            guard let url = URL(string: urlString) else {
                print("Invalid URL")
                return
            }

            // Create the request and set the Authorization header with the Bearer token
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

            // Perform the API call
            let (data, response) = try await URLSession.shared.data(for: request)

            // Debugging: Check the HTTP status code
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 401 {
                    print("Unauthorized: Bearer token might be incorrect or expired")
                }
            }

            // Debugging: Print the raw response body for further analysis
            print("Raw Response: \(String(data: data, encoding: .utf8)!)")

            // If the response is successful, proceed with parsing the JSON
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let decoder = JSONDecoder()
                let movieResponse = try decoder.decode(MovieResponse.self, from: data)
                self.movies = movieResponse.results
                print("Movies loaded successfully")
            }
        } catch {
            print("Request failed with error: \(error)")
        }
    }

    // Fetch Firestore data
    func fetchFirestoreData() async {
        db.collection("utilisateurs").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting Firestore documents: \(error)")
            } else {
                for document in querySnapshot!.documents {
                    print("\(document.documentID) => \(document.data())")
                }
            }
        }
    }

    // Load the .env file
    func loadEnv() -> [String: String]? {
        guard let path = Bundle.main.path(forResource: ".env.xcconfig", ofType: nil) else {
            print(".env file not found")
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
            print("Error reading .env file: \(error)")
            return nil
        }
    }
}

// Movie response to map the results from TMDB API
struct MovieResponse: Codable {
    let results: [Movie]
}

#Preview {
    ContentView()
}

import SwiftUI
import Firebase
import FirebaseFirestore
import ModalView

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

struct BottomBar: View {
    let currentPage: Int
    let totalPages: Int
    let onPageChange: (Int) -> Void
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())  // Supprimer le style par défaut du bouton
            
            Spacer()
            
            let lowerBound = max(1, currentPage - 1)
            let upperBound = min(totalPages, currentPage + 1) <= totalPages - 1 ? currentPage + 1 : currentPage + 2
                        
            // Afficher les boutons pour chaque page
            ForEach(lowerBound...upperBound, id: \.self) { page in
                Button(action: {
                    onPageChange(page)
                }) {
                    Text("\(page)")
                        .padding()
                        .background(currentPage == page ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()

            Button(action: onNext) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())  // Supprimer le style par défaut du bouton
        }
        .padding()
        .background(Color.white)  // Fond blanc pour la barre
        .cornerRadius(12)  // Coins arrondis pour la barre
        .shadow(radius: 5)  // Ombre douce pour la barre
        .padding([.leading, .trailing], 20)  // Ajouter du padding pour éviter que la barre touche les bords
    }
}

struct ContentView: View {
    @State private var movies: [Movie] = []
    @State private var selectedMovie: Movie?
    @State private var showModal = false
    @State private var currentPage = 1
    let db = Firestore.firestore()

    var body: some View {
        
        NavigationView {
            VStack {
                if movies.isEmpty {
                    // If no movies are loaded, show the buttons
                    Button(action: {
                        Task {
                            await getMovies(currentPage: currentPage)
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
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(movies) { movie in
                                HStack(alignment: .top) {
                                    // Afficher l'affiche du film
                                    ZStack {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))  // Placeholder gris pour les images manquantes
                                            .frame(width: 100, height: 150)  // Taille fixe pour l'emplacement de l'image
                                        
                                        if let posterURL = movie.posterURL {
                                            AsyncImage(url: posterURL) { image in
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 100, height: 150)  // Taille fixe pour l'image
                                                    .cornerRadius(8)
                                            } placeholder: {
                                                ProgressView()
                                                    .frame(width: 100, height: 150)  // Assure que le placeholder a la même taille que l'image
                                            }
                                        }
                                    }
                                    
                                    // Afficher les détails du film
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text(movie.title)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                            .padding(.top, 10)  // Espace en haut du texte
                                        
                                        Text(movie.overview)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .lineLimit(4)  // Limiter le nombre de lignes du résumé
                                            .padding(.bottom, 5)  // Espace en bas du résumé
                                        
                                        HStack {
                                            // Ajout d'un logo "info"
                                            Image(systemName: "info.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(.blue)
                                        }
                                        .padding(.leading, 10)
                                        .frame(maxWidth: .infinity, alignment: .topLeading)  // Aligner le texte au-dessus de l'image
                                    }
                                    .padding(.leading, 10)
                                    .frame(maxWidth: .infinity, alignment: .topLeading)  // Aligner le texte au-dessus de l'image
                                }
                                .frame(width: 350, height: 150)  // Taille fixe pour chaque carte
                                .background(Color.gray.opacity(0.2))  // Fond gris pour la carte
                                .cornerRadius(12)  // Coins arrondis pour la carte
                                .shadow(radius: 4)  // Ombre douce pour la carte
                                .onTapGesture {
                                    onClickCard(movie: movie)
                                }
                            }

                        }
                        .padding()
                    }
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
            }
            .navigationTitle("Popular Movies")
            .sheet(isPresented: $showModal) {
                if let selectedMovie = selectedMovie {
                    MovieDetailView(movie: selectedMovie)
                }
            }
        }
    }

    @State private var totalPages: Int = 1
    // Fetch movie data (TMDB API)
    func getMovies(currentPage: Int) async {
        // Load Bearer token from the .env file
        guard let bearerToken = loadEnv()?["API_TMDB_TOKEN"] else {
            print("Bearer Token is not loaded")
            return
        }

        do {
            let urlString = "https://api.themoviedb.org/3/movie/popular?language=en-US&page=\(currentPage)"
            guard let url = URL(string: urlString) else {
                print("Invalid URL")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 401 {
                    print("Unauthorized: Bearer token might be incorrect or expired")
                }
            }

            print("Raw Response: \(String(data: data, encoding: .utf8)!)")

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let decoder = JSONDecoder()
                let movieResponse = try decoder.decode(MovieResponse.self, from: data)
                self.movies = movieResponse.results
                self.totalPages = movieResponse.totalPages  // Mettre à jour le total des pages
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

    func onClickCard(movie: Movie) {
        selectedMovie = movie
        showModal = true
    }
}

// Movie response to map the results from TMDB API
struct MovieResponse: Codable {
    let results: [Movie]
    let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case results
        case totalPages = "total_pages"
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
                        .cornerRadius(10)  // Coins arrondis pour l'image
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
                .lineLimit(nil)  // Afficher tout le texte
                .padding(.bottom, 20)
            
            Spacer()
        }
        .padding()
        .background(Color.white)  // Fond blanc pour la modal
        .cornerRadius(12)  // Coins arrondis pour la modal
        .shadow(radius: 10)  // Ombre douce pour la modal
        .padding()  // Ajouter du padding pour éviter que la modal touche les bords de l'écran
    }
}

#Preview {
    ContentView()
}

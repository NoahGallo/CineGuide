import SwiftUI
import Firebase
import FirebaseFirestore

struct ContentView: View {
    @State private var apiKey: String?
    let db = Firestore.firestore()

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            
            Button(action: {
                Task {
                    await getMovies()
                }
            }, label: {
                Text("Fetch Movies")
            })
            
            Button(action: {
                Task {
                    await fetchFirestoreData()
                }
            }, label: {
                Text("Fetch Firestore Data")
            })
        }
        .padding()
        .task {
            await loadApiKey()
            await checkAuth()
        }
    }

    // Load the API key at launch
    func loadApiKey() async {
        if let env = loadEnv(), let key = env["API_TMDB_KEY"] {
            apiKey = key
            print("API Key loaded: \(key)")
        } else {
            print("API_TMDB_KEY not found in .env file")
        }
    }

    // Authenticate TMDB API
    func checkAuth() async {
        guard let apiKey = apiKey else {
            print("API Key is not loaded")
            return
        }

        do {
            let url = URL(string: "https://api.themoviedb.org/3/authentication")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 10
            request.allHTTPHeaderFields = [
                "accept": "application/json",
                "Authorization": "Bearer \(apiKey)"
            ]

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("HTTP error: \(httpResponse.statusCode)")
                return
            }

            print(String(decoding: data, as: UTF8.self))
        } catch {
            print("Request failed with error: \(error)")
        }
    }

    // Fetch movie data (TMDB API)
    func getMovies() async {
        await checkAuth()
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

#Preview {
    ContentView()
}

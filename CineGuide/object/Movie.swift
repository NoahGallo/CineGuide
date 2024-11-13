//
//  Movie.swift
//  CineGuide
//
//  Created by Etudiant on 17/09/2024.
//

import Foundation

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

struct MovieDetail: Codable {
    let id: Int
    let title: String
    let overview: String
    let releaseDate: String
    let runtime: Int
    let voteAverage: Double
    let genres: [Genre]
    let posterPath: String?  // Optional in case it's missing

    enum CodingKeys: String, CodingKey {
        case id, title, overview, runtime
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case genres
        case posterPath = "poster_path"  // Map to API's "poster_path"
    }
    
    // Computed property for poster URL with nil handling
    var posterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }
}


struct Genre: Codable {
    let name: String
}

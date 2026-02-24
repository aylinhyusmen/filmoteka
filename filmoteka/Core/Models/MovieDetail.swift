import Foundation

struct MediaDetail: Codable, Identifiable, Sendable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double?
    let runtime: Int?
    let genres: [Genre]?
    let status: String?
    let tagline: String?
    
    var formattedRuntime: String {
        if let runtime, runtime > 0 {
            let hours = runtime / 60
            let minutes = runtime % 60
            
            return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
        }
        
        return "N/A"
    }
    
    var genreText: String {
        if let firstGenre = genres?.first {
            return firstGenre.name
        } else {
            return "N/A"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, overview, runtime, genres, status, tagline
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
    }
}

struct Genre: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
}

struct MediaCategory: Sendable {
    let name: String
    let movies: [MediaItem]
}

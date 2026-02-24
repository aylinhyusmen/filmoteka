import Foundation

struct MediaItem: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let posterPath: String?
    let backdropPath: String?
    let mediaType: String?
    let title: String?
    let name: String?
    let originalTitle: String?
    let overview: String?
    let voteAverage: Double?
    let releaseDate: String?
        
    var displayTitle: String {
        return title ?? name ?? originalTitle ?? "Unknown"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, name, overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case mediaType = "media_type"
        case originalTitle = "original_title"
        case voteAverage = "vote_average"
        case releaseDate = "release_date"
    }
}

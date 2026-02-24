import Foundation

struct WatchedMovie: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let createdAt: String?
    let userID: UUID
    let movieID: Int
    let title: String?
    let posterPath: String?
    let runtime: Int?
    let rating: Int?
    let genre: String?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, runtime, rating, genre, notes
        case createdAt = "created_at"
        case userID = "user_id"
        case movieID = "movie_id"
        case posterPath = "poster_path"
    }
}

struct WatchedMovieInsert: Encodable, Sendable {
    let userID: UUID
    let movieID: Int
    let title: String?
    let posterPath: String?
    let runtime: Int?
    let rating: Int?
    let genre: String?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case title, runtime, rating, genre, notes
        case userID = "user_id"
        case movieID = "movie_id"
        case posterPath = "poster_path"
    }
}

struct WatchlistMovieInsert: Encodable, Sendable {
    let userID: UUID
    let movieID: Int
    let title: String?
    let posterPath: String?
    let runtime: Int?
    let genre: String?
    
    enum CodingKeys: String, CodingKey {
        case title, runtime, genre
        case userID = "user_id"
        case movieID = "movie_id"
        case posterPath = "poster_path"
    }
}

struct WatchlistMovie: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let createdAt: String?
    let userID: UUID
    let movieID: Int
    let title: String?
    let posterPath: String?
    let runtime: Int?
    let genre: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, runtime, genre
        case createdAt = "created_at"
        case userID = "user_id"
        case movieID = "movie_id"
        case posterPath = "poster_path"
    }
}

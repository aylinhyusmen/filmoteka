import Foundation

struct UserProfile: Codable, Identifiable, Sendable {
    let id: UUID
    let createdAt: String?
    let username: String?
    let avatarURL: String?
    let favoriteMovie: Int?
    let topThreeMovies: [Int]?
    let email: String?

    enum CodingKeys: String, CodingKey {
        case id, username, email
        case createdAt = "created_at"
        case avatarURL = "avatar_url"
        case favoriteMovie = "favorite_movie_id"
        case topThreeMovies = "top_three_movies_id"
    }
}

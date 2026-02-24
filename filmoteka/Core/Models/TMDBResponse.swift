import Foundation

struct TMDBResponse: Codable, Sendable {
    let results: [MediaItem]
}

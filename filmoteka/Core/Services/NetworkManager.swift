import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse(statusCode: Int)
    case decodingError(Error)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "invalid url"
        case .invalidResponse: return "invalid response"
        case .decodingError: return "bad decode"
        case .unknown: return "error"
        }
    }
}

final class NetworkManager: Sendable {
    
    static let shared = NetworkManager()
    
    private let session: URLSession
    
    private init(session: URLSession = .shared) {
        self.session = session
    }
    
    private enum Constants {
        static let baseURL = "https://api.themoviedb.org/3"
        static let baseImageURL = "https://image.tmdb.org/t/p/"
        static let apiKey = Bundle.main.secret(named: "TMDB_API_KEY")
    }
    
    private func buildURL(endpoint: String, queryItems: [URLQueryItem] = []) throws -> URL {
        guard var components = URLComponents(string: "\(Constants.baseURL)/\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        let defaultQueryItems = [
            URLQueryItem(name: "api_key", value: Constants.apiKey),
            URLQueryItem(name: "language", value: "en-US")
        ]
        
        components.queryItems = defaultQueryItems + queryItems
        
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        
        return url
    }
    
    private func fetch<T: Decodable>(endpoint: String, queryItems: [URLQueryItem] = []) async throws -> T {
        let url = try buildURL(endpoint: endpoint, queryItems: queryItems)
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse(statusCode: 0)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse(statusCode: httpResponse.statusCode)
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
    
    func fetchUpcomingMovies() async throws -> [MediaItem] {
        let response: TMDBResponse = try await fetch(endpoint: "movie/upcoming")
        return response.results
    }
    
    func fetchNowPlayingMovies() async throws -> [MediaItem] {
        let response: TMDBResponse = try await fetch(endpoint: "movie/now_playing")
        return response.results
    }
    
    func fetchTopRatedMovies() async throws -> [MediaItem] {
        let response: TMDBResponse = try await fetch(endpoint: "movie/top_rated")
        return response.results
    }
    
    func fetchPopularMovies() async throws -> [MediaItem] {
        let response: TMDBResponse = try await fetch(endpoint: "movie/popular")
        return response.results
    }
    
    func fetchMovieDetails(movieID: Int) async throws -> MediaDetail {
        return try await fetch(endpoint: "movie/\(movieID)")
    }
    
    func fetchMovieCredits(movieID: Int) async throws -> [CastMember] {
        let response: MovieCreditsResponse = try await fetch(endpoint: "movie/\(movieID)/credits")
        return response.cast
    }
    
    func fetchOnTheAirTVs() async throws -> [MediaItem] {
        let response: TMDBResponse = try await fetch(endpoint: "tv/on_the_air")
        return response.results
    }
    
    func fetchPopularTVs() async throws -> [MediaItem] {
        let response: TMDBResponse = try await fetch(endpoint: "tv/popular")
        return response.results
    }
    
    func fetchTopRatedTVs() async throws -> [MediaItem] {
        let response: TMDBResponse = try await fetch(endpoint: "tv/top_rated")
        return response.results
    }
    
    func fetchTrendingTVs() async throws -> [MediaItem] {
        let response: TMDBResponse = try await fetch(endpoint: "trending/tv/day")
        return response.results
    }
    
    func searchMovies(query: String) async throws -> [MediaItem] {
        let queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "include_adult", value: "false")
        ]
        
        let response: TMDBResponse = try await fetch(endpoint: "search/movie", queryItems: queryItems)
        return response.results
    }
}

extension Bundle {
    func secret(named key: String) -> String {
        guard let path = path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let value = dict[key] as? String else {
            fatalError("Missing \(key) in Secrets.plist")
        }
        return value
    }
}

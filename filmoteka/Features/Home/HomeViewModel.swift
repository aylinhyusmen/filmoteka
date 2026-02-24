import Foundation
import Supabase

@MainActor
final class HomeViewModel {
    
    enum FeedMode: Int {
        case movies = 0
        case tvShows = 1
    }
    
    var onFeedUpdated: (() -> Void)?
    var onSearchUpdated: (() -> Void)?
    var onError: ((Error) -> Void)?
    
    private(set) var upcomingMedia: [MediaItem] = []
    private(set) var categories: [MediaCategory] = []
    private(set) var searchResults: [MediaItem] = []
    
    var currentMode: FeedMode = .movies {
        didSet {
            guard currentMode != oldValue else { return }
            fetchData()
        }
    }
    
    var isUserLogged: Bool {
        guard let session = SupabaseManager.shared.client.auth.currentSession else { return false }
        return !session.isExpired
    }
    
    private var feedTask: Task<Void, Never>?
    private var searchTask: Task<Void, Never>?
    private let searchManager = MovieSearchManager()
    
    func fetchDataIfNeeded() {
        guard categories.isEmpty else { return }
        fetchData()
    }
    
    func fetchData() {
        feedTask?.cancel()
        upcomingMedia.removeAll()
        categories.removeAll()
        onFeedUpdated?()
        
        feedTask = Task { [weak self] in
            guard let self else { return }
            switch self.currentMode {
            case .movies:  await self.fetchMovieFeed()
            case .tvShows: await self.fetchTVFeed()
            }
        }
    }
    
    func cancelFeed() {
        feedTask?.cancel()
        searchManager.cancel()
    }
    
    func search(query: String) {
        searchTask?.cancel()
        
        searchTask = Task { [weak self] in
            guard let self else { return }
            do {
                self.searchResults = try await self.searchManager.performSearch(query: query)
                self.onSearchUpdated?()
            } catch {
                print("Search error: \(error.localizedDescription)")
            }
        }
    }
    
    private func fetchMovieFeed() async {
        do {
            async let fetchUpcoming   = NetworkManager.shared.fetchUpcomingMovies()
            async let fetchNowPlaying = NetworkManager.shared.fetchNowPlayingMovies()
            async let fetchTopRated   = NetworkManager.shared.fetchTopRatedMovies()
            async let fetchPopular    = NetworkManager.shared.fetchPopularMovies()
            
            let (upcoming, nowPlaying, topRated, popular) = try await (fetchUpcoming, fetchNowPlaying, fetchTopRated, fetchPopular)
            
            upcomingMedia = upcoming
            categories = [
                MediaCategory(name: "Now Playing", movies: nowPlaying),
                MediaCategory(name: "Top Rated",   movies: topRated),
                MediaCategory(name: "Popular",      movies: popular)
            ]
            onFeedUpdated?()
            
        } catch {
            onError?(error)
        }
    }
    
    private func fetchTVFeed() async {
        do {
            async let fetchOnAir    = NetworkManager.shared.fetchOnTheAirTVs()
            async let fetchTrending = NetworkManager.shared.fetchTrendingTVs()
            async let fetchPopular  = NetworkManager.shared.fetchPopularTVs()
            async let fetchTopRated = NetworkManager.shared.fetchTopRatedTVs()
            
            let (onAir, trending, popular, topRated) = try await (fetchOnAir, fetchTrending, fetchPopular, fetchTopRated)
            
            upcomingMedia = onAir
            categories = [
                MediaCategory(name: "Trending Today", movies: trending),
                MediaCategory(name: "Popular on TV",  movies: popular),
                MediaCategory(name: "Top Rated TV",   movies: topRated)
            ]
            onFeedUpdated?()
            
        } catch {
            onError?(error)
        }
    }
}

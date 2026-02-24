import Foundation
import UIKit

@MainActor
final class UserProfileViewModel {
    
    var onDataFetched: (() -> Void)?
    var onError: ((String) -> Void)?
    var onCriticalError: ((Error) -> Void)?
    var onAvatarUploadSuccess: (() -> Void)?
    var onMovieRemoved: ((IndexPath, Bool) -> Void)?
    var onFavoriteMovieLoaded: ((Int, MediaItem) -> Void)?
    // TODO: should navigate to home root.
    var onNavigateToLogin: (() -> Void)?
    var onNavigateToMovieDetail: ((MediaItem) -> Void)?
    
    private(set) var profile: UserProfile?
    private(set) var watchedMovies: [WatchedMovie] = []
    private(set) var watchlistMovies: [WatchlistMovie] = []
    private(set) var favoriteMoviesData: [Int: MediaItem] = [:]
    
    private var fetchTask: Task<Void, Never>?
    private var actionTask: Task<Void, Never>?
    
    var displayUsername: String {
        profile?.username ?? "Username"
    }
    
    var totalWatchTimeText: String {
        let totalMinutes = watchedMovies.compactMap { $0.runtime }.reduce(0, +)
        return "\(totalMinutes / 60)h \(totalMinutes % 60)m"
    }
    
    var mostWatchedGenreText: String {
        var genreCounts: [String: Int] = [:]
        for movie in watchedMovies {
            if let genre = movie.genre {
                genreCounts[genre, default: 0] += 1
            }
        }
        return genreCounts.max(by: { $0.value < $1.value })?.key ?? "N/A"
    }
    
    func fetchData() {
        fetchTask?.cancel()
        
        fetchTask = Task { [weak self] in
            guard let self else { return }
            
            do {
                async let fetchedProfile = SupabaseManager.shared.fetchUserProfile()
                async let fetchedWatched = SupabaseManager.shared.fetchWatchedMovies()
                async let fetchedWatchlist = SupabaseManager.shared.fetchWatchlistMovies()
                
                let (newProfile, newWatched, newWatchlist) = try await (fetchedProfile, fetchedWatched, fetchedWatchlist)
                
                self.profile = newProfile
                self.watchedMovies = newWatched
                self.watchlistMovies = newWatchlist
                
                self.loadFavoritesData()
                self.onDataFetched?()
                
            } catch {
                self.onError?("Failed to load profile data. Please check your connection.")
            }
        }
    }
    
    private func loadFavoritesData() {
        favoriteMoviesData.removeAll()
        
        if let favId = profile?.favoriteMovie {
            fetchAndSetFavorite(forID: favId, inSlot: 1)
        }
        
        if let topThree = profile?.topThreeMovies {
            for (index, movieID) in topThree.enumerated() {
                fetchAndSetFavorite(forID: movieID, inSlot: index + 2)
            }
        }
    }
    
    private func fetchAndSetFavorite(forID movieID: Int, inSlot slot: Int) {
        Task { [weak self] in
            guard let self else { return }
            do {
                let detail = try await NetworkManager.shared.fetchMovieDetails(movieID: movieID)
                
                let movie = MediaItem(
                    id: detail.id, posterPath: detail.posterPath, backdropPath: detail.backdropPath,
                    mediaType: nil, title: detail.title, name: nil, originalTitle: nil,
                    overview: detail.overview, voteAverage: detail.voteAverage, releaseDate: detail.releaseDate
                )
                
                self.favoriteMoviesData[slot] = movie
                self.onFavoriteMovieLoaded?(slot, movie)
            } catch {
                print("Failed to load favorite movie for slot \(slot)")
            }
        }
    }
    
    func removeMovie(at indexPath: IndexPath, isWatchedList: Bool) {
        actionTask?.cancel()
        
        actionTask = Task { [weak self] in
            guard let self else { return }
            
            do {
                if isWatchedList {
                    let movieID = self.watchedMovies[indexPath.row].movieID
                    try await SupabaseManager.shared.removeFromWatched(movieID: movieID)
                    self.watchedMovies.remove(at: indexPath.row)
                } else {
                    let movieID = self.watchlistMovies[indexPath.row].movieID
                    try await SupabaseManager.shared.removeFromWatchlist(movieID: movieID)
                    self.watchlistMovies.remove(at: indexPath.row)
                }
                
                self.onMovieRemoved?(indexPath, isWatchedList)
                self.onDataFetched?()
                
            } catch {
                self.onError?("Failed to remove movie")
            }
        }
    }
    
    func selectMovie(at indexPath: IndexPath, isWatchedList: Bool) {
        let movieID = isWatchedList ? watchedMovies[indexPath.row].movieID : watchlistMovies[indexPath.row].movieID
        
        actionTask?.cancel()
        actionTask = Task { [weak self] in
            guard let self else { return }
            do {
                let details = try await NetworkManager.shared.fetchMovieDetails(movieID: movieID)
                let fullMovie = MediaItem(
                    id: details.id, posterPath: details.posterPath, backdropPath: details.backdropPath,
                    mediaType: nil, title: details.title, name: nil, originalTitle: nil,
                    overview: details.overview, voteAverage: details.voteAverage, releaseDate: details.releaseDate
                )
                self.onNavigateToMovieDetail?(fullMovie)
            } catch {
                self.onError?("Could not load movie details.")
            }
        }
    }
    
    func updateFavoriteMovie(_ mediaItem: MediaItem, forSlot slot: Int) {
        favoriteMoviesData[slot] = mediaItem
        onFavoriteMovieLoaded?(slot, mediaItem)
        
        actionTask?.cancel()
        
        actionTask = Task { [weak self] in
            guard let self else { return }
            do {
                if slot == 1 {
                    try await SupabaseManager.shared.updateFavoriteMovie(movieID: mediaItem.id)
                } else {
                    let topThreeIDs = [2, 3, 4].compactMap { self.favoriteMoviesData[$0]?.id }
                    try await SupabaseManager.shared.updateTopThree(movieIDs: topThreeIDs)
                }
                
                let hasSeenMovie = self.watchedMovies.contains { $0.movieID == mediaItem.id }
                
                if !hasSeenMovie {
                    let detail = try await NetworkManager.shared.fetchMovieDetails(movieID: mediaItem.id)
                    try await SupabaseManager.shared.addToWatched(
                        movieID: mediaItem.id, title: mediaItem.displayTitle, posterPath: mediaItem.posterPath,
                        runtime: detail.runtime ?? 0, genre: detail.genres?.first?.name, rating: 0, notes: nil
                    )
                }
                self.fetchData()
                
            } catch {
                self.onError?("Failed to save your favorite movie.")
                self.fetchData()
            }
        }
    }
    
    func uploadAvatar(data: Data) {
        actionTask?.cancel()
        
        actionTask = Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await SupabaseManager.shared.updateAvatar(data: data)
                self.profile = try? await SupabaseManager.shared.fetchUserProfile()
                self.onAvatarUploadSuccess?()
            } catch {
                self.onError?("Avatar upload failed")
            }
        }
    }
    
    func signOut() {
        actionTask?.cancel()
        actionTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await SupabaseManager.shared.signOut()
                self.onNavigateToLogin?()
            } catch {
                self.onError?("Sign out failed. Please try again.")
            }
        }
    }
    
    func deleteAccount() {
        actionTask?.cancel()
        actionTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await SupabaseManager.shared.deleteAccount()
                self.onNavigateToLogin?()
            } catch {
                self.onError?("Failed to delete account")
            }
        }
    }
    
    func cancelTasks() {
        fetchTask?.cancel()
        actionTask?.cancel()
    }
}

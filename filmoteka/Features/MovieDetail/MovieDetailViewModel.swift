import Foundation

@MainActor
final class MovieDetailViewModel {
    
    var onDetailsFetched: (() -> Void)?
    var onCastFetched: (() -> Void)?
    var onWatchStatusUpdated: (() -> Void)?
    var onNoteUpdated: ((String?) -> Void)?
    var onError: ((String) -> Void)?
    var onSaveSuccess: (() -> Void)?
    
    let mediaItem: MediaItem
    private(set) var movieDetails: MediaDetail?
    private(set) var cast: [CastMember] = []
    
    private(set) var isWatchlisted: Bool = false
    private(set) var isWatched: Bool = false
    private(set) var savedNote: String?
    
    private var fetchTask: Task<Void, Never>?
    private var actionTask: Task<Void, Never>?
    
    init(mediaItem: MediaItem) {
        self.mediaItem = mediaItem
    }
    
    func fetchData() {
        fetchTask?.cancel()
        
        fetchTask = Task { [weak self] in
            guard let self else { return }
            let movieID = self.mediaItem.id
            
            // TMDB Fetch
            do {
                async let fetchDetails = NetworkManager.shared.fetchMovieDetails(movieID: movieID)
                async let fetchCredits = NetworkManager.shared.fetchMovieCredits(movieID: movieID)
                
                let (details, credits) = try await (fetchDetails, fetchCredits)
                
                self.movieDetails = details
                self.cast = credits.actorsOnly
                
                self.onDetailsFetched?()
                self.onCastFetched?()
            } catch {
                print("TMDB fetch error: \(error)")
            }
            
            // Supabase Fetch
            do {
                async let fetchWatched = SupabaseManager.shared.fetchWatchedMovies()
                async let fetchWatchlist = SupabaseManager.shared.fetchWatchlistMovies()
                
                let (watchedList, watchList) = try await (fetchWatched, fetchWatchlist)
                
                self.isWatched = watchedList.contains { $0.movieID == movieID }
                self.isWatchlisted = watchList.contains { $0.movieID == movieID }
                self.savedNote = watchedList.first(where: { $0.movieID == movieID })?.notes
                
                self.onWatchStatusUpdated?()
                self.onNoteUpdated?(self.savedNote)
                
            } catch {
                print("Supabase fetch error: \(error)")
                self.isWatched = false
                self.isWatchlisted = false
                self.onWatchStatusUpdated?()
            }
        }
    }
    
    func toggleWatchlist() {
        actionTask?.cancel()
        
        actionTask = Task { [weak self] in
            guard let self else { return }
            let movieID = self.mediaItem.id
            
            do {
                if self.isWatchlisted {
                    try await SupabaseManager.shared.removeFromWatchlist(movieID: movieID)
                    self.isWatchlisted = false
                } else {
                    try await SupabaseManager.shared.addToWatchlist(
                        movieID: movieID,
                        title: self.mediaItem.displayTitle,
                        posterPath: self.mediaItem.posterPath,
                        runtime: self.movieDetails?.runtime ?? 0,
                        genre: self.movieDetails?.genreText
                    )
                    self.isWatchlisted = true
                }
                self.onWatchStatusUpdated?()
                
            } catch {
                self.onError?("Failed to update watchlist")
            }
        }
    }
    
    func removeWatchedMovie() {
        actionTask?.cancel()
        
        actionTask = Task { [weak self] in
            guard let self else { return }
            
            do {
                try await SupabaseManager.shared.removeFromWatched(movieID: self.mediaItem.id)
                self.isWatched = false
                self.savedNote = nil
                self.onWatchStatusUpdated?()
                self.onNoteUpdated?(nil)
            } catch {
                self.onError?("Failed to remove movie")
            }
        }
    }
    
    func saveWatchedMovie(rating: Int, notes: String?) {
        actionTask?.cancel()
        
        actionTask = Task { [weak self] in
            guard let self else { return }
            
            do {
                try await SupabaseManager.shared.addToWatched(
                    movieID: self.mediaItem.id,
                    title: self.mediaItem.displayTitle,
                    posterPath: self.mediaItem.posterPath,
                    runtime: self.movieDetails?.runtime ?? 0,
                    genre: self.movieDetails?.genreText,
                    rating: rating,
                    notes: notes
                )
                
                self.isWatched = true
                self.isWatchlisted = false
                self.savedNote = notes
                
                self.onNoteUpdated?(notes)
                self.onWatchStatusUpdated?()
                self.onSaveSuccess?()
                
            } catch {
                self.onError?("Could not save movie.")
            }
        }
    }
    
    func cancelTasks() {
        fetchTask?.cancel()
        actionTask?.cancel()
    }
}

import Foundation

@MainActor
final class MovieSearchViewModel {
    
    var onSearchResultsUpdated: (() -> Void)?
    var onError: ((String) -> Void)?
    
    private(set) var searchResults: [MediaItem] = []
    
    private let searchManager = MovieSearchManager()
    private var searchTask: Task<Void, Never>?
    
    func search(query: String) {
        searchTask?.cancel()
        
        guard !query.isEmpty else {
            searchResults = []
            onSearchResultsUpdated?()
            return
        }
        
        searchTask = Task { [weak self] in
            guard let self else { return }
            
            do {
                self.searchResults = try await self.searchManager.performSearch(query: query)
                self.onSearchResultsUpdated?()
            } catch {
                self.onError?(error.localizedDescription)
            }
        }
    }
    
    func cancelSearch() {
        searchTask?.cancel()
        searchManager.cancel()
    }
    
    func movie(at index: Int) -> MediaItem? {
        guard searchResults.indices.contains(index) else { return nil }
        return searchResults[index]
    }
}

import Foundation

@MainActor
final class MovieSearchManager {
    
    private var debounceTask: Task<[MediaItem], Error>?
    private let debounceDelay: UInt64 = 300_000_000 // 0.3 seconds
    
    func performSearch(query: String) async throws -> [MediaItem] {
        debounceTask?.cancel()
        
        let cleaned = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleaned.isEmpty else {
            return []
        }
        
        let task = Task {
            try await Task.sleep(nanoseconds: debounceDelay)
            return try await NetworkManager.shared.searchMovies(query: cleaned)
        }
        
        debounceTask = task
        return try await task.value
    }
    
    func cancel() {
        debounceTask?.cancel()
    }
}

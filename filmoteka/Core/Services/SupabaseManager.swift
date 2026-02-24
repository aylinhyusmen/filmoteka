import Foundation
import Supabase
import UIKit

enum SupabaseError: Error, LocalizedError {
    case missingSession
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .missingSession:
            return "user not logged in"
        case .unknown:
            return "database error"
        }
    }
}

final class SupabaseManager {
    
    static let shared = SupabaseManager()
    
    private enum Constants {
        static let profilesTable = "profiles"
        static let watchedMoviesTable = "watched_movies"
        static let watchlistMoviesTable = "watchlist_movies"
        static let avatarsBucket = "avatars"
        static let supabaseURL = URL(string: Bundle.main.secret(named: "SUPABASE_URL"))!
        static let supabaseKey = Bundle.main.secret(named: "SUPABASE_KEY")
    }
    
    let client = SupabaseClient(
        supabaseURL: Constants.supabaseURL,
        supabaseKey: Constants.supabaseKey,
        options: SupabaseClientOptions(auth: .init(emitLocalSessionAsInitialSession: true))
    )

    private init() {}
    
    // account stuff
    
    func signUp(email: String, password: String, username: String) async throws -> User {
        let metadata: [String: AnyJSON] = [
            "username": .string(username),
            "email": .string(email)
        ]
        
        let response = try await client.auth.signUp(
            email: email,
            password: password,
            data: metadata
        )
        
        return response.user
    }
    
    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }
    
    func forgotPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(
            email,
            redirectTo: URL(string: "cinetecaapp://reset-password")
        )
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    func deleteAccount() async throws {
        try await client.functions.invoke("delete_user")
        try await client.auth.signOut()
    }
    
    func handleDeepLink(_ url: URL) async throws {
        try await client.auth.session(from: url)
    }
    
    func resetPassword(newPassword: String) async throws {
        let attributes = UserAttributes(password: newPassword)
        try await client.auth.update(user: attributes)
        try await signOut()
    }
    
    // database stuff
    
    private func requireUser() throws -> User {
        guard let user = client.auth.currentSession?.user else {
            throw SupabaseError.missingSession
        }
        return user
    }
    
    func addToWatched(movieID: Int, title: String, posterPath: String?, runtime: Int, genre: String?, rating: Int, notes: String?) async throws {
        let user = try requireUser()
        // TODO: extract to extension
        let insertData = WatchedMovieInsert(
            userID: user.id,
            movieID: movieID,
            title: title,
            posterPath: posterPath,
            runtime: runtime,
            rating: rating,
            genre: genre,
            notes: notes
        )
        
        try await client
            .from(Constants.watchedMoviesTable)
            .upsert(insertData)
            .execute()
        
        try await removeFromWatchlist(movieID: movieID)
    }
    
    func updateFavoriteMovie(movieID: Int) async throws {
        let user = try requireUser()
        
        try await client
            .from(Constants.profilesTable)
            .update(["favorite_movie_id": movieID])
            .eq("id", value: user.id)
            .execute()
    }
    
    func updateTopThree(movieIDs: [Int]) async throws {
        let user = try requireUser()
        
        let updateData: [String: AnyJSON] = [
            "top_three_movies_id": .array(movieIDs.map { movieID in
                return .integer(movieID)
            })
        ]
        
        try await client
            .from(Constants.profilesTable)
            .update(updateData)
            .eq("id", value: user.id)
            .execute()
    }
    
    func fetchUserProfile() async throws -> UserProfile {
        let user = try requireUser()
        
        return try await client
            .from(Constants.profilesTable)
            .select()
            .eq("id", value: user.id)
            .single()
            .execute()
            .value
    }
    
    func fetchWatchedMovies() async throws -> [WatchedMovie] {
        let user = try requireUser()
        
        return try await client
            .from(Constants.watchedMoviesTable)
            .select()
            .eq("user_id", value: user.id)
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    func fetchWatchlistMovies() async throws -> [WatchlistMovie] {
        let user = try requireUser()
        
        return try await client
            .from(Constants.watchlistMoviesTable)
            .select()
            .eq("user_id", value: user.id)
            .execute()
            .value
    }
    
    func addToWatchlist(movieID: Int, title: String, posterPath: String?, runtime: Int, genre: String?) async throws {
        let user = try requireUser()
        
        let insertData = WatchlistMovieInsert(
            userID: user.id,
            movieID: movieID,
            title: title,
            posterPath: posterPath,
            runtime: runtime,
            genre: genre
        )
        
        try await client
            .from(Constants.watchlistMoviesTable)
            .insert(insertData)
            .execute()
    }
    
    func removeFromWatchlist(movieID: Int) async throws {
        let user = try requireUser()
        
        try await client
            .from(Constants.watchlistMoviesTable)
            .delete()
            .eq("user_id", value: user.id)
            .eq("movie_id", value: movieID)
            .execute()
    }
    
    func removeFromWatched(movieID: Int) async throws {
        let user = try requireUser()
        
        try await client
            .from(Constants.watchedMoviesTable)
            .delete()
            .eq("user_id", value: user.id)
            .eq("movie_id", value: movieID)
            .execute()
    }
    
    func updateAvatar(data: Data) async throws -> String {
        let user = try requireUser()
        
        let path = "\(user.id.uuidString)/avatar.jpg"
        
        try await client.storage
            .from(Constants.avatarsBucket)
            .upload(
                path,
                data: data,
                options: FileOptions(contentType: "image/jpeg", upsert: true)
            )
        
        let publicURL = try client.storage
            .from(Constants.avatarsBucket)
            .getPublicURL(path: path)
        
        try await client
            .from(Constants.profilesTable)
            .update(["avatar_url": publicURL.absoluteString])
            .eq("id", value: user.id)
            .execute()
        
        return publicURL.absoluteString
    }
}

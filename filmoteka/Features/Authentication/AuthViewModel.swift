import Foundation

@MainActor
final class AuthViewModel {
    
    var onLoginSuccess: (() -> Void)?
    var onForgotPasswordSuccess: (() -> Void)?
    var onError: ((String) -> Void)?
    var onLoading: ((Bool) -> Void)?
    
    private var authTask: Task<Void, Never>?
    
    func login(email: String?, password: String?) {
        guard let email, !email.isEmpty, let password, !password.isEmpty else {
            onError?("Please enter both email and password.")
            return
        }
        
        onLoading?(true)
        authTask?.cancel()
        
        authTask = Task { [weak self] in
            guard let self else { return }
            
            do {
                try await SupabaseManager.shared.signIn(email: email, password: password)
                self.onLoading?(false)
                self.onLoginSuccess?()
            } catch {
                self.onLoading?(false)
                self.onError?("We couldn't log you in with those credentials.")
            }
        }
    }
    
    func forgotPassword(email: String?) {
        guard let email, !email.isEmpty else {
            onError?("Please enter your email to reset your password.")
            return
        }
        
        onLoading?(true)
        authTask?.cancel()
        
        authTask = Task { [weak self] in
            guard let self else { return }
            
            do {
                try await SupabaseManager.shared.forgotPassword(email: email)
                self.onLoading?(false)
                self.onForgotPasswordSuccess?()
            } catch {
                self.onLoading?(false)
                self.onError?("Unable to send. Try again later.")
            }
        }
    }
    
    func cancelTasks() {
        authTask?.cancel()
    }
}

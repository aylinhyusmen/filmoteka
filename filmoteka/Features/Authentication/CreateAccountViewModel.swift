import Foundation

@MainActor
final class CreateAccountViewModel {
    
    var onSuccess: (() -> Void)?
    var onError: ((String) -> Void)?
    var onLoading: ((Bool) -> Void)?
    
    private var signUpTask: Task<Void, Never>?
    
    func createAccount(email: String?, password: String?, confirmPassword: String?, username: String?) {
        guard let email, !email.isEmpty,
              let password, !password.isEmpty,
              let username, !username.isEmpty,
              let confirmPassword, password == confirmPassword
        else {
            onError?("Please enter all fields correctly.")
            return
        }
        
        onLoading?(true)
        signUpTask?.cancel()
        
        signUpTask = Task { [weak self] in
            guard let self else { return }
            
            do {
                _ = try await SupabaseManager.shared.signUp(email: email, password: password, username: username)
                self.onLoading?(false)
                self.onSuccess?()
            } catch {
                self.onLoading?(false)
                self.onError?(error.localizedDescription)
            }
        }
    }
    
    func cancelSignUp() {
        signUpTask?.cancel()
    }
}

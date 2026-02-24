import Foundation

@MainActor
final class ResetPasswordViewModel {
    
    var onSuccess: (() -> Void)?
    var onError: ((String) -> Void)?
    var onLoading: ((Bool) -> Void)?
    
    private var resetTask: Task<Void, Never>?
    
    func resetPassword(password: String?, confirmPassword: String?) {
        guard let password, !password.isEmpty,
              let confirmPassword, !confirmPassword.isEmpty else {
            onError?("Please fill in both fields.")
            return
        }
        
        guard password == confirmPassword else {
            onError?("Passwords do not match.")
            return
        }
        
        onLoading?(true)
        resetTask?.cancel()
        
        resetTask = Task { [weak self] in
            guard let self else { return }
            
            do {
                try await SupabaseManager.shared.resetPassword(newPassword: password)
                self.onLoading?(false)
                self.onSuccess?()
            } catch {
                self.onLoading?(false)
                self.onError?("Failed to update password. Link may have expired.")
            }
        }
    }
    
    func cancelTask() {
        resetTask?.cancel()
    }
}

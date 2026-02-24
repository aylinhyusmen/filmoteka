import UIKit

@MainActor
final class Navigator {
    
    static let shared = Navigator()
    private let storyboard = UIStoryboard(name: "Main", bundle: nil)
    
    private init() {}
    
    private var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
    
    private func instantiate<T: UIViewController>() -> T? {
        let identifier = String(describing: T.self)
        return storyboard.instantiateViewController(withIdentifier: identifier) as? T
    }
        
    func navigateToHome() {
        guard let homeNavController: UINavigationController = instantiate(),
              let window = keyWindow else { return }
        
        setRoot(homeNavController, on: window)
    }
    
    func navigateToLogin(from navigationController: UINavigationController?) {
        guard let loginVC: AuthViewController = instantiate() else { return }
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.pushViewController(loginVC, animated: true)
    }
    
    func navigateToCreateAccount(from navigationController: UINavigationController?) {
        guard let createVC: CreateAccountViewController = instantiate() else { return }
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.pushViewController(createVC, animated: true)
    }
    
    func navigateToResetPassword(on window: UIWindow? = nil) {
        guard let resetVC: ResetPasswordViewController = instantiate(),
              let targetWindow = window ?? keyWindow else { return }
        
        let navController = UINavigationController(rootViewController: resetVC)
        setRoot(navController, on: targetWindow)
    }
    
    func navigateToProfile(from navigationController: UINavigationController?) {
        guard let profileVC: UserProfileViewController = instantiate() else { return }
        navigationController?.pushViewController(profileVC, animated: true)
    }
    
    func navigateToMovieDetail(with movie: MediaItem, from navigationController: UINavigationController?) {
        guard let detailVC: MovieDetailViewController = instantiate() else { return }
        
        detailVC.viewModel = MovieDetailViewModel(mediaItem: movie)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func presentMovieSearch(onMovieSelected: @escaping (MediaItem) -> Void, from viewController: UIViewController?) {
        guard let searchVC: MovieSearchViewController = instantiate() else { return }
        
        searchVC.onMovieSelected = onMovieSelected
        let navController = UINavigationController(rootViewController: searchVC)
        viewController?.present(navController, animated: true)
    }
        
    // no back button
    private func setRoot(_ viewController: UIViewController, on window: UIWindow) {
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            window.rootViewController = viewController
        }, completion: nil)
    }
}

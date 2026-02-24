import UIKit

extension UIImageView {
    
    private enum Constants {
        static let defaultSize = "w500"
        static let tmdbBaseURL = "https://image.tmdb.org/t/p/"
        static let moviePlaceholderIcon = "photo"
        static let userPlaceholderIcon = "person.circle.fill"
        static let animationDuration: TimeInterval = 0.25
    }
    
    @discardableResult
    func loadTMDBImage(path: String?, size: String = Constants.defaultSize) -> Task<Void, Never>? {
        guard let path, !path.isEmpty else {
            setPlaceholder(systemName: Constants.moviePlaceholderIcon)
            return nil
        }
        
        let urlString = "\(Constants.tmdbBaseURL)\(size)\(path)"
        return downloadAndSetImage(urlString: urlString)
    }
    
    @discardableResult
    func loadFullURLImage(urlString: String?) -> Task<Void, Never>? {
        guard let urlString, !urlString.isEmpty else {
            setPlaceholder(systemName: Constants.userPlaceholderIcon)
            return nil
        }
        
        return downloadAndSetImage(urlString: urlString)
    }
    
    private func downloadAndSetImage(urlString: String) -> Task<Void, Never>? {
        if let cachedImage = ImageCache.shared.image(forKey: urlString) {
            self.image = cachedImage
            return nil
        }
        
        guard let url = URL(string: urlString) else { return nil }
        
        let downloadTask = Task { @MainActor [weak self] in
            guard let self else { return }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                
                guard !Task.isCancelled else { return }
                
                if let downloadedImage = UIImage(data: data) {
                    ImageCache.shared.save(downloadedImage, forKey: urlString)
                    
                    UIView.transition(with: self, duration: Constants.animationDuration, options: .transitionCrossDissolve, animations: {
                        self.image = downloadedImage
                    }, completion: nil)
                }
            } catch {
                print("error")
            }
        }
        
        return downloadTask
    }
    
    private func setPlaceholder(systemName: String) {
        self.image = UIImage(systemName: systemName)
        self.backgroundColor = .systemGray6
        self.tintColor = .systemGray3
        self.contentMode = .center
    }
}

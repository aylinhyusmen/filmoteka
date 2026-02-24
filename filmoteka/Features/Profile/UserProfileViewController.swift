import UIKit
import PhotosUI

final class UserProfileViewController: UIViewController {
    
    @IBOutlet weak var userProfilePic: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var totalMinutesWatched: UILabel!
    @IBOutlet weak var mostWatchedGenre: UILabel!
    
    @IBOutlet weak var favoriteMovie1: UIImageView!
    @IBOutlet weak var favoriteMovie2: UIImageView!
    @IBOutlet weak var favoriteMovie3: UIImageView!
    @IBOutlet weak var favoriteMovie4: UIImageView!
    
    @IBOutlet weak var watchedCollectionView: UICollectionView!
    @IBOutlet weak var watchlistCollectionView: UICollectionView!
    
    private let viewModel = UserProfileViewModel()
    private var avatarImageTask: Task<Void, Never>?
    
    private enum Constants {
        static let posterCellID = "StandardPosterCell"
        static let posterSize = CGSize(width: 95, height: 140)
        static let tmdbImageSize = "w500"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.fetchData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.cancelTasks()
        avatarImageTask?.cancel()
    }
    
    private func setupUI() {
        userProfilePic.isUserInteractionEnabled = true
        userProfilePic.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarTapped)))
        
        let favoriteViews = [favoriteMovie1, favoriteMovie2, favoriteMovie3, favoriteMovie4]
        for (index, imageView) in favoriteViews.enumerated() {
            guard let imageView else { continue }
            imageView.tag = index + 1
            imageView.isUserInteractionEnabled = true
            imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(favoriteMovieTapped(_:))))
            imageView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(favoriteMovieLongPressed(_:))))
        }
    }
    
    private func bindViewModel() {
        viewModel.onDataFetched = { [weak self] in
            self?.updateUI()
        }
        viewModel.onError = { [weak self] errorMessage in
            self?.showError(message: errorMessage)
        }
        viewModel.onCriticalError = { [weak self] error in
            self?.showErrorAndSignOut()
        }
        viewModel.onAvatarUploadSuccess = { [weak self] in
            self?.viewModel.fetchData()
        }
        viewModel.onMovieRemoved = { [weak self] indexPath, isWatched in
            if isWatched {
                self?.watchedCollectionView.deleteItems(at: [indexPath])
            } else {
                self?.watchlistCollectionView.deleteItems(at: [indexPath])
            }
        }
        viewModel.onFavoriteMovieLoaded = { [weak self] slot, movie in
            self?.updateFavoriteImage(forSlot: slot, path: movie.posterPath)
        }
        viewModel.onNavigateToLogin = { [weak self] in
            Navigator.shared.navigateToLogin(from: self?.navigationController)
        }
        viewModel.onNavigateToMovieDetail = { [weak self] movie in
            Navigator.shared.navigateToMovieDetail(with: movie, from: self?.navigationController)
        }
    }
    
    private func updateUI() {
        usernameLabel.text = viewModel.displayUsername
        totalMinutesWatched.text = viewModel.totalWatchTimeText
        mostWatchedGenre.text = viewModel.mostWatchedGenreText
        
        watchedCollectionView.reloadData()
        watchlistCollectionView.reloadData()
        
        avatarImageTask?.cancel()
        avatarImageTask = userProfilePic.loadFullURLImage(urlString: viewModel.profile?.avatarURL)
    }
    
    private func updateFavoriteImage(forSlot slot: Int, path: String?) {
        let size = Constants.tmdbImageSize
        switch slot {
        case 1: favoriteMovie1.loadTMDBImage(path: path, size: size)
        case 2: favoriteMovie2.loadTMDBImage(path: path, size: size)
        case 3: favoriteMovie3.loadTMDBImage(path: path, size: size)
        case 4: favoriteMovie4.loadTMDBImage(path: path, size: size)
        default: break
        }
    }
    
    @IBAction func settingsButtonTapped(_ sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: "Account Settings", message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Sign Out", style: .default) { [weak self] _ in
            self?.viewModel.signOut()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Delete Account", style: .destructive) { [weak self] _ in
            self?.promptAccountDeletion()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.barButtonItem = sender
        }
        
        present(actionSheet, animated: true)
    }
    
    private func promptAccountDeletion() {
        let alert = UIAlertController(
            title: "Delete Account",
            message: "Are you sure you want to delete your account?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.viewModel.deleteAccount()
        })
        
        present(alert, animated: true)
    }
    
    private func showErrorAndSignOut() {
        let alert = UIAlertController(title: "Session Expired", message: "Please log in again.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.viewModel.signOut()
        })
        present(alert, animated: true)
    }
}

extension UserProfileViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        collectionView == watchedCollectionView ? viewModel.watchedMovies.count : viewModel.watchlistMovies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.posterCellID, for: indexPath) as? StandardPosterCell else {
            return UICollectionViewCell()
        }
        
        if collectionView == watchedCollectionView {
            let watchedMovie = viewModel.watchedMovies[indexPath.row]
            let movieToPass = MediaItem(
                id: watchedMovie.movieID, posterPath: watchedMovie.posterPath, backdropPath: nil,
                mediaType: nil, title: watchedMovie.title, name: nil, originalTitle: nil,
                overview: nil, voteAverage: Double(watchedMovie.rating ?? 0), releaseDate: nil
            )
            cell.configure(with: movieToPass)
        } else {
            let watchlistMovie = viewModel.watchlistMovies[indexPath.row]
            let movieToPass = MediaItem(
                id: watchlistMovie.movieID, posterPath: watchlistMovie.posterPath, backdropPath: nil,
                mediaType: nil, title: watchlistMovie.title, name: nil, originalTitle: nil,
                overview: nil, voteAverage: 0.0, releaseDate: nil
            )
            cell.configure(with: movieToPass)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let deleteAction = UIAction(
                title: "Remove",
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { [weak self] _ in
                let isWatched = collectionView == self?.watchedCollectionView
                self?.viewModel.removeMovie(at: indexPath, isWatchedList: isWatched)
            }
            return UIMenu(title: "", children: [deleteAction])
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let isWatched = collectionView == watchedCollectionView
        viewModel.selectMovie(at: indexPath, isWatchedList: isWatched)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        Constants.posterSize
    }
}

extension UserProfileViewController: PHPickerViewControllerDelegate {
    
    @objc private func avatarTapped() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        
        provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
            guard let self, let uiImage = image as? UIImage else { return }
            
            guard let compressedData = uiImage.jpegData(compressionQuality: 0.2) else { return }
            
            Task { @MainActor in
                self.userProfilePic.image = uiImage
                self.viewModel.uploadAvatar(data: compressedData)
            }
        }
    }
}

extension UserProfileViewController {
    
    @objc private func favoriteMovieTapped(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view else { return }
        let slotIndex = view.tag
        
        if let existingMovie = viewModel.favoriteMoviesData[slotIndex] {
            Navigator.shared.navigateToMovieDetail(with: existingMovie, from: self.navigationController)
        } else {
            presentMovieSearch(forSlot: slotIndex)
        }
    }
    
    @objc private func favoriteMovieLongPressed(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began, let view = sender.view else { return }
        presentMovieSearch(forSlot: view.tag)
    }
    
    private func presentMovieSearch(forSlot slot: Int) {
        Navigator.shared.presentMovieSearch(onMovieSelected: { [weak self] selectedMovie in
            self?.viewModel.updateFavoriteMovie(selectedMovie, forSlot: slot)
        }, from: self)
    }
}

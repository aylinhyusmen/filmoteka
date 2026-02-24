import UIKit

final class MovieDetailViewController: UIViewController {
    
    @IBOutlet weak var backdropImageView: UIImageView!
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var overviewLabel: UILabel!
    @IBOutlet weak var metadataLabel: UILabel!
    @IBOutlet weak var castCollectionView: UICollectionView!
    @IBOutlet weak var noteLabel: UILabel!
    @IBOutlet weak var watchlistButton: UIButton!
    @IBOutlet weak var watchedButton: UIButton!
    
    private enum Constants {
        static let castCellID = "CastCell"
        static let backdropSize = "w780"
        static let posterSize = "w500"
    }
        
    var viewModel: MovieDetailViewModel!
    
    private var backdropTask: Task<Void, Never>?
    private var posterTask: Task<Void, Never>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialUI()
        bindViewModel()
        viewModel.fetchData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.cancelTasks()
        backdropTask?.cancel()
        posterTask?.cancel()
    }
        
    private func bindViewModel() {
        viewModel.onDetailsFetched = { [weak self] in
            self?.updateAdditionalDetailsUI()
        }
        viewModel.onCastFetched = { [weak self] in
            self?.castCollectionView.reloadData()
        }
        viewModel.onWatchStatusUpdated = { [weak self] in
            self?.updateButtonStates()
        }
        viewModel.onNoteUpdated = { [weak self] note in
            self?.updateNoteUI(with: note)
        }
        viewModel.onError = { [weak self] errorMessage in
            self?.showError(message: errorMessage)
            self?.updateButtonStates()
        }
        viewModel.onSaveSuccess = { [weak self] in
            self?.showSaveSuccessAlert()
        }
    }
    
    private func setupInitialUI() {
        let movie = viewModel.mediaItem
        titleLabel.text = movie.displayTitle
        overviewLabel.text = movie.overview
        
        let year = String(movie.releaseDate?.prefix(4) ?? "-")
        metadataLabel.text = "\(year)"
        
        backdropTask = backdropImageView.loadTMDBImage(path: movie.backdropPath, size: Constants.backdropSize)
        posterTask = posterImageView.loadTMDBImage(path: movie.posterPath, size: Constants.posterSize)
    }
    
    private func updateButtonStates() {
        watchedButton.isSelected = viewModel.isWatched
        watchlistButton.isSelected = viewModel.isWatchlisted
        watchlistButton.isEnabled = !viewModel.isWatched
        watchedButton.isEnabled = true
    }
    
    private func updateAdditionalDetailsUI() {
        guard let details = viewModel.movieDetails else { return }
        
        let year = String(details.releaseDate?.prefix(4) ?? "-")
        metadataLabel.text = "\(year) | \(details.genreText) | \(details.formattedRuntime)"
        
        if overviewLabel.text == "N/A" {
            overviewLabel.text = details.overview
        }
    }
    
    private func updateNoteUI(with note: String?) {
        if let note, !note.isEmpty {
            noteLabel.text = "Note: \(note)"
            noteLabel.isHidden = false
        } else {
            noteLabel.isHidden = true
        }
    }
    
    @IBAction func watchedButtonTapped(_ sender: UIButton) {
        watchedButton.isEnabled = false
        watchlistButton.isEnabled = false
        
        if viewModel.isWatched {
            presentRemoveAlert()
        } else {
            presentRateAlert()
        }
    }
    
    @IBAction func watchlistButtonTapped(_ sender: UIButton) {
        watchlistButton.isEnabled = false
        watchedButton.isEnabled = false
        viewModel.toggleWatchlist()
    }
    
    private func presentRemoveAlert() {
        let removeAlert = UIAlertController(
            title: "Remove Movie",
            message: "Remove \(viewModel.mediaItem.displayTitle) from your watched list?",
            preferredStyle: .alert
        )
        
        removeAlert.addAction(UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            self?.viewModel.removeWatchedMovie()
        })
        removeAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.updateButtonStates()
        })
        
        present(removeAlert, animated: true)
    }
    
    private func presentRateAlert() {
        let rateAlert = UIAlertController(
            title: "Log Movie",
            message: "Rate \(viewModel.mediaItem.displayTitle)",
            preferredStyle: .actionSheet
        )
        
        for rating in 1...5 {
            let stars = String(repeating: "★", count: rating)
            rateAlert.addAction(UIAlertAction(title: stars, style: .default) { [weak self] _ in
                self?.promptForNote(rating: rating, currentNote: self?.viewModel.savedNote)
            })
        }
        
        rateAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.updateButtonStates()
        })
        
        present(rateAlert, animated: true)
    }
    
    private func promptForNote(rating: Int, currentNote: String?) {
        let noteAlert = UIAlertController(
            title: "Add a Note",
            message: "Any thoughts on this movie?",
            preferredStyle: .alert
        )
        
        noteAlert.addTextField { textField in
            textField.placeholder = "Write here..."
            if let currentNote, !currentNote.isEmpty {
                textField.text = currentNote
            }
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            let text = noteAlert.textFields?.first?.text
            let finalNote = (text == "") ? nil : text
            self?.viewModel.saveWatchedMovie(rating: rating, notes: finalNote)
        }
        
        noteAlert.addAction(saveAction)
        noteAlert.addAction(UIAlertAction(title: "Skip", style: .cancel) { [weak self] _ in
            self?.viewModel.saveWatchedMovie(rating: rating, notes: nil)
        })
        
        present(noteAlert, animated: true)
    }
    
    private func showSaveSuccessAlert() {
        let successAlert = UIAlertController(title: "Saved!", message: "Added to your watched list.", preferredStyle: .alert)
        successAlert.addAction(UIAlertAction(title: "OK", style: .default))
        present(successAlert, animated: true)
    }
}

extension MovieDetailViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.cast.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.castCellID, for: indexPath) as? CastCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: viewModel.cast[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 95, height: 140)
    }
}

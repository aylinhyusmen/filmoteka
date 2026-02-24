import UIKit

final class StandardPosterCell: UICollectionViewCell {
    
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var movieTitleLabel: UILabel!
    
    private var imageTask: Task<Void, Never>?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        posterImageView.image = nil
        movieTitleLabel.text = nil
    }
    
    func configure(with movie: MediaItem) {
        movieTitleLabel.text = movie.displayTitle
        
        imageTask = posterImageView.loadTMDBImage(path: movie.posterPath)
    }
}

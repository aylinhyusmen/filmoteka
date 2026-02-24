import UIKit

final class PosterCollectionViewCell: UICollectionViewCell {
    
    private enum Constants {
        static let imageSize = "w780"
        static let titleFontSize: CGFloat = 18
        static let titleNumberOfLines = 2
    }
    
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var movieTitleLabel: UILabel!
    
    private var imageTask: Task<Void, Never>?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        posterImageView.image = nil
        movieTitleLabel.attributedText = nil
    }
    
    func configure(with movie: MediaItem) {
        let mainTitle = NSMutableAttributedString(string: movie.displayTitle, attributes: [
            .font: UIFont.boldSystemFont(ofSize: Constants.titleFontSize),
            .foregroundColor: UIColor.white
        ])
        
        movieTitleLabel.numberOfLines = Constants.titleNumberOfLines
        movieTitleLabel.attributedText = mainTitle
        
        imageTask = posterImageView.loadTMDBImage(path: movie.posterPath, size: Constants.imageSize)
    }
}

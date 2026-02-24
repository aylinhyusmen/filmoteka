import UIKit

final class UpcomingTableViewCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private enum Constants {
        static let posterCellID = "UpcomingPosterCell"
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var movies: [MediaItem] = []
    var didTapMovie: ((MediaItem) -> Void)?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        movies.removeAll()
        collectionView.reloadData()
        collectionView.setContentOffset(.zero, animated: false)
    }
    
    func configure(with movies: [MediaItem]) {
        self.movies = movies
        self.collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        movies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.posterCellID, for: indexPath) as? PosterCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        cell.configure(with: movies[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 40
        return CGSize(width: width, height: collectionView.bounds.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didTapMovie?(movies[indexPath.row])
    }
}

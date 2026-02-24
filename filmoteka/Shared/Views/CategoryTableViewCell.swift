import UIKit

final class CategoryTableViewCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource {
    
    private enum Constants {
        static let posterCellID = "CategoryPosterCell"
    }
    
    @IBOutlet weak var categoryTitleLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var movies: [MediaItem] = [] 
    var didTapMovie: ((MediaItem) -> Void)?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        categoryTitleLabel.text = nil
        movies.removeAll()
        collectionView.reloadData()
        collectionView.setContentOffset(.zero, animated: false)
    }
    
    func configure(with category: MediaCategory) {
        self.categoryTitleLabel.text = category.name
        self.movies = category.movies
        self.collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        movies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.posterCellID, for: indexPath) as? StandardPosterCell else {
            return UICollectionViewCell()
        }
        
        cell.configure(with: movies[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didTapMovie?(movies[indexPath.row])
    }
}

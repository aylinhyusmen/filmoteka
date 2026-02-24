import UIKit

final class CastCollectionViewCell: UICollectionViewCell {
    
    private static let imageSize = "w200"
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var roleLabel: UILabel!
    
    private var imageTask: Task<Void, Never>?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        imageView.image = nil
        nameLabel.text = nil
        roleLabel.text = nil
    }
    
    func configure(with actor: CastMember) {
        nameLabel.text = actor.name
        roleLabel.text = actor.character
        imageTask = imageView.loadTMDBImage(path: actor.profilePath, size: CastCollectionViewCell.imageSize)
    }
}

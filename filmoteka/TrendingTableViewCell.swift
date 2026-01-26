//
//  TrendingTableViewCell.swift
//  filmoteka
//
//  Created by Aylin Hyusmen on 26.01.26.
//

import UIKit

class TrendingTableViewCell: UITableViewCell {
    
    @IBOutlet weak var collectionView: UICollectionView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

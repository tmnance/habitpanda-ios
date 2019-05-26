//
//  CheckGridHeaderCell.swift
//  HabitPanda
//
//  Created by Tim Nance on 5/26/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit

class CheckGridHeaderCell: UICollectionViewCell {
    static let width = CGFloat(50)
    static let height = CGFloat(50)

    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var bottomBorder: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}

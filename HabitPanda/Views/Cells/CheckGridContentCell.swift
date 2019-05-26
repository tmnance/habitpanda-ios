//
//  CheckGridContentCell.swift
//  HabitPanda
//
//  Created by Tim Nance on 5/26/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit

class CheckGridContentCell: UICollectionViewCell {
    static let width = CheckGridHeaderCell.width
    static let height = CGFloat(88)

    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var bottomBorder: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}

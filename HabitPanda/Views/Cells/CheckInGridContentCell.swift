//
//  CheckInGridContentCell.swift
//  HabitPanda
//
//  Created by Tim Nance on 5/26/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit

class CheckInGridContentCell: UICollectionViewCell {
    static let width = CheckInGridHeaderCell.width
    static let height = CGFloat(88)

    @IBOutlet weak var contentContainer: UIView!
    @IBOutlet weak var checkmarkImageView: UIImageView!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var bottomBorder: UIView!

    var checkInCount = 0

    override func awakeFromNib() {
        super.awakeFromNib()
        updateUI()
    }
}


// MARK: - UI Methods
extension CheckInGridContentCell {
    func updateUI() {
        checkmarkImageView.image = checkInCount > 0 ? UIImage(named: "checkmark") : nil
        countLabel.text = checkInCount > 1 ? "\(checkInCount)" : ""
    }
}

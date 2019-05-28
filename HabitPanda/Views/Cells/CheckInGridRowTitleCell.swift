//
//  CheckInGridRowTitleCell.swift
//  HabitPanda
//
//  Created by Tim Nance on 5/26/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit

class CheckInGridRowTitleCell: UICollectionViewCell {
//    static let width = CGFloat(60)
    static let height = CGFloat(44)

    @IBOutlet weak var contentButton: UIButton!
    @IBOutlet weak var additionalDetailsLabel: UILabel!

    var name: String?
    var additionalDetailsText: String?
    var onRowNameButtonPressed: (() -> ())? = nil

    override func awakeFromNib() {
        super.awakeFromNib()
        updateUI()
    }
}


// MARK: - UI Methods
extension CheckInGridRowTitleCell {
    func updateUI() {
        contentButton.titleLabel!.numberOfLines = 2

        // prevents the button from flashing and momentarily seeing prior cell text when updating
        UIView.performWithoutAnimation {
            self.contentButton.setTitle(
                self.name,
                for: .normal
            )
            self.contentButton.layoutIfNeeded()
        }
        additionalDetailsLabel.text = additionalDetailsText
    }
}


// MARK: - Button Pressed Methods
extension CheckInGridRowTitleCell {
    @IBAction func rowNameButtonPressed(_ sender: UIButton) {
        onRowNameButtonPressed?()
    }
}

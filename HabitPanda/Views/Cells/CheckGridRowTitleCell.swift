//
//  CheckGridRowTitleCell.swift
//  HabitPanda
//
//  Created by Tim Nance on 5/26/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit

class CheckGridRowTitleCell: UICollectionViewCell {
    @IBOutlet weak var contentButton: UIButton!

//    static let width = CGFloat(60)
    static let height = CGFloat(44)

    var name: String?
    var onRowNameButtonPressed: (() -> ())? = nil

    override func awakeFromNib() {
        super.awakeFromNib()
        updateUI()
    }
}


// MARK: - UI Methods
extension CheckGridRowTitleCell {
    func updateUI() {
        // prevents the button from flashing and momentarily seeing prior cell text when updating
        UIView.performWithoutAnimation {
            self.contentButton.setTitle(
                self.name,
                for: .normal
            )
            self.contentButton.layoutIfNeeded()
        }
    }
}


// MARK: - Button Pressed Methods
extension CheckGridRowTitleCell {
    @IBAction func rowNameButtonPressed(_ sender: UIButton) {
        onRowNameButtonPressed?()
    }
}

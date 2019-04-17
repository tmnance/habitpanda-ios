//
//  SingleSelectButton.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/17/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit

class SingleSelectButton: UIButton {

//    let buttonTintColor = UIColor(red: 0.06, green: 0.46, blue: 0.51, alpha: 1.0) // 0F7583

    override func awakeFromNib() {
        super.awakeFromNib()

        setTitleColor(tintColor, for: .normal)
        setTitleColor(UIColor.white, for: .selected)
    }

    override var isSelected: Bool {
        didSet {
            switch isSelected {
            case true:
                layer.backgroundColor = tintColor.cgColor
            case false:
                layer.backgroundColor = UIColor.clear.cgColor
            }
        }
    }

    override var isHighlighted: Bool {
        didSet { if isHighlighted { isHighlighted = false } }
    }

}

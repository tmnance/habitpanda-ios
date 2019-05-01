//
//  SingleSelectButton.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/17/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit

@IBDesignable class SingleSelectButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    override func prepareForInterfaceBuilder() {
        sharedInit()
    }

    func sharedInit() {
        setTitleColor(Constants.Colors.tintColor, for: .normal)
        setTitleColor(UIColor.white, for: .selected)
    }

    override var isSelected: Bool {
        didSet {
            switch isSelected {
            case true:
                layer.backgroundColor = Constants.Colors.tintColor.cgColor
            case false:
                layer.backgroundColor = UIColor.clear.cgColor
            }
        }
    }

    override var isHighlighted: Bool {
        didSet { if isHighlighted { isHighlighted = false } }
    }
}

//
//  OptionSelectButton.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/17/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit

@IBDesignable class OptionSelectButton: UIButton {
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
        setTitleColor(Constants.Colors.tint, for: .normal)
        setTitleColor(Constants.Colors.textForTintBackground, for: .selected)
        layer.cornerRadius = frame.height / 3
    }

    override var isSelected: Bool {
        didSet {
            switch isSelected {
            case true:
                layer.backgroundColor = Constants.Colors.tint.cgColor
            case false:
                layer.backgroundColor = Constants.Colors.clear.cgColor
            }
        }
    }

    override var isHighlighted: Bool {
        didSet { if isHighlighted { isHighlighted = false } }
    }
}

//
//  MultiSelectButton.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/17/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit

class MultiSelectButton: SingleSelectButton {

    override func awakeFromNib() {
        super.awakeFromNib()

        layer.cornerRadius = frame.height / 3
    }

}

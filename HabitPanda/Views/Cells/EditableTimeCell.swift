//
//  EditableTimeCell.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/19/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit

class EditableTimeCell: UITableViewCell {
    var hour: Int?
    var minute: Int?
    var onEditButtonPressed: (() -> ())? = nil
    var onRemoveButtonPressed: (() -> ())? = nil

    override func awakeFromNib() {
        super.awakeFromNib()

        updateTimeDisplay()
    }

    // MARK: Button Pressed Methods

    @IBAction func editButtonPressed(_ sender: UIButton) {
        onEditButtonPressed?()
    }

    @IBAction func removeButtonPressed(_ sender: UIButton) {
        onRemoveButtonPressed?()
    }

    // MARK: Value Changed Methods

    @IBOutlet weak var timeValueLabel: UILabel!
    func updateTimeDisplay() {
        if let hour = hour, let minute = minute {
            timeValueLabel.text = TimeOfDay.getDisplayDate(hour: hour, minute: minute)
        }
    }
}


//
//  EditableTimeCell.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/19/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit

class EditableTimeCell: UITableViewCell {
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var frequencyDaysLabel: UILabel!

    var hour: Int?
    var minute: Int?
    var frequencyDays: [Int] = []
    var onEditButtonPressed: (() -> ())? = nil
    var onRemoveButtonPressed: (() -> ())? = nil

    override func awakeFromNib() {
        super.awakeFromNib()
        updateUI()
    }
}


// MARK: - UI Methods
extension EditableTimeCell {
    func updateUI() {
        updateTimeDisplay()
        updateFrequencyDays()
    }

    func updateTimeDisplay() {
        if let hour = hour, let minute = minute {
            timeLabel.text = TimeOfDay.getDisplayDate(hour: hour, minute: minute)
        }
    }

    func updateFrequencyDays() {
        let attributedString = NSMutableAttributedString(
            string: "SMTWTFS"
        )
        let nonOccurringDays = IndexSet(0..<7).subtracting(IndexSet(frequencyDays))
        nonOccurringDays.forEach{ (index) in
            let range = NSRange(location:index, length:1)
            attributedString.addAttribute(
                NSAttributedString.Key.foregroundColor,
                value: Constants.Colors.disabledTextColor,
                range: range
            )
        }

        frequencyDaysLabel.attributedText = attributedString
    }
}

// MARK: - Button Pressed Methods
extension EditableTimeCell {
    @IBAction func editButtonPressed(_ sender: UIButton) {
        onEditButtonPressed?()
    }

    @IBAction func removeButtonPressed(_ sender: UIButton) {
        onRemoveButtonPressed?()
    }
}

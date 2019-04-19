//
//  EditableTimeCell.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/19/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit

class EditableTimeCell: UITableViewCell {

    var hour:Int?
    var minute:Int?
    var onEditButtonPressed:(()->())? = nil
    var onRemoveButtonPressed:(()->())? = nil

    override func awakeFromNib() {
        super.awakeFromNib()

        updateTimeDisplay()
    }


    // MARK: - Button Pressed Methods

    @IBAction func editButtonPressed(_ sender: UIButton) {
        onEditButtonPressed?()
    }

    @IBAction func removeButtonPressed(_ sender: UIButton) {
        onRemoveButtonPressed?()
    }


    // MARK: - Value Changed Methods

    @IBOutlet weak var timeValueLabel: UILabel!
    func updateTimeDisplay() {
        if let hour = hour, let minute = minute {
            timeValueLabel.text = getDisplayDate(hour: hour, minute: minute)
        }
    }

    func getDisplayDate(hour:Int, minute:Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat =  "HH:mm"
        let date = dateFormatter.date(from: "\(hour):\(minute)")
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: date!)
    }

}


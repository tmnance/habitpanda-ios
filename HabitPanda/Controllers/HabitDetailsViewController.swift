//
//  HabitDetailsViewController.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/25/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit
import CoreData

class HabitDetailsViewController: UIViewController {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var frequencyLabel: UILabel!
    @IBOutlet weak var reminderTimesLabel: UILabel!

    var selectedHabit: Habit? {
        didSet {
            updateUI()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateUI()
    }
}


extension HabitDetailsViewController {
    func updateUI() {
        if let habit = selectedHabit {
            nameLabel?.text = habit.name
            frequencyLabel?.text = "?"
            var reminderTimes = habit.reminderTimes!
                .map {
                    $0 as! ReminderTime
                }
            reminderTimes.sort { $0.hour < $1.hour || ($0.hour == $1.hour && $0.minute < $1.minute) }

            reminderTimesLabel?.text = reminderTimes
                .map {
                    TimeOfDay.getDisplayDate(hour: Int($0.hour), minute: Int($0.minute))
                }
                .joined(separator: ", ")
        }
    }
}

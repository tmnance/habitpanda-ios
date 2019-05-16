//
//  HabitCheckInViewController.swift
//  HabitPanda
//
//  Created by Tim Nance on 5/14/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit

class HabitCheckInViewController: UIViewController {
    @IBOutlet weak var frequencyLabel: UILabel!
    @IBOutlet weak var checkInDayPicker: DateDayPicker!

    var delegateViewModel = HabitDetailsViewModel()
    var dateDayPicker: DateDayPicker!

    override func viewDidLoad() {
        super.viewDidLoad()


        let today = Date()
        var dateArray = [today]
        for i in 1...4 {
            let pastDay = Calendar.current.date(byAdding: .day, value: (-1 * i), to: today)!
            dateArray.append(pastDay)
        }

        dateDayPicker = DateDayPicker()
        dateDayPicker.pickerData = dateArray

        checkInDayPicker.delegate = dateDayPicker
        checkInDayPicker.dataSource = dateDayPicker

        checkInDayPicker.rotate90deg()
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    @IBAction func closeButtonPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
}


//// MARK: - UI Update Methods
//extension HabitSummaryViewController {
//    func updateUI() {
//        frequencyLabel?.text = getFrequencyDisplay() ?? "(none)"
//    }
//
//    func getFrequencyDisplay() -> String? {
//        guard delegateViewModel.frequencyDays.value.count > 0 else {
//            return nil
//        }
//        let frequencyOption = delegateViewModel.getFrequencyOption()
//        if frequencyOption == .Custom {
//            return frequencyOption.description + " - " +
//                delegateViewModel.frequencyDays.value
//                    .map{ $0.description }
//                    .joined(separator: " / ")
//        } else {
//            return frequencyOption.description
//        }
//    }
//}


//// MARK: - Delete Habit Methods
//extension HabitSummaryViewController {
//    @IBAction func deleteHabitButtonPressed(_ sender: UIButton) {
//        showDeleteHabitPopup()
//    }
//
//    func showDeleteHabitPopup() {
//        if let habit = delegateViewModel.selectedHabit {
//            let alert = UIAlertController(
//                title: "Confirm Delete",
//                message: "Are you sure you want to delete your habit named \"\(habit.name!)\"?",
//                preferredStyle: .alert
//            )
//
//            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { (action) in
//                self.delegateViewModel.deleteHabit()
//                self.navigationController?.popViewController(animated: true)
//            })
//            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
//
//            present(alert, animated: true, completion: nil)
//        }
//    }
//}

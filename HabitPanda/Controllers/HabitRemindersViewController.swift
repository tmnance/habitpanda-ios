//
//  HabitRemindersViewController.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/30/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit

class HabitRemindersViewController: UIViewController {
    @IBOutlet weak var reminderTimesLabel: UILabel!

    var delegateViewModel = HabitViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        delegateViewModel.reminderTimes.bind { [unowned self] (_) in
            self.updateUI()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
    }

    override func viewDidLayoutSubviews() {
        let targetSize = CGSize(
            width: view.bounds.width,
            height: UIView.layoutFittingCompressedSize.height
        )
        preferredContentSize = view.systemLayoutSizeFitting(targetSize)
    }
}


// MARK: - UI Update Methods
extension HabitRemindersViewController {
    func updateUI() {
        reminderTimesLabel?.text = getReminderTimesDisplay() ?? "(none)"
    }

    func getReminderTimesDisplay() -> String? {
        guard delegateViewModel.reminderTimes.value.count > 0 else {
            return nil
        }
        return delegateViewModel.reminderTimes.value
            .map {
                TimeOfDay.getDisplayDate(hour: Int($0.hour), minute: Int($0.minute))
            }
            .joined(separator: "\n")
    }
}

//
//  HabitSummaryViewController.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/30/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit

class HabitSummaryViewController: UIViewController {
    @IBOutlet weak var frequencyLabel: UILabel!

    var delegateViewModel = HabitDetailsViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
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
extension HabitSummaryViewController {
    func updateUI() {
        frequencyLabel?.text = delegateViewModel.getFrequencyPerWeekDisplayText()
    }
}


// MARK: - Delete Habit Methods
extension HabitSummaryViewController {
    @IBAction func deleteHabitButtonPressed(_ sender: UIButton) {
        showDeleteHabitPopup()
    }

    func showDeleteHabitPopup() {
        if let habit = delegateViewModel.selectedHabit {
            let alert = UIAlertController(
                title: "Confirm Delete",
                message: "Are you sure you want to delete your habit named \"\(habit.name!)\"?",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { (action) in
                self.delegateViewModel.deleteHabit()

                ToastHelper.makeToast("Habit deleted", state: .entityDeleted)

                self.navigationController?.popViewController(animated: true)
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            present(alert, animated: true, completion: nil)
        }
    }
}

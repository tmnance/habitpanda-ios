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

    private var viewModel = HabitViewModel()

    var selectedHabit: Habit? {
        didSet {
            viewModel.selectedHabit = selectedHabit
            updateUI()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.reminderTimes.bind { [unowned self] (_) in
            self.updateUI()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // TODO: feel this isn't the best way to handle this
        viewModel.reloadHabitData()

        updateUI()
    }
}


// MARK: - UI Update Methods
extension HabitDetailsViewController {
    func updateUI() {
        nameLabel?.text = viewModel.name.value
        frequencyLabel?.text = viewModel.frequencyDays.value
            .map{ $0.description }
            .joined(separator: ", ")
        reminderTimesLabel?.text = viewModel.reminderTimes.value
            .map {
                TimeOfDay.getDisplayDate(hour: Int($0.hour), minute: Int($0.minute))
            }
            .joined(separator: ", ")
    }
}


// MARK: - Top Nav Bar Methods
extension HabitDetailsViewController {
    @IBAction func editButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "goToEditHabit", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationNavigationVC = segue.destination as! UINavigationController
        let destinationVC = destinationNavigationVC.topViewController as! AddEditHabitViewController
        destinationVC.setSelectedHabit(selectedHabit!)
    }
}

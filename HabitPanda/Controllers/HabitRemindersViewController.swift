//
//  HabitRemindersViewController.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/30/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit

class HabitRemindersViewController: UIViewController {
    @IBOutlet weak var remindersTableView: UITableView!
    @IBOutlet weak var remindersTableViewHeightLayout: NSLayoutConstraint!

    var delegateViewModel = HabitDetailsViewModel() {
        didSet {
            viewModel.selectedHabit = delegateViewModel.selectedHabit
        }
    }
    private var viewModel = ReminderListViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupStylesAndBindings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // TODO: probably a better way of handling this
        self.viewModel.reloadData()
    }

    override func viewDidLayoutSubviews() {
        let targetSize = CGSize(
            width: view.bounds.width,
            height: UIView.layoutFittingCompressedSize.height
        )
        preferredContentSize = view.systemLayoutSizeFitting(targetSize)
    }
}


// MARK: - Setup Methods
extension HabitRemindersViewController {
    func setupStylesAndBindings() {
        remindersTableView.delegate = self
        remindersTableView.dataSource = self
        remindersTableView.separatorStyle = .none
        remindersTableView.isScrollEnabled = false

        remindersTableView.register(
            UINib(nibName: "EditableTimeCell", bundle: nil),
            forCellReuseIdentifier: "editableTimeCell"
        )

        viewModel.reminders.bind { [unowned self] (_) in
            self.updateReminders()
        }
    }
}


// MARK: - Reminder Methods
extension HabitRemindersViewController {
    func updateReminders() {
        remindersTableView.reloadData()
        remindersTableViewHeightLayout.constant = CGFloat(
            tableView(remindersTableView, numberOfRowsInSection: 0) * 46
        )
    }
}


// MARK: - Tableview Datasource Methods
extension HabitRemindersViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.reminders.value.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "editableTimeCell",
            for: indexPath
            ) as! EditableTimeCell
        let reminder = viewModel.reminders.value[indexPath.row]
        cell.hour = Int(reminder.hour)
        cell.minute = Int(reminder.minute)
        cell.frequencyDays = (reminder.frequencyDays ?? []).compactMap{ $0.intValue }

        cell.onEditButtonPressed = {
            self.performSegue(withIdentifier: "goToEditReminder", sender: indexPath)
        }
        cell.onRemoveButtonPressed = {
            // TODO: add confirm delete alert
            self.viewModel.removeReminder(atIndex: indexPath.row)

            ToastHelper.makeToast("Reminder removed", state: .entityDeleted)
        }

        cell.updateUI()
        cell.selectionStyle = .none

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}


// MARK: - Segue Methods
extension HabitRemindersViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationNavigationVC = segue.destination as! UINavigationController
        let destinationVC =
            destinationNavigationVC.topViewController as! ReminderAddEditViewController
        if segue.identifier == "goToEditReminder" {
            if let indexPath = sender as? IndexPath {
                destinationVC.setSelectedReminder(viewModel.reminders.value[indexPath.row])
            }
        }
        destinationVC.setParentHabit(viewModel.selectedHabit!)
    }
}

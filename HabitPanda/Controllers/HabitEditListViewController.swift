//
//  HabitEditListViewController.swift
//  HabitPanda
//
//  Created by Tim Nance on 1/26/20.
//  Copyright © 2020 Tim Nance. All rights reserved.
//

import UIKit
import CoreData

class HabitEditListViewController: UIViewController {
    private var viewModel = HabitListViewModel()
    @IBOutlet weak var habitsTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupStylesAndBindings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.reloadData()
    }
}


// MARK: - Top Nav Bar Methods
extension HabitEditListViewController {
    // MARK: Top Nav Button Pressed Methods

    @IBAction func doneButtonPressed(_ sender: UIBarButtonItem) {
        if viewModel.habits.value.count > 0 {
            viewModel.updateHabitOrder()

            ToastHelper.makeToast("Habit order updated", state: .entityUpdated)
        }

        dismiss(animated: true)
    }

    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
}


// MARK: - Setup Methods
extension HabitEditListViewController {
    func setupStylesAndBindings() {
        habitsTableView.delegate = self
        habitsTableView.dataSource = self
        habitsTableView.isEditing = true
    }
}


// MARK: - Tableview Datasource Methods
extension HabitEditListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.habits.value.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "HabitCell",
            for: indexPath
        )
        let habit = viewModel.habits.value[indexPath.row]

        cell.textLabel?.text = habit.name

        return cell
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let habitToMove = viewModel.habits.value[sourceIndexPath.row]
        viewModel.habits.value.remove(at: sourceIndexPath.row)
        viewModel.habits.value.insert(habitToMove, at: destinationIndexPath.row)
    }
}

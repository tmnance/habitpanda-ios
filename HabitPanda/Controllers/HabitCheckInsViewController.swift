//
//  HabitCheckInsViewController.swift
//  HabitPanda
//
//  Created by Tim Nance on 5/17/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit
import SwipeCellKit

class HabitCheckInsViewController: UIViewController {
    let cellHeight: CGFloat = 70.0

    @IBOutlet weak var checkInsTableView: UITableView!
    @IBOutlet weak var checkInsTableViewHeightLayout: NSLayoutConstraint!

    var delegateViewModel = HabitDetailsViewModel() {
        didSet {
            viewModel.selectedHabit = delegateViewModel.selectedHabit
        }
    }
    private var viewModel = CheckInListViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupFieldStylesAndBindings()
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

    func reloadData() {
        self.viewModel.reloadData()
    }
}


// MARK: - Field Setup Methods
extension HabitCheckInsViewController {
    func setupFieldStylesAndBindings() {
        checkInsTableView.delegate = self
        checkInsTableView.dataSource = self
        checkInsTableView.isScrollEnabled = false

        viewModel.checkIns.bind { [unowned self] (_) in
            self.updateCheckIns()
        }
    }
}


// MARK: - CheckIn Methods
extension HabitCheckInsViewController {
    func updateCheckIns() {
        checkInsTableView.reloadData()
        checkInsTableViewHeightLayout.constant = CGFloat(
            tableView(checkInsTableView, numberOfRowsInSection: 0)
        ) * cellHeight
    }
}


// MARK: - Tableview Datasource Methods
extension HabitCheckInsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.checkIns.value.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "CheckInCell",
            for: indexPath
            ) as! SwipeTableViewCell
        cell.delegate = self

        let checkIn = viewModel.checkIns.value[indexPath.row]

        cell.textLabel?.text = checkIn.getCheckInDisplayDate()
        cell.selectionStyle = .none

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! SwipeTableViewCell
        cell.showSwipe(orientation: .right, animated: true, completion: nil)
    }
}


// MARK: - SwipeCell Methods
extension HabitCheckInsViewController: SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }

        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            self.showDeleteCheckInPopup(forIndexPath: indexPath, withTableView: tableView)
        }

        deleteAction.image = UIImage(named: "delete-icon")

        return [deleteAction]
    }

    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = .destructive(automaticallyDelete: false)
        return options
    }
}


// MARK: - Delete Check-In Methods
extension HabitCheckInsViewController {
    func showDeleteCheckInPopup(forIndexPath indexPath: IndexPath, withTableView tableView: UITableView) {
        let index = indexPath.row
        let checkIn = viewModel.checkIns.value[index]
        let alert = UIAlertController(
            title: "Confirm Delete",
            message: "Are you sure you want to delete the check-in for \(checkIn.getCheckInDisplayDate())?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { (action) in
            self.viewModel.removeCheckIn(atIndex: index)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            let cell = tableView.cellForRow(at: indexPath) as! SwipeTableViewCell
            cell.hideSwipe(animated: true, completion: nil)
        })

        present(alert, animated: true, completion: nil)
    }
}

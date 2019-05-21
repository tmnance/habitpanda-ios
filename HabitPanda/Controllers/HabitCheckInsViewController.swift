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
            tableView(checkInsTableView, numberOfRowsInSection: 0) * 44
        )
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

        let date = checkIn.checkInDate!
        let df = DateFormatter()

        df.dateFormat = "EEE, MMMM d"
        let displayDate = df.string(from: date)

        df.dateFormat = "h:mm a"
        let displayTime = df.string(from: date)


        cell.textLabel?.text = "\(displayDate) at \(displayTime)"
        cell.selectionStyle = .none

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
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
            self.viewModel.removeCheckIn(atIndex: indexPath.row)
        }

        deleteAction.image = UIImage(named: "delete-icon")
        deleteAction.title = nil

        return [deleteAction]
    }

    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = .none
        return options
    }
}

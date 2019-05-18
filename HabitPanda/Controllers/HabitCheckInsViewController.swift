//
//  HabitCheckInsViewController.swift
//  HabitPanda
//
//  Created by Tim Nance on 5/17/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit

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
//        checkInsTableView.separatorStyle = .none
        checkInsTableView.isScrollEnabled = false

//        checkInsTableView.register(
//            UINib(nibName: "EditableTimeCell", bundle: nil),
//            forCellReuseIdentifier: "editableTimeCell"
//        )

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
        let cell = tableView.dequeueReusableCell(withIdentifier: "CheckInCell", for: indexPath)
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
}

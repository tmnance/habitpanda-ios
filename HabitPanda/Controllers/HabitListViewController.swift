//
//  HabitListViewController.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/12/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit
import CoreData

class HabitListViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!

    private var viewModel = HabitListViewModel()

    let numDates = 30
    var dateLabels: [String] = []
    var isInitiallyScrolledToToday = false

    let checkGridHeaderCellIdentifier = "checkGridHeaderCell"
    let checkGridRowTitleCellIdentifier = "checkGridRowTitleCell"
    let checkGridContentCellIdentifier = "checkGridContentCell"

    let colBgColor1 = Constants.Colors.listAlternatingBgColor1
    let colBgColor2 = Constants.Colors.listAlternatingBgColor2
    let rowTitleBgColor = Constants.Colors.listRowOverlayBgColor
    let tintColor = Constants.Colors.tintColor
    let checkboxColor = Constants.Colors.tintColor
    let borderColor = Constants.Colors.tintColor

    override func viewDidLoad() {
        super.viewDidLoad()

        setupStylesAndBindings()

        for item in 0..<numDates {
            let date = Calendar.current.date(
                byAdding: .day,
                value: -1 * (numDates - item - 2),
                to: Date()
            )!
            let df = DateFormatter()

            df.dateFormat = "M"
            let monthNumber = df.string(from: date)

            df.dateFormat = "d"
            let dayNumber = df.string(from: date)

            df.dateFormat = "EEE"
            let dayName = df.string(from: date)
            dateLabels.append("\(dayName)\n\(monthNumber)/\(dayNumber)")
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.reloadData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !isInitiallyScrolledToToday && collectionView.visibleCells.count > 0 {
            isInitiallyScrolledToToday = true
            // scroll to far right
            collectionView.contentOffset.x =
                collectionView.contentSize.width - collectionView.frame.width
        }
    }
}


// MARK: - Setup Methods
extension HabitListViewController {
    func setupStylesAndBindings() {
        collectionView.dataSource = self
        collectionView.delegate = self

        collectionView.register(
            UINib(nibName: "CheckGridHeaderCell", bundle: nil),
            forCellWithReuseIdentifier: checkGridHeaderCellIdentifier
        )
        collectionView.register(
            UINib(nibName: "CheckGridRowTitleCell", bundle: nil),
            forCellWithReuseIdentifier: checkGridRowTitleCellIdentifier
        )
        collectionView.register(
            UINib(nibName: "CheckGridContentCell", bundle: nil),
            forCellWithReuseIdentifier: checkGridContentCellIdentifier
        )

        viewModel.habits.bind { [unowned self] (_) in
            self.updateHabits()
        }
    }
}


// MARK: - Habit Methods
extension HabitListViewController {
    func updateHabits() {
        collectionView.reloadData()
        if let flowLayout = collectionView.collectionViewLayout as? CheckGridCollectionViewLayout {
            // unsure why but this appears to fix a bug with the sticky header positioning when
            // deleting a row
            DispatchQueue.main.async {
                self.collectionView.collectionViewLayout.invalidateLayout()
                self.collectionView.collectionViewLayout = flowLayout
            }
        }
    }
}


// MARK: - UICollectionViewDataSource
extension HabitListViewController: UICollectionViewDataSource {
    func getHabitForIndexPath(_ indexPath: IndexPath) -> Habit {
        return viewModel.habits.value[indexPath.section - 1]
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.habits.value.count + 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numDates
    }

    func collectionViewHeader(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: checkGridHeaderCellIdentifier,
            for: indexPath
        ) as! CheckGridHeaderCell

        cell.backgroundColor = indexPath.row % 2 == 0 ?
            colBgColor1 :
            colBgColor2
        cell.bottomBorder.backgroundColor = borderColor

        cell.isHidden = false
        if indexPath.row == 0 {
            cell.isHidden = true
        } else {
            cell.contentLabel.text = dateLabels[indexPath.row - 1]
        }

        return cell
    }

    func collectionViewRowTitle(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: checkGridRowTitleCellIdentifier,
            for: indexPath
        ) as! CheckGridRowTitleCell

        let habit = getHabitForIndexPath(indexPath)

        cell.backgroundColor = rowTitleBgColor
        cell.name = habit.name
        cell.onRowNameButtonPressed = {
            self.performSegue(withIdentifier: "goToHabitDetails", sender: indexPath)
        }

        cell.updateUI()

        return cell
    }

    func collectionViewContent(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: checkGridContentCellIdentifier,
            for: indexPath
        ) as! CheckGridContentCell

        cell.backgroundColor = indexPath.row % 2 == 0 ?
            colBgColor1 :
            colBgColor2

        cell.contentLabel.text = Int.random(in: 0...1) == 0 ? "✓" : ""
        cell.contentLabel.textColor = checkboxColor
        cell.bottomBorder.backgroundColor = borderColor

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            return collectionViewHeader(collectionView, cellForItemAt: indexPath)
        } else if indexPath.row == 0 {
            return collectionViewRowTitle(collectionView, cellForItemAt: indexPath)
        } else {
            return collectionViewContent(collectionView, cellForItemAt: indexPath)
        }
    }
}


// MARK: - Collection delegate methods
extension HabitListViewController: UICollectionViewDelegate {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToHabitDetails" {
            let destinationVC = segue.destination as! HabitDetailsViewController
            if let indexPath = sender as? IndexPath {
                destinationVC.selectedHabit = getHabitForIndexPath(indexPath)
            }
        }
    }
}

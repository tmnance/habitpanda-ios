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

    var dateLabels: [String] = []
    var isInitiallyScrolledToToday = false
    var dateListSaturdayOffset = 0

    let checkGridHeaderCellIdentifier = "checkGridHeaderCell"
    let checkGridRowTitleCellIdentifier = "checkGridRowTitleCell"
    let checkGridContentCellIdentifier = "checkGridContentCell"

    override func viewDidLoad() {
        super.viewDidLoad()

        setupStylesAndBindings()
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

        viewModel.currentDate.bind { [unowned self] (_) in
            self.updateDateRange()
        }
    }
}


// MARK: - Data Update Callback Methods
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

    func updateDateRange() {
        let startDate = viewModel.startDate
        for item in 0..<viewModel.numDates {
            let date = Calendar.current.date(
                byAdding: .day,
                value: 1 * item,
                to: startDate
            )!
            let df = DateFormatter()

            df.dateFormat = "M"
            let monthNumber = df.string(from: date)

            df.dateFormat = "d"
            let dayNumber = df.string(from: date)

            df.dateFormat = "EEE"
            let dayName = df.string(from: date)
            dateLabels.append("\(dayName)\n\(monthNumber)/\(dayNumber)")
            if item == 0 {
                dateListSaturdayOffset = Calendar.current.component(.weekday, from: date) % 7
            }
        }
    }
}


// MARK: - UICollectionViewDataSource
extension HabitListViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // add additional section for header row
        return viewModel.habits.value.count + 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // add additional row for habit name column row
        return viewModel.numDates + 1
    }

    func collectionViewHeader(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: checkGridHeaderCellIdentifier,
            for: indexPath
        ) as! CheckGridHeaderCell

        cell.backgroundColor = getCellBgColor(forIndexPath: indexPath)
        cell.bottomBorder.backgroundColor = Constants.Colors.listBorderColor

        cell.isHidden = false
        if indexPath.row == 0 {
            cell.isHidden = true
        } else {
            cell.contentLabel.text = getDateLabel(forIndexPath: indexPath)
        }

        return cell
    }

    func collectionViewRowTitle(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: checkGridRowTitleCellIdentifier,
            for: indexPath
        ) as! CheckGridRowTitleCell

        let habit = getHabit(forIndexPath: indexPath)

        cell.backgroundColor = Constants.Colors.listRowOverlayBgColor
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

        let didCheckIn = getDidCheckIn(forIndexPath: indexPath)

        cell.backgroundColor = getCellBgColor(forIndexPath: indexPath)

        cell.contentLabel.text = didCheckIn ? "✓" : ""
        cell.contentLabel.textColor = Constants.Colors.tintColor
        cell.bottomBorder.backgroundColor = Constants.Colors.listBorderColor

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


// MARK: - Collection helper methods
extension HabitListViewController {
    func getHabit(forIndexPath indexPath: IndexPath) -> Habit {
        return viewModel.habits.value[indexPath.section - 1]
    }

    func getCellBgColor(forIndexPath indexPath: IndexPath) -> UIColor {
        let index = indexPath.row - 1
        let saturdayOffset = (index + dateListSaturdayOffset) % 7
        let isWeekend = saturdayOffset <= 1

        if isWeekend {
            return Constants.Colors.listWeekendBgColor
        }

        return saturdayOffset % 2 == 1 ?
            Constants.Colors.listWeekdayBgColor1 :
            Constants.Colors.listWeekdayBgColor2
    }

    func getDateLabel(forIndexPath indexPath: IndexPath) -> String {
        let index = indexPath.row - 1
        return dateLabels[index]
    }

    func getDidCheckIn(forIndexPath indexPath: IndexPath) -> Bool {
        let habit = getHabit(forIndexPath: indexPath)
        return viewModel.didCheckIn(forHabit: habit, forDateOffset: indexPath.row - 1)
    }
}


// MARK: - Collection delegate methods
extension HabitListViewController: UICollectionViewDelegate {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToHabitDetails" {
            let destinationVC = segue.destination as! HabitDetailsViewController
            if let indexPath = sender as? IndexPath {
                destinationVC.selectedHabit = getHabit(forIndexPath: indexPath)
            }
        }
    }
}

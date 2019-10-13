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
    @IBOutlet weak var noContentView: UIView!

    private var viewModel = HabitListViewModel()

    var dateLabels: [String] = []
    var isInitiallyScrolledToToday = false
    var dateListSaturdayOffset = 0

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
            UINib(nibName: "\(CheckInGridHeaderCell.self)", bundle: nil),
            forCellWithReuseIdentifier: "\(CheckInGridHeaderCell.self)"
        )
        collectionView.register(
            UINib(nibName: "\(CheckInGridRowTitleCell.self)", bundle: nil),
            forCellWithReuseIdentifier: "\(CheckInGridRowTitleCell.self)"
        )
        collectionView.register(
            UINib(nibName: "\(CheckInGridContentCell.self)", bundle: nil),
            forCellWithReuseIdentifier: "\(CheckInGridContentCell.self)"
        )

        viewModel.habits.bind { [unowned self] (_) in
            self.updateHabitsListDisplay()
        }

        viewModel.currentDate.bind { [unowned self] (_) in
            self.updateDateRange()
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc func willEnterForeground() {
        viewModel.reloadData()
    }
}


// MARK: - Data Update Callback Methods
extension HabitListViewController {
    func updateHabitsListDisplay() {
        let hasAnyHabits = viewModel.habits.value.count > 0

        noContentView.isHidden = hasAnyHabits
        collectionView.isHidden = !hasAnyHabits

        collectionView.reloadData()
        if let flowLayout = collectionView.collectionViewLayout as? CheckInGridCollectionViewLayout {
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
        dateLabels = []

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
//            withReuseIdentifier: "\(CheckInGridHeaderCell.self)",
            withReuseIdentifier: "\(CheckInGridHeaderCell.self)",
            for: indexPath
        ) as! CheckInGridHeaderCell

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
            withReuseIdentifier: "\(CheckInGridRowTitleCell.self)",
            for: indexPath
        ) as! CheckInGridRowTitleCell

        let habit = getHabit(forIndexPath: indexPath)

        cell.backgroundColor = Constants.Colors.listRowOverlayBgColor
        cell.additionalDetailsLabel.textColor = Constants.Colors.subTextColor

        cell.name = habit.name
        cell.additionalDetailsText = "🎯\n\(habit.frequencyPerWeek)x/wk"
        cell.onRowNameButtonPressed = {
            self.performSegue(withIdentifier: "goToHabitDetails", sender: indexPath)
        }

        cell.updateUI()

        return cell
    }

    func collectionViewContent(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "\(CheckInGridContentCell.self)",
            for: indexPath
        ) as! CheckInGridContentCell

        let checkInCount = getCheckInCount(forIndexPath: indexPath)

        cell.contentContainer.backgroundColor = checkInCount != nil ?
            UIColor.clear :
            Constants.Colors.listDisabledCellOverlayColor

        cell.backgroundColor = getCellBgColor(forIndexPath: indexPath)
        cell.countLabel.textColor = Constants.Colors.listCheckmarkColor
        cell.bottomBorder.backgroundColor = Constants.Colors.listBorderColor

        cell.checkInCount = checkInCount ?? 0

        cell.updateUI()

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

    func getCheckInCount(forIndexPath indexPath: IndexPath) -> Int? {
        let habit = getHabit(forIndexPath: indexPath)
        return viewModel.getCheckInCount(forHabit: habit, forDateOffset: indexPath.row - 1)
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

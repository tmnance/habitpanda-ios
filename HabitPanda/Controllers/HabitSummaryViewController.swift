//
//  HabitSummaryViewController.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/30/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit
import Charts

class HabitSummaryViewController: UIViewController {
    @IBOutlet weak var chartView: LineChartView!

    var delegateViewModel = HabitDetailsViewModel()
    var numbers: [Double] = []
    let numDates = 14

    override func viewDidLoad() {
        super.viewDidLoad()

        setupStylesAndBindings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateChartData()
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
extension HabitSummaryViewController {
    func setupStylesAndBindings() {
        setupChartSettings()
        updateChartData()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc func willEnterForeground() {
        updateChartData()
    }

    func setupChartSettings() {
        // disable interaction functionality
        chartView.pinchZoomEnabled = false
        chartView.dragEnabled = false
        chartView.scaleXEnabled = false
        chartView.scaleYEnabled = false
        chartView.doubleTapToZoomEnabled = false
        chartView.highlightPerTapEnabled = false

        chartView.legend.enabled = false
        chartView.rightAxis.enabled = false

        chartView.noDataText = "No check-in data yet"

        chartView.resetZoom()
        chartView.zoomToCenter(scaleX: 0.1, scaleY: 0.1)
        chartView.autoScaleMinMaxEnabled = false


        let leftAxis = chartView.leftAxis
        leftAxis.drawAxisLineEnabled = false
        leftAxis.granularity = 1.0

        let xAxis = chartView.xAxis
        xAxis.gridLineDashLengths = [10, 10]
        xAxis.gridLineDashPhase = 0
        xAxis.labelPosition = .bottom
        xAxis.drawAxisLineEnabled = false
        xAxis.granularity = 1.0
    }

    func updateChartSettings(withStartDate startDate: Date) {
        let targetFrequencyPerWeek = Double(delegateViewModel.frequencyPerWeek.value)
        let minY = max(
            0,
            min(targetFrequencyPerWeek, numbers.min()!) - 1
        )
        let maxY = min(
            7,
            max(numbers.max()!, targetFrequencyPerWeek) + 1
        )

        let targetLine = ChartLimitLine(
            limit: targetFrequencyPerWeek,
            label: "🎯\(Int(targetFrequencyPerWeek))x/wk"
        )
        targetLine.lineWidth = 2
        targetLine.lineColor = Constants.Colors.tintColor2
        targetLine.lineDashLengths = [10, 10]
        targetLine.labelPosition = targetFrequencyPerWeek >= maxY ? .bottomRight : .topRight
        targetLine.valueFont = .systemFont(ofSize: 12)
        targetLine.valueTextColor = Constants.Colors.subTextColor

        let leftAxis = chartView.leftAxis
        leftAxis.removeAllLimitLines()
        leftAxis.addLimitLine(targetLine)
        leftAxis.axisMinimum = minY - 0.5
        leftAxis.axisMaximum = maxY + 0.5

        let xAxis = chartView.xAxis
        xAxis.valueFormatter = DateValueFormatter(date: startDate)
        xAxis.axisMinimum = Double(numbers.count - 14) - 0.5
        xAxis.axisMaximum = Double(numbers.count - 1) + 0.5
    }

    func getLineChartDataSet(entries: [ChartDataEntry]) -> LineChartDataSet {
        let line = LineChartDataSet(entries: entries, label: "Check-in 7-day rolling average")
        line.colors = [Constants.Colors.tintColor]
        line.lineWidth = 4
        line.drawValuesEnabled = false
        line.drawCirclesEnabled = true
        line.circleColors = [Constants.Colors.tintColor]
        line.circleRadius = 2

        return line
    }
}


// MARK: - UI Update Methods
extension HabitSummaryViewController {
    func updateUI() {
//        frequencyLabel?.text = delegateViewModel.getFrequencyPerWeekDisplayText()
    }

    func updateChartData() {
        guard let firstCheckInDate = delegateViewModel.getFirstCheckIn()?.createdAt else {
            // no checkins found
            chartView.data = nil
            return
        }

        let currentDate = Date().stripTime()
        let startDate = max(
            firstCheckInDate,
            Calendar.current.date(
                byAdding: .day,
                value: -1 * (numDates - 1),
                to: currentDate
                )!
            ).stripTime()
        let firstCheckinOffset = Calendar.current.dateComponents(
            [.day],
            from: startDate,
            to: firstCheckInDate
            ).day ?? 0

        // this is the Array that will eventually be displayed on the chart.
        var lineChartEntry = [ChartDataEntry]()
        numbers = delegateViewModel.getCheckInFrequencyRollingAverageData(fromStartDate: startDate)
        updateChartSettings(withStartDate: startDate)

        //here is the for loop
        for startDateOffset in max(firstCheckinOffset, 0)..<numbers.count {
            // here we set the X and Y status in a data chart entry
            let value = ChartDataEntry(x: Double(startDateOffset), y: numbers[startDateOffset])
            // here we add it to the data set
            lineChartEntry.append(value)
        }

        let line1 = getLineChartDataSet(entries: lineChartEntry)

        // This is the object that will be added to the chart
        let data = LineChartData()
        data.addDataSet(line1)

        // finally - it adds the chart data to the chart and causes an update
        chartView.data = data
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

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
        chartView.noDataTextColor = Constants.Colors.label

        chartView.resetZoom()
        chartView.zoomToCenter(scaleX: 0.1, scaleY: 0.1)
        chartView.autoScaleMinMaxEnabled = false


        let leftAxis = chartView.leftAxis
        leftAxis.drawAxisLineEnabled = false
        leftAxis.granularity = 1.0
        leftAxis.gridColor = Constants.Colors.chartGrid
        leftAxis.labelTextColor = Constants.Colors.label

        let xAxis = chartView.xAxis
        xAxis.gridLineDashLengths = [10, 10]
        xAxis.gridLineDashPhase = 0
        xAxis.labelPosition = .bottom
        xAxis.drawAxisLineEnabled = false
        xAxis.granularity = 1.0
        xAxis.gridColor = Constants.Colors.chartGrid
        xAxis.labelTextColor = Constants.Colors.label
    }

    func updateChartSettings(withStartDate startDate: Date, andChartData chartData: [Double]) {
        let targetFrequencyPerWeek = Double(delegateViewModel.frequencyPerWeek.value)
        let minY = max(
            0,
            min(targetFrequencyPerWeek, chartData.min()!) - 1
        )
        let maxY = { () -> Double in
            let maxTemp = max(chartData.max()!, targetFrequencyPerWeek)
            return maxTemp == 7 ? 7 : maxTemp + 1
        }()

        let targetLine = ChartLimitLine(
            limit: targetFrequencyPerWeek,
            label: "🎯\(Int(targetFrequencyPerWeek))x/wk"
        )
        targetLine.lineWidth = 2
        targetLine.lineColor = Constants.Colors.tint2
        targetLine.lineDashLengths = [10, 10]
        targetLine.labelPosition = targetFrequencyPerWeek >= maxY - 1 ? .rightBottom : .rightTop
        targetLine.valueFont = .systemFont(ofSize: 12)
        targetLine.valueTextColor = Constants.Colors.subText

        let leftAxis = chartView.leftAxis
        leftAxis.removeAllLimitLines()
        leftAxis.addLimitLine(targetLine)
        leftAxis.axisMinimum = minY - 0.5
        leftAxis.axisMaximum = maxY + 0.5

        let xAxis = chartView.xAxis
        xAxis.valueFormatter = DateValueFormatter(date: startDate)
        xAxis.axisMinimum = Double(chartData.count - numDates) - 0.5
        xAxis.axisMaximum = Double(chartData.count - 1) + 0.5
    }

    func getLineChartDataSet(
        fromChartData chartData: [Double],
        withLabel label: String
    ) -> LineChartDataSet {
        var entries = [ChartDataEntry]()

        for startDateOffset in 0..<chartData.count {
            let value = ChartDataEntry(x: Double(startDateOffset), y: chartData[startDateOffset])
            entries.append(value)
        }

        return LineChartDataSet(entries: entries, label: label)
    }

    func setupLineChartDataSetStyles(_ line: LineChartDataSet) {
        line.colors = [Constants.Colors.tint]
        line.lineWidth = 4
        line.drawValuesEnabled = false
        line.drawCirclesEnabled = true
        line.circleColors = [Constants.Colors.tint]
        line.circleRadius = 2
    }
}


// MARK: - UI Update Methods
extension HabitSummaryViewController {
    func updateChartData() {
        guard let firstCheckInDate = delegateViewModel.getFirstCheckIn()?.checkInDate else {
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

        let chartData = delegateViewModel.getCheckInFrequencyRollingAverageData(
            fromStartDate: startDate
        )
        updateChartSettings(withStartDate: startDate, andChartData: chartData)

        let line1 = getLineChartDataSet(
            fromChartData: chartData,
            withLabel: "Check-in 7-day rolling average"
        )
        setupLineChartDataSetStyles(line1)

        let data = LineChartData()
        data.append(line1)

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

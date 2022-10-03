//
//  DateValueFormatter.swift
//  HabitPanda
//
//  Created by Tim Nance on 5/30/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import Foundation
import Charts

public class DateValueFormatter: NSObject, AxisValueFormatter {
    private let dateFormatter = DateFormatter()
    private var startDate: Date = Date()

    override init() {
        super.init()
        initialize()
    }

    init(date: Date) {
        super.init()
        initialize()
        self.startDate = date
    }

    private func initialize() {
        dateFormatter.dateFormat = "EEE'\n'M'/'d"
    }

    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let date = Calendar.current.date(
            byAdding: .day,
            value: 1 * Int(value),
            to: startDate
        )!

        return dateFormatter.string(from: date)
    }
}

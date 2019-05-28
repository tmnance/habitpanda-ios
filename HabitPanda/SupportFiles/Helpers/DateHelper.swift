//
//  DateHelper.swift
//  HabitPanda
//
//  Created by Tim Nance on 5/28/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import Foundation

struct DateHelper {
    enum DateFormat: String {
        case dateOnly, timeOnly, dateAndTime
    }

    static func getDateString(forDate date: Date, withFormat format: DateFormat) -> String {
        let df = DateFormatter()
        var displayDate = ""

        if format == .dateOnly || format == .dateAndTime {
            df.dateFormat = "EEE, MMMM d"
            displayDate = df.string(from: date)
        }

        if format == .timeOnly || format == .dateAndTime {
            df.dateFormat = "h:mm a"
            displayDate += displayDate == "" ? "" : " at "
            displayDate += df.string(from: date)
        }

        return displayDate
    }
}

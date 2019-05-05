//
//  TimeOfDay.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/25/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import Foundation

struct TimeOfDay {
    var hour: Int
    var minute: Int

    func getDisplayDate() -> String {
        return TimeOfDay.getDisplayDate(hour: hour, minute: minute)
    }

    static func getDisplayDate(hour: Int, minute: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat =  "HH:mm"
        let date = dateFormatter.date(from: "\(hour):\(minute)")
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: date!)
    }

    static func generateFromCurrentTime(witMinuteRounding minuteRounding: Int? = nil) -> TimeOfDay {
        var now = Date()
        if minuteRounding != nil {
            now = now.rounded(
                minutes: TimeInterval(minuteRounding!),
                rounding: .floor
            )
        }
        let components = Calendar.current.dateComponents(
            [.hour, .minute],
            from: now
        )
        return TimeOfDay(hour: components.hour!, minute: components.minute!)
    }
}

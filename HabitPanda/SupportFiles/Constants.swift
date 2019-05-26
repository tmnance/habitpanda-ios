//
//  Constants.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/30/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit

struct Constants {
    struct Colors {
        // 0F7583
        static let tintColor = UIColor(red: 15/255.0, green: 117/255.0, blue: 131/255.0, alpha: 1.0)
//        static let tintColor = UIColor(red: 0.06, green: 0.46, blue: 0.51, alpha: 1.0)
        static let tintColor2 = UIColor.orange
        // CCCCCC
        static let disabledTextColor = UIColor(red:0.80, green:0.80, blue:0.80, alpha:1.0)

        static let listAlternatingBgColor1 = UIColor(white: 230/255.0, alpha: 1)
        static let listAlternatingBgColor2 = UIColor(white: 240/255.0, alpha: 1)
        static let listRowOverlayBgColor = UIColor(white: 255/255.0, alpha: 0.60)
    }

    struct Habit {
        // mirrors the default Habit.frequencyPerWeek attribute in DataModel.xcdatamodel
        static let defaultFrequencyPerWeek = 1
    }

    struct Reminder {
        static let maxReminderNotificationCount = 50
    }

    struct TimePicker {
        static let minuteInterval = 5
    }
}

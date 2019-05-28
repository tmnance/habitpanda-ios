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
        static let tintColor = UIColor(red: 15/255, green: 117/255, blue: 131/255, alpha: 1)

        static let tintColor2 = UIColor.orange
        // CCCCCC
        static let disabledTextColor = UIColor(white: 204/255, alpha: 1)

        static let listWeekdayBgColor1 = UIColor(white: 230/255, alpha: 1)
        static let listWeekdayBgColor2 = UIColor(white: 240/255, alpha: 1)
        static let listWeekendBgColor = UIColor(
            red: 215/255,
            green: 223/255,
            blue: 225/255,
            alpha: 1
        )
        static let listCheckmarkColor = UIColor(white: 70/255, alpha: 1)
        static let listRowOverlayBgColor = UIColor(white: 255/255, alpha: 0.6)
        static let listBorderColor = UIColor(white: 60/255, alpha: 0.6)
        static let listDisabledCellOverlayColor = UIColor(
            patternImage: UIImage(named: "disabled-diag-stripe")!
        ).withAlphaComponent(0.05)

        static let toastSuccessBgColor = UIColor(
            red: 76/255,
            green: 209/255,
            blue: 55/255,
            alpha: 1
        )
        static let toastErrorBgColor = UIColor(
            red: 232/255,
            green: 65/255,
            blue: 24/255,
            alpha: 1
        )
        static let toastWarningBgColor = UIColor(
            red: 251/255,
            green: 197/255,
            blue: 49/255,
            alpha: 1
        )
        static let toastInfoBgColor = UIColor(
            red: 53/255,
            green: 59/255,
            blue: 72/255,
            alpha: 1
        )
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

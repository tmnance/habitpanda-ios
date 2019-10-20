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
        static let clear = UIColor.clear

        static let tintColor = UIColor(named: "tint")!
        static let textColorForTintBackground = UIColor(named: "textForTintBackground")!

        static let tintColor2 = UIColor(named: "tint2")!
        static let disabledTextColor = UIColor(named: "disabledText")!
        static let subTextColor = UIColor(named: "subText")!

        static let listWeekdayBgColor1 = UIColor(named: "listWeekdayBg1")!
        static let listWeekdayBgColor2 = UIColor(named: "listWeekdayBg2")!
        static let listWeekendBgColor = UIColor(named: "listWeekendBg")!
        static let listCheckmarkColor = UIColor(named: "listCheckmark")!
        static let listRowOverlayBgColor = UIColor(named: "listRowOverlayBg")!
        static let listBorderColor = UIColor(named: "listBorder")!
        static let listDisabledCellOverlayColor = UIColor(
            patternImage: UIImage(named: "disabled-diag-stripe")!
        ).withAlphaComponent(0.05)

        static let toastSuccessBgColor = UIColor(named: "toastSuccessBg")!
        static let toastErrorBgColor = UIColor(named: "toastErrorBg")!
        static let toastWarningBgColor = UIColor(named: "toastWarningBg")!
        static let toastInfoBgColor = UIColor(named: "toastInfoBg")!
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

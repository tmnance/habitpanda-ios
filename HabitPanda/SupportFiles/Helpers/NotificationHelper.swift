//
//  NotificationHelper.swift
//  HabitPanda
//
//  Created by Tim Nance on 5/3/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import Foundation
import UserNotifications

class NotificationHelper {
    static var isGranted = false

    static func setCategories() {
        let clearRepeatAction = UNNotificationAction(
            identifier: "clear.repeat.action",
            title: "Stop Repeat",
            options: [])
        let pizzaCategory = UNNotificationCategory(
            identifier: "pizza.reminder.category",
            actions: [clearRepeatAction],
            intentIdentifiers: [],
            options: [])
        UNUserNotificationCenter.current().setNotificationCategories([pizzaCategory])
    }

    static func cleanRepeatingNotifications() {
        // cleans notification with a userInfo key endDate which have expired.
        let center = UNUserNotificationCenter.current()
        var cleanStatus = "Cleaning...."
        center.getPendingNotificationRequests { (requests) in
            for request in requests{
                if let endDate = request.content.userInfo["endDate"] {
                    if Date() >= (endDate as! Date) {
                        cleanStatus += "Cleaned request"
                        center.removePendingNotificationRequests(
                            withIdentifiers: [request.identifier]
                        )
                    } else {
                        cleanStatus += "No Cleaning"
                    }
                    print(cleanStatus)
                }
            }
        }
    }

    static func removeAllPendingNotifications() {
        let center = UNUserNotificationCenter.current()
        // remove all pending notifications which are scheduled but not yet delivered
        center.removeAllPendingNotificationRequests()
    }

    static func removeAllDeliveredNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllDeliveredNotifications()
    }
}

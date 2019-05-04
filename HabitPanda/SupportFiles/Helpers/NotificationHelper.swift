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

    static func sendPushNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Notif Title"
        content.body = "Notif Body"
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

        //        let trigger2 = UNCalendarNotificationTrigger(dateMatching: <#T##DateComponents#>, repeats: false)

        let request = UNNotificationRequest(
            identifier: "testIdentifier", // old notifications requests will be overridden when new ones are setup
            content: content,
            trigger: trigger)

        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }




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

    static func getPendingNotificationCount() -> Int? {
//        return UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
//        }
        return nil
    }
}

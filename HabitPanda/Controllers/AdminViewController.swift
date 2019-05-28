//
//  AdminViewController.swift
//  HabitPanda
//
//  Created by Tim Nance on 5/3/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

class AdminViewController: UIViewController {
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    @IBOutlet weak var notificationsReportText: UILabel!

    var isLoading = false
    var pendingRequests: [UNNotificationRequest] = []
    var deliveredNotifications: [UNNotification] = []
    var reminders: [Reminder] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        loadNotificationData()
        loadRemindersData()

        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
        print("NotificationHelper.isGranted = \(NotificationHelper.isGranted)")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    @IBAction func adminButtonPressed(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            NotificationHelper.removeAllPendingNotifications()
            loadNotificationData()
            ToastHelper.makeToast("Pending notifications removed", state: .info)
        case 1:
            NotificationHelper.removeAllDeliveredNotifications()
            loadNotificationData()
            ToastHelper.makeToast("Sent notifications removed", state: .info)
        case 2:
            ReminderNotificationService.removeOrphanedDeliveredNotifications()
            loadNotificationData()
            ToastHelper.makeToast("Orphaned sent notifications removed", state: .info)
        case 3:
            ReminderNotificationService.refreshNotificationsForAllReminders()
            loadNotificationData()
            ToastHelper.makeToast("All notifications refreshed", state: .info)
        case 4:
            ReminderNotificationService.sendTestNotification()
            ToastHelper.makeToast("Test notification sent", state: .info)
        default:
            print("Unrecognized")
        }
        updateUI()
    }
}


extension AdminViewController {
    func loadNotificationData() {
        var loadingNum = 2
        let loadedCallback = {
            loadingNum -= 1
            if loadingNum == 0 {
                self.isLoading = false
                self.updateUI()
            }
        }

        isLoading = true
        updateUI()

        UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
            // send to main thread
            DispatchQueue.main.async {
                self.pendingRequests = requests
                loadedCallback()
            }
        }

        UNUserNotificationCenter.current().getDeliveredNotifications { (notifications) in
            // send to main thread
            DispatchQueue.main.async {
                self.deliveredNotifications = notifications
                loadedCallback()
            }
        }
    }

    func updateUI() {
        if isLoading {
            notificationsReportText.text = "Loading..."
            return
        }

        notificationsReportText.text =
            "\(getAppVersionString())\n\n" +
            "\(getRemindersReportString())\n\n" +
            "\(getNotificationsReportString())"
    }

    func getNotificationsReportString() -> String {
        return "Notifications:\n" +
            "- \(pendingRequests.count) pending notification(s) set\n" +
            "- \(deliveredNotifications.count) delivered notification(s)"
    }
}


extension AdminViewController {
    private func loadRemindersData() {
        reminders = Reminder.getAll()
        updateUI()
    }

    func getRemindersReportString() -> String {
        var notificationCount = 0
        var habitUUIDs = Set<UUID>()

        let remindersByDay = ReminderNotificationService.RemindersForWeek(forReminders: reminders)

        let currentWeekdayIndex = ReminderNotificationService.getCurrentWeekdayIndex()
        let weekdayIndexLoop = ReminderNotificationService.getNext7DayWeekdayIndexLoop()
        let currentTimeInMinutes = TimeOfDay.generateFromCurrentTime().getTimeInMinutes()

        for (i, weekdayIndex) in weekdayIndexLoop.enumerated() {
            let remindersForDay = remindersByDay.getForWeekdayIndex(weekdayIndex)
            let sortedTimes = remindersForDay.getSortedTimes()

            for time in sortedTimes {
                if i == 0 && weekdayIndex == currentWeekdayIndex && time <= currentTimeInMinutes {
                    continue
                }
                let remindersForDayAndTime = remindersForDay.getForTime(time)
                for reminder in remindersForDayAndTime {
                    notificationCount += 1
                    habitUUIDs.insert(reminder.habit!.uuid!)
                }
            }
        }

        return "Reminders:\n" +
            "- currentWeekdayIndex = \(currentWeekdayIndex)\n" +
            "- weekdayIndexLoop = \(weekdayIndexLoop)\n" +
            "- currentTimeInMinutes = \(currentTimeInMinutes)\n" +
            "- \(notificationCount) notification\(notificationCount == 1 ? "" : "s") " +
            "will be needed across \(habitUUIDs.count) habit\(habitUUIDs.count == 1 ? "" : "s")"
    }
}


extension AdminViewController {
    func getAppVersionString() -> String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        let appName = dictionary["CFBundleName"] as! String

        return "App version: \(appName) v\(version) (Build \(build))\n" +
            "- buildDate = \(getDateAsString(buildDate))"
    }

    func getDateAsString(_ date: Date) -> String {
        let df = DateFormatter()

        df.dateFormat = "EEE, MMMM d"
        let displayDate = df.string(from: date)

        df.dateFormat = "h:mm a"
        let displayTime = df.string(from: date)

        return "\(displayDate) at \(displayTime)"
    }

    var buildDate:Date
    {
        if let infoPath = Bundle.main.path(forResource: "Info.plist", ofType: nil),
            let infoAttr = try? FileManager.default.attributesOfItem(atPath: infoPath),
            let infoDate = infoAttr[FileAttributeKey.creationDate] as? Date
            {
                return infoDate
            }
        return Date()
    }
}

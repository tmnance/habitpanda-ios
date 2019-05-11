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
        case 1:
            NotificationHelper.removeAllDeliveredNotifications()
            loadNotificationData()
        case 2:
            ReminderNotificationService.refreshNotificationsForAllReminders()
            loadNotificationData()
        case 3:
            NotificationHelper.sendTestPushNotification()
        default:
            print("Unrecognized")
        }
        updateUI()
    }
}


extension AdminViewController {
    func loadNotificationData() {
        isLoading = true
        updateUI()
        UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
            // send to main thread
            DispatchQueue.main.async{
                self.isLoading = false
                self.pendingRequests = requests
                self.updateUI()
            }
        }
    }

    func updateUI() {
        if isLoading {
            notificationsReportText.text = "Loading..."
            return
        }

        notificationsReportText.text = "\(getRemindersReportString())\n\n" +
            "\(getNotificationsReportString())"
    }

    func getNotificationsReportString() -> String {
        return "Notifications:\n" +
            "- \(pendingRequests.count) pending notification(s) set"
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

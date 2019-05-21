//
//  ReminderNotificationService.swift
//  HabitPanda
//
//  Created by Tim Nance on 5/9/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import Foundation
import UserNotifications

struct ReminderNotificationService {
    typealias WeekdayIndex = Int
    typealias TimeInMinutes = Int
    typealias RemindersByDay = [WeekdayIndex: RemindersForDay]

    struct RemindersForDay {
        var value: [TimeInMinutes: [Reminder]] = [:]

        mutating func addReminder(_ reminder: Reminder) {
            let time = reminder.getTimeInMinutes()
            if value[time] == nil {
                value[time] = []
            }
            value[time]!.append(reminder)
        }

        func getSortedTimes() -> [TimeInMinutes] {
            return [TimeInMinutes](value.keys).sorted(by: <)
        }

        func getForTime(_ time: TimeInMinutes) -> [Reminder] {
            return value[time] ?? []
        }
    }

    struct RemindersForWeek {
        private var value: [WeekdayIndex: RemindersForDay] = [:]

        init(forReminders reminders: [Reminder]) {
            // stub out each day
            [WeekdayIndex](0...6).forEach{ value[$0] = RemindersForDay() }

            reminders.forEach{ (reminder) in
                reminder.frequencyDays?.forEach{
                    let reminderWeekdayIndex = $0.intValue
                    value[reminderWeekdayIndex]!.addReminder(reminder)
                }
            }
        }

        func getForWeekdayIndex(_ weekdayIndex: WeekdayIndex) -> RemindersForDay {
            return value[weekdayIndex] ?? RemindersForDay()
        }
    }
}


// Mark: - Weekday Index methods
extension ReminderNotificationService {
    static func getNext7DayWeekdayIndexLoop(
        startingFromWeekdayIndex startingWeekdayIndex: WeekdayIndex = getCurrentWeekdayIndex()
    ) -> [WeekdayIndex] {
        return [WeekdayIndex](startingWeekdayIndex...6) + [WeekdayIndex](0..<startingWeekdayIndex)
    }

    static func getCurrentWeekdayIndex() -> WeekdayIndex {
        return Calendar.current.component(.weekday, from: Date()) - 1
    }
}


// Mark: - Setup methods
extension ReminderNotificationService {
    static func refreshNotificationsForAllReminders() {
        // TODO: may eventually have other non-reminder notifications that shouldn't be cleared
        NotificationHelper.removeAllPendingNotifications()

        setupNotificationsForReminders(Reminder.getAll())
    }

    static func setupNotificationsForReminders(_ reminders: [Reminder]) {
        var notificationCount = 0
        var habitUUIDs = Set<UUID>()

        let remindersByDay = RemindersForWeek(forReminders: reminders)

        let currentWeekdayIndex = getCurrentWeekdayIndex()
        let weekdayIndexLoop = getNext7DayWeekdayIndexLoop()
        let currentTimeInMinutes = TimeOfDay.generateFromCurrentTime().getTimeInMinutes()

        outerLoop: for (i, weekdayIndex) in weekdayIndexLoop.enumerated() {
            let remindersForDay = remindersByDay.getForWeekdayIndex(weekdayIndex)
            let sortedTimes = remindersForDay.getSortedTimes()

            for time in sortedTimes {
                if i == 0 && weekdayIndex == currentWeekdayIndex && time <= currentTimeInMinutes {
                    continue
                }
                let remindersForDayAndTime = remindersForDay.getForTime(time)
                for reminder in remindersForDayAndTime {
                    setupNotificationForReminder(reminder, forWeekdayIndex: weekdayIndex)
                    habitUUIDs.insert(reminder.habit!.uuid!)
                    notificationCount += 1
                    if notificationCount >= Constants.Reminder.maxReminderNotificationCount {
                        break outerLoop
                    }
                }
            }
        }
    }

    static func setupNotificationForReminder(
        _ reminder: Reminder,
        forWeekdayIndex weekdayIndex: WeekdayIndex
    ) {
        let time = reminder.getTimeInMinutes()
        let habit = reminder.habit!

        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar.current
        dateComponents.weekday = weekdayIndex + 1
        dateComponents.hour = Int(reminder.hour)
        dateComponents.minute = Int(reminder.minute)

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let content = UNMutableNotificationContent()

        //adding title, subtitle, body and badge
        content.title = "Reminder for \(habit.name!)"
        content.subtitle = "Friendly reminder to check-in scheduled for \(reminder.getTimeOfDay().getDisplayDate())"
        content.body = "Notification body!"
        content.userInfo = [
            "reminderUUID": reminder.uuid!.uuidString
        ]

        let request = UNNotificationRequest(
            identifier: "\(reminder.uuid!).\(weekdayIndex).\(time)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { (error) in
            if error != nil {
                print("Error scheduling notification for (\"\(reminder.habit!.name!)\", \(weekdayIndex):\(time))")
            }
        }

        print("  - setupNotificationForReminder(\"\(reminder.habit!.name!)\", \(weekdayIndex):\(time))")
    }

    static func removeOrphanedDeliveredNotifications() {
        UNUserNotificationCenter.current().getDeliveredNotifications { (notifications) in
            // send to main thread
            DispatchQueue.main.async {
                var identifiersToRemove: [String] = []

                notifications.forEach({ (notification) in
                    let userInfo = notification.request.content.userInfo
                    guard
                        let reminderUUID = UUID(uuidString: userInfo["reminderUUID"] as? String ?? ""),
                        let _ = Reminder.get(withUUID: reminderUUID)
                        else {
                            identifiersToRemove.append(notification.request.identifier)
                            return
                        }
                })

                if identifiersToRemove.count > 0 {
                    UNUserNotificationCenter.current().removeDeliveredNotifications(
                        withIdentifiers: identifiersToRemove
                    )
                }
            }
        }

    }
}

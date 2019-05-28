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


// Mark: - Weekday index methods
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


// Mark: - Notification setup methods
extension ReminderNotificationService {
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

        let identifier = "\(reminder.uuid!).\(weekdayIndex).\(time)"
        let content = getNotificationContentForReminder(reminder)
        let trigger = getNotificationTriggerForReminder(reminder, forWeekdayIndex: weekdayIndex)
        let debugIdentifier = "(Habit: \"\(reminder.habit!.name!)\", Time:\(weekdayIndex):\(time))"

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                print("Error scheduling notification for \(debugIdentifier) -> \(error)")
            }
        }

//        print("  - setupNotificationForReminder(\(debugIdentifier))")
    }

    static func getNotificationContentForReminder(_ reminder: Reminder) -> UNNotificationContent {
        let content = UNMutableNotificationContent()

        let habit = reminder.habit!
        let frequencyPerWeek = Int(habit.frequencyPerWeek)

        // setup title, subtitle, body, badge, userInfo
        content.title = "Habit check-in reminder!"
        content.body = "Friendly reminder regarding your habit \"\(habit.name!)\" that you are " +
        "aiming to perform \(frequencyPerWeek) time\(frequencyPerWeek == 1 ? "" : "s") / week."
        content.userInfo = [
            "reminderUUID": reminder.uuid!.uuidString
        ]

        return content
    }

    static func getNotificationTriggerForReminder(
        _ reminder: Reminder,
        forWeekdayIndex weekdayIndex: WeekdayIndex
    ) -> UNCalendarNotificationTrigger {
        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar.current
        dateComponents.weekday = weekdayIndex + 1
        dateComponents.hour = Int(reminder.hour)
        dateComponents.minute = Int(reminder.minute)

        return UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
    }
}


// Mark: - Cleanup methods
extension ReminderNotificationService {
    static func refreshNotificationsForAllReminders() {
        // TODO: may eventually have other non-reminder notifications that shouldn't be cleared
        NotificationHelper.removeAllPendingNotifications()

        setupNotificationsForReminders(Reminder.getAll())
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

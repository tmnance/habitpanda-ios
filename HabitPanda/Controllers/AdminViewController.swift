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
    struct AdminAction {
        let name: String
        let action: () -> Void

        init(name: String, action: @escaping () -> Void) {
            self.name = name
            self.action = action
        }
    }

    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    @IBOutlet weak var notificationsReportText: UILabel!
    @IBOutlet weak var actionsTableView: UITableView!

    var isLoading = false
    var pendingRequests: [UNNotificationRequest] = []
    var deliveredNotifications: [UNNotification] = []
    var reminders: [Reminder] = []

    lazy var actions = [
        AdminAction(
            name: "Remove all pending notifications",
            action: {
                NotificationHelper.removeAllPendingNotifications()
                self.loadNotificationData()
                ToastHelper.makeToast("Pending notifications removed", state: .info)
            }
        ),
        AdminAction(
            name: "Remove all sent notifications",
            action: {
                NotificationHelper.removeAllDeliveredNotifications()
                self.loadNotificationData()
                ToastHelper.makeToast("Sent notifications removed", state: .info)
            }
        ),
        AdminAction(
            name: "Remove orphaned sent notifications",
            action: {
                ReminderNotificationService.removeOrphanedDeliveredNotifications()
                self.loadNotificationData()
                ToastHelper.makeToast("Orphaned sent notifications removed", state: .info)
            }
        ),
        AdminAction(
            name: "(Re)set all notifications",
            action: {
                ReminderNotificationService.refreshNotificationsForAllReminders()
                self.loadNotificationData()
                ToastHelper.makeToast("All notifications refreshed", state: .info)
            }
        ),
        AdminAction(
            name: "Send test notification",
            action: {
                ReminderNotificationService.sendTestNotification()
                ToastHelper.makeToast("Test notification sent", state: .info)
            }
        ),
        AdminAction(
            name: "Seed test data",
            action: {
                self.seedTestData()
            }
        ),
        AdminAction(
            name: "Delete all data",
            action: {
                self.deleteAllData()
            }
        ),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupStylesAndBindings()
        loadNotificationData()
        loadRemindersData()

        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
        print("NotificationHelper.isGranted = \(NotificationHelper.isGranted)")
    }
}


// MARK: - Setup Methods
extension AdminViewController {
    func setupStylesAndBindings() {
        actionsTableView.delegate = self
        actionsTableView.dataSource = self
        actionsTableView.separatorStyle = .none
    }
}


// MARK: - Tableview Datasource Methods
extension AdminViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "ActionCell",
            for: indexPath
        )
        let action = actions[indexPath.row]

        cell.textLabel?.text = action.name

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let action = actions[indexPath.row]

        actionsTableView.deselectRow(at: indexPath, animated: true)
        action.action()
    }
}


// MARK: - UI Update Methods
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


extension AdminViewController {
    func seedTestData() {
        let alert = UIAlertController(
            title: "Confirm Seed Data",
            message: "Warning: seeding test data will clear all existing data",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Confirm", style: .destructive) { (action) in
            self.createSeedTestHabits()
            ReminderNotificationService.refreshNotificationsForAllReminders()
            self.loadNotificationData()
            ToastHelper.makeToast("Test data seeded", state: .info)
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alert, animated: true, completion: nil)
    }

    func deleteAllData() {
        let alert = UIAlertController(
            title: "Delete All Data",
            message: "Warning: this will clear all existing data",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Confirm", style: .destructive) { (action) in
            self.deleteAllHabits()
            ReminderNotificationService.refreshNotificationsForAllReminders()
            self.loadNotificationData()
            ToastHelper.makeToast("All habit data deleted", state: .info)
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alert, animated: true, completion: nil)
    }

    func createSeedTestHabits() {
        deleteAllHabits()

        let seedHabits:[[String:Any]] = [
            [
                "name": "Call mom",
                "frequencyPerWeek": 1,
                //                 98765432109876543210
                "checkInHistory": "    X      X      X "
            ],
            [
                "name": "Do some form of exercise",
                "frequencyPerWeek": 5,
                //                 98765432109876543210
                "checkInHistory": " XXX X  X X X X 2 XX"
            ],
            [
                "name": "Have a no-TV night",
                "frequencyPerWeek": 2,
                //                 98765432109876543210
                "checkInHistory": " X  X      X      X "
            ],
            [
                "name": "Make the bed every morning",
                "frequencyPerWeek": 7,
                //                 98765432109876543210
                "checkInHistory": "XXXXXXXXXXXXXXXXXXXX",
                "reminders": [
                    [
                        "hour": 8,
                        "minute": 30,
                        //                SMTWTFS
                        "frequencyDays": "X     X",
                    ],
                    [
                        "hour": 7,
                        "minute": 30,
                        //                SMTWTFS
                        "frequencyDays": " XXXXX ",
                    ],
                ],
            ],
            [
                "name": "Read for fun or growth 20 minutes",
                "frequencyPerWeek": 5,
                //                 98765432109876543210
                "checkInHistory": " X X X X XXXX X XX X"
            ],
            [
                "name": "Take daily vitamins",
                "frequencyPerWeek": 7,
                //                 98765432109876543210
                "checkInHistory": "XX XXXXXXXXXX XXXXXX"
            ],
        ]

        let createdAtDate = Calendar.current.date(
            byAdding: .day,
            value: -20,
            to: Date()
        )!

        seedHabits.enumerated().forEach{ (i, seedHabit) in
            let newHabit = createSeedHabit(
                withName: seedHabit["name"] as? String ?? "",
                withFrequencyPerWeek: seedHabit["frequencyPerWeek"] as? Int ?? 1,
                forDate: Calendar.current.date(
                    byAdding: .second,
                    value: i,
                    to: createdAtDate
                )!,
                withOrder: i
            )

            Array(seedHabit["checkInHistory"] as? String ?? "").reversed().enumerated()
                .forEach{ (dayOffset, checkInState) in
                    let checkInCount: Int = {
                        switch checkInState {
                        case " ":
                            return 0
                        case "X":
                            return 1
                        default:
                            return Int("\(checkInState)") ?? 0
                        }
                    }()

                    if checkInCount > 0 {
                        let checkInDate = Calendar.current.date(
                            byAdding: .day,
                            value: -1 * dayOffset,
                            to: Date()
                        )!
                        (0..<checkInCount).forEach{ _ in
                            let _ = createSeedCheckIn(forHabit: newHabit, forDate: checkInDate)
                        }
                    }
                }

            if let seedReminders = seedHabit["reminders"] as? [[String:Any]] {
                seedReminders.forEach{ (seedReminder) in
                    let _ = createSeedReminder(
                        forHabit: newHabit,
                        withHour: seedReminder["hour"] as? Int ?? 0,
                        withMinute: seedReminder["minute"] as? Int ?? 0,
                        withFrequencyDays: seedReminder["frequencyDays"] as? String ?? ""
                    )
                }
            }
        }

        do {
            try context.save()
        } catch {
            print("Error saving context, \(error)")
        }
    }

    func createSeedHabit(
        withName name: String,
        withFrequencyPerWeek frequencyPerWeek: Int,
        forDate date: Date,
        withOrder order: Int
    ) -> Habit {
        let habitToSave = Habit(context: context)
        habitToSave.createdAt = date
        habitToSave.uuid = UUID()
        habitToSave.name = name
        habitToSave.frequencyPerWeek = Int32(frequencyPerWeek)
        habitToSave.order = Int32(order)

        return habitToSave
    }

    func createSeedCheckIn(forHabit habit: Habit, forDate date: Date) -> CheckIn {
        let checkInToSave = CheckIn(context: context)
        checkInToSave.createdAt = date
        checkInToSave.uuid = UUID()
        checkInToSave.habit = habit
        checkInToSave.checkInDate = date.stripTime()
        checkInToSave.isSuccess = true

        return checkInToSave
    }

    func createSeedReminder(
        forHabit habit: Habit,
        withHour hour: Int,
        withMinute minute: Int,
        withFrequencyDays frequencyDays: String
        ) -> Reminder {
        let reminderToSave = Reminder(context: context)
        reminderToSave.createdAt = Date()
        reminderToSave.uuid = UUID()
        reminderToSave.habit = habit

        reminderToSave.hour = Int32(hour)
        reminderToSave.minute = Int32(minute)
        reminderToSave.frequencyDays =
            Array(frequencyDays).enumerated().filter{ $0.1 != " " }.map{ $0.0 as NSNumber }

        return reminderToSave
    }

    func deleteAllHabits() {
        Habit.getAll().forEach({ context.delete($0) })

        do {
            try context.save()
        } catch {
            print("Error saving context, \(error)")
        }
    }
}

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
                self.showConfirmPrompt(
                    title: "Confirm Seed Data",
                    message: "Warning: seeding test data will clear all existing data"
                ) {
                    self.createSeedTestHabits()
                    ReminderNotificationService.refreshNotificationsForAllReminders()
                    self.loadNotificationData()
                    ToastHelper.makeToast("Test data seeded", state: .info)
                }
            }
        ),
        AdminAction(
            name: "Delete all data",
            action: {
                self.showConfirmPrompt(
                    title: "Delete All Data",
                    message: "Warning: this will clear all existing data"
                ) {
                    self.deleteAllHabits()
                    ReminderNotificationService.refreshNotificationsForAllReminders()
                    self.loadNotificationData()
                    ToastHelper.makeToast("All habit data deleted", state: .info)
                }
            }
        ),
        AdminAction(
            name: "Export current data",
            action: {
                self.exportCurrentData()
                ToastHelper.makeToast("Current data exported to clipboard", state: .info)
            }
        ),
        AdminAction(
            name: "Import data",
            action: {
                self.showConfirmPrompt(
                    title: "Import data from clipboard",
                    message: "Warning: this will clear all existing data"
                ) {
                    if self.importData() {
                        ToastHelper.makeToast("Data imported from clipboard", state: .info)
                        ReminderNotificationService.refreshNotificationsForAllReminders()
                        self.loadNotificationData()
                    } else {
                        ToastHelper.makeToast("Unable to import data from clipboard", state: .info)
                    }
                }
            }
        ),
    ]

    func showConfirmPrompt(title: String, message: String, confirmCallback: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Confirm", style: .destructive) { _ in confirmCallback() })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

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


// MARK: - Data Seed/Delete Methods
extension AdminViewController {
    func createSeedTestHabits() {
        deleteAllHabits()

        let seedHabits: [[String:Any]] = [
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
            let newHabit = createHabit(
                name: seedHabit["name"] as? String ?? "",
                frequencyPerWeek: seedHabit["frequencyPerWeek"] as? Int ?? 1,
                createdAt: Calendar.current.date(
                    byAdding: .second,
                    value: i,
                    to: createdAtDate
                )!,
                order: i
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
                            let _ = createCheckIn(habit: newHabit, createdAt: checkInDate)
                        }
                    }
                }

            if let seedReminders = seedHabit["reminders"] as? [[String:Any]] {
                seedReminders.forEach{ (seedReminder) in
                    let frequencyDays = Array(seedReminder["frequencyDays"] as? String ?? "")
                        .enumerated()
                        .filter { $0.1 != " " }
                        .map { $0.0 as Int }
                    let _ = createReminder(
                        habit: newHabit,
                        hour: seedReminder["hour"] as? Int ?? 0,
                        minute: seedReminder["minute"] as? Int ?? 0,
                        frequencyDays: frequencyDays
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

    func createHabit(
        uuid: UUID? = nil,
        name: String,
        frequencyPerWeek: Int,
        createdAt: Date,
        order: Int
    ) -> Habit {
        let habitToSave = Habit(context: context)
        habitToSave.createdAt = createdAt
        habitToSave.uuid = uuid ?? UUID()
        habitToSave.name = name
        habitToSave.frequencyPerWeek = Int32(frequencyPerWeek)
        habitToSave.order = Int32(order)

        return habitToSave
    }

    func createCheckIn(
        uuid: UUID? = nil,
        habit: Habit,
        createdAt: Date,
        checkInDate: Date? = nil
    ) -> CheckIn {
        let checkInToSave = CheckIn(context: context)
        checkInToSave.createdAt = createdAt
        checkInToSave.uuid = uuid ?? UUID()
        checkInToSave.habit = habit
        checkInToSave.checkInDate = checkInDate ?? createdAt.stripTime()
        checkInToSave.isSuccess = true

        return checkInToSave
    }

    func createReminder(
        uuid: UUID? = nil,
        habit: Habit,
        createdAt: Date? = nil,
        hour: Int,
        minute: Int,
        frequencyDays: [Int]
    ) -> Reminder {
        let reminderToSave = Reminder(context: context)
        reminderToSave.createdAt = createdAt ?? Date()
        reminderToSave.uuid = uuid ?? UUID()
        reminderToSave.habit = habit
        reminderToSave.hour = Int32(hour)
        reminderToSave.minute = Int32(minute)
        reminderToSave.frequencyDays = frequencyDays.map { $0 as NSNumber }

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


// MARK: - Data Export Methods
extension AdminViewController {
    struct ExportHabit: Codable {
        let uuid: String
        let createdAt: Int
        let name: String
        let order: Int
        let frequencyPerWeek: Int
        let checkIns: [ExportCheckIn]
        let reminders: [ExportReminder]

        init(habit: Habit) {
            self.uuid = habit.uuid!.uuidString
            self.createdAt = Int(habit.createdAt!.timeIntervalSince1970)
            self.name = habit.name!
            self.order = Int(habit.order)
            self.frequencyPerWeek = Int(habit.frequencyPerWeek)
            self.checkIns = (habit.checkIns as? Set<CheckIn> ?? [])
                .sorted { $0.createdAt! < $1.createdAt! }
                .map { ExportCheckIn(checkIn: $0) }
            self.reminders = (habit.reminders as? Set<Reminder> ?? [])
                .sorted { $0.createdAt! < $1.createdAt! }
                .map { ExportReminder(reminder: $0) }
        }
    }

    struct ExportCheckIn: Codable {
        let uuid: String
        let createdAt: Int
        let checkInDate: Int
        let isSuccess: Bool

        init(checkIn: CheckIn) {
            self.uuid = checkIn.uuid!.uuidString
            self.createdAt = Int(checkIn.createdAt!.timeIntervalSince1970)
            self.checkInDate = Int(checkIn.checkInDate!.timeIntervalSince1970)
            self.isSuccess = checkIn.isSuccess
        }
    }

    struct ExportReminder: Codable {
        let uuid: String
        let createdAt: Int
        let isEnabled: Bool
        let hour: Int
        let minute: Int
        let frequencyDays: [Int]

        init(reminder: Reminder) {
            self.uuid = reminder.uuid!.uuidString
            self.createdAt = Int(reminder.createdAt!.timeIntervalSince1970)
            self.isEnabled = reminder.isEnabled
            self.hour = Int(reminder.hour)
            self.minute = Int(reminder.minute)
            self.frequencyDays = (reminder.frequencyDays ?? []).map { Int(truncating: $0) }
        }
    }

    func exportCurrentData() {
        let exportData: [ExportHabit] = Habit.getAll(sortedBy: [("order", .asc), ("createdAt", .asc)])
            .map { ExportHabit(habit: $0) }
        let jsonEncoder = JSONEncoder()

        do {
            let jsonData = try jsonEncoder.encode(exportData)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            let pasteboard = UIPasteboard.general
            pasteboard.string = jsonString
        } catch {
            print("Error exporting context, \(error)")
        }
    }

    func importData() -> Bool {
        let pasteboard = UIPasteboard.general
        guard let importString = pasteboard.string else { return false }
        guard let jsonString = importString.data(using: .utf8) else { return false }
        let importedHabits: [ExportHabit] = {
            do {
                return try JSONDecoder().decode([ExportHabit].self, from: jsonString)
            } catch {
                return []
            }
        }()
        guard importedHabits.count > 0 else { return false }

        deleteAllHabits()

        importedHabits.forEach{ habit in
            let newHabit = createHabit(
                uuid: UUID(uuidString: habit.uuid),
                name: habit.name,
                frequencyPerWeek: habit.frequencyPerWeek,
                createdAt: Date(timeIntervalSince1970: Double(habit.createdAt)),
                order: habit.order
            )
            habit.checkIns.forEach { checkIn in
                let _ = createCheckIn(
                    uuid: UUID(uuidString: checkIn.uuid),
                    habit: newHabit,
                    createdAt: Date(timeIntervalSince1970: Double(checkIn.createdAt)),
                    checkInDate: Date(timeIntervalSince1970: Double(checkIn.checkInDate))
                )
            }
            habit.reminders.forEach { reminder in
                let _ = createReminder(
                    habit: newHabit,
                    hour: reminder.hour,
                    minute: reminder.minute,
                    frequencyDays: reminder.frequencyDays
                )
            }
        }

        do {
            try context.save()
        } catch {
            print("Error saving context, \(error)")
        }

        return true
    }
}

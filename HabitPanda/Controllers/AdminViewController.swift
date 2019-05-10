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
            NotificationHelper.removeAllNotifications()
        case 1:
            print("Reset all notifications")
        case 2:
            NotificationHelper.sendPushNotification()
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

        notificationsReportText.text = "Report:\n" +
            "\(getRemindersReportString())\n" +
            "\(getNotificationsReportString())"
    }

    func getNotificationsReportString() -> String {
        return "Notifications:\n" +
            "- \(pendingRequests.count) pending notification(s) set"
    }
}


extension AdminViewController {
    private func loadRemindersData() {
        let request: NSFetchRequest<Reminder> = Reminder.fetchRequest()
//        let predicates = [NSPredicate(format: "habit = %@", habit)]
//        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [
            NSSortDescriptor(key: "hour", ascending: true),
            NSSortDescriptor(key: "minute", ascending: true),
            NSSortDescriptor(key: "frequencyDays", ascending: true)
        ]

        do {
            reminders = try context.fetch(request)
        } catch {
            print("Error fetching data from context, \(error)")
        }
        updateUI()
    }

    func getRemindersReportString() -> String {
        let returnCounts =
            ReminderNotificationService.setupNotificationsForReminders(reminders)

        return "Reminders:\n" +
            "- \(returnCounts.0) notification(s) will be needed across \(returnCounts.1) habit(s)"
    }
}

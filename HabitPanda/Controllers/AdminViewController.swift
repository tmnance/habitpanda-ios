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

    override func viewDidLoad() {
        super.viewDidLoad()
        loadNotificationData()

        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
        print("NotificationHelper.isGranted = \(NotificationHelper.isGranted)")
        NotificationHelper.sendPushNotification()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
        var text = ""
        if isLoading {
            text = "Loading..."
        } else {
            text = "Notifications: \(pendingRequests.count)"
//            text += "\nNext notification: Today at 2:00 PM"
        }

        notificationsReportText.text = text
    }
}

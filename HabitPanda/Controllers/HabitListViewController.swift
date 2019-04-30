//
//  HabitListViewController.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/12/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

class HabitListViewController: UITableViewController {
    var habitList = [Habit]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    override func viewDidLoad() {
        super.viewDidLoad()

        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
//        sendPushNotification()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadData()
    }

    func sendPushNotification() {
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
}


// MARK: - Tableview Datasource Methods
extension HabitListViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HabitCell", for: indexPath)
        let habit = habitList[indexPath.row]

        cell.textLabel?.text = "\(habit.name!) (\(habit.reminderTimes?.count ?? 0))"

        return cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return habitList.count
    }
}


// MARK: - Tableview Delegate Methods
extension HabitListViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "goToHabitDetails", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToHabitDetails" {
            let destinationVC = segue.destination as! HabitDetailsViewController
            if let indexPath = tableView.indexPathForSelectedRow {
                destinationVC.selectedHabit = habitList[indexPath.row]
            }
        }
    }
}


// MARK: - Load Data Methods
extension HabitListViewController {
    func loadData() {
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        do {
            habitList = try context.fetch(request)
        } catch {
            print("Error fetching data from context, \(error)")
        }

        tableView.reloadData()
    }
}

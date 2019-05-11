//
//  ReminderListViewModel.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/23/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit
import CoreData

class ReminderListViewModel {
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    var reminders: Box<[Reminder]> = Box([])
    var selectedHabit: Habit? {
        didSet {
            if selectedHabit != nil {
                loadRemindersData()
            }
        }
    }
}


// MARK: - Save Data Methods
extension ReminderListViewModel {
    func removeReminder(atIndex index: Int) {
        context.delete(reminders.value[index])
        reminders.value.remove(at: index)

        do {
            try context.save()
            ReminderNotificationService.refreshNotificationsForAllReminders()
        } catch {
            print("Error saving context, \(error)")
        }
    }
}


// MARK: - Load Data Methods
extension ReminderListViewModel {
    func reloadRemindersData() {
        loadRemindersData()
    }

    private func loadRemindersData() {
        if let habit = selectedHabit {
            let request: NSFetchRequest<Reminder> = Reminder.fetchRequest()
            let predicates = [NSPredicate(format: "habit = %@", habit)]
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            request.sortDescriptors = [
                NSSortDescriptor(key: "hour", ascending: true),
                NSSortDescriptor(key: "minute", ascending: true),
                NSSortDescriptor(key: "frequencyDays", ascending: true)
            ]

            do {
                reminders.value = try context.fetch(request)
            } catch {
                print("Error fetching data from context, \(error)")
            }
        } else {
            reminders.value = []
        }
    }
}

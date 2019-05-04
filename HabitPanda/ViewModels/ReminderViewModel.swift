//
//  ReminderViewModel.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/23/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit
import CoreData

class ReminderViewModel {
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    var reminders: Box<[TimeOfDay]> = Box([])
    var selectedHabit: Habit? {
        didSet {
            if selectedHabit != nil {
                loadRemindersData()
            }
        }
    }
    var selectedHabitReminders: [Reminder] = []
}


// MARK: - Save Data Methods
extension ReminderViewModel {
    func saveReminders() {
        guard let habit = selectedHabit else {
            return
        }
        var anyChanged = false
        // need to reconcile added and removed reminders

        // add any reminders not yet in the habit
        reminders.value
            .filter{
                let updatedReminder = $0
                return !selectedHabitReminders.contains{
                    updatedReminder.hour == $0.hour && updatedReminder.minute == $0.minute
                }
            }
            .forEach{ (reminder) in
                createReminder(fromTimeOfDay: reminder, forHabit: habit)
                anyChanged = true
            }

        // remove any reminders from the habit that no longer exist
        for (index, origReminder) in selectedHabitReminders.enumerated().reversed() {
            let isRemoved = !reminders.value.contains{
                origReminder.hour == $0.hour && origReminder.minute == $0.minute
            }
            if isRemoved {
                context.delete(selectedHabitReminders[index])
                selectedHabitReminders.remove(at: index)
                anyChanged = true
            }
        }

        if anyChanged {
            do {
                try context.save()
            } catch {
                print("Error saving context, \(error)")
            }
            loadRemindersData()
        }
    }

    func createReminder(fromTimeOfDay timeOfDay: TimeOfDay, forHabit habit: Habit) {
        let newReminder = Reminder(context: self.context)
        newReminder.hour = Int32(timeOfDay.hour)
        newReminder.minute = Int32(timeOfDay.minute)
        newReminder.habit = habit
    }
}


// MARK: - Load Data Methods
extension ReminderViewModel {
    func loadRemindersData() {
        if let habit = selectedHabit {
            let request: NSFetchRequest<Reminder> = Reminder.fetchRequest()
            let predicates = [NSPredicate(format: "habit = %@", habit)]
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

            do {
                selectedHabitReminders = try context.fetch(request)
                reminders.value = convertSelectedRemindersToTimeOfDay()
            } catch {
                print("Error fetching data from context, \(error)")
            }
        } else {
            selectedHabitReminders = []
        }
    }

}


// MARK: - Reminder Methods
extension ReminderViewModel {
    func convertSelectedRemindersToTimeOfDay() -> [TimeOfDay] {
        return selectedHabitReminders
            .map {
                let reminder = $0
                return TimeOfDay(
                    hour: Int(reminder.hour),
                    minute: Int(reminder.minute)
                )
            }
            .sorted {
                $0.hour < $1.hour || ($0.hour == $1.hour && $0.minute < $1.minute)
            }
    }

    func addReminder(hour: Int, minute: Int) {
        if findReminderIndex(withHour: hour, withMinute: minute) != nil {
            // a reminder already exists with this time, keep it and ignore this one
            return
        }

        let newReminder = TimeOfDay(hour: hour, minute: minute)
        self.reminders.value.append(newReminder)
        reminders.value.sort {
            $0.hour < $1.hour || ($0.hour == $1.hour && $0.minute < $1.minute)
        }
    }

    func removeReminder(atIndex index: Int) {
        reminders.value.remove(at: index)
    }

    func findReminderIndex(withHour hour: Int, withMinute minute: Int) -> Int? {
        return reminders.value.indices
            .filter {
                reminders.value[$0].hour == hour && reminders.value[$0].minute == minute
            }
            .first
    }
}

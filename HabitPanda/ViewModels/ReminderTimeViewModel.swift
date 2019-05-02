//
//  ReminderTimeViewModel.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/23/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit
import CoreData

class ReminderTimeViewModel {
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    var reminderTimes: Box<[TimeOfDay]> = Box([])
    var selectedHabit: Habit? {
        didSet {
            if selectedHabit != nil {
                loadReminderTimesData()
            }
        }
    }
    var selectedHabitReminderTimes: [ReminderTime] = []
}


// MARK: - Save Data Methods
extension ReminderTimeViewModel {
    func saveReminderTimes() {
        guard let habit = selectedHabit else {
            return
        }
        var anyChanged = false
        // need to reconcile added and removed reminders

        // add any reminders not yet in the habit
        reminderTimes.value
            .filter{
                let updatedReminder = $0
                return !selectedHabitReminderTimes.contains{
                    updatedReminder.hour == $0.hour && updatedReminder.minute == $0.minute
                }
            }
            .forEach{ (reminder) in
                createReminderTime(fromTimeOfDay: reminder, forHabit: habit)
                anyChanged = true
            }

        // remove any reminders from the habit that no longer exist
        for (index, origReminder) in selectedHabitReminderTimes.enumerated().reversed() {
            let isRemoved = !reminderTimes.value.contains{
                origReminder.hour == $0.hour && origReminder.minute == $0.minute
            }
            if isRemoved {
                context.delete(selectedHabitReminderTimes[index])
                selectedHabitReminderTimes.remove(at: index)
                anyChanged = true
            }
        }

        if anyChanged {
            do {
                try context.save()
            } catch {
                print("Error saving context, \(error)")
            }
            loadReminderTimesData()
        }
    }

    func createReminderTime(fromTimeOfDay timeOfDay: TimeOfDay, forHabit habit: Habit) {
        let newReminder = ReminderTime(context: self.context)
        newReminder.hour = Int32(timeOfDay.hour)
        newReminder.minute = Int32(timeOfDay.minute)
        newReminder.habit = habit
    }
}


// MARK: - Load Data Methods
extension ReminderTimeViewModel {
    func loadReminderTimesData() {
        if let habit = selectedHabit {
            let request: NSFetchRequest<ReminderTime> = ReminderTime.fetchRequest()
            let predicates = [NSPredicate(format: "habit = %@", habit)]
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

            do {
                selectedHabitReminderTimes = try context.fetch(request)
                reminderTimes.value = convertSelectedReminderTimesToTimeOfDay()
            } catch {
                print("Error fetching data from context, \(error)")
            }
        } else {
            selectedHabitReminderTimes = []
        }
    }

}


// MARK: - Reminder Methods
extension ReminderTimeViewModel {
    func convertSelectedReminderTimesToTimeOfDay() -> [TimeOfDay] {
        return selectedHabitReminderTimes
            .map {
                let reminderTime = $0
                return TimeOfDay(
                    hour: Int(reminderTime.hour),
                    minute: Int(reminderTime.minute)
                )
            }
            .sorted {
                $0.hour < $1.hour || ($0.hour == $1.hour && $0.minute < $1.minute)
            }
    }

    func addReminderTime(hour: Int, minute: Int) {
        if findReminderTimeIndex(withHour: hour, withMinute: minute) != nil {
            // a reminder already exists with this time, keep it and ignore this one
            return
        }

        let newReminder = TimeOfDay(hour: hour, minute: minute)
        self.reminderTimes.value.append(newReminder)
        reminderTimes.value.sort {
            $0.hour < $1.hour || ($0.hour == $1.hour && $0.minute < $1.minute)
        }
    }

    func removeReminderTime(atIndex index: Int) {
        reminderTimes.value.remove(at: index)
    }

    func findReminderTimeIndex(withHour hour: Int, withMinute minute: Int) -> Int? {
        return reminderTimes.value.indices
            .filter {
                reminderTimes.value[$0].hour == hour && reminderTimes.value[$0].minute == minute
            }
            .first
    }
}

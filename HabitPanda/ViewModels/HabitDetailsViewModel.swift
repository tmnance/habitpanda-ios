//
//  HabitDetailsViewModel.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/23/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit
import CoreData

class HabitDetailsViewModel {
    enum ViewInteractionMode {
        case Add, Edit, View
    }

    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    var name: Box<String> = Box("")
    var frequencyPerWeek: Box<Int> = Box(Constants.Habit.defaultFrequencyPerWeek)
    var interactionMode: Box<ViewInteractionMode> = Box(.Add)
    var selectedHabit: Habit? {
        didSet {
            if let habit = selectedHabit {
                name.value = habit.name!
                frequencyPerWeek.value = Int(habit.frequencyPerWeek)
            }
            interactionMode.value = selectedHabit == nil ? .Add : .Edit
        }
    }
}


// MARK: - Save Data Methods
extension HabitDetailsViewModel {
    func saveHabit() {
        let habitToSave = interactionMode.value == .Add ? Habit(context: context) : selectedHabit!
        habitToSave.createdAt = Date()
        habitToSave.uuid = UUID()
        habitToSave.name = name.value
        habitToSave.frequencyPerWeek = Int32(frequencyPerWeek.value)

        do {
            try context.save()
            ReminderNotificationService.refreshNotificationsForAllReminders()
        } catch {
            print("Error saving context, \(error)")
        }
    }

    func deleteHabit() {
        guard let habit = selectedHabit else {
            return
        }

        context.delete(habit)

        do {
            try context.save()
            ReminderNotificationService.refreshNotificationsForAllReminders()
        } catch {
            print("Error saving context, \(error)")
        }
    }

    func addCheckIn(forDate date: Date) {
        guard let habit = selectedHabit else {
            return
        }

        // TODO: will likely move this to its own VM once more functionality is added
        let checkInToSave = CheckIn(context: context)

        checkInToSave.createdAt = Date()
        checkInToSave.uuid = UUID()
        checkInToSave.habit = habit
        checkInToSave.checkInDate = date
        checkInToSave.isSuccess = true

        do {
            try context.save()
            ReminderNotificationService.refreshNotificationsForAllReminders()
        } catch {
            print("Error saving context, \(error)")
        }
    }
}


// MARK: - Load Data Methods
extension HabitDetailsViewModel {
    func reloadHabitData() {
        if let habit = selectedHabit {
            let request: NSFetchRequest<Habit> = Habit.fetchRequest()
            let predicates = [NSPredicate(format: "uuid = %@", habit.uuid! as CVarArg)]
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

            do {
                selectedHabit = try context.fetch(request).first
            } catch {
                print("Error fetching data from context, \(error)")
            }
        }
    }
}


// MARK: - Frequency Methods
extension HabitDetailsViewModel {
    func getFrequencyPerWeekDisplayText() -> String {
        return "\(frequencyPerWeek.value) time\(frequencyPerWeek.value == 1 ? "" : "s") / week"
    }
}

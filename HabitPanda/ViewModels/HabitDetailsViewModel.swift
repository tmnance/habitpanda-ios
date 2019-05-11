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
    typealias FrequencyOption = DayOfWeek.WeekSubsetType
    typealias FrequencyDay = DayOfWeek.Day
    enum ViewInteractionMode {
        case Add, Edit, View
    }

    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    var name: Box<String> = Box("")
    var frequencyDays: Box<[FrequencyDay]> = Box([])
    var interactionMode: Box<ViewInteractionMode> = Box(.Add)
    var selectedHabit: Habit? {
        didSet {
            if let habit = selectedHabit {
                name.value = habit.name!
                frequencyDays.value = (habit.frequencyDays ?? [])
                    .compactMap{ FrequencyDay(rawValue: $0.intValue) }
            }
            interactionMode.value = selectedHabit == nil ? .Add : .Edit
        }
    }
}


// MARK: - Save Data Methods
extension HabitDetailsViewModel {
    func saveHabit() {
        let habitToSave = interactionMode.value == .Add ? Habit(context: context) : selectedHabit!
        habitToSave.name = name.value
        habitToSave.createdAt = Date()
        habitToSave.uuid = UUID()
        habitToSave.frequencyDays = frequencyDays.value
            .sorted{ $0.rawValue < $1.rawValue }
            .map{ $0.rawValue as NSNumber }

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
    func toggleFrequencyDay(_ day: FrequencyDay) {
        if let index = frequencyDays.value.firstIndex(of: day) {
            frequencyDays.value.remove(at: index)
        } else {
            frequencyDays.value.append(day)
        }
    }

    func getFrequencyOption() -> FrequencyOption {
        var option:FrequencyOption = .Custom

        if frequencyDays.value.count == 7 {
            option = .Daily
        } else if (
            frequencyDays.value.count == 5 &&
                (frequencyDays.value.filter { ![.Sat, .Sun].contains($0) }).count == 5
        ) {
            // exactly 5 items selected and they are all weekdays
            option = .Weekdays
        }
        return option
    }

    func updateFrequencyDays(forOption option: FrequencyOption) {
        switch option {
        case .Daily:
            frequencyDays.value = [.Sun, .Mon, .Tue, .Wed, .Thu, .Fri, .Sat]
            break
        case .Weekdays:
            frequencyDays.value = [.Mon, .Tue, .Wed, .Thu, .Fri]
            break
        case .Custom:
            frequencyDays.value = []
            break
        }
    }
}

//
//  HabitViewModel.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/23/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit
import CoreData

struct HabitViewModelConstants {
    static let timePickerMinuteInterval = 5
}

class HabitViewModel {
    typealias FrequencyOption = Habit.FrequencyOption
    typealias FrequencyDay = Habit.FrequencyDay
    enum ViewInteractionMode {
        case Add, Edit, View
    }

    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    var name: Box<String> = Box("")
    var frequencyDays: Box<[FrequencyDay]> = Box([])
    var reminderTimes: Box<[TimeOfDay]> = Box([])
    var interactionMode: Box<ViewInteractionMode> = Box(.Add)
    var selectedHabit: Habit? {
        didSet {
            if let habit = selectedHabit {
                name.value = habit.name!
                frequencyDays.value = (habit.frequencyDays ?? [])
                    .compactMap{ FrequencyDay(rawValue: $0.intValue) }
                loadReminderTimesData()
            }
            interactionMode.value = selectedHabit == nil ? .Add : .Edit
        }
    }
    var selectedHabitReminderTimes: [ReminderTime] = []
}


// MARK: - Save Data Methods
extension HabitViewModel {
    func saveHabit(_ text: String) {
        let habitToSave = interactionMode.value == .Add ? Habit(context: context) : selectedHabit!
        habitToSave.name = text
        habitToSave.createdAt = Date()
        habitToSave.uuid = UUID()
        habitToSave.frequencyDays = frequencyDays.value.map{ $0.rawValue as NSNumber }

        if interactionMode.value == .Add {
            // all reminders are new
            reminderTimes.value.forEach{ (reminder) in
                createReminderTime(fromTimeOfDay: reminder, forHabit: habitToSave)
            }
        } else {
            // need to reconcile added and removed reminders

            // get reminders added while editing that are not in the original habit
            reminderTimes.value
                .filter{
                    let updatedReminder = $0
                    return !selectedHabitReminderTimes.contains{
                        updatedReminder.hour == $0.hour && updatedReminder.minute == $0.minute
                    }
                }
                .forEach{ (reminder) in
                    createReminderTime(fromTimeOfDay: reminder, forHabit: habitToSave)
                }

            // get reminders removed while editing that are in the original habit

            for (index, origReminder) in selectedHabitReminderTimes.enumerated().reversed() {
                let isRemoved = !reminderTimes.value.contains{
                    origReminder.hour == $0.hour && origReminder.minute == $0.minute
                }
                if isRemoved {
                    context.delete(selectedHabitReminderTimes[index])
                    selectedHabitReminderTimes.remove(at: index)
                }
            }
        }

        do {
            try context.save()
        } catch {
            print("Error saving context, \(error)")
        }
    }

    func createReminderTime(fromTimeOfDay timeOfDay: TimeOfDay, forHabit habit: Habit) {
        let newReminder = ReminderTime(context: self.context)
        newReminder.hour = Int32(timeOfDay.hour)
        newReminder.minute = Int32(timeOfDay.minute)
        newReminder.habit = habit
    }

    func deleteHabit() {
        guard let habit = selectedHabit else {
            return
        }

        context.delete(habit)

        do {
            try context.save()
        } catch {
            print("Error saving context, \(error)")
        }
    }
}


// MARK: - Load Data Methods
extension HabitViewModel {
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
//        tableView.reloadData()
    }

}


// MARK: - Name Methods
extension HabitViewModel {
    func updateName(name: String) {
        self.name.value = name
    }
}


// MARK: - Frequency Methods
extension HabitViewModel {
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


// MARK: - Reminder Methods
extension HabitViewModel {
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

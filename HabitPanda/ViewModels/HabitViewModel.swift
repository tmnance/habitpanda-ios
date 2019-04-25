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

    let context = (UIApplication.shared.delegate   as! AppDelegate).persistentContainer.viewContext

    var name: Box<String> = Box("")
    var frequencyDays: Box<[FrequencyDay]> = Box([])
    var reminderTimes: Box<[TimeOfDay]> = Box([])


    init() {
        print("HabitViewModel.init()")
    }
}


// MARK: - Add Data Methods
extension HabitViewModel {
    func addHabit(_ text: String) {
        print("Wanting to add habit \(text)")

        let newHabit = Habit(context: context)
        newHabit.name = text
        newHabit.createdAt = Date()
        newHabit.uuid = UUID()

        reminderTimes.value.forEach { (reminder) in
            let newReminder = ReminderTime(context: self.context)
            newReminder.hour = Int32(reminder.hour)
            newReminder.minute = Int32(reminder.minute)
            newReminder.habit = newHabit
//            context.delete(self.reminderTimes.value[index])
//            reminder.habit = newHabit
        }

        do {
            try context.save()
        } catch {
            print("Error saving context, \(error)")
        }
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
        } else if frequencyDays.value.count == 5 && (frequencyDays.value.filter { ![.Sat, .Sun].contains($0) }).count == 5 {
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
    func addReminderTime(hour: Int, minute: Int) {
        if findReminderTimeIndex(withHour: hour, withMinute: minute) != nil {
            // a reminder already exists with this time, keep it and ignore this one
            return
        }

        let newReminder = TimeOfDay(hour: hour, minute: minute)
        self.reminderTimes.value.append(newReminder)
        reminderTimes.value.sort {$0.hour < $1.hour || ($0.hour == $1.hour && $0.minute < $1.minute) }
    }

    func removeReminderTime(atIndex index: Int) {
        reminderTimes.value.remove(at: index)
    }

    func findReminderTimeIndex(withHour hour: Int, withMinute minute: Int) -> Int? {
        return reminderTimes.value.indices
            .filter { reminderTimes.value[$0].hour == hour && reminderTimes.value[$0].minute == minute }
            .first
    }
}

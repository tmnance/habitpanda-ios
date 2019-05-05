//
//  ReminderDetailsViewModel.swift
//  HabitPanda
//
//  Created by Tim Nance on 5/5/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit
import CoreData

class ReminderDetailsViewModel {
    typealias FrequencyOption = DayOfWeek.WeekSubsetType
    typealias FrequencyDay = DayOfWeek.Day
    enum ViewInteractionMode {
        case Add, Edit, View
    }

    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    var parentHabit: Habit?
    var selectedReminder: Reminder? {
        didSet {
            if let reminder = selectedReminder {
                frequencyDays.value = (reminder.frequencyDays ?? [])
                    .compactMap{ FrequencyDay(rawValue: $0.intValue) }
                time.value = TimeOfDay(
                    hour: Int(reminder.hour),
                    minute: Int(reminder.minute)
                )
            }
            interactionMode.value = selectedReminder == nil ? .Add : .Edit
        }
    }
    var interactionMode: Box<ViewInteractionMode> = Box(.Add)
    var time: Box<TimeOfDay> = Box(
        TimeOfDay.generateFromCurrentTime(witMinuteRounding: Constants.TimePicker.minuteInterval)
    )
    var frequencyDays: Box<[FrequencyDay]> = Box([])
}


// MARK: - Save Data Methods
extension ReminderDetailsViewModel {
    func saveReminder() {
        // TODO: add duplicate checking
        let reminderToSave = interactionMode.value == .Add ?
            Reminder(context: context) :
            selectedReminder!

        reminderToSave.createdAt = Date()
        reminderToSave.uuid = UUID()
        reminderToSave.habit = parentHabit!
        reminderToSave.hour = Int32(time.value.hour)
        reminderToSave.minute = Int32(time.value.minute)
        reminderToSave.frequencyDays = frequencyDays.value
            .sorted{ $0.rawValue < $1.rawValue }
            .map{ $0.rawValue as NSNumber }

        do {
            try context.save()
        } catch {
            print("Error saving context, \(error)")
        }
    }
}


// MARK: - Reminder Methods
extension ReminderDetailsViewModel {
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

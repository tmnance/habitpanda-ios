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
        case add, edit, view
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
            interactionMode.value = selectedReminder == nil ? .add : .edit
        }
    }
    var interactionMode: Box<ViewInteractionMode> = Box(.add)
    var time: Box<TimeOfDay> = Box(
        TimeOfDay.generateFromCurrentTime(witMinuteRounding: Constants.TimePicker.minuteInterval)
    )
    var frequencyDays: Box<[FrequencyDay]> = Box([])
}


// MARK: - Save Data Methods
extension ReminderDetailsViewModel {
    func saveReminder() {
        // TODO: add duplicate checking?
        let isNew = interactionMode.value == .add
        let reminderToSave = isNew ?
            Reminder(context: context) :
            selectedReminder!

        if isNew {
            reminderToSave.createdAt = Date()
            reminderToSave.uuid = UUID()
            reminderToSave.habit = parentHabit!
        }

        reminderToSave.hour = Int32(time.value.hour)
        reminderToSave.minute = Int32(time.value.minute)
        reminderToSave.frequencyDays = frequencyDays.value
            .sorted{ $0.rawValue < $1.rawValue }
            .map{ $0.rawValue as NSNumber }

        do {
            try context.save()
            ReminderNotificationService.refreshNotificationsForAllReminders()
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
        var option:FrequencyOption = .custom

        if frequencyDays.value.count == 7 {
            option = .daily
        } else if (
            frequencyDays.value.count == 5 &&
                (frequencyDays.value.filter { ![.sat, .sun].contains($0) }).count == 5
            ) {
            // exactly 5 items selected and they are all weekdays
            option = .weekdays
        }
        return option
    }

    func updateFrequencyDays(forOption option: FrequencyOption) {
        switch option {
        case .daily:
            frequencyDays.value = [.sun, .mon, .tue, .wed, .thu, .fri, .sat]
            break
        case .weekdays:
            frequencyDays.value = [.mon, .tue, .wed, .thu, .fri]
            break
        case .custom:
            frequencyDays.value = []
            break
        }
    }
}

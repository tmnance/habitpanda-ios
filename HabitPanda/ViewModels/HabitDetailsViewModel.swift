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
        case add, edit, view
    }

    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    var name: Box<String> = Box("")
    var frequencyPerWeek: Box<Int> = Box(Constants.Habit.defaultFrequencyPerWeek)
    var interactionMode: Box<ViewInteractionMode> = Box(.add)
    private var onDataLoad: (() -> Void)? = nil
    var selectedHabit: Habit? {
        didSet {
            if let habit = selectedHabit {
                name.value = habit.name!
                frequencyPerWeek.value = Int(habit.frequencyPerWeek)
                onDataLoad?()
            }
            interactionMode.value = selectedHabit == nil ? .add : .edit
        }
    }
    
    func setOnDataLoad(_ fn: (() -> Void)?) {
        onDataLoad = fn
        if selectedHabit != nil {
            onDataLoad?()
        }
    }
}


// MARK: - Save Data Methods
extension HabitDetailsViewModel {
    func saveHabit() {
        let isNew = interactionMode.value == .add
        let habitToSave = isNew ?
            Habit(context: context) :
            selectedHabit!

        if isNew {
            habitToSave.createdAt = Date()
            habitToSave.uuid = UUID()
            habitToSave.order = Int32(Habit.getCount() - 1)
        }

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
            Habit.fixHabitOrder()
            ReminderNotificationService.refreshNotificationsForAllReminders()
            ReminderNotificationService.removeOrphanedDeliveredNotifications()
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
        checkInToSave.checkInDate = date.stripTime()
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
    func getFrequencyPerWeekDisplayText(
        usingOverflowValue overflowValue: Int? = nil
    ) -> String {
        var displayValue = "\(frequencyPerWeek.value)"
        var isPlural = frequencyPerWeek.value != 1
        if let overflowValue = overflowValue {
            displayValue = "\(overflowValue)+"
            isPlural = overflowValue != 1
        }
        return "\(displayValue) time\(isPlural ? "s" : "") / week"
    }
}


// MARK: - Rolling average calculation
extension HabitDetailsViewModel {
    func getFirstCheckIn() -> CheckIn? {
        guard let selectedHabit = selectedHabit else {
            return nil
        }

        let checkIns = CheckIn.getAll(
            sortedBy: [("checkInDate", .asc)],
            forHabitUUIDs: [selectedHabit.uuid!],
            withLimit: 1
        )

        return checkIns.first ?? nil
    }

    func getCheckInFrequencyRollingAverageData(
        fromStartDate startDate: Date? = nil,
        toEndDate endDate: Date? = nil,
        withDayWindow dayWindow: Int = 7
    ) -> [Double] {
        guard let selectedHabit = selectedHabit else {
            return []
        }

        let startDate = (startDate ?? selectedHabit.createdAt!).stripTime()
        let endDate = (endDate ?? Date()).stripTime()
        let intervalDayCount = (Calendar.current.dateComponents(
            [.day],
            from: startDate,
            to: endDate
        ).day ?? 0) + 1

        // get extra days before startDate to be used in rolling average calculations
        let startDateIncludingWindow = Calendar.current.date(
            byAdding: .day,
            value: (1 - dayWindow),
            to: startDate
        )!
        let checkIns = CheckIn.getAll(
            sortedBy: [("checkInDate", .asc)],
            forHabitUUIDs: [selectedHabit.uuid!],
            fromStartDate: startDateIncludingWindow,
            toEndDate: endDate
        )

        let startDateOffsetCheckInCountMap = getStartDateOffsetCheckInCountMap(
            fromStartDate: startDate,
            forCheckIns: checkIns
        )

        var checkInFrequencyRollingAverageData: [Double] = []
        var rollingSum = 0

        for startDateOffset in (1 - dayWindow)..<intervalDayCount {
            if startDateOffset >= 1 {
                rollingSum -= startDateOffsetCheckInCountMap[startDateOffset - dayWindow] ?? 0
            }
            rollingSum += startDateOffsetCheckInCountMap[startDateOffset] ?? 0
            // skip over negative
            if startDateOffset >= 0 {
                checkInFrequencyRollingAverageData.append(Double(rollingSum))
            }
        }

        return checkInFrequencyRollingAverageData
    }

    private func getStartDateOffsetCheckInCountMap(
        fromStartDate startDate: Date,
        forCheckIns checkIns: [CheckIn]
    ) -> [Int: Int] {
        var startDateOffsetCheckInCountMap: [Int: Int] = [:]

        checkIns.forEach{ (checkIn) in
            let checkInDate = checkIn.checkInDate!.stripTime()
            let startDateOffset = Calendar.current.dateComponents(
                [.day],
                from: startDate,
                to: checkInDate
            ).day ?? 0
            startDateOffsetCheckInCountMap[startDateOffset] = (startDateOffsetCheckInCountMap[startDateOffset] ?? 0) + 1
        }

        return startDateOffsetCheckInCountMap
    }
}

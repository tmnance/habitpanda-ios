//
//  HabitListViewModel.swift
//  HabitPanda
//
//  Created by Tim Nance on 5/26/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit
import CoreData

class HabitListViewModel {
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    let numDates = 30

    var habits: Box<[Habit]> = Box([])
    var currentDate: Box<Date> = Box(Date().stripTime())
    var startDate: Date {
        return Calendar.current.date(
            byAdding: .day,
            value: -1 * (numDates - 1),
            to: currentDate.value
        )!
    }

    typealias CheckInGridOffsetMap = [Int: Int]
    private var habitCheckInGridOffsetMap: [UUID: CheckInGridOffsetMap] = [:]
    private var habitCreatedAtOffsetMap: [UUID: Int] = [:]
    private var habitFirstCheckInOffsetMap: [UUID: Int?] = [:]

    init() {
        loadData()
    }
}


// MARK: - Save Data Methods
extension HabitListViewModel {
    func updateHabitOrder() {
        guard habits.value.count > 0 else {
            return
        }

        var order = 0

        habits.value.forEach { (habit) in
            let habitToSave = habit
            habitToSave.order = Int32(order)
            order += 1
        }

        do {
            try context.save()
        } catch {
            print("Error saving context, \(error)")
        }
    }
}


// MARK: - Load Data Methods
extension HabitListViewModel {
    func reloadData() {
        loadData()
    }

    private func loadData() {
        if currentDate.value != Date().stripTime() {
            // only update when changed
            currentDate.value = Date().stripTime()
        }

        BoxHelper.processBeforeListenerInvocation {
            habits.value = Habit.getAll(sortedBy: [("order", .asc), ("createdAt", .asc)])

            buildHabitCheckInMaps()
            habits.value.forEach{ (habit) in
                habitCreatedAtOffsetMap[habit.uuid!] =
                    (Calendar.current.dateComponents(
                        [.day],
                        from: startDate,
                        to: habit.createdAt!
                    ).day ?? 0) - 1

                if let firstCheckInDate = habit.getFirstCheckInDate() {
                    habitFirstCheckInOffsetMap[habit.uuid!] =
                        (Calendar.current.dateComponents(
                            [.day],
                            from: startDate,
                            to: firstCheckInDate
                        ).day ?? 0) - 1
                } else {
                    habitFirstCheckInOffsetMap[habit.uuid!] = nil
                }
            }
        }
    }
}


// MARK: - Check-In Grid Helper Methods
extension HabitListViewModel {
    func buildHabitCheckInMaps() {
        habitCheckInGridOffsetMap = [:]

        let checkIns = CheckIn.getAll(
            forHabitUUIDs: habits.value.map { $0.uuid! },
            fromStartDate: startDate
        )

        checkIns.forEach{ (checkIn) in
            let habitUUID = checkIn.habit!.uuid!
            let date = checkIn.checkInDate!.stripTime()
            let dateOffset = Calendar.current.dateComponents(
                [.day],
                from: startDate,
                to: date
            ).day ?? 0

            habitCheckInGridOffsetMap[habitUUID] =
                habitCheckInGridOffsetMap[habitUUID] ?? [:]
            habitCheckInGridOffsetMap[habitUUID]![dateOffset] =
                (habitCheckInGridOffsetMap[habitUUID]![dateOffset] ?? 0) + 1
        }
    }

    func getCheckInCount(forHabit habit: Habit, forDateOffset dateOffset: Int) -> Int? {
        let uuid = habit.uuid!
        guard (habitFirstCheckInOffsetMap[uuid] ?? 0) ?? 0 < dateOffset else {
            return nil
        }
        return habitCheckInGridOffsetMap[uuid]?[dateOffset] ?? 0
    }
    
    func getCreatedAtOffset(forHabit habit: Habit) -> Int {
        let uuid = habit.uuid!
        return habitCreatedAtOffsetMap[uuid]!
    }
    
    func getFirstCheckInOffset(forHabit habit: Habit) -> Int {
        let uuid = habit.uuid!
        // if no check ins, represent today's offset
        return (habitFirstCheckInOffsetMap[uuid] ?? nil) ?? (numDates - 2)
    }
}

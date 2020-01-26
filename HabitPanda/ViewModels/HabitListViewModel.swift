//
//  HabitListViewModel.swift
//  HabitPanda
//
//  Created by Tim Nance on 5/26/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import Foundation

class HabitListViewModel {
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
    var habitCheckInGridOffsetMap: [UUID: CheckInGridOffsetMap] = [:]
    var habitCreatedAtOffsetMap: [UUID: Int] = [:]
    var habitMinCheckInOffsetMap: [UUID: Int] = [:]
    var habitEarliestCheckInMap: [UUID: Date] = [:]

    init() {
        loadData()
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
            habits.value = Habit.getAll(sortedBy: "createdAt")
            let checkIns = CheckIn.getAll(
                forHabitUUIDs: habits.value.map { $0.uuid! },
                fromStartDate: startDate
            )

            buildHabitCheckInMaps(forCheckIns: checkIns)
            habits.value.forEach{ (habit) in
                let createdAtOffset = Calendar.current.dateComponents(
                    [.day],
                    from: startDate,
                    to: habit.createdAt!
                ).day ?? 0
                let minCheckInOffset = Calendar.current.dateComponents(
                    [.day],
                    from: startDate,
                    to: habitEarliestCheckInMap[habit.uuid!] ?? startDate
                ).day ?? 0

                habitCreatedAtOffsetMap[habit.uuid!] = createdAtOffset - 1
                habitMinCheckInOffsetMap[habit.uuid!] = minCheckInOffset - 1
            }
        }
    }
}


// MARK: - Check-In Grid Helper Methods
extension HabitListViewModel {
    func buildHabitCheckInMaps(forCheckIns checkIns: [CheckIn]) {
        habitCheckInGridOffsetMap = [:]
        habitEarliestCheckInMap = [:]

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
            habitEarliestCheckInMap[habitUUID] =
                habitEarliestCheckInMap[habitUUID] ?? date
        }
    }

    func getCheckInCount(forHabit habit: Habit, forDateOffset dateOffset: Int) -> Int? {
        let uuid = habit.uuid!
        guard habitMinCheckInOffsetMap[uuid] ?? 0 < dateOffset else {
            return nil
        }
        return habitCheckInGridOffsetMap[uuid]?[dateOffset] ?? 0
    }

    func getCreatedAtOffset(forHabit habit: Habit) -> Int {
        let uuid = habit.uuid!
        return habitCreatedAtOffsetMap[uuid]!
    }
}

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
    var habitMinOffsetMap: [UUID: Int] = [:]

    init() {
        loadData()
    }
}


// MARK: - Load Data Methods
extension HabitListViewModel {
    func reloadData() {
        loadData()
    }

    private func loadData(isTest: Bool? = false) {
        if currentDate.value != Date().stripTime() {
            // only update when changed
            currentDate.value = Date().stripTime()
        }

        BoxHelper.processBeforeListenerInvocation {
            habits.value = Habit.getAll(sortedBy: "createdAt")
            let allCheckIns = CheckIn.getAll(
                forHabitUUIDs: habits.value.map { $0.uuid! },
                afterDate: startDate
            )

            buildHabitCheckInGridOffsetMap(forCheckIns: allCheckIns)
            habits.value.forEach{ (habit) in
                let dateOffset = Calendar.current.dateComponents(
                    [.day],
                    from: startDate,
                    to: habit.createdAt!
                ).day ?? 0
                habitMinOffsetMap[habit.uuid!] = dateOffset - 1
            }
        }
    }
}


// MARK: - Check-In Grid Helper Methods
extension HabitListViewModel {
    func buildHabitCheckInGridOffsetMap(forCheckIns checkIns: [CheckIn]) {
        habitCheckInGridOffsetMap = [:]

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
        guard habitMinOffsetMap[uuid] ?? 0 < dateOffset else {
            return nil
        }
        return habitCheckInGridOffsetMap[uuid]?[dateOffset] ?? 0
    }
}

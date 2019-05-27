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

        let allHabits = Habit.getAll(sortedBy: "createdAt")
        let allCheckIns = CheckIn.getAll(
            forHabitUUIDs: allHabits.map { $0.uuid! },
            afterDate: startDate
        )

        buildHabitCheckInGridOffsetMap(forCheckIns: allCheckIns)

        // trigger binding updates
        habits.value = allHabits
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

    func getCheckInCount(forHabit habit: Habit, forDateOffset dateOffset: Int) -> Int {
        return habitCheckInGridOffsetMap[habit.uuid!]?[dateOffset] ?? 0
    }
}

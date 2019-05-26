//
//  HabitListViewModel.swift
//  HabitPanda
//
//  Created by Tim Nance on 5/26/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import Foundation

class HabitListViewModel {
    var habits: Box<[Habit]> = Box([])

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
        habits.value = Habit.getAll(sortedBy: "createdAt")
    }
}

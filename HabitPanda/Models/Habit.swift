//
//  Habit.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/13/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit
import CoreData

@objc(Habit)
public class Habit: NSManagedObject {
    public static func getAll(sortedBy sortKey: String = "name") -> [Habit] {
        let context = (UIApplication.shared.delegate as! AppDelegate)
            .persistentContainer.viewContext
        var habits: [Habit] = []

        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: sortKey, ascending: true)
        ]

        do {
            habits = try context.fetch(request)
        } catch {
            print("Error fetching data from context, \(error)")
        }

        return habits
    }
}

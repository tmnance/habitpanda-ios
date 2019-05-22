//
//  Habit.swift
//  HabitPanda
//
//  Created by Tim Nance on 4/13/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit
import Foundation
import CoreData

@objc(Habit)
public class Habit: NSManagedObject {
    public static func getAll() -> [Habit] {
        let context = (UIApplication.shared.delegate as! AppDelegate)
            .persistentContainer.viewContext
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        var habits: [Habit] = []

        request.sortDescriptors = [
            NSSortDescriptor(key: "name", ascending: true)
        ]

        do {
            habits = try context.fetch(request)
        } catch {
            print("Error fetching data from context, \(error)")
        }

        return habits
    }
}

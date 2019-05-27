//
//  CheckIn.swift
//  HabitPanda
//
//  Created by Tim Nance on 5/13/19.
//  Copyright © 2019 Tim Nance. All rights reserved.
//

import UIKit
import CoreData

@objc(CheckIn)
public class CheckIn: NSManagedObject {
    func getCheckInDisplayDate() -> String {
        let date = checkInDate!
        let df = DateFormatter()

        df.dateFormat = "EEE, MMMM d"
        let displayDate = df.string(from: date)

        df.dateFormat = "h:mm a"
        let displayTime = df.string(from: date)
        return "\(displayDate) at \(displayTime)"
    }

    public static func getAll(
        sortedBy sortKey: String = "checkInDate",
        forHabitUUIDs habitUUIDs: [UUID]? = nil,
        afterDate: Date? = nil,
        beforeDate: Date? = nil
    ) -> [CheckIn] {
        let context = (UIApplication.shared.delegate as! AppDelegate)
            .persistentContainer.viewContext
        var checkIns: [CheckIn] = []

        let request: NSFetchRequest<CheckIn> = CheckIn.fetchRequest()
        var predicates: [NSPredicate] = []

        if let habitUUIDs = habitUUIDs {
            print("filtering \(habitUUIDs)")
            let uuidArgs = habitUUIDs.map { $0.uuidString as CVarArg }
            print("uuidArgs \(uuidArgs)")
            predicates.append(NSPredicate(format: "habit.uuid IN %@", uuidArgs))
        }

        if let afterDate = afterDate {
            predicates.append(NSPredicate(format: "checkInDate >= %@", afterDate as NSDate))
        }
        if let beforeDate = beforeDate {
            predicates.append(NSPredicate(format: "checkInDate <= %@", beforeDate as NSDate))
        }

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [
            NSSortDescriptor(key: sortKey, ascending: true)
        ]

        do {
            checkIns = try context.fetch(request)
        } catch {
            print("Error fetching data from context, \(error)")
        }

        return checkIns
    }
}
